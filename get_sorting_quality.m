function sortingInfo = get_sorting_quality(eData,predModel,ttFnames,varargin)

if ~isempty(predModel)
    predictQuality = true;
else
    predictQuality = false;
end

if ~isempty(varargin)
    sortingInfo = varargin{1};
    cell_k = length(sortingInfo)+1;
else
    sortingInfo = struct('batNum',[],'cellInfo',[],'isolationDistance',[],'LRatio',[],'sortingQuality',[]);
    cell_k = 1;
end

ttExt = '.ntt';

ttSplit = strsplit(ttFnames(1).name(1:end-4),'_');
current_tetrode_file = fullfile(ttFnames(1).folder,[strjoin(ttSplit(1:3),'_') ttExt]);
load_tt_file = true;
for d = 1:length(ttFnames)
    ttSplit = strsplit(ttFnames(d).name(1:end-4),'_');
    tetrode_file = fullfile(ttFnames(d).folder,[strjoin(ttSplit(1:3),'_') ttExt]);
    clusterNum = str2double(ttSplit{5});
    
    tetrodeNum = str2double(ttSplit{3}(3:end));
    
    if ~ismember(ttSplit{1},eData.batNums)
        continue
    end
    
    if any(strcmp({sortingInfo.batNum},ttSplit{1}) & strcmp({sortingInfo.cellInfo},strjoin(ttSplit(2:5),'_')))
       continue 
    end
    
    sortingInfo(cell_k).batNum = ttSplit{1};
    sortingInfo(cell_k).cellInfo = strjoin(ttSplit(2:5),'_');
    
    b = strcmp(sortingInfo(cell_k).batNum,eData.batNums);
    
    display(['processing cell ' sortingInfo(cell_k).batNum ' - ' sortingInfo(cell_k).cellInfo ', #' num2str(d) ' out of ' num2str(length(ttFnames))])
    
    if ~strcmp(tetrode_file,current_tetrode_file) || load_tt_file
        [cellNumbers, samples] = Nlx2MatSpike(tetrode_file,[0 0 1 0 1],0,1,[]);
        peak = squeeze(max(samples,[],1));
        height = squeeze(abs(max(samples,[],1) - min(samples,[],1)));
        current_tetrode_file = tetrode_file;
    end
    
    featureIdx = ismember(4*(tetrodeNum-1):4*(tetrodeNum)-1,eData.activeChannels{b});
    
    [~, Lratio_peak] = calculate_L_ratio(peak(featureIdx,:)', find(cellNumbers==clusterNum));
    isoDist_peak = calculate_isolation_distance(peak(featureIdx,:)', find(cellNumbers==clusterNum));
    
    
    [~, Lratio_height] = calculate_L_ratio(height(featureIdx,:)', find(cellNumbers==clusterNum));
    isoDist_height = calculate_isolation_distance(height(featureIdx,:)', find(cellNumbers==clusterNum));
    
    isoDist = max(isoDist_peak,isoDist_height);
    Lratio = min(Lratio_peak,Lratio_height);
    
    sortingInfo(cell_k).isolationDistance = isoDist;
    sortingInfo(cell_k).LRatio = Lratio;
    
    if predictQuality
        dataSample = table(isoDist,Lratio,'VariableNames',{'isolationDistance','LRatio'});
        sortingInfo(cell_k).sortingQuality = predModel.predictFcn(dataSample);
    end
    
    cell_k = cell_k + 1;
    load_tt_file = false;
end


end
