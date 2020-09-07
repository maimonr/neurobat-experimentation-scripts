function export_juvenile_lfp_data
eData = ephysData('juvenile');
baseDir = 'G:\Maimon\juvenile_recording';
outDir = 'F:\maimon\lfp_data\juvenile_recording';
t = tic;
file_k = 1;
for b = 1:length(eData.batNums)
    batDir = fullfile(baseDir,['bat' eData.batNums{b}]);
    nlg_dirs = dir(fullfile(batDir,'neurologger_recording*'));
    nlg_dirs = nlg_dirs(~arrayfun(@(exp) contains(exp.name,'_2'),nlg_dirs));
    for nlg_k = 1:length(nlg_dirs)
        lfp_fname = fullfile(batDir,nlg_dirs(nlg_k).name,'lfpformat','LFP.mat');
        if isfile(lfp_fname)
            exp_date_str = regexp(lfp_fname,'\d{8}','match');
            exp_date_str = exp_date_str{1};
            
            s = load(lfp_fname,'lfpData','active_channels','downsample_factor','filter_data','fs','orig_lfp_fs','timestamps');
            
            new_lfp_fname = fullfile(outDir,[eData.batNums{b} '_' exp_date_str '_LFP.mat']);
            save(new_lfp_fname,'-struct','s')
        end
        fprintf('%d s elapsed, %d files processed',round(toc(t)),file_k)
        file_k = file_k + 1;
    end
end