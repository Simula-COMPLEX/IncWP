function simulateVesselIncWPKmeans(vesselName, selectionType, experimentNumber, resumeFromLastIteration, dataRoot)
% simulateVesselIncWPKmeans Regenerate IncWP_Kmeans simulation files.

    arguments
        vesselName {mustBeTextScalar}
        selectionType {mustBeTextScalar}
        experimentNumber {mustBeNumeric}
        resumeFromLastIteration logical = true
        dataRoot {mustBeTextScalar} = ""
    end

    vesselName = char(vesselName);
    selectionType = char(selectionType);
    experimentNumber = double(experimentNumber);

    if strlength(string(dataRoot)) == 0
        scriptRoot = fileparts(mfilename('fullpath'));
        repoRoot = fileparts(fileparts(scriptRoot));
        dataRoot = fullfile(repoRoot, 'replicationRuns', 'experiments');
    end

    resultsFolder = fullfile(char(dataRoot), vesselName, sprintf('%s-exNum%d', selectionType, experimentNumber));
    if ~isfolder(resultsFolder)
        error('Copied replication folder not found: %s', resultsFolder);
    end

    finalInfoFile = fullfile(resultsFolder, 'finalInformation.mat');
    if ~isfile(finalInfoFile)
        error('Missing finalInformation.mat in %s', resultsFolder);
    end
    finalInfo = load(finalInfoFile, 'enviromentRandom');
    if ~isfield(finalInfo, 'enviromentRandom')
        error('Missing enviromentRandom in %s', finalInfoFile);
    end
    enviromentRandom = finalInfo.enviromentRandom;

    resultFiles = dir(fullfile(resultsFolder, 'WptIdx-resultsWpt-*.mat'));
    if isempty(resultFiles)
        error('No WptIdx-resultsWpt-*.mat files found in %s', resultsFolder);
    end

    wptIndices = getWaypointIndices(resultFiles);
    shipParam = loadShipSearchParameters(vesselName);
    initialPoints = getInitialPoints(shipParam);
    resumeInfo = findLatestReplayIteration(resultsFolder, resumeFromLastIteration);
    ranAnySimulation = false;

    for wi = 1:numel(wptIndices)
        wptIndex = wptIndices(wi);
        if wptIndex < 2
            continue;
        end
        if resumeInfo.enabled && wptIndex < resumeInfo.wptIndex
            continue;
        end

        resultsWptFile = fullfile(resultsFolder, sprintf('WptIdx-resultsWpt-%d.mat', wptIndex));
        data = load(resultsWptFile, 'mappingOfIndexes', 'paretoFrontPopulations');
        if ~isfield(data, 'mappingOfIndexes') || ~isfield(data, 'paretoFrontPopulations')
            continue;
        end

        mappingOfIndexes = data.mappingOfIndexes;
        populationDecs = data.paretoFrontPopulations.decs;
        previousDecs = getPreviousStartDecisions(resultsFolder, wptIndex, initialPoints);

        generationNumbers = unique(mappingOfIndexes(:, 2), 'stable')';
        baseObj = struct();
        baseObj.vesselName = vesselName;
        baseObj.R_switch = shipParam.R_switch;
        baseObj.enviromentRandom = enviromentRandom;
        baseObj.endWptIndex = wptIndex;
        baseObj.vesselResultsPath = [resultsFolder filesep 'WptIdx-'];
        waypointTimer = tic;

        for generationNumber = generationNumbers
            rows = find(mappingOfIndexes(:, 2) == generationNumber);
            if isempty(rows)
                continue;
            end

            firstIterationInGeneration = mappingOfIndexes(rows(1), 1);
            lastIterationInGeneration = mappingOfIndexes(rows(end), 1);
            if shouldSkipGeneration(resumeInfo, wptIndex, lastIterationInGeneration)
                continue;
            end

            pathsFile = fullfile(resultsFolder, sprintf('WptIdx-%d-paths-g%d.mat', wptIndex, generationNumber));
            [timestamps, missingPathLabel, paths] = initializeGenerationResults(pathsFile, numel(rows), resumeInfo.enabled);
            generationRanSimulation = false;
            simulationsToRun = numel(rows);
            if resumeInfo.enabled && wptIndex == resumeInfo.wptIndex
                simulationsToRun = lastIterationInGeneration - max(firstIterationInGeneration, resumeInfo.iterationIndex) + 1;
            end

            fprintf('%s / %s-exNum%d / WptIdx-%d / generation %d: running %d simulations\n', ...
                vesselName, selectionType, experimentNumber, wptIndex, generationNumber, simulationsToRun);

            for rowIndex = 1:numel(rows)
                mappingRow = mappingOfIndexes(rows(rowIndex), :);
                iterationIndex = mappingRow(1);
                if shouldSkipIteration(resumeInfo, wptIndex, iterationIndex)
                    continue;
                end

                selectedDec = populationDecs(iterationIndex, :);
                startWptIndex = mappingRow(3);
                startWpt = previousDecs(startWptIndex, :);

                wpt = buildWaypoint(startWpt, selectedDec);
                obj = baseObj;
                obj.iterationIndex = iterationIndex;
                obj.startWptIndex = startWptIndex;

                [~, reachedWaypoint, ~, ~, ~, angles] = runVesselSimulation(obj, wpt);
                ranAnySimulation = true;
                generationRanSimulation = true;
                timestamps(rowIndex) = toc(waypointTimer);
                missingPathLabel(rowIndex) = ~reachedWaypoint;

                pathInfo = containers.Map();
                pathInfo('angles') = angles;
                paths(string(iterationIndex)) = pathInfo;
            end

            if generationRanSimulation
                save(pathsFile, 'timestamps', 'missingPathLabel', 'paths');
            end
        end
    end

    if ~ranAnySimulation
        error('No replay entries prepared for %s %s-exNum%d', vesselName, selectionType, experimentNumber);
    end
end

function wptIndices = getWaypointIndices(files)
    wptIndices = zeros(numel(files), 1);
    for i = 1:numel(files)
        tok = regexp(files(i).name, 'WptIdx-resultsWpt-(\d+)\.mat', 'tokens', 'once');
        if isempty(tok)
            wptIndices(i) = NaN;
        else
            wptIndices(i) = str2double(tok{1});
        end
    end
    wptIndices = sort(unique(wptIndices(~isnan(wptIndices))));
end

function initialPoints = getInitialPoints(shipParam)
    initialPoints = [zeros(1, shipParam.pointDimension); ...
        reshape(shipParam.initialPoints, [shipParam.pointDimension, shipParam.numWaypoints])'];
end

function previousDecs = getPreviousStartDecisions(resultsFolder, wptIndex, initialPoints)
    if wptIndex == 2
        previousDecs = initialPoints(1, :);
        return;
    end

    previousFile = fullfile(resultsFolder, sprintf('WptIdx-resultsWpt-%d.mat', wptIndex - 1));
    previousData = load(previousFile, 'paretoFrontPopulations');
    previousDecs = previousData.paretoFrontPopulations.decs;
end

function wpt = buildWaypoint(startWpt, selectedDec)
    wpt = struct();
    wpt.pos.x = [startWpt(1); selectedDec(1)];
    wpt.pos.y = [startWpt(2); selectedDec(2)];
    if numel(selectedDec) == 3
        wpt.pos.z = [startWpt(3); selectedDec(3)];
    end
end

function tf = shouldSkipGeneration(resumeInfo, wptIndex, lastIterationInGeneration)
    tf = false;
    if ~resumeInfo.enabled || wptIndex ~= resumeInfo.wptIndex
        return;
    end

    tf = lastIterationInGeneration < resumeInfo.iterationIndex;
end

function tf = shouldSkipIteration(resumeInfo, wptIndex, iterationIndex)
    tf = false;
    if ~resumeInfo.enabled
        return;
    end
    if wptIndex > resumeInfo.wptIndex
        return;
    end

    tf = iterationIndex < resumeInfo.iterationIndex;
end

function resumeInfo = findLatestReplayIteration(resultsFolder, resumeFromLastIteration)
    resumeInfo = struct('enabled', false, 'wptIndex', 0, 'iterationIndex', 0);
    if ~resumeFromLastIteration
        return;
    end

    replayIterFiles = dir(fullfile(resultsFolder, 'WptIdx-*-iter*.mat'));
    if isempty(replayIterFiles)
        return;
    end

    bestWpt = 0;
    bestIter = 0;
    for i = 1:numel(replayIterFiles)
        tok = regexp(replayIterFiles(i).name, 'WptIdx-(\d+)-iter(\d+)\.mat', 'tokens', 'once');
        if isempty(tok)
            continue;
        end

        wptIndex = str2double(tok{1});
        iterationIndex = str2double(tok{2});
        if wptIndex > bestWpt || (wptIndex == bestWpt && iterationIndex > bestIter)
            bestWpt = wptIndex;
            bestIter = iterationIndex;
        end
    end

    if bestWpt > 0
        resumeInfo.enabled = true;
        resumeInfo.wptIndex = bestWpt;
        resumeInfo.iterationIndex = bestIter;
    end
end

function [timestamps, missingPathLabel, paths] = initializeGenerationResults(pathsFile, generationSize, loadExisting)
    timestamps = zeros(generationSize, 1);
    missingPathLabel = zeros(generationSize, 1);
    paths = containers.Map();

    if ~loadExisting || ~isfile(pathsFile)
        return;
    end

    data = load(pathsFile, 'timestamps', 'missingPathLabel', 'paths');
    if isfield(data, 'timestamps') && numel(data.timestamps) == generationSize
        timestamps = data.timestamps;
    end
    if isfield(data, 'missingPathLabel') && numel(data.missingPathLabel) == generationSize
        missingPathLabel = data.missingPathLabel;
    end
    if isfield(data, 'paths') && isa(data.paths, 'containers.Map')
        paths = data.paths;
    end
end
