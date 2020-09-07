function [all_call_info,expDates] = assign_bhv_call_ids(cData,bhvDir)

baseDir = 'Y:\users\maimon\adult_recording\';
expDirs = dir(fullfile(baseDir,'*20*'));
expDates = cellfun(@(x) datetime(x,'InputFormat','MMddyyyy'),{expDirs.name});

call_bhv_dirs = cell(1,length(expDirs));
for k = 1:length(expDirs)
    call_bhv_dirs{k} = dir(fullfile(expDirs(k).folder,expDirs(k).name,'audio\communication\ch1\call_info*.mat'));
end
expDates = expDates(~cellfun(@isempty,call_bhv_dirs));
call_bhv_dirs = vertcat(call_bhv_dirs{:});

n_call_bhv_files = length(expDates);
all_call_info = cell(1,n_call_bhv_files);
for k = 1:n_call_bhv_files
    s = load(fullfile(call_bhv_dirs(k).folder,call_bhv_dirs(k).name));
    call_info = s.call_info;
    for call_k = 1:length(call_info)
        callID = cData.callID(cData.file_call_pos(:,1) == call_info(call_k).eventpos(1) & cData.expDay == expDates(k));
        if length(callID) ~= 1
            call_info(call_k).callID = NaN;
        else
            call_info(call_k).callID = callID;
        end
    end
    [call_info.expDate] = deal(expDates(k));
    all_call_info{k} = call_info;
    save(fullfile(call_bhv_dirs(k).folder,call_bhv_dirs(k).name),'call_info')
    save(fullfile(bhvDir,call_bhv_dirs(k).name),'call_info')
end



end