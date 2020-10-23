function export_adult_call_data(eData,outDir,sessionType)

baseDir = eData.baseDirs{1};
T = eData.recLogs;

T = T(strcmp(T.Session,sessionType) & T.usable,:);
nSession = height(T);

exp_date_dir_format = 'mmddyyyy';
exp_date_fname_format = 'yyyymmdd';

for k = 1:nSession
    
    exp_date_dir_str = datestr(T.Date(k),exp_date_dir_format);
    exp_date_fname_str = datestr(T.Date(k),exp_date_fname_format);
    boxStr = num2str(T.Box(k));
    if strcmp(sessionType,'operant')
        audio_exp_dir = fullfile(baseDir,exp_date_dir_str,'operant',['box' boxStr]);
    else
        audio_exp_dir = fullfile(baseDir,exp_date_dir_str,'audio',sessionType,'ch1');
    end
    
    audio2nlg_fName = fullfile(audio_exp_dir,'audio2nlg_fit.mat');
    
    if strcmp(sessionType,'operant')
        audio2nlg_fName_out = fullfile(outDir,[exp_date_fname_str '_audio2nlg_fit_operant_box_' boxStr '.mat']);
    elseif strcmp(sessionType,'social')
        audio2nlg_fName_out = fullfile(outDir,[exp_date_fname_str '_audio2nlg_fit_social.mat']);
    else
        audio2nlg_fName_out = fullfile(outDir,[exp_date_fname_str '_audio2nlg_fit.mat']);
    end
    
    if exist(audio2nlg_fName_out,'file') || ~exist(audio2nlg_fName,'file')
        continue
    end
    copyfile(audio2nlg_fName,audio2nlg_fName_out);
    
    cut_call_fName = fullfile(audio_exp_dir,'cut_call_data.mat');   
    manual_al_classify_fname = fullfile(audio_exp_dir,'manual_al_classify_batNum.mat');
    
    switch sessionType
        case 'communication'
            cut_call_fName_out = fullfile(outDir,[exp_date_fname_str '_cut_call_data.mat']);
        case 'operant'
            cut_call_fName_out = fullfile(outDir,[exp_date_fname_str '_cut_call_data_operant_box_' boxStr '.mat']);
        case 'vocal'
            cut_call_fName_out = fullfile(outDir,[exp_date_fname_str '_cut_call_data.mat']);
        case 'social'
            cut_call_fName_out = fullfile(outDir,[exp_date_fname_str '_cut_call_data_social.mat']);
    end
    
    if ~exist(cut_call_fName,'file') || ~exist(manual_al_classify_fname,'file') || exist(cut_call_fName_out,'file')
        continue
    end
    
    s = load(cut_call_fName);
    cut_call_data = s.cut_call_data;
    
    s = load(manual_al_classify_fname);
    manual_al_classify_batNum = s.manual_al_classify_batNum;
    
    assert(length(manual_al_classify_batNum) == length(cut_call_data) && ~any(cellfun(@isempty,manual_al_classify_batNum)));
    
    for call_k = 1:length(cut_call_data)
        cut_call_data(call_k).batNum = manual_al_classify_batNum{call_k};
        cut_call_data(call_k).noise = any(strcmp(manual_al_classify_batNum{call_k},'noise'));
    end
    
    idx = ~strcmp(manual_al_classify_batNum,'noise');
    cut_call_data = cut_call_data(idx);
    
    save(cut_call_fName_out,'cut_call_data');
    
end
