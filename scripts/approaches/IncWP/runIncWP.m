function [resultingWaypoints, fullSearchTime] = runIncWP(vesselName, selectionType, resultsPath, experimentNumber, numGenerations, populationSize)
    % Run one incremental waypoint search with a single selection rule.
    initialTimestamp = tic;
    algorithm = @WPgen;
    vesselResultsPathBase = append(resultsPath, "/", vesselName, "/", selectionType, "-exNum", string(experimentNumber), "/WptIdx-");

    problem = @incrementalWaypointProblem;

    % Load vessel-specific waypoint and simulation settings.
    parameter.vesselInformation = loadShipSearchParameters(vesselName);
    initialPointsMatrix = [zeros(1, parameter.vesselInformation.pointDimension); ...
                           reshape(parameter.vesselInformation.initialPoints, [parameter.vesselInformation.pointDimension, parameter.vesselInformation.numWaypoints])'];

    % Split the full budget across waypoint-to-waypoint searches.
    MaxEvaluation = ceil(populationSize * numGenerations / (parameter.vesselInformation.numWaypoints * populationSize)) * populationSize;
    numberOfGenerationsInSearch = ceil(MaxEvaluation / populationSize);

    numberOfSamples = parameter.vesselInformation.numberOfSamples;
    numberOfRandomEnviromentVariables = parameter.vesselInformation.numberOfRandomEnviromentVariables;
    enviromentRandom = randn([numberOfRandomEnviromentVariables, numberOfSamples + 1]);
    parameter.enviromentRandom = enviromentRandom;
    parameter.iterationIndex = 0;
    parameter.generation = 1;

    % Start from the initial vessel position and advance one waypoint at a time.
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
        
        % Run the search for the current waypoint transition.
        platemo('algorithm', algorithm, 'problem', problem, 'N', populationSize, 'maxFE', MaxEvaluation, 'save', 0, 'run', 1, 'parameter', parameter);
        
        % Load the saved population and select the next waypoint.
        [finalPopulation, objectivesWithoutPrev] = loadCombinedPopulation(append(parameter.vesselResultsPath, string(wptIndex)), numberOfGenerationsInSearch);

        objectives = finalPopulation.objs;
        paretoFront = finalPopulation.best;
        decs = finalPopulation.decs;
        if ~isempty(paretoFront.decs)
            [isMember, ~] = ismember(finalPopulation.decs, paretoFront.decs, 'rows');
            indexesParetoFront = find(isMember);
            bestObjectives = paretoFront.objs;
        else
            bestObjectives = finalPopulation.objs;
            indexesParetoFront = 1:size(bestObjectives,1);
        end

        if isscalar(indexesParetoFront)
            indexOfBestIteration = indexesParetoFront;
        elseif size(bestObjectives,1) == 1
            indexOfBestIteration = indexesParetoFront(1);
        else
            if selectionType == "IncWP_KP"
                [~, indexOfBestIteration] = knee_pt(bestObjectives(:,1), bestObjectives(:,2), true);
                if isnan(indexOfBestIteration)
                    indexOfBestIteration = randsample(1:size(bestObjectives,1), 1);
                end
                PFObjective = bestObjectives(indexOfBestIteration, :);
                indexOfBestIteration = find(ismember(objectives, PFObjective, 'rows'));
            elseif selectionType == "IncWP_Rnd"
                indexOfBestIteration = randsample(indexesParetoFront, 1);
            elseif selectionType == "IncWP_Unst"
                [~, indexOfBestIteration] = min(bestObjectives(:,1));
                PFObjective = bestObjectives(indexOfBestIteration, :);
                indexOfBestIteration = find(ismember(objectives, PFObjective, 'rows'));
            elseif selectionType == "IncWP_Prox"
                [~, indexOfBestIteration] = min(bestObjectives(:,2));
                PFObjective = bestObjectives(indexOfBestIteration, :);
                indexOfBestIteration = find(ismember(objectives, PFObjective, 'rows'));
            else
                error("Unknown incremental selectionType: %s", selectionType);
            end
            if size(indexOfBestIteration, 1) > 1
                indexOfBestIteration = indexOfBestIteration(1);
            end
        end

        timestamp = toc(timestampBeforeSearch);
        save(parameter.vesselResultsPath + "resultsWpt-" + string(wptIndex), "finalPopulation", "indexOfBestIteration", "prevWptObjectiveScores", "timestamp");

        % Store the selected waypoint and continue from it.
        startWpt = decs(indexOfBestIteration, :);
        prevWptObjectiveScores = [prevWptObjectiveScores; objectivesWithoutPrev(indexOfBestIteration, :)];
        startWptIndex = indexOfBestIteration;
        resultingWaypoints = [resultingWaypoints; startWpt];
    end
    fullSearchTime = toc(initialTimestamp);
    save(append(resultsPath, "/", vesselName, "/", selectionType, "-exNum", string(experimentNumber), "/finalInformation"), "fullSearchTime", "enviromentRandom", "resultingWaypoints");
end
