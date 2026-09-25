function report = migrateExperimentFolders(vesselNames, step, applyChanges, sourceRoot, targetRoot)
% Run one step at a time: "rename", "renumber", then "move".
% Preview: migrateExperimentFolders("remus100", "rename")
% Apply:   migrateExperimentFolders("remus100", "rename", true)
% Rename keeps original numbers and prefixes excluded folders with deprecated-.
% Renumber fills gaps in 1:30. Move transfers retained folders to experimentsData.
% Optional sourceRoot/targetRoot override ExperimentsResults/experimentsData.

    projectRoot = fileparts(which('setupProject.m'));
    if nargin < 1 || isempty(vesselNames)
        vesselNames = ["remus100", "nspauv", "mariner"];
    end
    if nargin < 2
        step = "rename";
    end
    step = string(validatestring(step,{'rename','renumber','move'}));
    if nargin < 3
        applyChanges = false;
    end
    if nargin < 4 || isempty(sourceRoot)
        sourceRoot = fullfile(projectRoot,'ExperimentsResults');
    end
    if nargin < 5 || isempty(targetRoot)
        targetRoot = fullfile(projectRoot,'experimentsData');
    end
    sourceRoot = string(sourceRoot);
    targetRoot = string(targetRoot);
    if ~isfolder(sourceRoot)
        error('Source folder does not exist: %s',sourceRoot);
    end
    if strcmp(regexprep(sourceRoot,'[/\\]+$',''),regexprep(targetRoot,'[/\\]+$',''))
        error('Source and destination roots must be different.');
    end

    % Source folder prefix | key in loadExperimentsStatusOriginal | destination prefix
    folderNames = [
        "KneePointSel",      "IncWP_KP",     "IncWP_KP"
        "RandomSel",         "IncWP_Rnd",    "IncWP_Rnd"
        "MaxInstabilitySel", "IncWP_Unst",   "IncWP_Unst"
        "MinDiffWP",         "IncWP_Prox",   "IncWP_Prox"
        "SelectionAllPF",    "IncWP_Kmeans", "IncWP_K3Means"
        "RandomSearch",      "RandomSearch", "RandomSearch"
    ];
    report = table('Size',[0,8], ...
        'VariableTypes',{'string','string','double','double','string','string','string','string'}, ...
        'VariableNames',{'Vessel','Approach','OriginalNumber','NewNumber','Source','Destination','Action','Status'});

    for vessel = reshape(string(vesselNames),1,[])
        selected = loadExperimentsStatusOriginal(vessel,true);
        folders = dir(fullfile(sourceRoot,vessel));
        folders = folders([folders.isdir]);
        for approachIndex = 1:size(folderNames,1)
            sourceName = folderNames(approachIndex,1);
            selectionKey = folderNames(approachIndex,2);
            targetName = folderNames(approachIndex,3);
            numbers = sort(selected(selectionKey));
            gaps = setdiff(1:30,numbers(numbers<=30));
            if numel(numbers) ~= 30 || numel(unique(numbers)) ~= 30 || numel(gaps) ~= sum(numbers>30)
                error('%s / %s must select 30 original experiments before renumbering.',vessel,selectionKey);
            end
            newNumbers = numbers;
            newNumbers(numbers>30) = gaps;
            switch step
                case "rename"
                    for folderIndex = 1:numel(folders)
                        folderName = string(folders(folderIndex).name);
                        token = regexp(folderName,'^(.*)-exNum(\d+)$','tokens','once');
                        if isempty(token) || string(token{1}) ~= sourceName
                            continue;
                        end
                        number = str2double(token{2});
                        source = fullfile(sourceRoot,vessel,folderName);
                        if ismember(number,numbers)
                            destinationName = targetName+"-exNum"+string(number);
                            action = "rename";
                        else
                            destinationName = "deprecated-"+folderName;
                            action = "deprecate";
                        end
                        destination = fullfile(sourceRoot,vessel,destinationName);
                        status = destinationStatus(source,destination);
                        report(end+1,:) = {vessel,targetName,number,number,source,destination,action,status};
                    end

                case "renumber"
                    oldFolders = dir(fullfile(sourceRoot,vessel,sourceName+"-exNum*"));
                    if sourceName ~= targetName && any([oldFolders.isdir])
                        error('Complete the rename step for %s / %s first.',vessel,sourceName);
                    end
                    for index = find(numbers>30)
                        number = numbers(index);
                        newNumber = newNumbers(index);
                        source = fullfile(sourceRoot,vessel,targetName+"-exNum"+string(number));
                        destination = fullfile(sourceRoot,vessel,targetName+"-exNum"+string(newNumber));
                        status = destinationStatus(source,destination);
                        report(end+1,:) = {vessel,targetName,number,newNumber,source,destination,step,status};
                    end

                case "move"
                    oldFolders = dir(fullfile(sourceRoot,vessel,sourceName+"-exNum*"));
                    if sourceName ~= targetName && any([oldFolders.isdir])
                        error('Complete the rename step for %s / %s first.',vessel,sourceName);
                    end
                    for number = numbers(numbers>30)
                        if isfolder(fullfile(sourceRoot,vessel,targetName+"-exNum"+string(number)))
                            error('Complete the renumber step for %s / %s first.',vessel,targetName);
                        end
                    end
                    for number = 1:30
                        folderName = targetName+"-exNum"+string(number);
                        source = fullfile(sourceRoot,vessel,folderName);
                        destination = fullfile(targetRoot,vessel,folderName);
                        status = destinationStatus(source,destination);
                        originalNumber = numbers(newNumbers==number);
                        report(end+1,:) = {vessel,targetName,originalNumber,number,source,destination,step,status};
                    end
            end
        end
    end

    if applyChanges
        reportFile = fullfile(sourceRoot,"folder-migration-"+step+"-"+string(datetime('now','Format','yyyyMMdd-HHmmssSSS'))+".csv");
        writetable(report,reportFile);
        rows = [find(report.Action=="deprecate"); find(report.Action~="deprecate")];
        for row = rows'
            if ~startsWith(report.Status(row),"ready")
                continue;
            end
            source = report.Source(row);
            destination = report.Destination(row);
            report.Status(row) = destinationStatus(source,destination);
            if startsWith(report.Status(row),"ready")
                try
                    if isfolder(destination)
                        rmdir(destination); % Only an empty directory; never recursive.
                    end
                    parent = fileparts(destination);
                    if ~isfolder(parent)
                        mkdir(parent);
                    end
                    [ok,message] = movefile(source,destination);
                    if ok
                        report.Status(row) = "done";
                    else
                        report.Status(row) = "failed: "+string(message);
                    end
                catch err
                    report.Status(row) = "failed: "+string(err.message);
                end
            end
            writetable(report,reportFile);
        end
        fprintf('Migration report: %s\n',reportFile);
    else
        fprintf('Preview only. Pass true as the third argument to apply this step.\n');
    end
    disp(report);
end

function status = destinationStatus(source,destination)
    if source == destination
        status = "unchanged";
    elseif ~isfolder(source)
        if isfolder(destination)
            status = "source absent; destination exists (not verified)";
        else
            status = "missing source";
        end
    elseif isfile(destination)
        status = "conflict: destination is a file";
    elseif isfolder(destination)
        items = dir(destination);
        items = items(~ismember({items.name},{'.','..'}));
        if isempty(items)
            status = "ready: replace empty destination";
        else
            status = "conflict: destination is not empty";
        end
    else
        status = "ready";
    end
end
