function batch_get_call_trig_lfp(eData,remoteDir,varargin)

pnames = {'overwrite_call_trig','callType','lfp_call_offset'};
dflts  = {false,'call',4};
[overwrite_call_trig_flag,callType,lfp_call_offset] = internal.stats.parseArgs(pnames,dflts,varargin{:});

t = tic;
total_dirs = 0;

if any(strcmp(eData.expType{1},{'adult','adult_operant','adult_social'}))
    
    all_lfp_dirs = get_lfp_data_fnames(remoteDir);
    lfp_data_dir = fullfile(eData.baseDirs{1},'lfp_data\');
    call_data_dir = fullfile(eData.baseDirs{1},'call_data\');
    
    lastProgress = 0;
    for k = 1:length(all_lfp_dirs)
        
        [cut_call_data_fname,call_trig_lfp_fname,batNum] = get_event_trig_fnames(eData,all_lfp_dirs(k).name,call_data_dir,callType);
        
        call_trig_lfp_fname = fullfile(lfp_data_dir,call_trig_lfp_fname);
        
        if exist(call_trig_lfp_fname,'file') && ~overwrite_call_trig_flag
            disp('call trig lfp file already exists, continuing')
            continue
        end
        
        if ~exist(cut_call_data_fname,'file')
            continue
        end
        
        s = load(cut_call_data_fname,'cut_call_data');
        cut_call_data = s.cut_call_data;
        
        lfp_fname = fullfile(all_lfp_dirs(k).folder,all_lfp_dirs(k).name);
        lfpData = matfile(lfp_fname);
        
        get_call_trig_lfp(eData.expType{1},batNum,cut_call_data,lfp_call_offset,call_trig_lfp_fname,lfpData);
        
        progress = 100*(k/length(all_lfp_dirs));
        elapsed_time = round(toc(t));
        if mod(progress,10) < mod(lastProgress,10)
            fprintf('%d %% of directories  processed, %d s elapsed\n',round(progress),elapsed_time);
        end
        lastProgress = progress;
        
    end
    
    
    
elseif strcmp(eData.expType{1},'juvenile')
    call_data_dir = fullfile(eData.baseDirs{1},'call_data\');
    for b = 1:length(eData.batNums)
        lfp_data_dir = fullfile(eData.baseDirs{b},'lfp_data\');
        batNum = eData.batNums{b};
        baseDir = fullfile(remoteDir,['bat' batNum]);
        nlgDirs = dir(fullfile(baseDir,'neurologger_recording*'));
        lastProgress = 0;
        for d = 1:length(nlgDirs)
            exp_dir = fullfile(baseDir,nlgDirs(d).name);
            lfp_dir = fullfile(exp_dir,'lfpformat');
            lfp_file_name = fullfile(lfp_dir,'LFP.mat');
            
            exp_date_str = regexp(exp_dir,'\d{8}','match');
            exp_date_str = exp_date_str{1};
            
            if exist(lfp_file_name,'file')
                
                call_trig_lfp_fname = fullfile(lfp_data_dir, [batNum '_' exp_date_str '_' callType '_trig.mat']);
                cut_call_data_fname = fullfile(call_data_dir,[batNum '_' exp_date_str '_cut_call_data.mat']);
                
                if exist(call_trig_lfp_fname,'file') && ~overwrite_call_trig_flag
                    disp('call trig lfp file already exists, continuing')
                    continue
                end
                
                if ~exist(cut_call_data_fname,'file')
                    continue
                end
                
                s = load(cut_call_data_fname,'cut_call_data');
                cut_call_data = s.cut_call_data;
                
                lfpData = load(lfp_file_name,'lfpData','fs','timestamps','active_channels');
                
                channelIdx = ismember(lfpData.active_channels,eData.activeChannels{b});
                lfpData.lfpData = lfpData.lfpData(channelIdx,:);
                
                get_call_trig_lfp(eData.expType{b},batNum,cut_call_data,lfp_call_offset,call_trig_lfp_fname,lfpData);
            end
            progress = 100*(d/length(nlgDirs));
            elapsed_time = round(toc(t));
            total_dirs = total_dirs + 1;
            if mod(progress,10) < mod(lastProgress,10)
                fprintf('%d %% of current bat''s directories  processed\n',round(progress));
                fprintf('%d total directories processed, %d s elapsed\n',total_dirs,elapsed_time);
            end
            lastProgress = progress;
        end
    end
    
elseif strcmp(eData.expType, 'adult_wujie')
    
    lfp_files = dir([eData.lfp_data_dir '*LFP.mat']);
    lastProgress = 0;
    for k = 1:length(lfp_files)
        lfp_fname_parts = strsplit(lfp_files(k).name,'_');
        batNum = lfp_fname_parts{1};
        exp_dir_str = lfp_fname_parts{2};
        
        b = strcmp(eData.batNums,batNum);
        bNum = eData.batNums{b};
        baseDir = eData.baseDirs{b};
        exp_dir = [baseDir 'neurologger_recording' exp_dir_str filesep];
        if ~exist(exp_dir,'dir')
            continue
        end
        bat_dir = dir([exp_dir 'bat' bNum '*']);
        
        if isempty(bat_dir)
            exp_dir = [baseDir 'neurologger_recording' exp_dir_str '_2' filesep];
            bat_dir = dir([exp_dir 'bat' bNum '*']);
            if isempty(bat_dir)
                keyboard
            end
        end
        
        lfp_file_name = fullfile(lfp_files(k).folder,lfp_files(k).name);
        
        proceed_with_call_trig_lfp = check_for_saved_variable(lfp_file_name,'call_trig_csc_struct',overwrite_call_trig_flag);
        
        if proceed_with_call_trig_lfp
            lfpData = load(lfp_file_name);
            get_call_trig_lfp(exp_dir,lfp_call_offset,eData.expType,overwrite_call_trig_flag,lfp_file_name,lfpData);
        end
    end
    progress = 100*(k/length(lfp_files));
    elapsed_time = round(toc(t));
    total_dirs = total_dirs + 1;
    if mod(progress,10) < mod(lastProgress,10)
        fprintf('%d %% of current bat''s directories  processed\n',round(progress));
        fprintf('%d total directories processed, %d s elapsed\n',total_dirs,elapsed_time);
    end
    lastProgress = progress;
    
end

end

function proceed = check_for_saved_variable(fName,varName,overwriteFlag)


if ~overwriteFlag
    m = matfile(fName);
    varNames = who(m);
    if any(ismember(varNames,varName))
        proceed = false;
        disp([varName ' already processed'])
    else
        proceed = true;
    end
else
    proceed = true;
end

end

function all_lfp_dirs = get_lfp_data_fnames(remoteDir)

if contains(remoteDir,'lfp_data')
    all_lfp_dirs = dir(fullfile(remoteDir,'*LFP.mat'));
else
    exp_dirs = dir(fullfile(remoteDir,'*20*'));
    
    all_lfp_dirs = cell(1,length(exp_dirs));
    for k = 1:length(exp_dirs)
        all_lfp_dirs{k} = dir(fullfile(exp_dirs(k).folder,exp_dirs(k).name,'lfpformat','*LFP.mat'));
    end
    all_lfp_dirs = vertcat(all_lfp_dirs{:});
end
end

function [cut_call_data_fname,call_trig_lfp_fname,batNum] = get_event_trig_fnames(eData,lfpDir,call_data_dir,callStr)

batNum = regexp(lfpDir,'\d{5}','match');
batNum = batNum{1};
b = strcmp(eData.batNums,batNum);

exp_day_str = regexp(lfpDir,'\d{8}','match');
exp_day_str = exp_day_str{1};

call_trig_lfp_fname = strrep(lfpDir,'.mat','');

if strcmp(callStr,'operant')
    cut_call_data_fname = fullfile(call_data_dir,[exp_day_str '_cut_call_data_operant_box_' eData.boxNums{b} '.mat']);
    call_trig_lfp_fname = [call_trig_lfp_fname '_call_trig_operant.mat'];
elseif strcmp(callStr,'social')
    cut_call_data_fname = fullfile(call_data_dir,[exp_day_str '_cut_call_data_social.mat']);
    call_trig_lfp_fname = [call_trig_lfp_fname '_call_trig_operant.mat'];
else
    cut_call_data_fname = fullfile(call_data_dir,[exp_day_str '_cut_' callStr '_data.mat']);
    call_trig_lfp_fname = [call_trig_lfp_fname '_' callStr '_trig.mat'];
end

end