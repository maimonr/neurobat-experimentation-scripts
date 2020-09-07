function save_logger_data
script_dir = 'C:\Users\Batman\Documents\GoogleDriveNeuroBatGroup\JuvenileRecordings\'; % location of .bat file and xlsx file

loggerStrings = {'AUDIOLOG','MOUSELOG'};
logger_dir_strings = {'audiologgers','neurologgers'};
base_dir = 'C:\Users\Batman\Documents\DataDeuteron'; % base saving directory
DateStr = datestr(date,'yyyymmdd'); % date string for saving

status = dos([script_dir 'list_drive_letters.bat']);
if status
    disp('error getting drive names')
    return
end

fid = fopen([script_dir 'drivenames.txt']);
driveNames = textscan(fid,'%s','Delimiter','\n');
fclose(fid);
driveNames = driveNames{1}(~cellfun(@isempty,driveNames{1}));

idx = find(cellfun(@(x) contains(x,'--'),driveNames));
nDrive = idx - 1;

driveLetters = driveNames(1:nDrive);
driveLabels = driveNames(idx+1:idx+nDrive);

%% First transfer logger data of the SD cards and save event files as CSV format
fprintf(1,'1. Transferring data from SD cards\n')
logger_data_dir = cell(length(loggerStrings),1);
for logger_type_k = 1:length(loggerStrings)
    drive_idx = find(cellfun(@(x) ~isempty(strfind(x,loggerStrings{logger_type_k})),driveLabels));
    nLoggers = length(drive_idx);
    logger_data_dir{logger_type_k} = cell(nLoggers,1);
    for logger_k = 1:nLoggers
        loggerLabel = driveLabels{drive_idx(logger_k)};
        loggerNumber = str2double(loggerLabel(strfind(loggerLabel,loggerStrings{logger_type_k})+length(loggerStrings{logger_type_k}):end));
        logger_base_dir = fullfile(base_dir, DateStr, logger_dir_strings{logger_type_k}); % directory for saving today's data
        
        if ~exist(logger_base_dir,'dir')
            mkdir(logger_base_dir)
        end
        
        logger_data_dir{logger_type_k}{logger_k} = fullfile(logger_base_dir,['logger' num2str(loggerNumber)]);
        if ~exist(logger_data_dir{logger_type_k}{logger_k},'dir') || isempty(dir(logger_data_dir{logger_type_k}{logger_k}))
            mkdir(logger_data_dir{logger_type_k}{logger_k})
            logger_drive_dir = strtrim(driveLetters{drive_idx(logger_k)});
            disp(['Copying file from from ' logger_dir_strings{logger_type_k} ' #' num2str(loggerNumber) ' ...']);
            status = copyfile(fullfile(logger_drive_dir,'*'),logger_data_dir{logger_type_k}{logger_k});
            if status
                disp(['**** Files copied successfully from ' logger_dir_strings{logger_type_k} ' #' num2str(loggerNumber) ' ****'])
            else
                disp(['Failed to copy files from ' logger_dir_strings{logger_type_k} ' #' num2str(loggerNumber)])
            end
        else
            disp('Logger directory already exists DATA ARE NOT TRANSFERRED')
        end
    end
end
fprintf(1,'All Loggers Processed\n')

end