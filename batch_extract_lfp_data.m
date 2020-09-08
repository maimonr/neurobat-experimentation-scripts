function [success,errs] = batch_extract_lfp_data(eData,baseDir,varargin)

pnames = {'localDir','overwrite_flag'};
dflts  = {[],false,false};
[localDir,overwrite_flag] = internal.stats.parseArgs(pnames,dflts,varargin{:});

remote_copy_flag = ~isempty(localDir);

total_dirs = 1;
t = tic;
success = [];
exp_dirs = dir(fullfile(baseDir,'*20*'));

all_exp_dirs = cell(1,length(exp_dirs));
for k = 1:length(exp_dirs)
    all_exp_dirs{k} = dir(fullfile(exp_dirs(k).folder,exp_dirs(k).name,'neurologgers','logger*','extracted_data','*CSC0.mat'));
end

lastProgress = 0;
for k = 1:length(exp_dirs)
    [exp_dir,remote_exp_dir] = deal(fullfile(exp_dirs(k).folder,exp_dirs(k).name));
    if remote_copy_flag
        exp_date_str = exp_dirs(k).name;
        expDate = datetime(exp_date_str,'InputFormat','MMddyyyy');
        local_exp_dir = fullfile(localDir,exp_date_str);
        exp_dir = local_exp_dir;
    end
    for b = 1:length(eData.batNums)
        nlgDir = dir(fullfile(remote_exp_dir,'neurologgers','**',[eData.batNums{b} '*CSC0.mat']));
        if ~isempty(dir(fullfile(remote_exp_dir,'neurologgers','**',[eData.batNums{b} '*CSC0.mat'])))
            if remote_copy_flag
                remote_nlg_dir = fullfile(nlgDir(1).folder,'*CSC*.mat');
                remote_lfp_dir = fullfile(remote_exp_dir,'lfpformat');
                
                if ~overwrite_flag &&  ~isempty(dir(fullfile(remote_lfp_dir,[eData.batNums{b} '*LFP.mat'])))
                    disp('LFP file already exists')
                    continue
                end
                
                T = get_rec_logs;
                
                T = T(T.Date == expDate,:);
                sessType = T.Session{find(ismember(T.Session,{'social','vocal'}),1,'first')};
                remote_audio_dir = fullfile(remote_exp_dir,'audio',sessType,'ch1','audio2nlg_fit.mat');
                
                local_nlg_dir = fullfile(local_exp_dir,'neurologgers','extracted_data');
                local_audio_dir = fullfile(local_exp_dir,'audio',sessType,'ch1');
                mkdir(local_audio_dir)
                
                if ~exist(remote_audio_dir,'file')
                    disp('Could not file audio2nlg file')
                    errs{total_dirs} = 'Could not file audio2nlg file';
                    continue
                end
                remote_copy(remote_audio_dir,local_audio_dir);
                remote_copy(remote_nlg_dir,local_nlg_dir);
            end
            
            try
                extract_lfp_data(exp_dir,eData.expType{b},eData.batNums{b},overwrite_flag,eData.activeChannels{b});
            catch err
                errs{total_dirs} = err;
                success(total_dirs) = false;
            end
            success(total_dirs) = true;
            
            if remote_copy_flag
                local_lfp_dir = fullfile(local_exp_dir,'lfpformat');
                remote_lfp_dir = fullfile(remote_exp_dir,'lfpformat');
                remote_copy(local_lfp_dir,remote_lfp_dir);
                
                [rmdir_status, rmdir_err_msg] = rmdir(local_exp_dir,'s');
                if ~rmdir_status
                    disp(rmdir_err_msg)
                    keyboard
                end
            end
            
            progress = 100*(total_dirs/length(all_exp_dirs));
            elapsed_time = round(toc(t));
            
            if mod(progress,10) < mod(lastProgress,10)
                fprintf('%d %% of current bat''s directories  processed\n',round(progress));
                fprintf('%d total directories processed, %d s elapsed\n',total_dirs,elapsed_time);
            end
            total_dirs = total_dirs + 1;
            lastProgress = progress;
        end
    end
end

end

function [status,copy_err_msg] = remote_copy(remoteDir,localDir)

status = false;
copy_err_msg = [];

TicTransfer = tic;

while ~status && toc(TicTransfer)<30*60
    [status,copy_err_msg] = copyfile(remoteDir,localDir,'f');
end


if ~status
    disp('Failed to copy folder TO server after 30 minutes')
    disp(copy_err_msg)
    keyboard
end

end
