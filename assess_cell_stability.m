function cell_stability_info = assess_cell_stability(tetrode_fNames,batNums,baseDir,expType,varargin)

overwriteFlag = true;

if ~isempty(varargin)
    cell_stability_info = varargin{1};
    cell_k = varargin{2};
else
    cell_stability_info = struct('batNum',[],'cellInfo',[],'tsStart',[],'tsEnd',[]);
    cell_k = 1;
end

date_regexp_str = '\d{8}';

figure('units','normalized','outerposition',[0 0 1 1]);

for k = cell_k:length(tetrode_fNames)
    
    cellInfo = strrep(tetrode_fNames(k).name,'.ntt','');
    cellInfo = strrep(cellInfo,[batNums{k} '_'],'');
    
    if ~overwriteFlag && any(strcmp({cell_stability_info.cellInfo},cellInfo) & strcmp({cell_stability_info.batNum},batNums{k}))
        continue        
    end
    
    tt_fName = fullfile(tetrode_fNames(k).folder,tetrode_fNames(k).name);
    
    exp_date = regexp(tetrode_fNames(k).name,date_regexp_str,'match');
    exp_date = exp_date{1};
    
    cell_stability_info(cell_k).batNum = batNums{k};
    cell_stability_info(cell_k).cellInfo = cellInfo;
    
    switch expType
        case 'juvenile'
            nlx_dir = [baseDir 'bat' batNums{b} filesep 'neurologger_recording' exp_date filesep 'nlxformat\'];
            events_fName = fullfile(nlx_dir,'EVENTS.mat');
        case 'adult'
            events_fName = dir(fullfile(tetrode_fNames(k).folder,'*EVENTS.mat'));
            events_fName = fullfile(events_fName.folder,events_fName.name);
    end
            
    
    display(['processing cell ' cell_stability_info(cell_k).cellInfo ', #' num2str(k) ' out of ' num2str(length(tetrode_fNames))])
    cell_stability_info = assess_stability(cell_stability_info,cell_k,tt_fName,events_fName);
    save(fullfile(baseDir,'documents','cell_stability_info.mat'),'cell_stability_info');
    cell_k = cell_k + 1;
    
end

end

function cell_stability_info = assess_stability(cell_stability_info,cell_k,tt_fName,events_fName)

session_strings = {'start_','stop_'};
recording_strings = {'Started recording','Stopped recording'};
digital_in_string = 'Digital in';

n_feat_to_plot = 4;

[timestamps, features] = Nlx2MatSpike(tt_fName,[1 0 0 1 0],0,1,[]);
events = load(events_fName);
%%
hold on
for i = 1:n_feat_to_plot
    scatter(1e-3*timestamps,features(i,:))
end
sessionTime = zeros(1,length(session_strings));
recordingTime = zeros(1,length(recording_strings));
for s = 1:length(session_strings)
    sessionIdx = cellfun(@(x) contains(x,session_strings{s}),events.event_types_and_details);
    if sum(sessionIdx) ~= 1
        if s == 1
            sessionIdx = find(cellfun(@(x) contains(x,digital_in_string),events.event_types_and_details),1,'first');
        else
            sessionIdx = find(cellfun(@(x) contains(x,digital_in_string),events.event_types_and_details),1,'last');
        end
    end
    sessionTime(s) = 1e-3*events.event_timestamps_usec(sessionIdx);
    plot(repmat(sessionTime(s),1,2),get(gca,'ylim'),'k')

    recordingIdx = cellfun(@(x) strcmp(x,recording_strings{s}),events.event_types_and_details);
    if sum(recordingIdx) ~= 1
        if s == 1
            recordingIdx = find(~isnan(events.event_timestamps_usec) & events.event_timestamps_usec>0,1,'first');
        else
            recordingIdx = find(~isnan(events.event_timestamps_usec) & events.event_timestamps_usec>0,1,'last');
        end
    end
    recordingTime(s) = 1e-3*events.event_timestamps_usec(recordingIdx);
    
end
xlim(recordingTime .* [0.99 1.01])
%%
unstable = input('Unstable?');

if unstable
    [x,~] = ginput(2*unstable);
    bounds = sort(x);
    cell_stability_info(cell_k).tsStart = bounds(1:2:2*unstable);
    cell_stability_info(cell_k).tsEnd = bounds(2:2:2*unstable);
else
    cell_stability_info(cell_k).tsStart = -inf;
    cell_stability_info(cell_k).tsEnd = inf;
end
cla

end