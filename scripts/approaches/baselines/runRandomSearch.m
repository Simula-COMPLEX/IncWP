function [resultingWaypoints, fullSearchTime] = runRandomSearch(vesselName, resultsPath, experimentNumber, numGenerations, populationSize)
    % Run the random-search baseline waypoint by waypoint.
    initialTimestamp = tic;
    algorithm = @RandomSearchAlogrithm;
    problem = @incrementalWaypointProblem;

    selectionType = "RandomSearch";
    vesselResultsPathBase = append(resultsPath, "/", vesselName, "/", selectionType, "-exNum", string(experimentNumber), "/WptIdx-");

    % Load vessel-specific waypoint and simulation settings.
    parameter.vesselInformation = loadShipSearchParameters(vesselName);
    initialPointsMatrix = [zeros(1, parameter.vesselInformation.pointDimension); ...
                           reshape(parameter.vesselInformation.initialPoints, [parameter.vesselInformation.pointDimension, parameter.vesselInformation.numWaypoints])'];

    % RandomSearch spends the full waypoint budget in one generation.
    MaxEvaluation = round((populationSize * numGenerations / parameter.vesselInformation.numWaypoints) / populationSize) * populationSize;
    populationSize = MaxEvaluation;
    numGenerations = 1;

    numberOfSamples = parameter.vesselInformation.numberOfSamples;
    numberOfRandomEnviromentVariables = parameter.vesselInformation.numberOfRandomEnviromentVariables;
    enviromentRandom = randn([numberOfRandomEnviromentVariables, numberOfSamples + 1]);
    parameter.enviromentRandom = enviromentRandom;
    parameter.iterationIndex = 0;
    parameter.generation = 1;

    % The search starts from the initial vessel position and advances one waypoint at a time.
    startWpt = initialPointsMatrix(1, :);
    startWptIndex = 1;
    prevWptObjectiveScores = [];
    resultingWaypoints = startWpt;

    for wptIndex = 2:parameter.vesselInformation.numWaypoints + 1
        timestampBeforeSearch = tic;
        endWpt = initialPointsMatrix(wptIndex, :);
        parameter.startWpt = startWpt;
        parameter.startWptIndex = startWptIndex;
        parameter.endWpt = endWpt;
        parameter.endWptIndex = wptIndex;
        parameter.prevWptObjectiveScores = prevWptObjectiveScores;
        parameter.vesselResultsPath = vesselResultsPathBase;

        % Run the random population search for this waypoint transition.
        platemo('algorithm', algorithm, 'problem', problem, 'N', populationSize, 'maxFE', MaxEvaluation, 'save', 0, 'run', 1, 'parameter', parameter);
        
        % Load the saved population and choose one valid solution at random.
        [finalPopulation, objectivesWithoutPrev] = loadCombinedPopulation(append(parameter.vesselResultsPath, string(wptIndex)), numGenerations);

        decs = finalPopulation.decs;
        cons = finalPopulation.cons;

        validPathsIndexes = find(cons == 0);
        if ~isempty(validPathsIndexes)
            indexOfBestIteration = randsample(validPathsIndexes, 1);
            timestamp = toc(timestampBeforeSearch);

            save(parameter.vesselResultsPath + "resultsWpt-" + string(wptIndex), "finalPopulation", "indexOfBestIteration", "prevWptObjectiveScores", "timestamp");
    
            % Store the selected waypoint and continue from it.
            startWpt = decs(indexOfBestIteration, :);
            prevWptObjectiveScores = [prevWptObjectiveScores; objectivesWithoutPrev(indexOfBestIteration,:)];
            startWptIndex = indexOfBestIteration;
            resultingWaypoints = [resultingWaypoints; startWpt];
        end
    end
    fullSearchTime = toc(initialTimestamp);
    save(append(resultsPath, "/", vesselName, "/", selectionType, "-exNum", string(experimentNumber), "/finalInformation"), "fullSearchTime", "enviromentRandom", "resultingWaypoints");
end
