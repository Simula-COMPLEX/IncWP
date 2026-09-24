function timestamps = analysisWaypointTimestamps(folder, approach, waypoint)
% One elapsed completion time per population row, in numeric generation order.
% Cumulative snapshots are sliced, not concatenated repeatedly. K-means
% sub-search clocks are offset at the saved parent-search boundaries.
    info = analysisApproachInfo(approach);
    if info.isFullWP
        files = analysisGenerationFiles(folder);
        archived = fullfile(folder,"WptIdx-resultsWpt-"+string(waypoint)+".mat");
        % Preserve original timing when paths have subsequently been replayed.
        if isfile(archived)
            data = load(archived,'timestamps','individualClassMatrixWpt');
            rawAvailable = ~isempty(files) && isfile(fullfile(folder,strrep(files(1).name,'-population-','-paths-')));
            if isfield(data,'timestamps') && (~rawAvailable || (isfield(data,'individualClassMatrixWpt') && ...
                    numel(data.timestamps)==numel(data.individualClassMatrixWpt)))
                timestamps = data.timestamps(:);
                validateTimes(timestamps,folder);
                return;
            end
        end
    else
        files = analysisGenerationFiles(folder,waypoint);
    end
    assert(~isempty(files),'Analysis:MissingPopulation','No population generations in %s.',folder);
    mapping = [];
    if info.isKmeans
        resultFile = fullfile(folder,"WptIdx-resultsWpt-"+string(waypoint)+".mat");
        if isfile(resultFile)
            data = load(resultFile,'mappingOfIndexes');
            if isfield(data,'mappingOfIndexes'), mapping = data.mappingOfIndexes; end
        end
    end
    timestamps = [];
    previousRawEnd = 0; previousLength = 0; previousParent = NaN; offset = 0;
    for k = 1:numel(files)
        pop = load(fullfile(folder,files(k).name),'Population');
        count = size(pop.Population.decs,1);
        pathFile = fullfile(folder,strrep(files(k).name,'-population-','-paths-'));
        assert(isfile(pathFile),'Analysis:MissingTimes','Missing timestamp file: %s',pathFile);
        data = load(pathFile,'timestamps');
        raw = data.timestamps(:);
        assert(numel(raw) >= count,'Analysis:TimestampSize','Too few timestamps in %s.',pathFile);
        current = raw(end-count+1:end);
        newSearch = k > 1 && (numel(raw) < previousLength || current(1) < previousRawEnd);
        if ~isempty(mapping)
            parent = unique(mapping(mapping(:,2)==k,3));
            assert(isscalar(parent),'Analysis:ParentMapping','Ambiguous parent search in %s generation %d.',folder,k);
            newSearch = k > 1 && parent ~= previousParent;
            previousParent = parent;
        end
        % FullWP native snapshots grow; replay files use a fresh generation timer.
        if info.isFullWP && k>1 && numel(raw)==count, newSearch = true; end
        if newSearch, offset = timestamps(end); end
        timestamps = [timestamps; offset+current];
        previousRawEnd = current(end);
        previousLength = numel(raw);
    end
    validateTimes(timestamps,folder);
end

function validateTimes(timestamps,folder)
    assert(all(isfinite(timestamps)) && all(timestamps >= 0) && all(diff(timestamps) >= 0), ...
        'Analysis:InvalidTimes','Nonfinite, negative or decreasing timestamps in %s.',folder);
end
