function saveAnalysisResults(base, dataset, values, varargin)
% Save small MAT shards and invalidate every dependent dataset.
% Merge=true replaces/adds only supplied shards, retaining other approaches/runs.
    parser = inputParser;
    addParameter(parser,'Merge',false,@(x) islogical(x)&&isscalar(x));
    addParameter(parser,'ExternalFiles',strings(0,1));
    parse(parser,varargin{:}); options = parser.Results;
    dataset = analysisDatasetName(dataset);
    manifest = analysisResultManifest(base,'refresh');
    old = find(strcmp({manifest.datasets.id},dataset),1);
    previous = emptyRecords();
    if ~isempty(old), previous = manifest.datasets(old).records; end
    if options.Merge
        assert(~isempty(old) && strcmp(manifest.datasets(old).status,'current'), ...
            'Analysis:PartialOutdatedUpdate','Partial updates require a current dataset. Rebuild outdated results in full first.');
        metadataFile = fullfile(base,'results',dataset,'metadata.mat');
        if isfile(metadataFile)
            saved = load(metadataFile,'result');
            if isfield(values,'experimentInfoMap') && isfield(saved.result,'experimentInfoMap')
                values.experimentInfoMap = mergeExperiments(saved.result.experimentInfoMap,values.experimentInfoMap);
            end
        end
    end
    analysisResultManifest(base,'begin',dataset);
    records = emptyRecords();
    if options.Merge, records = previous; end
    metadata = values;
    switch dataset
        case "classification"
            writeRuns('selectionTypeClassification',values.selectionTypeClassification,'classification');
            metadata = drop(metadata,{'selectionTypeClassification','selectionTypeClassificationWithBrackets', ...
                'distancesRanges','selectionResultsDistributionMap','resultsMatrix','precentageResultsMap'});
        case "timing"
            writeRuns('selectionTypeTimeStamps',values.selectionTypeTimeStamps,'timing');
            metadata = drop(metadata,{'selectionTypeTimeStamps'});
        case "candidates"
            writeCandidates(values.approachSortedInfoMap);
            metadata = drop(metadata,{'approachSortedInfoMap','approachDataMap','combinedsolutionsMap','waypointRangesMap'});
        case "timeLimited"
            writeCandidates(values.approachSortedInfoMap);
            writeRuns('selectionTypeClassification',values.selectionTypeClassification,'classification');
            writeRuns('selectionTypeTimeStamps',values.selectionTypeTimeStamps,'timing');
            metadata = drop(metadata,{'approachSortedInfoMap','selectionTypeClassification','selectionTypeTimeStamps'});
        case "metrics"
            for waypoint = string(values.metrics.keys())
                byApproach = values.metrics(waypoint);
                for approach = string(byApproach.keys())
                    if approach=="StatisticalComparisonResults"
                        writePart(byApproach(approach),'metrics','',0,str2double(waypoint),'comparisons', ...
                            fullfile('comparisons',sprintf('waypoint-%02d.mat',str2double(waypoint))));
                        continue;
                    end
                    metric = byApproach(approach);
                    groups = {{'HV','IGD','experimentNumbers'}, ...
                        {'bracketsDistanceCount','bracketsTimeCount','wayPointTimeInfo'}, ...
                        {'uniqueStats'},{'clusterData'}};
                    parts = ["quality","classification-timing","unique-points","clusters"];
                    for g = 1:numel(groups)
                        subset = containers.Map();
                        for key = string(groups{g})
                            if isKey(metric,key), subset(key) = metric(key); end
                        end
                        writePart(subset,'metrics',approach,0,str2double(waypoint),parts(g), ...
                            fullfile(safeName(approach),sprintf('waypoint-%02d',str2double(waypoint)),parts(g)+'.mat'));
                    end
                    known = [groups{:}]; extras = setdiff(metric.keys(),known);
                    if ~isempty(extras)
                        subset = containers.Map(extras,metric.values(extras));
                        writePart(subset,'metrics',approach,0,str2double(waypoint),'additional', ...
                            fullfile(safeName(approach),sprintf('waypoint-%02d',str2double(waypoint)),'additional.mat'));
                    end
                end
            end
            metadata = drop(metadata,{'metrics'});
        case "reports"
            for field = string(fieldnames(values))'
                writePart(values.(field),field,'',0,0,field,field+'.mat');
            end
            metadata = struct();
    end
    writePart(metadata,'metadata','',0,0,'metadata','metadata.mat');
    for filename = reshape(string(options.ExternalFiles),1,[])
        info = dir(fullfile(base,filename));
        assert(isscalar(info),'Analysis:MissingReport','Missing report file: %s',filename);
        record = makeRecord(filename,'external','',0,0,'external',info);
        records = putRecord(records,record);
    end
    analysisResultManifest(base,'finish',dataset,records);
    % Remove only superseded files owned by this result store, after commit.
    obsolete = setdiff(string({previous.path}),string({records.path}));
    for filename = obsolete
        if startsWith(filename,"results"+filesep+dataset+filesep) && isfile(fullfile(base,filename))
            delete(fullfile(base,filename));
        end
    end

    function writeRuns(runVariable,runApproaches,runPart)
        for runApproach = string(runApproaches.keys())
            runEntries = runApproaches(runApproach);
            for runExperiment = string(runEntries.keys())
                runValue = runEntries(runExperiment);
                if strcmp(runVariable,'selectionTypeClassification') && isKey(runValue,'bracketClassMap')
                    runValue = containers.Map(runValue.keys(),runValue.values());
                    remove(runValue,'bracketClassMap'); % Omit legacy bracket data.
                end
                writePart(runValue,runVariable,runApproach,str2double(runExperiment),0,runPart, ...
                    fullfile(runPart,safeName(runApproach),sprintf('experiment-%04d.mat',str2double(runExperiment))));
            end
        end
    end

    function writeCandidates(candidateApproaches)
        for candidateApproach = string(candidateApproaches.keys())
            candidateWaypoints = candidateApproaches(candidateApproach);
            for candidateWaypoint = string(candidateWaypoints.keys())
                candidateRuns = candidateWaypoints(candidateWaypoint);
                for candidateExperiment = string(candidateRuns.keys())
                    writePart(candidateRuns(candidateExperiment),'approachSortedInfoMap',candidateApproach,str2double(candidateExperiment), ...
                        str2double(candidateWaypoint),'candidates',fullfile(safeName(candidateApproach), ...
                        sprintf('experiment-%04d',str2double(candidateExperiment)),sprintf('waypoint-%02d.mat',str2double(candidateWaypoint))));
                end
            end
        end
    end

    function writePart(result,partVariable,partApproach,partExperiment,partWaypoint,partLabel,partRelative)
        partRelative = fullfile('results',dataset,partRelative);
        partFilename = fullfile(base,partRelative); partFolder = fileparts(partFilename);
        if ~isfolder(partFolder), mkdir(partFolder); end
        partPending = [tempname(partFolder),'.mat'];
        save(partPending,'result','-v7.3');
        [partOK,partMessage] = movefile(partPending,partFilename,'f');
        assert(partOK,'Analysis:ResultWrite','%s',partMessage);
        partRecord = makeRecord(partRelative,partVariable,partApproach,partExperiment,partWaypoint,partLabel,dir(partFilename));
        records = putRecord(records,partRecord);
    end
end

function values = drop(values,names)
    names = intersect(fieldnames(values),names);
    if ~isempty(names), values = rmfield(values,names); end
end

function records = emptyRecords()
    records = struct('path',{},'variable',{},'approach',{},'experiment',{},'waypoint',{}, ...
        'part',{},'bytes',{},'modified',{});
end

function record = makeRecord(path,variable,approach,experiment,waypoint,part,info)
    record = struct('path',char(path),'variable',char(variable),'approach',char(approach), ...
        'experiment',experiment,'waypoint',waypoint,'part',char(part),'bytes',info.bytes,'modified',info.datenum);
end

function records = putRecord(records,record)
    index = find(strcmp({records.path},record.path),1);
    if isempty(index), records(end+1) = record; else, records(index) = record; end
end

function name = safeName(original)
    name = regexprep(char(original),'[^A-Za-z0-9_-]','_');
    if ~strcmp(name,char(original)) || numel(name)>100
        digest = java.security.MessageDigest.getInstance('SHA-256');
        digest.update(typecast(unicode2native(char(original),'UTF-8'),'int8'));
        hash = lower(reshape(dec2hex(typecast(digest.digest(),'uint8'),2)',1,[]));
        name = [name(1:min(80,numel(name))),'--',hash(1:12)];
    end
    assert(~isempty(name),'Analysis:ResultName','Empty result name.');
end

function result = mergeExperiments(old,new)
    result = containers.Map();
    for name = string(old.keys()), result(name) = old(name); end
    for approach = string(new.keys())
        numbers = new(approach);
        if isKey(result,approach), numbers = union(result(approach),numbers); end
        result(approach) = numbers(:)';
    end
end
