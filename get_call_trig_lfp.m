function call_trig_csc_struct = get_call_trig_lfp(expType,batNum,cut_call_data,lfp_call_offset,lfp_file_name,lfpData)

overwriteFlag = false;
replace_artifacts = false;

if any(strcmp(expType,{'adult','adult_operant','adult_social'}))
                
        callpos = 1e-3*vertcat(cut_call_data.corrected_callpos)';
        if isempty(callpos) || any(isnan(callpos(:)))
            return
        end
        
        fs = lfpData.fs;
        timestamps = lfpData.timestamps;
        
        outDir = lfp_file_name;
        
elseif strcmp(expType,'juvenile')

        cut_call_data = cut_call_data(~[cut_call_data.noise]);
        if isempty(cut_call_data)
            call_trig_csc_struct = [];
            return
        end
        
        callpos = 1e-3*vertcat(cut_call_data.corrected_callpos)';
        if isempty(callpos) || any(isnan(callpos(:)))
            return
        end
        
        fs = lfpData.fs;
        timestamps = lfpData.timestamps;
        outDir = lfp_file_name;
        
elseif strcmp(expType,'adult_wujie')

        cut_call_data = cut_call_data(~[cut_call_data.noise]);
        if isempty(cut_call_data)
            call_trig_csc_struct = [];
            return
        end
        
        eData = ephysData('adult');
        [~,lfp_fName]=fileparts(lfp_file_name);
        lfp_fname_parts = strsplit(lfp_fName,'_');
        exp_dir_str = lfp_fname_parts{2};
        
        b = cellfun(@(x) contains(lfp_file_name,x),eData.batNums);
        batIdx = unique(cellfun(@(call) find(cellfun(@(bNum) strcmp(bNum,eData.batNums{b}),call)),{cut_call_data.batNum}));
        
        if length(batIdx) == 1
            callpos = horzcat(cut_call_data.corrected_callpos);
            callpos = callpos(batIdx,:);
            [cut_call_data.corrected_callpos] = deal(callpos{:});
        else
            keyboard
        end
        call_info_fname = dir([audioDir 'call_info_*_call_' exp_dir_str '.mat']);
        if length(call_info_fname) > 1
            keyboard
        end
        s = load(fullfile(call_info_fname.folder,call_info_fname.name));
        call_info = s.call_info;
        
        assert(all([cut_call_data.uniqueID] == [call_info.callID]));
        
        bat_calls = cellfun(@(x) ischar(x{1}) && contains(x,batNum),{call_info.behaviors});
        cut_call_data = cut_call_data(bat_calls);
        callpos = 1e-3*vertcat(cut_call_data.corrected_callpos)';
        
        if isempty(callpos) || any(isnan(callpos(:)))
            return
        end
        
        fs = lfpData.sampling_freq;
        timestamps = 1e-3*lfpData.timestamps_ms;
end

if ~overwriteFlag
    m = matfile(lfp_file_name);
    varNames = who(m);
    
    if ~overwriteFlag && any(ismember(varNames,'call_trig_csc_struct'))
        disp('call trig lfp already calculated')
        return
    end
end

if replace_artifacts
    artifact_info = load(lfp_file_name,'logical_indices_artifacts', 'artifact_replacement_voltages');
end
notch_filter_60Hz=designfilt('bandstopiir','FilterOrder',2,'HalfPowerFrequency1',59.5,'HalfPowerFrequency2',60.5,'DesignMethod','butter','SampleRate',fs);
notch_filter_120Hz=designfilt('bandstopiir','FilterOrder',2,'HalfPowerFrequency1',119.5,'HalfPowerFrequency2',120.5,'DesignMethod','butter','SampleRate',fs);
filters = {notch_filter_60Hz,notch_filter_120Hz};
%%

n_channel = length(lfpData.active_channels);

lfp_call_offset_csc_samples = round(lfp_call_offset*fs);
n_lfp_samples = 2*lfp_call_offset_csc_samples + 1;

used_call_idx = find([Inf diff(callpos(1,:))] > lfp_call_offset & (callpos(1,:)-lfp_call_offset > min(timestamps)) & (callpos(2,:)+lfp_call_offset < max(timestamps)));
used_call_IDs = [cut_call_data(used_call_idx).uniqueID];
n_used_calls = length(used_call_idx);
batNums = {cut_call_data(used_call_idx).batNum};

call_trig_csc = zeros(n_lfp_samples,n_used_calls,n_channel);
included_artifact_indices = cell(n_used_calls,n_channel);
for ch = 1:n_channel
    if replace_artifacts
        artifact_indices = find(artifact_info.logical_indices_artifacts(ch,:));
        lfpData.lfpData(ch,artifact_info.logical_indices_artifacts(ch,:)) = artifact_info.artifact_replacement_voltages(ch,artifact_indices);
    end
    k = 1;
    for call_k = used_call_idx
        [~,csc_call_idx] = min(abs(timestamps - callpos(1,call_k))); 
        csc_idx = (csc_call_idx-lfp_call_offset_csc_samples):(csc_call_idx+lfp_call_offset_csc_samples);
        if replace_artifacts
            included_artifact_indices{k,ch} = intersect(csc_idx,artifact_indices,'stable');
        end
        call_trig_csc(:,k,ch) = lfpData.lfpData(ch,csc_idx);
        call_trig_csc(:,k,ch) = filtfilt(notch_filter_60Hz,call_trig_csc(:,k,ch));
        call_trig_csc(:,k,ch) = filtfilt(notch_filter_120Hz,call_trig_csc(:,k,ch));
        k = k + 1;
    end
end

call_trig_csc_struct = struct('call_trig_csc',call_trig_csc,'used_call_IDs',used_call_IDs,...
    'filters',{filters},'included_artifact_indices',{included_artifact_indices},...
    'lfp_call_offset',lfp_call_offset,'batNums',{batNums},'active_channels',lfpData.active_channels);

if exist('outDir','var')
    save(outDir,'-struct','call_trig_csc_struct')
else
    save(lfp_file_name,'-append','call_trig_csc_struct')
end

end