function assignCallIDs(expType,varargin)

nID = 1e6;
overwriteFlag = true;

if nargin == 0
    expType = 'juvenile';
    call_echo = 'call';
elseif nargin == 1
    call_echo = 'call';
elseif nargin == 2
    call_echo = varargin{1};
end

if any(strcmp(expType,{'juvenile','adult_wujie'}))
    
    addpath('C:\Users\phyllo\Documents\MATLAB\subdir\')
    eData = ephysData(expType);
    
    for b = 1:length(eData.batNums)
        switch expType
            case 'juvenile'
                baseDir = [eData.baseDirs{b} 'bat' eData.batNums{b} filesep];
            case 'adult'
                baseDir = eData.baseDirs{b};
        end
        cut_call_data_fNames = subdir([baseDir '*cut_' call_echo '_data.mat']);
        all_used_call_IDs = assign_cut_call_IDs(cut_call_data_fNames,nID,overwriteFlag);
    end
    
    rmpath('C:\Users\phyllo\Documents\MATLAB\subdir\')
    
elseif strcmp(expType,'piezo_recording')
    baseDir = 'Z:\users\Maimon\acoustic_recording\audio\';
    cut_call_data_fNames = dir([baseDir '*\audio\ch1\cut_call_data.mat']);
    
    all_used_call_IDs = assign_cut_call_IDs(cut_call_data_fNames,nID,overwriteFlag);
    
elseif any(strcmp(expType,{'adult','adult_operant','adult_social'}))
    baseDir = fullfile('Z:\users\Maimon\',[expType '_recording'],'call_data');
    cut_call_data_fNames = dir([baseDir '\*cut_' call_echo '_data*.mat']);
    
    all_used_call_IDs = assign_cut_call_IDs(cut_call_data_fNames,nID,overwriteFlag);
    
end

assert(length(unique(all_used_call_IDs)) == length(all_used_call_IDs));
end

function all_used_call_IDs = assign_cut_call_IDs(cut_call_data_fNames,nID,overwriteFlag)

usedID = false(1,nID);

for d = 1:length(cut_call_data_fNames)
    fName = fullfile(cut_call_data_fNames(d).folder,cut_call_data_fNames(d).name);
    s = load(fName);
    cut_call_data = s.cut_call_data;
    
    if ~overwriteFlag && isfield(cut_call_data,'uniqueID')
        if all(arrayfun(@(x) ~isempty(x.uniqueID),cut_call_data))
            used_uniqe_IDs = [cut_call_data.uniqueID];
            assert(~any(ismember(used_uniqe_IDs,find(usedID))))
            
            usedID(used_uniqe_IDs) = true;
            continue
        elseif any(arrayfun(@(x) ~isempty(x.uniqueID),cut_call_data))
            keyboard
        end
    end

    available_call_IDs = find(~usedID);
    sample_call_ID_idx = randperm(length(available_call_IDs),length(cut_call_data));
    usedID(available_call_IDs(sample_call_ID_idx)) = true;
    randIDs = num2cell(available_call_IDs(sample_call_ID_idx));

    [cut_call_data(1:length(cut_call_data)).uniqueID] = deal(randIDs{:});    
    save(fName,'cut_call_data');
    
end

all_used_call_IDs = find(usedID);

end