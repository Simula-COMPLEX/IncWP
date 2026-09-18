function results = runValidation(vesselName, selectionType, experimentNumber, writeFolder, overwriteProgress)
% Validate every saved individual using the other simulator.
% Run setupProject first, then addpath('validation').
% Example: results = runValidation("remus100", "IncWP_KP", 1);
% Optional output name: runValidation("remus100", "IncWP_KP", 1, "IncWP_KP_validation");
% FullWP uses segment simulation; single-selection IncWP uses full-path simulation.
% Resume by default. Pass true as argument 5 to discard saved progress.
% On resume, print a results overview for checkpointed individuals first.
% FullWP saves trajectory comparison labels; legacy checkpoints are compacted
% on resume without discarding completed individuals.

    arguments
        vesselName = "remus100"
        %selectionType = "IncWP_KP"
        selectionType = "FullWP"
        experimentNumber = 1
        writeFolder = selectionType + "_validation"
        overwriteProgress (1,1) logical = false
    end

    repoRoot = fileparts(fileparts(mfilename('fullpath')));
    dataRoot = fullfile(repoRoot, "experimentsData");
    % This folder is only used to load the original experiment data.
    sourceSelectionType = selectionType;
    if selectionType == "FullWPNoStopping"
        sourceSelectionType = "FullWP";
    end
    sourceFolder = fullfile(dataRoot, vesselName, sourceSelectionType + "-exNum" + experimentNumber);
    % Validation outputs and checkpoints are separate from the source data.
    writeFolder = fullfile(dataRoot, vesselName, writeFolder + "-exNum" + experimentNumber);

    if selectionType == "FullWP"
        results = validateFullWP(sourceFolder, writeFolder, overwriteProgress);
    elseif selectionType == "FullWPNoStopping"
        results = validateFullWPNoStopping(sourceFolder, writeFolder, overwriteProgress);
    else
        results = validateIncremental(sourceFolder, vesselName, selectionType, writeFolder, overwriteProgress);
    end
end

function results = validateFullWP(sourceFolder, writeFolder, overwriteProgress)
% Load FullWP decision and objective matrices, then prepare waypoint pairs.

    %% Load the original FullWP data
    saved = load(fullfile(sourceFolder, "setupConfiguration.mat"), "parameter");
    settings = saved.parameter.shipInformation;
    environment = saved.parameter.enviromentRandom;
    populationType = string(saved.parameter.populationType);
    numGenerations = 1000;
    populationSize = 10;
    overwriteIndividualStates = true; % Reuse the same state file per waypoint for each individual.

    allDecisions = [];
    allObjectives = [];
    for generationNumber = 1:numGenerations
        populationFile = fullfile(sourceFolder, populationType + "-population-g" + generationNumber + ".mat");
        saved = load(populationFile, "Population");
        decisions = saved.Population.decs;
        objectives = saved.Population.objs;
        allDecisions = [allDecisions; decisions];
        allObjectives = [allObjectives; objectives];
    end

    %% Prepare validation state and original classifications
    pointDimension = settings.pointDimension;
    numIndividuals = numGenerations * populationSize;
    segmentFitness = NaN(numIndividuals, settings.numWaypoints, 2);
    reachedWaypoints = NaN(numIndividuals, settings.numWaypoints);
    incrementalFitness = NaN(numIndividuals,2);
    recalculatedFitness = NaN(numIndividuals,2);
    subpathStatus = repmat("not simulated",numIndividuals,settings.numWaypoints);
    pathTypes = repmat("not simulated",numIndividuals,settings.numWaypoints);
    peak_analysis = [];
    originalTypes = repmat("original unavailable",numIndividuals,settings.numWaypoints);
    % Use the published original classifications, aligned with population rows.
    classificationFile = fullfile(sourceFolder,"classificiation.mat");
    if isfile(classificationFile)
        classification = load(classificationFile,"classesMap");
        for waypointIndex = 1:settings.numWaypoints
            labels = classification.classesMap(string(waypointIndex+1));
            originalTypes(:,waypointIndex) = string(labels(:));
        end
    else
        for waypointIndex = 1:settings.numWaypoints
            classificationFile = fullfile(sourceFolder,"WptIdx-resultsWpt-" + (waypointIndex+1) + ".mat");
            if ~isfile(classificationFile), continue; end
            classification = load(classificationFile,"individualClassMatrixWpt");
            if isfield(classification,"individualClassMatrixWpt")
                originalTypes(:,waypointIndex) = string(classification.individualClassMatrixWpt(:));
            end
        end
    end
    R_switch = settings.R_switch;
    environmentRandomValues = environment;
    if ~isfolder(writeFolder)
        mkdir(writeFolder);
    end
    % A fixed prefix reuses the state files across validation runs.
    vesselResultsPath = fullfile(writeFolder, "WptIdx-");

    %% Load or create the resume checkpoint
    checkpointFile = fullfile(writeFolder, "validationCheckpoint.mat");
    metadata = struct('mode', "FullWP", 'sourceFolder', string(sourceFolder), ...
        'settings', settings, 'environment', environment, ...
        'decisions', allDecisions, 'objectives', allObjectives, 'numIndividuals', numIndividuals);
    state = struct();
    state.segmentFitness = segmentFitness;
    state.reachedWaypoints = reachedWaypoints;
    state.incrementalFitness = incrementalFitness;
    state.recalculatedFitness = recalculatedFitness;
    state.subpathStatus = subpathStatus;
    state.pathTypes = pathTypes;
    checkpoint = loadValidationCheckpoint(checkpointFile, metadata, state, overwriteProgress);
    originalPathCache = struct('generation', 0, 'paths', []);
    % Upgrade legacy checkpoints before resuming, preserving every comparison.
    if isfield(checkpoint.state, 'subpaths')
        fprintf('Compacting saved trajectories into comparison results...\n');
        for completedIndex = 1:checkpoint.completedIndividuals
            [subpathStatus(completedIndex,:), originalPathCache] = compareValidationSubpaths( ...
                sourceFolder, populationType, populationSize, completedIndex, ...
                allDecisions(completedIndex,:), pointDimension, R_switch, ...
                checkpoint.state.subpaths(completedIndex,:), ...
                checkpoint.state.reachedWaypoints(completedIndex,:), originalPathCache);
            checkpoint.state.subpaths(completedIndex,:) = {[]};
            if mod(completedIndex,100) == 0
                fprintf('Compared saved trajectories: %d/%d.\n', ...
                    completedIndex, checkpoint.completedIndividuals);
            end
        end
        checkpoint.state = rmfield(checkpoint.state, 'subpaths');
        checkpoint.state.subpathStatus = subpathStatus;
        saveValidationCheckpoint(checkpointFile, checkpoint);
        fprintf('Checkpoint compacted; completed individuals preserved.\n');
    end
    segmentFitness = checkpoint.state.segmentFitness;
    reachedWaypoints = checkpoint.state.reachedWaypoints;
    incrementalFitness = checkpoint.state.incrementalFitness;
    recalculatedFitness = checkpoint.state.recalculatedFitness;
    subpathStatus = checkpoint.state.subpathStatus;
    pathTypes = checkpoint.state.pathTypes;
    fprintf('FullWP validation: %d/%d individuals already completed.\n', ...
        checkpoint.completedIndividuals, numIndividuals);
    displayValidationOverview(checkpoint, originalTypes);

    %% Simulate each individual
    for index = checkpoint.completedIndividuals+1:numIndividuals
        % These identify the individual, not a simulation timestep. Its next
        % segment resumes the state stored under the same individual index.
        currentIterationNumber = index;
        if overwriteIndividualStates
            currentIterationNumber = 1;
        end
        prevIterationNumber = currentIterationNumber;
        % The simulator adds <waypoint>-iter<individual>.mat to the prefix.
        % Reusing individual 1 overwrites the previous individual's state;
        % separate waypoint files still preserve state between its segments.
        % Each individual's first segment starts at the origin. Later segments
        % use the previous target waypoint; vessel state comes from its state file.
        startPoint = zeros(1,pointDimension);
        points = zeros(settings.numWaypoints+1,pointDimension);
        path = zeros(0,pointDimension);
        individualSubpaths = cell(1,settings.numWaypoints);
        individualSegmentFitness = NaN(settings.numWaypoints,2);

        for waypointIndex = 1:settings.numWaypoints
            columns = (waypointIndex-1)*pointDimension + (1:pointDimension);
            endPoint = allDecisions(index,columns);
            originalWaypoint = settings.initialPoints(columns);
            points(waypointIndex+1,:) = endPoint;
            wpt.pos.x = [startPoint(1); endPoint(1)];
            wpt.pos.y = [startPoint(2); endPoint(2)];
            if pointDimension == 3
                wpt.pos.z = [startPoint(3); endPoint(3)];
            end
            % The subpath functions count the origin as waypoint 1.
            currentWaypointIndex = waypointIndex+1;

            endIteration = NaN;
            reachedWaypoint = NaN;
            lengthOfPath = NaN; % Returned sample count, not distance in metres.
            lastPoint = NaN(1,pointDimension);
            subpath = [];
            angles = [];
            % Calls remain commented: these functions save intermediate state
            % using vesselResultsPath, which points to writeFolder only.
            if string(settings.shipName) == "mariner"
                % [endIteration, reachedWaypoint, lengthOfPath, lastPoint, subpath, angles] = ...
                %     runSubPathMariner(wpt, currentWaypointIndex, R_switch, environmentRandomValues, ...
                %         currentIterationNumber, prevIterationNumber, vesselResultsPath);
            elseif string(settings.shipName) == "nspauv"
                [endIteration, reachedWaypoint, lengthOfPath, lastPoint, subpath, angles] = ...
                     runSubPathNspauv(wpt, currentWaypointIndex, R_switch, environmentRandomValues, ...
                         currentIterationNumber, prevIterationNumber, vesselResultsPath);
            elseif string(settings.shipName) == "remus100"
                [endIteration, reachedWaypoint, lengthOfPath, lastPoint, subpath, angles] = ...
                     runSubPathRemus100(wpt, currentWaypointIndex, R_switch, environmentRandomValues, ...
                         currentIterationNumber, prevIterationNumber, vesselResultsPath);
            end

            individualSubpaths{waypointIndex} = subpath;
            reachedWaypoints(index,waypointIndex) = reachedWaypoint;

            % Same classification as calculatePathClassification: reachability
            % takes precedence; otherwise count oscillation peaks in all angles.
            if reachedWaypoint == false
                pathTypes(index,waypointIndex) = "missing";
            elseif reachedWaypoint == true
                pathTypes(index,waypointIndex) = "angles unavailable";
                if ~isempty(angles) && all(isfinite(angles(:)))
                    if isempty(peak_analysis)
                        analysisFolder = char(fullfile(fileparts(fileparts(mfilename('fullpath'))),"analysis"));
                        pythonPath = py.sys.path;
                        if count(pythonPath,analysisFolder) == 0
                            insert(pythonPath,int32(0),analysisFolder);
                        end
                        peak_analysis = py.importlib.import_module('calculate_number_of_peaks');
                    end
                    numPeaks = zeros(1,size(angles,2));
                    for angleIndex = 1:size(angles,2)
                        numPeaks(angleIndex) = calculateNumberOfPeaks(angles(:,angleIndex),true,peak_analysis);
                    end
                    pathTypes(index,waypointIndex) = "stable";
                    if any(numPeaks > 0)
                        pathTypes(index,waypointIndex) = "unstable";
                    end
                end
            end

            % Leave fitness uncalculated while the simulation call is disabled.
            if ~isempty(subpath)
                path = [path; subpath];
                pathLength = sum(sqrt(sum(diff(subpath,1,1).^2,2)));
                instability = pathLength / pdist2(originalWaypoint, startPoint);
                proximity = pdist2(originalWaypoint, endPoint);
                if ~reachedWaypoint
                    instability = 999999999;
                end
                individualSegmentFitness(waypointIndex,:) = [-instability, proximity];
                segmentFitness(index,waypointIndex,1) = -instability;
                segmentFitness(index,waypointIndex,2) = proximity;
            end
            startPoint = endPoint;
        end

        % Incremental fitness uses the mean instability and summed proximity.
        incrementalFitness(index,:) = [mean(individualSegmentFitness(:,1)), ...
            sum(individualSegmentFitness(:,2))];

        % Use the original FullWP formula for comparison with its saved fitness.
        if ~isempty(path) && all(~isnan(reachedWaypoints(index,:)))
            [transitions, segments, numberReached] = splitDataBetweenWaypoints(points(2:end,:), settings.R_switch, path);
            [proximity, instability, ~, missing] = evalauteWaypointsAndPath( ...
                settings.initialPoints, [], allDecisions(index,:), path, segments, transitions, numberReached);
            if any(missing)
                instability = 999999999;
            end
            recalculatedFitness(index,:) = [-instability, proximity];
        end
        [subpathStatus(index,:), originalPathCache] = compareValidationSubpaths( ...
            sourceFolder, populationType, populationSize, index, allDecisions(index,:), ...
            pointDimension, R_switch, individualSubpaths, reachedWaypoints(index,:), originalPathCache);
        % Retain comparison labels, not trajectories from previous individuals.
        clear individualSubpaths path subpath segments
        % Save only after every waypoint for this individual is complete.
        checkpoint.state.segmentFitness = segmentFitness;
        checkpoint.state.reachedWaypoints = reachedWaypoints;
        checkpoint.state.incrementalFitness = incrementalFitness;
        checkpoint.state.recalculatedFitness = recalculatedFitness;
        checkpoint.state.subpathStatus = subpathStatus;
        checkpoint.state.pathTypes = pathTypes;
        checkpoint.completedIndividuals = index;
        saveValidationCheckpoint(checkpointFile, checkpoint);
    end

    clear originalPathCache
    % Compare all individuals after simulation, preserving generation/row order.
    absoluteTolerance = 1e-8;
    relativeTolerance = 1e-8;
    fitnessDifference = recalculatedFitness - allObjectives;
    objectivesMatch = NaN(numIndividuals,1);
    objectiveStatus = repmat("not simulated",numIndividuals,1);
    for index = 1:numIndividuals
        if any(isnan(recalculatedFitness(index,:))), continue; end
        tolerance = absoluteTolerance + relativeTolerance * abs(allObjectives(index,:));
        objectivesMatch(index) = all(isfinite(recalculatedFitness(index,:))) && ...
            all(abs(fitnessDifference(index,:)) <= tolerance);
        objectiveStatus(index) = "different";
        if objectivesMatch(index), objectiveStatus(index) = "same"; end
    end

    % Present aggregate statistics; do not return paths, settings or loop state.
    outcome = ["Same objectives"; "Different objectives"; "Not simulated / incomplete"];
    outcomeCounts = [sum(objectiveStatus == "same"); sum(objectiveStatus == "different"); ...
        sum(objectiveStatus == "not simulated")];
    results.individuals = table(outcome, outcomeCounts, 100*outcomeCounts/numIndividuals, ...
        'VariableNames', {'Outcome', 'Individuals', 'PercentOfAll'});

    objectiveNames = ["Instability"; "Proximity"];
    compared = zeros(2,1);
    invalid = zeros(2,1);
    matchPercent = NaN(2,1);
    meanError = NaN(2,1);
    maxError = NaN(2,1);
    for objectiveIndex = 1:2
        available = ~isnan(recalculatedFitness(:,objectiveIndex));
        finite = available & isfinite(recalculatedFitness(:,objectiveIndex)) & ...
            isfinite(allObjectives(:,objectiveIndex));
        compared(objectiveIndex) = sum(finite);
        invalid(objectiveIndex) = sum(available & ~finite);
        if compared(objectiveIndex) > 0
            errors = abs(fitnessDifference(finite,objectiveIndex));
            tolerance = absoluteTolerance + relativeTolerance * abs(allObjectives(finite,objectiveIndex));
            matchPercent(objectiveIndex) = 100*sum(errors <= tolerance)/compared(objectiveIndex);
            meanError(objectiveIndex) = mean(errors);
            maxError(objectiveIndex) = max(errors);
        end
    end
    results.objectives = table(objectiveNames, compared, invalid, matchPercent, meanError, maxError, ...
        'VariableNames', {'Objective', 'FiniteComparisons', 'NonfiniteValues', ...
        'MatchPercent', 'MeanAbsoluteError', 'MaxAbsoluteError'});

    outcome = ["Same"; "Different coordinates"; "Different sample counts"; ...
        "Original unavailable"; "Not simulated"];
    outcomeCounts = [sum(subpathStatus(:) == "same"); sum(subpathStatus(:) == "different"); ...
        sum(subpathStatus(:) == "different sample counts"); ...
        sum(subpathStatus(:) == "original unavailable"); sum(subpathStatus(:) == "not simulated")];
    results.subpaths = table(outcome, outcomeCounts, 'VariableNames', {'Outcome', 'Subpaths'});
    results.waypoints = table((1:settings.numWaypoints)', ...
        sum(reachedWaypoints == 1,1)', sum(reachedWaypoints == 0,1)', ...
        sum(isnan(reachedWaypoints),1)', ...
        'VariableNames', {'Waypoint', 'Reached', 'NotReached', 'NotSimulated'});

    types = ["stable"; "unstable"; "missing"];
    originalCounts = zeros(3,1);
    recalculatedCounts = zeros(3,1);
    transitions = zeros(3,3);
    for originalType = 1:3
        originalCounts(originalType) = sum(originalTypes(:) == types(originalType));
        recalculatedCounts(originalType) = sum(pathTypes(:) == types(originalType));
        for newType = 1:3
            transitions(originalType,newType) = sum(originalTypes(:) == types(originalType) & ...
                pathTypes(:) == types(newType));
        end
    end
    results.pathTypes = table(types, originalCounts, recalculatedCounts, ...
        'VariableNames', {'Type', 'OriginalSubpaths', 'RecalculatedSubpaths'});
    results.typeTransitions = array2table(transitions, ...
        'RowNames', cellstr(types), 'VariableNames', {'Stable', 'Unstable', 'Missing'});
    comparable = ismember(originalTypes,types) & ismember(pathTypes,types);
    comparedTypes = sum(comparable(:));
    matchingTypes = sum(originalTypes(comparable) == pathTypes(comparable));
    typeMatchPercent = NaN;
    if comparedTypes > 0, typeMatchPercent = 100*matchingTypes/comparedTypes; end
    results.typeAgreement = table(comparedTypes, matchingTypes, comparedTypes-matchingTypes, typeMatchPercent, ...
        sum(~ismember(originalTypes(:),types)), sum(pathTypes(:) == "not simulated"), ...
        sum(pathTypes(:) == "angles unavailable"), ...
        'VariableNames', {'Compared', 'Same', 'Different', 'MatchPercent', ...
        'OriginalUnavailable', 'NotSimulated', 'AnglesUnavailable'});

    fprintf('\nFullWP validation: %d individuals across %d generations\n', numIndividuals, numGenerations);
    fprintf('Fitness comparison uses the original FullWP definition.\n');
    fprintf('Match tolerance: %.1g absolute + %.1g relative.\n', absoluteTolerance, relativeTolerance);
    disp(results.individuals);
    disp(results.objectives);
    disp(results.subpaths);
    disp(results.waypoints);
    disp(results.pathTypes);
    fprintf('Path type transitions: rows = original, columns = recalculated.\n');
    disp(results.typeTransitions);
    disp(results.typeAgreement);
    fprintf('Objective percentages/errors use finite comparisons only. NaN means no comparisons available.\n');
    save(fullfile(writeFolder, "validationResults.mat"), "results");

end

function [status, cache] = compareValidationSubpaths(sourceFolder, populationType, populationSize, index, decisions, pointDimension, R_switch, subpaths, reached, cache)
% Keep only one original generation in memory, shared by its individuals.
    status = repmat("not simulated",1,numel(subpaths));
    if all(isnan(reached)), return; end
    simulated = ~cellfun(@isempty,subpaths);
    status(simulated) = "original unavailable";
    generationNumber = ceil(index/populationSize);
    individualIndex = mod(index-1,populationSize)+1;
    if cache.generation ~= generationNumber
        cache.paths = [];
        cache.generation = generationNumber;
        pathsFile = fullfile(sourceFolder, populationType + "-paths-g" + generationNumber + ".mat");
        if isfile(pathsFile)
            savedPaths = load(pathsFile,"paths");
            cache.paths = savedPaths.paths;
        end
    end
    originalPaths = cache.paths;
    if isempty(originalPaths) || ~isKey(originalPaths,string(individualIndex)), return; end
    original = originalPaths(string(individualIndex));
    if ~isKey(original,"fullpath"), return; end
    points = reshape(decisions,pointDimension,[])';
    [~, originalSubpaths, ~] = splitDataBetweenWaypoints(points,R_switch,original("fullpath"));
    for waypointIndex = 1:numel(subpaths)
        if ~simulated(waypointIndex) || waypointIndex > numel(originalSubpaths), continue; end
        current = subpaths{waypointIndex};
        reference = originalSubpaths{waypointIndex};
        status(waypointIndex) = "different sample counts";
        if ~isequal(size(reference),size(current)), continue; end
        difference = abs(current-reference);
        tolerance = 1e-8 + 1e-8*abs(reference);
        status(waypointIndex) = "different";
        if all(isfinite(current(:))) && all(difference(:) <= tolerance(:))
            status(waypointIndex) = "same";
        end
    end
end

function results = validateFullWPNoStopping(sourceFolder, writeFolder, overwriteProgress)
% Re-run every FullWP individual with the no-divergence-stopping simulators.

    %% Load original FullWP data
    repoRoot = fileparts(fileparts(mfilename('fullpath')));
    saved = load(fullfile(sourceFolder, "setupConfiguration.mat"), "parameter");
    settings = saved.parameter.shipInformation;
    environment = saved.parameter.enviromentRandom;
    populationType = string(saved.parameter.populationType);
    numGenerations = 1000;
    populationSize = 10;
    countIndividuals = numGenerations * populationSize;
    decisions = [];
    for generationNumber = 1:numGenerations
        populationFile = fullfile(sourceFolder, populationType + "-population-g" + generationNumber + ".mat");
        population = load(populationFile, "Population");
        decisions = [decisions; population.Population.decs];
    end

    %% Load the original path types for comparison
    originalTypes = repmat("original unavailable", countIndividuals, settings.numWaypoints);
    classification = load(fullfile(sourceFolder, "classificiation.mat"), "classesMap");
    for waypointIndex = 1:settings.numWaypoints
        types = string(classification.classesMap(string(waypointIndex+1)));
        assert(numel(types) == countIndividuals, 'Validation:ClassificationSize', ...
            'Original classifications for waypoint %d do not match the population.', waypointIndex+1);
        originalTypes(:,waypointIndex) = types(:);
    end

    %% Use only the copied simulators without divergence stopping
    noStoppingPath = fullfile(repoRoot, "scripts", "vesselSearch", "globalSearch", ...
        "pathSimulation", "withoutEarlyStopping");
    addpath(noStoppingPath, '-begin');
    restorePath = onCleanup(@() rmpath(noStoppingPath));
    analysisPath = fullfile(repoRoot, "analysis");
    if count(py.sys.path, analysisPath) == 0
        insert(py.sys.path, int32(0), analysisPath);
    end
    peakAnalysis = py.importlib.import_module('calculate_number_of_peaks');

    %% Load or create the resume checkpoint
    checkpointFile = fullfile(writeFolder, "validationCheckpoint.mat");
    metadata = struct('mode', "FullWPNoStopping", 'sourceFolder', string(sourceFolder), ...
        'vesselName', string(settings.shipName), 'numIndividuals', countIndividuals, ...
        'numWaypoints', settings.numWaypoints, 'pointDimension', settings.pointDimension, ...
        'numGenerations', numGenerations, 'populationSize', populationSize);
    initialState = struct('simulationSeconds', NaN(countIndividuals,1), ...
        'newTypes', repmat("not simulated", countIndividuals, settings.numWaypoints), ...
        'reachedWaypoints', false(countIndividuals, settings.numWaypoints));
    checkpoint = loadValidationCheckpoint(checkpointFile, metadata, initialState, overwriteProgress);
    simulationSeconds = checkpoint.state.simulationSeconds;
    newTypes = checkpoint.state.newTypes;
    reachedWaypoints = checkpoint.state.reachedWaypoints;
    fprintf('FullWP no-stopping validation: %d/%d individuals already completed.\n', ...
        checkpoint.completedIndividuals, countIndividuals);
    displayValidationOverview(checkpoint, originalTypes);

    %% Simulate, time, and classify each original individual
    for index = checkpoint.completedIndividuals+1:countIndividuals
        points = reshape(decisions(index,:), settings.pointDimension, [])';

        % The full-path simulators require origin followed by the saved waypoints.
        wpt.pos.x = [0; points(:,1)];
        wpt.pos.y = [0; points(:,2)];
        if settings.pointDimension == 3
            wpt.pos.z = [0; points(:,3)];
        end
        % Run one full route with the vessel-specific simulator.
        started = tic;
        if string(settings.shipName) == "mariner"
            [simdata, ~, ~] = marinerPath(wpt, settings.R_switch, environment);
            ALOSdata = [];
        elseif string(settings.shipName) == "remus100"
            [simdata, ALOSdata, ~] = remus100path(wpt, settings.R_switch, environment);
        elseif string(settings.shipName) == "nspauv"
            [simdata, ALOSdata, ~] = npsauvPath(wpt, settings.R_switch, environment);
        else
            error('Validation:UnknownVessel', 'Unsupported vessel: %s.', settings.shipName);
        end
        simulationSeconds(index) = toc(started);
        % Split the resulting full path into its waypoint subpaths.
        [angles, fullpath] = extractAnglesAndPath(simdata, ALOSdata, string(settings.shipName));
        [transitions, ~, numberReached] = splitDataBetweenWaypoints(points, settings.R_switch, fullpath);
        reachedWaypoints(index,1:numberReached) = true;
        newTypes(index,:) = repmat("missing", 1, settings.numWaypoints);
        startIndex = 1;
        for waypointIndex = 1:numberReached
            endIndex = transitions(waypointIndex);
            segmentAngles = angles(startIndex:endIndex,:);
            peakCounts = zeros(1,size(segmentAngles,2));
            for angleIndex = 1:size(segmentAngles,2)
                peakCounts(angleIndex) = calculateNumberOfPeaks( ...
                    segmentAngles(:,angleIndex), true, peakAnalysis);
            end
            newTypes(index,waypointIndex) = "stable";
            if any(peakCounts > 0)
                newTypes(index,waypointIndex) = "unstable";
            end
            startIndex = endIndex + 1;
        end

        % Save this completed individual before starting the next one.
        checkpoint.state.simulationSeconds = simulationSeconds;
        checkpoint.state.newTypes = newTypes;
        checkpoint.state.reachedWaypoints = reachedWaypoints;
        checkpoint.completedIndividuals = index;
        saveValidationCheckpoint(checkpointFile, checkpoint);
    end

    %% Assemble and save comparison results
    typeMatches = newTypes == originalTypes;
    individual = (1:countIndividuals)';
    results.individuals = table(individual, simulationSeconds, sum(typeMatches,2), ...
        settings.numWaypoints - sum(typeMatches,2), ...
        'VariableNames', {'Individual', 'SimulationSeconds', 'MatchingSubpaths', 'IncorrectSubpaths'});
    comparisonIndividual = repelem(individual, settings.numWaypoints);
    waypoint = repmat((1:settings.numWaypoints)', countIndividuals, 1);
    results.subpaths = table(comparisonIndividual, waypoint, originalTypes(:), newTypes(:), ...
        typeMatches(:), 'VariableNames', {'Individual', 'Waypoint', 'OriginalType', ...
        'NoStoppingType', 'TypeMatches'});
    results.originalTypes = originalTypes;
    results.newTypes = newTypes;
    results.typeMatches = typeMatches;
    results.reachedWaypoints = reachedWaypoints;
    results.totalSimulationSeconds = sum(simulationSeconds);
    results.incorrectSubpaths = sum(~typeMatches, 'all');
    results.correctSubpaths = sum(typeMatches, 'all');
    results.writeFolder = string(writeFolder);
    save(fullfile(writeFolder, "validationResults.mat"), "results", "-v7.3");
    clear restorePath
end

function results = validateIncremental(sourceFolder, vesselName, selectionType, writeFolder, overwriteProgress)
% Replay selected earlier waypoints with every final-waypoint candidate.

    %% Load the original incremental data
    settings = loadShipSearchParameters(vesselName);
    saved = load(fullfile(sourceFolder, "finalInformation.mat"), "enviromentRandom");
    environment = saved.enviromentRandom;
    if ~isfolder(writeFolder), mkdir(writeFolder); end

    if selectionType == "IncWP_Kmeans"
        individuals = loadIncrementalIndividuals(sourceFolder, settings, selectionType);
    else
        [individuals, selectedWaypoints, numGenerations] = ...
            loadIncrementalValidationRoutes(sourceFolder, settings);
        if ~isfolder(writeFolder), mkdir(writeFolder); end
        fprintf('IncWP validation: %d full routes, %d generations per waypoint search.\n', ...
            height(individuals), numGenerations);
    end
    recalculatedFitness = NaN(height(individuals),2);
    recalculatedSegmentFitness = NaN(height(individuals),2);
    obj = struct('shipName', string(vesselName), 'pointDimension', settings.pointDimension, ...
        'R_switch', settings.R_switch, 'enviromentRandom', environment);

    %% Load or create the resume checkpoint
    checkpointFile = fullfile(writeFolder, "validationCheckpoint.mat");
    metadata = struct('mode', string(selectionType), 'sourceFolder', string(sourceFolder), ...
        'settings', settings, 'environment', environment, ...
        'individuals', individuals, 'numIndividuals', height(individuals));
    state = struct('recalculatedFitness', recalculatedFitness, ...
        'recalculatedSegmentFitness', recalculatedSegmentFitness);
    checkpoint = loadValidationCheckpoint(checkpointFile, metadata, state, overwriteProgress);
    recalculatedFitness = checkpoint.state.recalculatedFitness;
    recalculatedSegmentFitness = checkpoint.state.recalculatedSegmentFitness;

    if selectionType ~= "IncWP_Kmeans"
        save(fullfile(writeFolder, "validationInputs.mat"), ...
            "individuals", "selectedWaypoints", "numGenerations", "settings", "environment");
    end

    %% Simulate each route and save after each completed individual
    fprintf('IncWP validation: %d/%d individuals already completed.\n', ...
        checkpoint.completedIndividuals, height(individuals));
    displayValidationOverview(checkpoint);
    for index = checkpoint.completedIndividuals+1:height(individuals)
        points = individuals.Waypoints{index};
        [path, ~, ~, ~, ~] = performSimulation(reshape(points(2:end,:)',1,[]), obj);
        scores = incrementalSegmentFitness(path, points, settings);
        recalculatedFitness(index,:) = accumulateFitness(scores, selectionType);
        recalculatedSegmentFitness(index,:) = scores(end,:);

        checkpoint.state.recalculatedFitness = recalculatedFitness;
        checkpoint.state.recalculatedSegmentFitness = recalculatedSegmentFitness;
        checkpoint.completedIndividuals = index;
        saveValidationCheckpoint(checkpointFile, checkpoint);
    end

    %% Compare recalculated fitness with the original saved fitness
    absoluteTolerance = 1e-8;
    relativeTolerance = 1e-8;
    fitnessDifference = recalculatedFitness - individuals.StoredFitness;
    segmentFitnessDifference = recalculatedSegmentFitness - individuals.StoredSegmentFitness;

    fitnessMatches = NaN(height(individuals),1);
    segmentFitnessMatches = NaN(height(individuals),1);
    for index = 1:height(individuals)
        originalFitness = individuals.StoredFitness(index,:);
        newFitness = recalculatedFitness(index,:);
        if all(isfinite(originalFitness)) && all(isfinite(newFitness))
            tolerance = absoluteTolerance + relativeTolerance * abs(originalFitness);
            fitnessMatches(index) = all(abs(fitnessDifference(index,:)) <= tolerance);
        end

        originalSegmentFitness = individuals.StoredSegmentFitness(index,:);
        newSegmentFitness = recalculatedSegmentFitness(index,:);
        if all(isfinite(originalSegmentFitness)) && all(isfinite(newSegmentFitness))
            tolerance = absoluteTolerance + relativeTolerance * abs(originalSegmentFitness);
            segmentFitnessMatches(index) = ...
                all(abs(segmentFitnessDifference(index,:)) <= tolerance);
        end
    end

    %% Assemble and save results
    results.writeFolder = writeFolder;
    results.individuals = individuals;
    results.individuals.RecalculatedFitness = recalculatedFitness;
    results.individuals.FitnessDifference = fitnessDifference;
    results.individuals.FitnessMatches = fitnessMatches;
    results.individuals.RecalculatedSegmentFitness = recalculatedSegmentFitness;
    results.individuals.SegmentFitnessDifference = segmentFitnessDifference;
    results.individuals.SegmentFitnessMatches = segmentFitnessMatches;
    results.initialWaypoints = reshape(settings.initialPoints, settings.pointDimension, [])';
    results.environment = environment;
    if selectionType == "IncWP_Kmeans"
        results.fitnessNote = "Kmeans aggregate accumulation in the current runner has incompatible " + ...
            "column counts. Aggregate fitness is NaN; segment fitness is compared for every individual.";
    else
        results.selectedWaypoints = selectedWaypoints;
        results.numGenerationsPerWaypoint = numGenerations;
    end
    comparison = ["Full route fitness"; "Final segment fitness"];
    same = [sum(fitnessMatches == 1); sum(segmentFitnessMatches == 1)];
    different = [sum(fitnessMatches == 0); sum(segmentFitnessMatches == 0)];
    unavailable = [sum(isnan(fitnessMatches)); sum(isnan(segmentFitnessMatches))];
    results.fitnessComparison = table(comparison, same, different, unavailable, ...
        'VariableNames', {'Comparison', 'Same', 'Different', 'Unavailable'});
    save(fullfile(writeFolder, "validationResults.mat"), "results");
end

function individuals = loadIncrementalIndividuals(folder, settings, approach)
    files = dir(fullfile(folder, "WptIdx-*-population-g*.mat"));
    fileKeys = zeros(numel(files),2);
    for k = 1:numel(files)
        token = regexp(files(k).name, 'WptIdx-(\d+)-population-g(\d+)\.mat$', 'tokens', 'once');
        fileKeys(k,:) = [str2double(token{1}), str2double(token{2})];
    end
    [fileKeys, order] = sortrows(fileKeys, [1 2]);
    files = files(order);
    waypointResults = cell(settings.numWaypoints+1,1);
    for waypointIndex = unique(fileKeys(:,1))'
        waypointResults{waypointIndex} = load(fullfile(folder, ...
            "WptIdx-resultsWpt-" + waypointIndex + ".mat"));
    end

    ids = zeros(0,3);
    waypoints = cell(0,1);
    parents = cell(0,1);
    fitness = zeros(0,2);
    segmentFitness = zeros(0,2);
    for fileIndex = 1:numel(files)
        saved = load(fullfile(folder, files(fileIndex).name));
        decisions = saved.Population.decs;
        objectives = saved.Population.objs;
        waypointIndex = fileKeys(fileIndex,1);
        generationNumber = fileKeys(fileIndex,2);
        for individualIndex = 1:size(decisions,1)
            points = zeros(waypointIndex,settings.pointDimension);
            points(end,:) = decisions(individualIndex,:);
            parentIndices = zeros(waypointIndex-2,1);
            if approach == "IncWP_Kmeans"
                mapping = waypointResults{waypointIndex}.mappingOfIndexes;
                rows = mapping(mapping(:,2) == generationNumber,:);
                parentIndex = rows(individualIndex,3);
            end
            for previousWaypoint = waypointIndex-1:-1:2
                previous = waypointResults{previousWaypoint};
                if approach == "IncWP_Kmeans"
                    previousDecisions = previous.paretoFrontPopulations.decs;
                else
                    previousDecisions = previous.finalPopulation.decs;
                    parentIndex = previous.indexOfBestIteration;
                end
                points(previousWaypoint,:) = previousDecisions(parentIndex,:);
                parentIndices(previousWaypoint-1) = parentIndex;
                if approach == "IncWP_Kmeans"
                    row = previous.mappingOfIndexes(:,1) == parentIndex;
                    parentIndex = previous.mappingOfIndexes(row,3);
                end
            end
            ids(end+1,:) = [waypointIndex, generationNumber, individualIndex];
            waypoints{end+1,1} = points;
            parents{end+1,1} = parentIndices;
            fitness(end+1,:) = objectives(individualIndex,:);
            segmentFitness(end+1,:) = saved.objectivesWithoutPrevList(individualIndex,:);
        end
    end
    individuals = table(ids(:,1), ids(:,2), ids(:,3), waypoints, parents, fitness, segmentFitness, ...
        'VariableNames', {'WaypointIndex', 'GenerationNumber', 'IndividualIndex', ...
        'Waypoints', 'ParentIndices', 'StoredFitness', 'StoredSegmentFitness'});
end

function scores = incrementalSegmentFitness(path, points, settings)
    % Same segment objectives as incrementalWaypointProblem.CalObj.
    % Stop each segment at first arrival: the full simulator may continue
    % beyond the final waypoint, which is outside the incremental objective.
    nominal = reshape(settings.initialPoints, settings.pointDimension, [])';
    scores = zeros(size(points,1)-1,2);
    firstSample = 1;
    for k = 1:size(points,1)-1
        remaining = path(firstSample:end,:);
        arrival = find(pdist2(remaining, points(k+1,:)) < settings.R_switch, 1);
        scores(k,2) = pdist2(nominal(k,:), points(k+1,:));
        if isempty(arrival)
            scores(k,1) = -999999999;
            firstSample = size(path,1)+1;
        else
            segment = remaining(1:arrival,:);
            lengthOfPath = sum(sqrt(sum(diff(segment,1,1).^2,2)));
            scores(k,1) = -lengthOfPath / pdist2(nominal(k,:), points(k,:));
            firstSample = firstSample + arrival;
        end
    end
end

function fitness = accumulateFitness(scores, approach)
    if approach == "IncWP_Kmeans"
        % The current Kmeans runner's accumulation has incompatible widths.
        % Do not invent an aggregate and present it as the archived formula.
        fitness = [NaN NaN];
    else
        fitness = [mean(scores(:,1)), sum(scores(:,2))];
    end
end


function [individuals, selectedWaypoints, numGenerations] = loadIncrementalValidationRoutes(folder, settings, originalGenerations, populationSize)
% Assemble the saved selected prefix with every final-waypoint individual.
    arguments
        folder
        settings
        originalGenerations = 1000
        populationSize = 10
    end

    % Same budget split as runIncWP and getPopulation.
    maxEvaluation = ceil(populationSize * originalGenerations / ...
        (settings.numWaypoints * populationSize)) * populationSize;
    numGenerations = ceil(maxEvaluation / populationSize);
    lastWaypoint = settings.numWaypoints + 1;
    prefix = zeros(settings.numWaypoints, settings.pointDimension);
    selectedIndices = zeros(settings.numWaypoints-1,1);

    for waypointIndex = 2:lastWaypoint
        decisions = [];
        objectives = [];
        segmentObjectives = [];
        ids = [];
        for generation = 1:numGenerations
            filename = fullfile(folder, "WptIdx-" + waypointIndex + ...
                "-population-g" + generation + ".mat");
            saved = load(filename, "Population", "objectivesWithoutPrevList");
            generationDecisions = saved.Population.decs;
            count = size(generationDecisions,1);
            decisions = [decisions; generationDecisions];
            objectives = [objectives; saved.Population.objs];
            segmentObjectives = [segmentObjectives; saved.objectivesWithoutPrevList];
            ids = [ids; repmat([waypointIndex generation],count,1), (1:count)'];
        end

        if waypointIndex < lastWaypoint
            selected = load(fullfile(folder, "WptIdx-resultsWpt-" + ...
                waypointIndex + ".mat"), "indexOfBestIteration");
            index = selected.indexOfBestIteration;
            assert(isscalar(index) && index >= 1 && index <= size(decisions,1) && ...
                index == fix(index), 'Invalid saved selection for waypoint %d.', waypointIndex);
            % The saved index addresses the populations concatenated in generation order.
            prefix(waypointIndex,:) = decisions(index,:);
            selectedIndices(waypointIndex-1) = index;
        end
    end

    % No selection at the last waypoint: retain all generations and rows.
    count = size(decisions,1);
    waypoints = cell(count,1);
    for index = 1:count
        waypoints{index} = [prefix; decisions(index,:)];
    end
    parents = repmat({selectedIndices},count,1);
    individuals = table(ids(:,1), ids(:,2), ids(:,3), waypoints, parents, ...
        objectives, segmentObjectives, 'VariableNames', ...
        {'WaypointIndex', 'GenerationNumber', 'IndividualIndex', 'Waypoints', ...
        'ParentIndices', 'StoredFitness', 'StoredSegmentFitness'});
    selectedWaypoints = table((2:lastWaypoint-1)', selectedIndices, prefix(2:end,:), ...
        'VariableNames', {'WaypointIndex', 'SelectedIndividualIndex', 'Coordinates'});
end


function checkpoint = loadValidationCheckpoint(filename, metadata, initialState, overwriteProgress)
% Shared resume state for FullWP, FullWPNoStopping, and incremental validation.

    if isfile(filename) && ~overwriteProgress
        saved = load(filename, 'checkpoint');
        assert(isfield(saved, 'checkpoint') && isfield(saved.checkpoint, 'version') && ...
            saved.checkpoint.version == 1, 'Validation:InvalidCheckpoint', ...
            'Unsupported checkpoint. Set overwriteProgress=true to start again.');
        checkpoint = saved.checkpoint;
        assert(isequaln(checkpoint.metadata, metadata), 'Validation:CheckpointMismatch', ...
            'Validation inputs changed. Set overwriteProgress=true to start again.');
        count = checkpoint.completedIndividuals;
        assert(isscalar(count) && isfinite(count) && count == fix(count) && ...
            count >= 0 && count <= metadata.numIndividuals, ...
            'Validation:InvalidCheckpoint', 'Invalid completed-individual count.');
    else
        checkpoint = struct('version', 1, 'metadata', metadata, ...
            'completedIndividuals', 0, 'state', initialState);
        saveValidationCheckpoint(filename, checkpoint);
    end
end

function displayValidationOverview(checkpoint, originalTypes)
% Summarize only completed rows, without loading or comparing trajectories.
    count = checkpoint.completedIndividuals;
    if count == 0, return; end
    total = checkpoint.metadata.numIndividuals;
    rows = 1:count;
    state = checkpoint.state;
    fprintf('\nSaved results overview: %d/%d completed (%.2f%%), %d remaining.\n', ...
        count, total, 100*count/total, total-count);
    fprintf('All comparisons below use completed individuals only.\n');

    if isfield(state, 'recalculatedFitness')
        if checkpoint.metadata.mode == "FullWP"
            original = checkpoint.metadata.objectives(rows,:);
        else
            original = checkpoint.metadata.individuals.StoredFitness(rows,:);
        end
        displayFitnessOverview("Full route objectives", original, state.recalculatedFitness(rows,:));
    end
    if isfield(state, 'recalculatedSegmentFitness')
        original = checkpoint.metadata.individuals.StoredSegmentFitness(rows,:);
        displayFitnessOverview("Final segment objectives", original, state.recalculatedSegmentFitness(rows,:));
    end
    if isfield(state, 'reachedWaypoints')
        reached = state.reachedWaypoints(rows,:);
        disp(table((1:size(reached,2))', sum(reached == 1,1)', ...
            sum(reached == 0,1)', sum(isnan(reached),1)', ...
            'VariableNames', {'Waypoint', 'Reached', 'NotReached', 'Unavailable'}));
    end
    if isfield(state, 'subpathStatus')
        status = state.subpathStatus(rows,:);
        outcomes = ["same"; "different"; "different sample counts"; ...
            "original unavailable"; "not simulated"];
        counts = zeros(numel(outcomes),1);
        for k = 1:numel(outcomes)
            counts(k) = sum(status(:) == outcomes(k));
        end
        disp(table(outcomes, counts, 'VariableNames', {'TrajectoryComparison', 'Subpaths'}));
    end
    if nargin > 1
        if isfield(state, 'pathTypes')
            newTypes = state.pathTypes(rows,:);
        else
            newTypes = state.newTypes(rows,:);
        end
        originalTypes = originalTypes(rows,:);
        types = ["stable"; "unstable"; "missing"];
        originalCounts = zeros(3,1);
        newCounts = zeros(3,1);
        for k = 1:3
            originalCounts(k) = sum(originalTypes(:) == types(k));
            newCounts(k) = sum(newTypes(:) == types(k));
        end
        disp(table(types, originalCounts, newCounts, ...
            'VariableNames', {'Type', 'OriginalSubpaths', 'RecalculatedSubpaths'}));
        comparable = ismember(originalTypes,types) & ismember(newTypes,types);
        same = sum(originalTypes(comparable) == newTypes(comparable));
        compared = sum(comparable(:));
        fprintf('Path classifications: %d same, %d different, %d unavailable.\n', ...
            same, compared-same, numel(comparable)-compared);
        if compared > 0
            fprintf('Classification agreement: %.2f%% of comparable subpaths.\n', 100*same/compared);
        end
    end
    if isfield(state, 'simulationSeconds')
        seconds = state.simulationSeconds(rows);
        seconds = seconds(isfinite(seconds));
        if ~isempty(seconds)
            fprintf('Simulation time: %.1f s/individual on average; ~%.2f hours remaining\n', ...
                mean(seconds), mean(seconds)*(total-count)/3600);
            fprintf('(Estimate excludes classification and checkpoint saving.)\n');
        end
    end
    if count < total
        fprintf('Resuming at individual %d.\n\n', count+1);
    else
        fprintf('Simulation complete; assembling final results.\n\n');
    end
end

function displayFitnessOverview(label, original, recalculated)
    comparable = all(isfinite(original),2) & all(isfinite(recalculated),2);
    tolerance = 1e-8 + 1e-8*abs(original);
    matches = comparable & all(abs(recalculated-original) <= tolerance,2);
    fprintf('%s: %d same, %d different, %d unavailable (tolerance 1e-8 absolute + relative).\n', ...
        label, sum(matches), sum(comparable & ~matches), sum(~comparable));
end

function saveValidationCheckpoint(filename, checkpoint)
% Save only after one individual is complete, so an interrupted one is rerun.

    checkpoint.savedAt = datetime('now');
    pendingFile = string(filename) + ".pending.mat";
    save(pendingFile, 'checkpoint', '-v7.3');
    [success, message] = movefile(pendingFile, filename, 'f');
    assert(success, 'Validation:CheckpointWriteFailed', '%s', message);
end
