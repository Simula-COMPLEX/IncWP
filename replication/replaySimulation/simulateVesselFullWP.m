function simulateVesselFullWP(vesselName, selectionType, experimentNumber, resumeFromLastIteration, dataRoot)
% simulateVesselFullWP Regenerate FullWP Comb-paths-g*.mat files.

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

    setupFile = fullfile(resultsFolder, 'setupConfiguration.mat');
    if ~isfile(setupFile)
        error('Missing setupConfiguration.mat in %s', resultsFolder);
    end

    setupData = load(setupFile, 'parameter');
    if ~isfield(setupData, 'parameter')
        error('Missing parameter in %s', setupFile);
    end

    parameter = setupData.parameter;
    if ~isfield(parameter, 'shipInformation') || ~isfield(parameter, 'enviromentRandom')
        error('Missing shipInformation or enviromentRandom in %s', setupFile);
    end

    shipInformation = parameter.shipInformation;
    populationType = string(parameter.populationType);
    populationFiles = dir(fullfile(resultsFolder, sprintf('%s-population-g*.mat', populationType)));
    if isempty(populationFiles)
        error('No %s-population-g*.mat files found in %s', populationType, resultsFolder);
    end

    generationNumbers = getGenerationNumbers(populationFiles, populationType);
    replayObj = struct();
    replayObj.shipName = string(shipInformation.shipName);
    replayObj.initialPoints = shipInformation.initialPoints;
    replayObj.pointDimension = shipInformation.pointDimension;
    replayObj.R_switch = shipInformation.R_switch;
    replayObj.initialPath = [];
    replayObj.enviromentRandom = parameter.enviromentRandom;

    for generationNumber = generationNumbers
        pathsFile = fullfile(resultsFolder, sprintf('%s-paths-g%d.mat', populationType, generationNumber));
        if resumeFromLastIteration && isfile(pathsFile)
            continue;
        end

        populationFile = fullfile(resultsFolder, sprintf('%s-population-g%d.mat', populationType, generationNumber));
        populationData = load(populationFile, 'Population');
        if ~isfield(populationData, 'Population')
            error('Missing Population in %s', populationFile);
        end

        populationDecs = extractPopulationDecisions(populationData.Population);
        if isempty(populationDecs)
            error('Population decisions missing in %s', populationFile);
        end

        generationSize = size(populationDecs, 1);
        paths = containers.Map();
        timestamps = zeros(generationSize, 1);
        missingPathLabel = zeros(generationSize, 1);
        subPathDistanceMatrix = [];
        pathMissingFlagsMatrix = [];
        generationTimer = tic;

        fprintf('%s / %s-exNum%d / generation %d: running %d simulations\n', ...
            vesselName, selectionType, experimentNumber, generationNumber, generationSize);

        for individualIndex = 1:generationSize
            individual = populationDecs(individualIndex, :);
            [fullpath, subPaths, transitionIndices, angles, numberOfPointsReached] = performSimulation(individual, replayObj);

            pathInfo = containers.Map();
            pathInfo("fullpath") = fullpath;
            pathInfo("transitionIndices") = transitionIndices;
            pathInfo("angles") = angles;
            paths(string(individualIndex)) = pathInfo;

            [~, ~, subPathDistances, pathMissingFlagsList] = evalauteWaypointsAndPath( ...
                replayObj.initialPoints, replayObj.initialPath, individual, fullpath, subPaths, transitionIndices, numberOfPointsReached);

            if any(pathMissingFlagsList)
                missingPathLabel(individualIndex) = 1;
                missingCount = numel(individual) / replayObj.pointDimension - numel(subPathDistances);
                if missingCount > 0
                    subPathDistances = [subPathDistances; -999999999 * ones(missingCount, 1)];
                end
            end

            subPathDistanceMatrix = [subPathDistanceMatrix subPathDistances];
            pathMissingFlagsMatrix = [pathMissingFlagsMatrix; pathMissingFlagsList];
            timestamps(individualIndex) = toc(generationTimer);
        end

        save(pathsFile, 'paths', 'timestamps', 'missingPathLabel', 'subPathDistanceMatrix', 'pathMissingFlagsMatrix');
    end
end

function generationNumbers = getGenerationNumbers(files, populationType)
    generationNumbers = zeros(numel(files), 1);
    pattern = sprintf('%s-population-g(\\d+)\\.mat', regexptranslate('escape', char(populationType)));
    for i = 1:numel(files)
        tok = regexp(files(i).name, pattern, 'tokens', 'once');
        if isempty(tok)
            generationNumbers(i) = NaN;
        else
            generationNumbers(i) = str2double(tok{1});
        end
    end
    generationNumbers = sort(unique(generationNumbers(~isnan(generationNumbers))));
end

function populationDecs = extractPopulationDecisions(population)
    populationDecs = [];

    if isstruct(population)
        if isfield(population, 'decs')
            populationDecs = population.decs;
        elseif isfield(population, 'dec')
            populationDecs = population.dec;
        end
        return;
    end

    if isobject(population)
        try
            populationDecs = population.decs;
        catch
            populationDecs = [];
        end
    end
end
