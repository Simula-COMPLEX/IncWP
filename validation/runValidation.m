function results = runValidation(vesselName, selectionType, experimentNumber, writeFolder)
% Validate every saved individual using the other simulator.
% Run setupProject first, then addpath('validation').
% Example: results = runValidation("remus100", "IncWP_KP", 1);
% Optional output name: runValidation("remus100", "IncWP_KP", 1, "IncWP_KP_validation");
% Simulation blocks are commented out: only inputs are loaded for now.

    arguments
        vesselName = "remus100"
        %selectionType = "IncWP_KP"
        selectionType = "FullWP"
        experimentNumber = 1
        writeFolder = selectionType + "_validation"
    end

    repoRoot = fileparts(fileparts(mfilename('fullpath')));
    dataRoot = fullfile(repoRoot, "experimentsData");
    % This folder is only used to load the original experiment data.
    sourceFolder = fullfile(dataRoot, vesselName, selectionType + "-exNum" + experimentNumber);
    % Proposed destination only; no folder is created or renamed.
    writeFolder = fullfile(dataRoot, vesselName, writeFolder + "-exNum" + experimentNumber);

    if selectionType == "FullWP"
        results = validateFullWP(sourceFolder, writeFolder);
    else
        results = validateIncremental(sourceFolder, vesselName, selectionType, writeFolder);
    end
end

function results = validateFullWP(sourceFolder, writeFolder)
% Load FullWP decision and objective matrices, then prepare waypoint pairs.

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

    pointDimension = settings.pointDimension;
    numIndividuals = numGenerations * populationSize;
    segmentFitness = NaN(numIndividuals, settings.numWaypoints, 2);
    reachedWaypoints = NaN(numIndividuals, settings.numWaypoints);
    incrementalFitness = NaN(numIndividuals,2);
    recalculatedFitness = NaN(numIndividuals,2);
    subpaths = cell(numIndividuals, settings.numWaypoints);
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

    for index = 1:numIndividuals
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

            subpaths{index,waypointIndex} = subpath;
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
    end

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

    % Original FullWP trajectories, when available, are in Comb-paths-g*.mat.
    % New subpaths are already retained in memory, even if state files are reused.
    subpathStatus = repmat("not simulated",numIndividuals,settings.numWaypoints);
    for generationNumber = 1:numGenerations
        pathsFile = fullfile(sourceFolder, populationType + "-paths-g" + generationNumber + ".mat");
        originalPaths = [];
        if isfile(pathsFile)
            savedPaths = load(pathsFile,"paths");
            originalPaths = savedPaths.paths;
        end
        for individualIndex = 1:populationSize
            index = (generationNumber-1)*populationSize + individualIndex;
            if all(isnan(reachedWaypoints(index,:))), continue; end
            simulated = ~cellfun(@isempty,subpaths(index,:));
            subpathStatus(index,simulated) = "original unavailable";
            if isempty(originalPaths) || ~isKey(originalPaths,string(individualIndex)), continue; end
            original = originalPaths(string(individualIndex));
            if ~isKey(original,"fullpath"), continue; end
            points = zeros(settings.numWaypoints,pointDimension);
            for waypointIndex = 1:settings.numWaypoints
                columns = (waypointIndex-1)*pointDimension + (1:pointDimension);
                points(waypointIndex,:) = allDecisions(index,columns);
            end
            [~, originalSubpaths, ~] = splitDataBetweenWaypoints(points,R_switch,original("fullpath"));
            for waypointIndex = 1:settings.numWaypoints
                current = subpaths{index,waypointIndex};
                if isempty(current)
                    subpathStatus(index,waypointIndex) = "not simulated";
                    continue;
                end
                if waypointIndex > numel(originalSubpaths), continue; end
                reference = originalSubpaths{waypointIndex};
                subpathStatus(index,waypointIndex) = "different sample counts";
                if ~isequal(size(reference),size(current)), continue; end
                difference = abs(current-reference);
                tolerance = absoluteTolerance + relativeTolerance * abs(reference);
                subpathStatus(index,waypointIndex) = "different";
                if all(isfinite(current(:))) && all(difference(:) <= tolerance(:))
                    subpathStatus(index,waypointIndex) = "same";
                end
            end
        end
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

end

function results = validateIncremental(sourceFolder, vesselName, selectionType, writeFolder)
% Load incremental individuals and recalculate fitness with full-path simulation.
% Each candidate includes its saved parent sequence, ending at its own waypoint.
% Source files are read-only; all results stay in memory.

    settings = loadShipSearchParameters(vesselName);
    saved = load(fullfile(sourceFolder, "finalInformation.mat"), "enviromentRandom");
    environment = saved.enviromentRandom;
    individuals = loadIncrementalIndividuals(sourceFolder, settings, selectionType);
    recalculatedFitness = NaN(height(individuals),2);
    recalculatedSegmentFitness = NaN(height(individuals),2);
    obj = struct('shipName', string(vesselName), 'pointDimension', settings.pointDimension, ...
        'R_switch', settings.R_switch, 'enviromentRandom', environment);

    % Disabled along with the dependent fitness calculations.
    %{
    for index = 1:height(individuals)
        points = individuals.Waypoints{index};
        [path, ~, ~, ~, ~] = performSimulation(reshape(points(2:end,:)',1,[]), obj);
        scores = incrementalSegmentFitness(path, points, settings);
        recalculatedFitness(index,:) = accumulateFitness(scores, selectionType);
        recalculatedSegmentFitness(index,:) = scores(end,:);
    end
    %}

    results.writeFolder = writeFolder;
    results.individuals = individuals;
    results.individuals.RecalculatedFitness = recalculatedFitness;
    results.individuals.FitnessDifference = recalculatedFitness - individuals.StoredFitness;
    results.individuals.RecalculatedSegmentFitness = recalculatedSegmentFitness;
    results.individuals.SegmentFitnessDifference = recalculatedSegmentFitness - individuals.StoredSegmentFitness;
    results.initialWaypoints = reshape(settings.initialPoints, settings.pointDimension, [])';
    results.environment = environment;
    if selectionType == "IncWP_Kmeans"
        results.fitnessNote = "Kmeans aggregate accumulation in the current runner has incompatible " + ...
            "column counts. Aggregate fitness is NaN; segment fitness is compared for every individual.";
    end
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
