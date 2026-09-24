function report = addTimeLimitedFullWP(vesselName, resultsPath, analysisPath, policy)
% Add derived FullWP views without changing source files or unrestricted views.
% One shared cutoff per experiment by default; optional mean or per-approach cutoffs.
    if nargin < 4, policy = "slowestIncremental"; end
    policy = string(validatestring(policy,{'perApproach','slowestIncremental','averageIncremental'}));
    base = fullfile(analysisPath,vesselName,'AnalysedResults');
    manifest = analysisResultManifest(base,'read');
    analysisResultManifest(base,'configure',manifest.configuration.sourceFolder,policy);
    combined = loadAnalysisResults(base,'candidates','IncludeTimeLimited',false, ...
        'Variables',["experimentInfoMap","approachSortedInfoMap"]);
    classified = loadAnalysisResults(base,'classification','IncludeTimeLimited',false,'Variables','selectionTypeClassification');
    timing = loadAnalysisResults(base,'timing','IncludeTimeLimited',false);
    limited = struct('experimentInfoMap',containers.Map(),'approachSortedInfoMap',containers.Map(), ...
        'selectionTypeClassification',containers.Map(),'selectionTypeTimeStamps',containers.Map());
    experimentInfoMap = combined.experimentInfoMap;
    approachSortedInfoMap = combined.approachSortedInfoMap;
    names = string(experimentInfoMap.keys());
    full = false(size(names));
    incremental = false(size(names));
    for k = 1:numel(names)
        info = analysisApproachInfo(names(k));
        incremental(k) = info.isIncremental;
        full(k) = info.isFullWP;
    end
    fullNames = names(full);
    selectedExperiments = loadExperimentsStatus(vesselName);
    incNames = names(incremental);
    report = table('Size',[0,5],'VariableTypes',{'string','string','double','double','double'}, ...
        'VariableNames',{'Approach','TimeSource','Experiment','CutoffSeconds','RetainedIndividuals'});
    if isempty(fullNames) || isempty(incNames)
        fprintf('No paired FullWP/incremental approaches: retaining all available original approaches.\n');
        limited.timeLimitReport = report;
        saveAnalysisResults(base,'timeLimited',limited);
        return;
    end
    settings = loadShipSearchParameters(vesselName);
    for fullName = fullNames
        cutoffName = fullName+"_TimeCutoff";
        if ~isKey(selectedExperiments,cutoffName)
            continue;
        end
        selectedNumbers = intersect(experimentInfoMap(fullName),selectedExperiments(cutoffName));
        donors = incNames;
        if policy ~= "perApproach", donors = policy; end
        for donor = donors
            donorNumbers = [];
            if policy == "perApproach"
                donorNumbers = experimentInfoMap(donor);
            else
                for incName = incNames, donorNumbers = union(donorNumbers,experimentInfoMap(incName)); end
            end
            numbers = intersect(selectedNumbers,donorNumbers);
            unmatched = setdiff(selectedNumbers,numbers);
            if ~isempty(unmatched)
                warning('Analysis:UnpairedTimeLimit','%s / %s: no matching cutoff for experiments %s. Unrestricted results remain.', ...
                    fullName,donor,mat2str(unmatched));
            end
            if isempty(numbers), continue; end
            name = cutoffName;
            if policy == "perApproach"
                name = cutoffName+"_"+donor;
            end
            assert(~isKey(experimentInfoMap,name),'Analysis:DuplicateApproach','Derived name already exists: %s',name);
            sourceWaypoints = approachSortedInfoMap(fullName);
            sourceClasses = classified.selectionTypeClassification(fullName);
            newWaypoints = containers.Map(); newClasses = containers.Map(); newTimes = containers.Map();
            for waypoint = 2:settings.numWaypoints+1, newWaypoints(string(waypoint)) = containers.Map(); end
            for number = numbers(:)'
                sources = donor;
                if policy ~= "perApproach"
                    sources = incNames(arrayfun(@(n) ismember(number,experimentInfoMap(n)),incNames));
                end
                budgets = zeros(size(sources));
                for j = 1:numel(sources)
                    budgets(j) = incrementalRuntime(resultsPath,vesselName,sources(j),number,timing.selectionTypeTimeStamps);
                end
                if policy == "averageIncremental"
                    budget = mean(budgets);
                    timeSource = "mean("+strjoin(sources,", ")+")";
                else
                    [budget,j] = max(budgets);
                    timeSource = sources(j);
                end
                fullTimes = timing.selectionTypeTimeStamps(fullName);
                times = fullTimes(string(number)); times = times(:);
                assert(~isempty(times),'Analysis:MissingTimes','No FullWP completion times for %s.',fullName);
                keep = times <= budget;
                originalClassification = sourceClasses(string(number));
                numPeaksMap = containers.Map(); classesMap = containers.Map(); distanceMap = containers.Map();
                for waypoint = 2:settings.numWaypoints+1
                    key = string(waypoint);
                    sourceExperiments = sourceWaypoints(key);
                    original = sourceExperiments(string(number));
                    assert(numel(original('timestamp'))==numel(keep),'Analysis:RowAlignment','FullWP waypoint rows are not aligned.');
                    copied = containers.Map();
                    for field = ["classes","decisions","objectives,","constraints","timestamp"]
                        values = original(field);
                        copied(field) = values(keep,:);
                    end
                    copied('endTime') = min(budget,times(end));
                    copied('timeBudget') = budget;
                    experiments = newWaypoints(key);
                    experiments(string(number)) = copied;
                    newWaypoints(key) = experiments;
                    originalPeaks = originalClassification('numberOfPeaks');
                    peaks = originalPeaks(key);
                    if size(peaks,1)~=numel(keep) && size(peaks,2)==numel(keep), peaks=peaks'; end
                    assert(size(peaks,1)==numel(keep),'Analysis:RowAlignment','Peak rows do not match %s.',fullName);
                    numPeaksMap(key) = peaks(keep,:);
                    originalClassMap = originalClassification('classes'); values = originalClassMap(key);
                    classesMap(key) = reshape(string(values(keep)),[],1);
                    originalDistances = originalClassification('distances'); values = originalDistances(key);
                    distanceMap(key) = reshape(values(keep),[],1);
                end
                newClasses(string(number)) = containers.Map({'numberOfPeaks','classes','distances'}, ...
                    {numPeaksMap,classesMap,distanceMap});
                newTimes(string(number)) = times(keep);
                report(end+1,:) = {name,timeSource,number,budget,sum(keep)};
            end
            limited.experimentInfoMap(name) = numbers(:)';
            limited.approachSortedInfoMap(name) = newWaypoints;
            limited.selectionTypeClassification(name) = newClasses;
            limited.selectionTypeTimeStamps(name) = newTimes;
        end
    end
    limited.timeLimitReport = report;
    writetable(report,fullfile(base,'timeLimits.csv'));
    saveAnalysisResults(base,'timeLimited',limited,'ExternalFiles',"timeLimits.csv");
end

function seconds = incrementalRuntime(resultsPath,vesselName,approach,number,timestamps)
    filename = fullfile(resultsPath,vesselName,approach+"-exNum"+string(number),'finalInformation.mat');
    seconds = NaN;
    if isfile(filename)
        saved = load(filename,'fullSearchTime');
        if isfield(saved,'fullSearchTime'), seconds = saved.fullSearchTime; end
    end
    if isnan(seconds)
        experiments = timestamps(approach); waypoints = experiments(string(number));
        seconds = 0;
        for key = string(waypoints.keys())
            times = waypoints(key);
            assert(~isempty(times),'Analysis:MissingTimes','No times for %s experiment %d.',approach,number);
            seconds = seconds+times(end);
        end
    end
    assert(isscalar(seconds) && isfinite(seconds) && seconds>=0,'Analysis:InvalidCutoff', ...
        'Invalid runtime for %s experiment %d.',approach,number);
end
