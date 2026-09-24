function values = loadAnalysisResults(base,dataset,varargin)
% Load selected shards, or reconstruct the previous complete result structures.
% Filters: Approach, Experiment, Waypoint, Part, Variables. Stale reads require
% AllowOutdated=true; an interrupted/in-progress write is never readable.
    parser = inputParser;
    addParameter(parser,'Approach',strings(0,1));
    addParameter(parser,'Experiment',[]);
    addParameter(parser,'Waypoint',[]);
    addParameter(parser,'Part',strings(0,1));
    addParameter(parser,'Variables',strings(0,1));
    addParameter(parser,'AllowOutdated',false,@(x) islogical(x)&&isscalar(x));
    addParameter(parser,'IncludeTimeLimited',true,@(x) islogical(x)&&isscalar(x));
    parse(parser,varargin{:}); options = parser.Results;
    options.Approach = string(options.Approach); options.Part = string(options.Part); options.Variables = string(options.Variables);
    dataset = analysisDatasetName(dataset);
    assert(isempty(options.Experiment) || ~any(dataset==["metrics","reports"]), ...
        'Analysis:AggregateSelection','Metrics/reports aggregate experiments. Select an experiment from candidates, classification or timing.');
    manifest = analysisResultManifest(base,'refresh');
    if dataset=="all"
        values = struct();
        for id = ["classification","timing","candidates","metrics","reports"]
            if any(strcmp({manifest.datasets.id},id))
                values.(id) = loadAnalysisResults(base,id,varargin{:});
            end
        end
        return;
    end
    entry = requireEntry(manifest,dataset,options.AllowOutdated);
    values = readDataset(base,entry,options);
    if options.IncludeTimeLimited && any(dataset==["classification","timing","candidates"]) && ...
            string(manifest.configuration.timeLimitPolicy)~="none"
        limitedEntry = requireEntry(manifest,"timeLimited",options.AllowOutdated);
        if dataset=="classification", variable = 'selectionTypeClassification';
        elseif dataset=="timing", variable = 'selectionTypeTimeStamps';
        else, variable = 'approachSortedInfoMap'; end
        limitedOptions = options;
        if isempty(options.Variables), limitedOptions.Variables = string(variable); end
        limited = readDataset(base,limitedEntry,limitedOptions);
        if isfield(limited,variable)
            if ~isfield(values,variable), values.(variable) = containers.Map(); end
            for name = string(limited.(variable).keys()), values.(variable)(name) = limited.(variable)(name); end
        end
        values.experimentInfoMap = mergeExperiments(values.experimentInfoMap,limited.experimentInfoMap);
        if isfield(limited,'timeLimitReport'), values.timeLimitReport = limited.timeLimitReport; end
    end
    % Materialise aggregate views only when the caller asks for them.
    requested = options.Variables;
    if dataset=="candidates" && (isempty(requested) || any(ismember(requested, ...
            ["approachDataMap","combinedsolutionsMap","waypointRangesMap"])))
        [values.approachDataMap,values.waypointRangesMap,values.combinedsolutionsMap] = ...
            buildAnalysisAggregates(values.approachSortedInfoMap,values.experimentInfoMap);
    elseif dataset=="classification" && (isempty(requested) || any(requested=="distancesRanges"))
        values.distancesRanges = classificationRanges(values.selectionTypeClassification);
    end
    if ~isempty(requested)
        assert(all(isfield(values,cellstr(requested))),'Analysis:ResultVariable','Requested result variable is unavailable.');
        values = rmfield(values,setdiff(fieldnames(values),cellstr(requested)));
    end
end

function entry = requireEntry(manifest,id,allowOutdated)
    index = find(strcmp({manifest.datasets.id},id),1);
    assert(~isempty(index),'Analysis:MissingResults', ...
        'No split %s results. Run analysis or migrateAnalysisResults for old MAT files.',id);
    entry = manifest.datasets(index);
    assert(~strcmp(entry.status,'building'),'Analysis:IncompleteResults', ...
        '%s is being rebuilt or its last write was interrupted. Rebuild it before loading.',id);
    assert(strcmp(entry.status,'current') || allowOutdated,'Analysis:OutdatedResults', ...
        '%s results are outdated: %s Run analysisResultStatus for details.',id,entry.reason);
end

function values = readDataset(base,entry,options)
    metadata = entry.records(strcmp({entry.records.variable},'metadata'));
    assert(numel(metadata)==1,'Analysis:ResultMetadata','Missing metadata for %s.',entry.id);
    saved = load(fullfile(base,metadata.path),'result'); values = saved.result;
    if isfield(values,'experimentInfoMap')
        values.experimentInfoMap = selectExperiments(values.experimentInfoMap,options);
    end
    switch string(entry.id)
        case "classification", values.selectionTypeClassification = containers.Map();
        case "timing", values.selectionTypeTimeStamps = containers.Map();
        case "candidates", values.approachSortedInfoMap = containers.Map();
        case "timeLimited"
            values.approachSortedInfoMap = containers.Map(); values.selectionTypeClassification = containers.Map(); values.selectionTypeTimeStamps = containers.Map();
        case "metrics", values.metrics = containers.Map();
    end
    for record = reshape(entry.records,1,[])
        if any(string(record.variable)==["metadata","external"]), continue; end
        if ~isempty(options.Approach) && ~isempty(record.approach) && ~any(options.Approach==string(record.approach)), continue; end
        if ~isempty(options.Experiment) && record.experiment>0 && ~ismember(record.experiment,options.Experiment), continue; end
        if ~isempty(options.Waypoint) && record.waypoint>0 && ~ismember(record.waypoint,options.Waypoint), continue; end
        if ~isempty(options.Part) && ~any(options.Part==string(record.part)), continue; end
        if ~needsVariable(record.variable,entry.id,options.Variables), continue; end
        saved = load(fullfile(base,record.path),'result'); result = saved.result;
        approach = string(record.approach); experiment = string(record.experiment); waypoint = string(record.waypoint);
        switch string(record.variable)
            case "approachSortedInfoMap"
                waypoints = getMap(values.approachSortedInfoMap,approach); runs = getMap(waypoints,waypoint);
                runs(experiment) = result; waypoints(waypoint) = runs; values.approachSortedInfoMap(approach) = waypoints;
            case "selectionTypeClassification"
                if ~isempty(options.Waypoint)
                    for field = ["classes","distances","numberOfPeaks","bracketClassMap"]
                        if isKey(result,field), result(field) = selectWaypoints(result(field),options.Waypoint); end
                    end
                end
                runs = getMap(values.selectionTypeClassification,approach); runs(experiment) = result;
                values.selectionTypeClassification(approach) = runs;
            case "selectionTypeTimeStamps"
                if isa(result,'containers.Map') && ~isempty(options.Waypoint), result = selectWaypoints(result,options.Waypoint); end
                runs = getMap(values.selectionTypeTimeStamps,approach); runs(experiment) = result;
                values.selectionTypeTimeStamps(approach) = runs;
            case "metrics"
                byApproach = getMap(values.metrics,waypoint);
                if string(record.part)=="comparisons"
                    if ~isempty(options.Approach)
                        keep = ismember(result(:,1),options.Approach) | ismember(result(:,2),options.Approach); keep(1) = true;
                        result = result(keep,:);
                    end
                    byApproach('StatisticalComparisonResults') = result;
                else
                    data = getMap(byApproach,approach);
                    for key = string(result.keys()), data(key) = result(key); end
                    byApproach(approach) = data;
                end
                values.metrics(waypoint) = byApproach;
            otherwise
                values.(record.variable) = result;
        end
    end
end

function needed = needsVariable(variable,dataset,requested)
    if isempty(requested), needed = true; return; end
    switch string(variable)
        case "approachSortedInfoMap"
            needed = any(ismember(requested,["approachSortedInfoMap","approachDataMap","combinedsolutionsMap","waypointRangesMap"]));
        case "selectionTypeClassification"
            needed = any(ismember(requested,["selectionTypeClassification","distancesRanges"]));
        case "selectionTypeTimeStamps", needed = any(requested=="selectionTypeTimeStamps");
        otherwise, needed = any(requested==string(variable));
    end
end

function map = getMap(parent,key)
    map = containers.Map();
    if isKey(parent,key), map = parent(key); end
end

function result = selectExperiments(original,options)
    result = containers.Map();
    for name = string(original.keys())
        if ~isempty(options.Approach) && ~any(name==options.Approach), continue; end
        numbers = original(name);
        if ~isempty(options.Experiment), numbers = intersect(numbers,options.Experiment); end
        if ~isempty(numbers), result(name) = numbers(:)'; end
    end
end

function result = mergeExperiments(original,additional)
    result = containers.Map();
    for name = string(original.keys()), result(name) = original(name); end
    for name = string(additional.keys()), result(name) = additional(name); end
end

function result = selectWaypoints(original,numbers)
    result = containers.Map();
    for number = numbers(:)'
        key = string(number);
        if isKey(original,key), result(key) = original(key); end
    end
end

function [ranges,numWaypoints] = classificationRanges(classification)
    numWaypoints = 1; ranges = zeros(0,2);
    for approach = string(classification.keys())
        runs = classification(approach);
        for experiment = string(runs.keys())
            run = runs(experiment); distances = run('distances');
            for waypoint = string(distances.keys())
                number = str2double(waypoint); numWaypoints = max(numWaypoints,number);
                if size(ranges,1)<number-1, ranges(end+1:number-1,:) = repmat([Inf,-Inf],number-1-size(ranges,1),1); end
                d = distances(waypoint); d = d(isfinite(d));
                if ~isempty(d), ranges(number-1,:) = [min(ranges(number-1,1),min(d)),max(ranges(number-1,2),max(d))]; end
            end
        end
    end
    ranges(~isfinite(ranges)) = 0;
end

function [approachDataMap, waypointRangesMap, combinedsolutionsMap] = buildAnalysisAggregates(approachSortedInfoMap, experimentInfoMap)
% Build aligned aggregate views from per-experiment rows, including empty views.
    approachDataMap = containers.Map(); waypointRangesMap = containers.Map(); combinedsolutionsMap = containers.Map();
    for approach = string(experimentInfoMap.keys())
        sortedWaypoints = approachSortedInfoMap(approach);
        waypointData = containers.Map();
        for waypoint = string(sortedWaypoints.keys())
            experiments = sortedWaypoints(waypoint);
            objectives = []; decisions = []; constraints = []; classes = strings(0,1); timestamps = []; endTimes = [];
            numbers = experimentInfoMap(approach);
            for number = numbers
                data = experiments(string(number));
                objectives = [objectives; data('objectives,')];
                decisions = [decisions; data('decisions')];
                constraints = [constraints; data('constraints')];
                classes = [classes; string(data('classes'))];
                times = data('timestamp');
                timestamps = [timestamps; times(:)];
                if isKey(data,'endTime')
                    lastTime = data('endTime');
                elseif isempty(times)
                    lastTime = 0;
                else
                    lastTime = times(end);
                end
                endTimes = [endTimes,lastTime];
            end
            % Preserve column dimensions for a cutoff before the first evaluation.
            if isempty(objectives)
                first = experiments(string(numbers(1)));
                objectives = zeros(0,2); decisions = first('decisions'); constraints = first('constraints');
            end
            missing = abs(objectives(:,1))>1e8 | ~all(isfinite(objectives),2);
            waypointData(waypoint) = containers.Map( ...
                {'objectives','contraints','decisions','timestamp','missingPathsFlag','classes','approachTimeExperiments','experimentsnumList'}, ...
                {objectives,constraints,decisions,timestamps,missing,classes,endTimes,numbers});
            if isKey(combinedsolutionsMap,waypoint)
                combined = combinedsolutionsMap(waypoint);
                oldObjs = combined('objs'); oldDecs = combined('decs'); oldCons = combined('cons'); oldMissing = combined('missingFlag');
            else
                oldObjs = []; oldDecs = []; oldCons = []; oldMissing = [];
            end
            combinedsolutionsMap(waypoint) = containers.Map({'objs','decs','cons','missingFlag'}, ...
                {[oldObjs;objectives],[oldDecs;decisions],[oldCons;constraints],[oldMissing;missing]});
        end
        approachDataMap(approach) = waypointData;
    end
    for waypoint = string(combinedsolutionsMap.keys())
        combined = combinedsolutionsMap(waypoint);
        objectives = combined('objs'); missing = combined('missingFlag');
        valid = objectives(~missing,:);
        finiteProximity = objectives(isfinite(objectives(:,2)),2);
        ranges = NaN(1,6);
        if ~isempty(valid), ranges(1:4) = [max(valid,[],1),min(valid,[],1)]; end
        if ~isempty(finiteProximity), ranges(5:6) = [max(finiteProximity),min(finiteProximity)]; end
        waypointRangesMap(waypoint) = ranges;
    end
end
