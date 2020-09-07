function extract_lfp_data(exp_dir,expType,batNum,overwrite_flag,active_channels)

if nargin == 3
    overwrite_flag = false;
    active_channels = 0:15;
elseif nargin == 4
    active_channels = 0:15;
end
low_pass_filt_stopband = 1000;
low_pass_filt_cutoff = 1200;
downsample_factor = 15;
if strcmp(expType,'juvenile')
    csc_data_dir = [exp_dir 'nlxformat\'];
    lfp_dir = [exp_dir 'lfpformat\'];
    audio_dir = [exp_dir 'audio\ch1\'];
    csc_files = dir([csc_data_dir 'CSC*.mat']);
    csc_file_names = {csc_files.name};
    lfp_fname = fullfile(lfp_dir, 'LFP.mat');
elseif any(strcmp(expType,{'adult','adult_operant'}))
    csc_files = dir(fullfile(exp_dir,'neurologgers','**',[batNum '*CSC*.mat']));
    csc_file_names = {csc_files.name};
    csc_data_dir = unique({csc_files.folder});
    assert(length(csc_data_dir) == 1)
    csc_data_dir = csc_data_dir{1};
    lfp_dir = fullfile(exp_dir,'lfpformat');
    audio_dir = fullfile(exp_dir,'audio\communication\ch1');
    if ~exist(audio_dir,'dir')
        audio_dir = dir(fullfile(exp_dir,'operant','box*'));
        audio_dir = fullfile(audio_dir(1).folder,audio_dir(1).name);
    end
    exp_date_str = regexp(csc_file_names{1},'\d{8}','match');
    exp_date_str = exp_date_str{1};
    lfp_fname = fullfile(lfp_dir,[batNum '_' exp_date_str '_LFP.mat']);
elseif strcmp(expType,'adult_social')
    
    csc_files = dir(fullfile(exp_dir,'neurologgers','**',[batNum '*CSC*.mat']));
    csc_file_names = {csc_files.name};
    csc_data_dir = unique({csc_files.folder});
    assert(length(csc_data_dir) == 1)
    csc_data_dir = csc_data_dir{1};
    lfp_dir = fullfile(exp_dir,'lfpformat');

    exp_date_str = regexp(csc_file_names{1},'\d{8}','match');
    exp_date_str = exp_date_str{1};
    lfp_fname = fullfile(lfp_dir,[batNum '_' exp_date_str '_LFP.mat']);
    
    T = get_rec_logs;
    expDate = datetime(exp_date_str,'InputFormat','yyyyMMdd');
    T = T(T.Date == expDate,:);
    sessType = T.Session{find(ismember(T.Session,{'social','vocal'}),1,'first')};
    audio_dir = fullfile(exp_dir,'audio',sessType,'ch1');
end

if exist(lfp_fname,'file') && ~overwrite_flag
    disp('lfp directory already exists, skipping processing')
    return
elseif ~exist(lfp_dir,'dir')
    mkdir(lfp_dir)
end

audio2nlg = load(fullfile(audio_dir,'audio2nlg_fit.mat'));

csc_str = 'CSC';
processed_channels = cellfun(@(x) regexp(x,[csc_str '\d{1,2}'],'match'),csc_file_names);
processed_channels = cellfun(@(x) str2double(strrep(x,csc_str,'')),processed_channels);
active_channels = processed_channels(ismember(processed_channels,active_channels));
[active_channels,idx] = sort(active_channels);
csc_file_names = csc_file_names(idx);
nChannel = length(csc_file_names);

csc_fname_idx = contains({csc_files.name},['CSC' num2str(active_channels(1)) '.mat']);

if strcmp(expType,'juvenile')
    tsData = load(fullfile(csc_data_dir,csc_files(csc_fname_idx).name),'AD_count_int16','sampling_period_usec','AD_count_to_uV_factor');
    nSamp = length(tsData.AD_count_int16);
    AD_count_to_uV_factor = tsData.AD_count_to_uV_factor;
    orig_lfp_fs = round(1/(tsData.sampling_period_usec*1e-6));
elseif any(strcmp(expType,{'adult','adult_operant','adult_social'}))
    tsData = matfile(fullfile(csc_data_dir,csc_files(csc_fname_idx).name));
    nSamp = length(tsData.AD_count_int16);
    orig_lfp_fs = round(nanmean(tsData.Estimated_channelFS_Transceiver));
    AD_count_to_uV_factor = tsData.AD_count_to_uV_factor;
end

clear tsData

fcuts = [low_pass_filt_stopband low_pass_filt_cutoff];
mags = [1 0];
devs = [0.05 0.01];
[n,Wn,beta,ftype] = kaiserord(fcuts,mags,devs,orig_lfp_fs);
n = n + rem(n,2);
hh = fir1(n,Wn,ftype,kaiser(n+1,beta),'noscale');
delay = round(mean(grpdelay(hh)));

nT = (1+floor((nSamp-delay-1)/downsample_factor));

lfpData = zeros(nChannel,nT);

for c = 1:nChannel
    csc_fname_idx = contains({csc_files.name},['CSC' num2str(active_channels(c)) '.mat']);
    current_channel_lfp_data = load(fullfile(csc_data_dir,csc_files(csc_fname_idx).name),'AD_count_int16');
    current_channel_lfp_data = double(AD_count_to_uV_factor*current_channel_lfp_data.AD_count_int16);
    current_channel_lfp_data = filter(hh,1,current_channel_lfp_data);
    current_channel_lfp_data(1:delay) = [];
    current_channel_lfp_data = downsample(current_channel_lfp_data,downsample_factor);
    lfpData(c,:) = current_channel_lfp_data;
end
%%
if strcmp(expType,'juvenile')
        tsData = load(fullfile(csc_data_dir,csc_files(csc_fname_idx).name),'indices_of_first_samples','timestamps_of_first_samples_usec','sampling_period_usec','AD_count_to_uV_factor');
        timestamps_usec = get_timestamps_for_Nlg_voltage_all_samples(nSamp,tsData.indices_of_first_samples,tsData.timestamps_of_first_samples_usec,tsData.sampling_period_usec);
elseif any(strcmp(expType,{'adult','adult_operant','adult_social'}))
        tsData = load(fullfile(csc_data_dir,csc_files(csc_fname_idx).name),'Indices_of_first_and_last_samples','Timestamps_of_first_samples_usec','Estimated_channelFS_Transceiver');
        orig_lfp_sampling_period = 1e6/nanmean(tsData.Estimated_channelFS_Transceiver);
        timestamps_usec = get_timestamps_for_Nlg_voltage_all_samples(nSamp,tsData.Indices_of_first_and_last_samples(:,1)',...
            tsData.Timestamps_of_first_samples_usec,orig_lfp_sampling_period);
        
end

timestamps = 1e-3*(1e-3*timestamps_usec - audio2nlg.first_nlg_pulse_time); % in seconds, aligned to beginning of communication session
timestamps = timestamps(1:end-delay);
timestamps = downsample(timestamps,downsample_factor);
%%
fs = round(orig_lfp_fs/downsample_factor);
filter_data = struct('low_pass_filt_stopband',low_pass_filt_stopband,'low_pass_filt_cutoff',low_pass_filt_cutoff,'fcuts',fcuts,'mags',mags,'devs',devs,'filter_coef',hh);
save(lfp_fname,'lfpData','timestamps','fs','active_channels','downsample_factor','orig_lfp_fs','filter_data','-v7.3');


end