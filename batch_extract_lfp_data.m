function [success,errs] = batch_extract_lfp_data(eData,baseDir)

overwrite_flag = false;
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
    exp_dir = fullfile(exp_dirs(k).folder,exp_dirs(k).name);
    for b = 1:length(eData.batNums)
        if ~isempty(dir(fullfile(exp_dir,'neurologgers','**',[eData.batNums{b} '*CSC0.mat'])))
            try
                extract_lfp_data(exp_dir,eData.expType{b},eData.batNums{b},overwrite_flag,eData.activeChannels{b});
            catch err
                errs{total_dirs} = err;
                success(total_dirs) = false;
            end
            success(total_dirs) = true;
            
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
