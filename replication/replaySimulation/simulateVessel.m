function simulateVessel(vesselName, selectionType, experimentNumber, resumeFromLastIteration, dataRoot)
% simulateVessel Regenerate standard waypoint simulation files.

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
    experimentsRoot = char(dataRoot);

    resultsFolder = fullfile(experimentsRoot, vesselName, sprintf('%s-exNum%d', selectionType, experimentNumber));
    if ~isfolder(resultsFolder)
        error('Copied replication folder not found: %s', resultsFolder);
    end

    finalInfoFile = fullfile(resultsFolder, 'finalInformation.mat');
    resultingWaypoints = [];
    enviromentRandom = [];
    if isfile(finalInfoFile)
        finfo = load(finalInfoFile, 'resultingWaypoints', 'enviromentRandom');
        if isfield(finfo, 'resultingWaypoints')
            resultingWaypoints = finfo.resultingWaypoints;
        end
        if isfield(finfo, 'enviromentRandom')
            enviromentRandom = finfo.enviromentRandom;
        end
    end

    files = dir(fullfile(resultsFolder, 'WptIdx-resultsWpt-*.mat'));
    if isempty(files)
        error('No WptIdx-resultsWpt-*.mat files found in %s', resultsFolder);
    end

    wptIndices = zeros(numel(files), 1);
    for i = 1:numel(files)
        tok = regexp(files(i).name, 'WptIdx-resultsWpt-(\d+)\.mat', 'tokens');
        if ~isempty(tok)
            wptIndices(i) = str2double(tok{1}{1});
        else
            wptIndices(i) = NaN;
        end
    end
    wptIndices = sort(unique(wptIndices(~isnan(wptIndices))));

    shipParam = loadShipSearchParameters(vesselName);
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
        data = load(resultsWptFile);
        if ~isfield(data, 'indexOfBestIteration') || ~isfield(data, 'finalPopulation')
            continue;
        end

        finalPopulation = data.finalPopulation;
        pointDim = size(finalPopulation.decs, 2);

        if ~isempty(resultingWaypoints) && size(resultingWaypoints, 1) >= (wptIndex - 1)
            startWpt = resultingWaypoints(wptIndex - 1, :);
        else
            startWpt = zeros(1, pointDim);
        end

        prevSelectedIndex = 1;
        if wptIndex > 2
            prevFile = fullfile(resultsFolder, sprintf('WptIdx-resultsWpt-%d.mat', wptIndex - 1));
            if isfile(prevFile)
                prevData = load(prevFile, 'indexOfBestIteration');
                if isfield(prevData, 'indexOfBestIteration')
                    prevSelectedIndex = double(prevData.indexOfBestIteration);
                end
            end
        end

        popFiles = dir(fullfile(resultsFolder, sprintf('WptIdx-%d-population-g*.mat', wptIndex)));
        if isempty(popFiles)
            continue;
        end

        generationNumbers = zeros(numel(popFiles), 1);
        for pi = 1:numel(popFiles)
            tok = regexp(popFiles(pi).name, sprintf('WptIdx-%d-population-g(\\d+)\\.mat', wptIndex), 'tokens', 'once');
            generationNumbers(pi) = str2double(tok{1});
        end
        [generationNumbers, order] = sort(generationNumbers);
        popFiles = popFiles(order);

        baseObj = struct();
        baseObj.vesselName = vesselName;
        baseObj.R_switch = shipParam.R_switch;
        baseObj.enviromentRandom = enviromentRandom;
        baseObj.startWptIndex = prevSelectedIndex;
        baseObj.endWptIndex = wptIndex;
        baseObj.vesselResultsPath = [resultsFolder filesep 'WptIdx-'];

        iterationCounter = 0;
        waypointTimer = tic;
        missingPathLabelState = [];

        for gi = 1:numel(popFiles)
            generationNumber = generationNumbers(gi);
            popData = load(fullfile(resultsFolder, popFiles(gi).name), 'Population');
            population = popData.Population;
            generationDecs = population.decs;
            generationSize = size(generationDecs, 1);
            firstIterationInGeneration = iterationCounter + 1;
            lastIterationInGeneration = iterationCounter + generationSize;
            if shouldSkipGeneration(resumeInfo, wptIndex, lastIterationInGeneration)
                iterationCounter = lastIterationInGeneration;
                continue;
            end

            pathsFile = fullfile(resultsFolder, sprintf('WptIdx-%d-paths-g%d.mat', wptIndex, generationNumber));
            [timestamps, missingPathLabel, paths] = initializeGenerationResults(pathsFile, generationSize, resumeInfo.enabled);
            if isempty(missingPathLabelState) || numel(missingPathLabelState) ~= generationSize
                missingPathLabelState = zeros(size(missingPathLabel));
            end
            if resumeInfo.enabled && isfile(pathsFile)
                missingPathLabelState = missingPathLabel;
            else
                missingPathLabel = missingPathLabelState;
            end
            generationRanSimulation = false;
            simulationsToRun = generationSize;
            if resumeInfo.enabled && wptIndex == resumeInfo.wptIndex
                simulationsToRun = lastIterationInGeneration - max(firstIterationInGeneration, resumeInfo.iterationIndex) + 1;
            end

            fprintf('%s / %s-exNum%d / WptIdx-%d / generation %d: running %d simulations\n', ...
                vesselName, selectionType, experimentNumber, wptIndex, generationNumber, simulationsToRun);

            for individualIndex = 1:generationSize
                iterationCounter = iterationCounter + 1;
                if shouldSkipIteration(resumeInfo, wptIndex, iterationCounter)
                    continue;
                end
                selectedDec = generationDecs(individualIndex, :);

                wpt = struct();
                wpt.pos.x = [startWpt(1); selectedDec(1)];
                wpt.pos.y = [startWpt(2); selectedDec(2)];
                if pointDim == 3
                    wpt.pos.z = [startWpt(3); selectedDec(3)];
                end

                obj = baseObj;
                obj.iterationIndex = iterationCounter;

                [endIteration, reachedWaypoint, lengthOfPath, lastPoint, subpath, angles] = runVesselSimulation(obj, wpt);
                ranAnySimulation = true;
                generationRanSimulation = true;
                timestamps(individualIndex) = toc(waypointTimer);
                if ~reachedWaypoint
                    missingPathLabel(individualIndex) = 1;
                    missingPathLabelState(individualIndex) = 1;
                end

                pathInfo = containers.Map();
                pathInfo('angles') = angles;
                paths(string(iterationCounter)) = pathInfo;
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

function tf = shouldSkipGeneration(resumeInfo, wptIndex, lastIterationInGeneration)
    tf = false;
    if ~resumeInfo.enabled || wptIndex ~= resumeInfo.wptIndex
        return;
    end

    tf = lastIterationInGeneration < resumeInfo.iterationIndex;
end

function tf = shouldSkipIteration(resumeInfo, wptIndex, iterationCounter)
    tf = false;
    if ~resumeInfo.enabled
        return;
    end

    if wptIndex > resumeInfo.wptIndex
        return;
    end

    tf = iterationCounter < resumeInfo.iterationIndex;
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

    newestTime = -Inf;
    newestWpt = 0;
    newestIter = 0;
    for i = 1:numel(replayIterFiles)
        tok = regexp(replayIterFiles(i).name, 'WptIdx-(\d+)-iter(\d+)\.mat', 'tokens', 'once');
        if isempty(tok)
            continue;
        end

        wptIndex = str2double(tok{1});
        iterationIndex = str2double(tok{2});
        fileTime = replayIterFiles(i).datenum;
        if fileTime > newestTime || (fileTime == newestTime && iterationIndex > newestIter)
            newestTime = fileTime;
            newestWpt = wptIndex;
            newestIter = iterationIndex;
        end
    end

    if newestWpt > 0
        resumeInfo.enabled = true;
        resumeInfo.wptIndex = newestWpt;
        resumeInfo.iterationIndex = newestIter;
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
