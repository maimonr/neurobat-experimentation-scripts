function cell_stability_info = export_adult_neural_data(tetrode_fNames,baseDir,outDir,expType,varargin)

pnames = {'date_regexp_str','cell_stability_info','cellType'};
dflts  = {'\d{8}',[],'singleUnit'};
[date_regexp_str,cell_stability_info,cellType] = internal.stats.parseArgs(pnames,dflts,varargin{:});

if strcmp(cellType,'multiUnit')
    lib_fname = 'C:\Users\phyllo\Documents\GitHub\LoggerDataProcessing\library_of_acceptable_spike_shapes.mat';
    s = load(lib_fname);
    spikeLib = zscore(s.library_of_acceptable_spike_shapes)';
    spike_corr_thresh = 0.9;
end

for f = 1:length(tetrode_fNames)
    
    cellInfo = strrep(tetrode_fNames(f).name,'.ntt','');
    spikes_fName = fullfile(outDir,[cellInfo '.csv']);
    batNum = cellInfo(1:5);
    cellInfo = cellInfo(7:end);
    
    if exist(spikes_fName,'file')
        continue
    end
    
    exp_date = regexp(tetrode_fNames(f).folder,date_regexp_str,'match');
    exp_date = exp_date{1};
    
    switch expType
        case 'adult_operant'
            
            audio2nlg_fname = fullfile(baseDir,exp_date,'audio','communication','ch1','audio2nlg_fit.mat');
            
            if ~exist(audio2nlg_fname,'file')
                operant_dirs = dir(fullfile(baseDir,exp_date,'operant','box*'));
                if ~isempty(operant_dirs)
                    audio2nlg_fname = fullfile(operant_dirs(1).folder,operant_dirs(1).name,'audio2nlg_fit.mat');
                end
                
                if ~exist(audio2nlg_fname,'file')
                    continue
                end
            end
            
        case 'adult_social'
            expDate = datetime(exp_date,'InputFormat','MMddyyyy');
            T = get_rec_logs;
            T = T(T.Date == expDate,:);
            sessType = T.Session{find(ismember(T.Session,{'social','vocal'}),1,'first')};
            audio2nlg_fname = fullfile(baseDir,exp_date,'audio',sessType,'ch1','audio2nlg_fit.mat');
            if ~exist(audio2nlg_fname,'file')
                continue
            end
    end
    
    audio2nlg = load(audio2nlg_fname);
    
    if strcmp(cellType,'singleUnit')
        stabilityIdx = strcmp({cell_stability_info.cellInfo},cellInfo) & strcmp({cell_stability_info.batNum},batNum);
        if ~any(stabilityIdx)
            continue
        end
    end
    
    ttDir = fullfile(tetrode_fNames(f).folder,tetrode_fNames(f).name);
    
    if strcmp(cellType,'singleUnit')
        timestamps = Nlx2MatSpike(ttDir,[1 0 0 0 0],0,1,[]); % load sorted cell data
        timestamps = 1e-3*timestamps; % convert to ms
        timestamps_idx = false(1,length(timestamps));
        if all(isinf(cell_stability_info(stabilityIdx).tsStart)) && all(isinf(cell_stability_info(stabilityIdx).tsEnd))
            cell_stability_info(stabilityIdx).tsStart = min(timestamps)-eps;
            cell_stability_info(stabilityIdx).tsEnd = max(timestamps)+eps;
        end
        
        current_stability_info = cell_stability_info(stabilityIdx);
        for bound_k = 1:length(current_stability_info.tsStart)
            stabilityBounds = [current_stability_info.tsStart(bound_k) current_stability_info.tsEnd(bound_k)];
            [~,bound_idx] = inRange(timestamps,stabilityBounds);
            timestamps_idx = timestamps_idx | bound_idx;
        end
        timestamps = timestamps(timestamps_idx);
    elseif strcmp(cellType,'multiUnit')
        [timestamps, cellIdx, samples] = Nlx2MatSpike(ttDir,[1 0 1 0 1],0,1,[]); % load sorted cell data
        
        timestamps = 1e-3*timestamps; % convert to ms
        timestamps = timestamps(cellIdx == 0);
        samples = samples(:,:,cellIdx == 0);
        [~,idx] = max(max(samples,[],1));
        max_channel_samples = zeros(size(samples,1),size(samples,3));
        for spike_k = 1:size(samples,3)
            max_channel_samples(:,spike_k) = squeeze(samples(:,idx(spike_k),spike_k));
        end
        
        r = corr(max_channel_samples,spikeLib);
        r = max(r,[],2);
        timestamps = timestamps(r>spike_corr_thresh);
    end
    
    timestamps = timestamps - audio2nlg.first_nlg_pulse_time; % keep spikes during stable period and align to first TTL pulse on the NLG
    
    dlmwrite(spikes_fName,timestamps,'delimiter',',','precision','%.3f');
    
end

end