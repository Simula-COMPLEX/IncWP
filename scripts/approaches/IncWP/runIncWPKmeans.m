function [resultingWaypoints, fullSearchTime] = runIncWPKmeans(vesselName, resultsPath, experimentNumber, numGenerationsOriginal, populationSize)
    % Run the incremental multi-start variant that clusters Pareto solutions.
    initialTimestamp = tic;
    algorithm = @WPgen;

    resultsSelectionType = "IncWP_Kmeans";
    selectionType = "kMeans";
    vesselResultsPathBase = append(resultsPath, "/", vesselName, "/", resultsSelectionType, "-exNum", string(experimentNumber), "/WptIdx-");

    problem = @incrementalWaypointProblem;

    % Load vessel-specific waypoint and simulation settings.
    parameter.vesselInformation = loadShipSearchParameters(vesselName);
    initialPointsMatrix = [zeros(1, parameter.vesselInformation.pointDimension); ...
                           reshape(parameter.vesselInformation.initialPoints, [parameter.vesselInformation.pointDimension, parameter.vesselInformation.numWaypoints])'];

    maxNumberOfSubpathsFromPF = 3;
    budgetPerSearch = ceil((populationSize * numGenerationsOriginal / ((parameter.vesselInformation.numWaypoints - 1) * maxNumberOfSubpathsFromPF + 1)) / populationSize) * populationSize;
    numberOfSamples = parameter.vesselInformation.numberOfSamples;
    numberOfRandomEnviromentVariables = parameter.vesselInformation.numberOfRandomEnviromentVariables;
    enviromentRandom = randn([numberOfRandomEnviromentVariables, numberOfSamples + 1]);
    parameter.enviromentRandom = enviromentRandom;
    parameter.iterationIndex = 0;

    % Start from the initial vessel position and carry forward multiple candidates.
    startWpt = initialPointsMatrix(1, :);
    resultingWaypoints = startWpt;
    indexesParetoFront = 1;
    decsions = initialPointsMatrix(1, :);
    prevObjectivesMap = containers.Map();
    prevObjectivesMap('1') = 0;
    prevObjectivesMap('2') = 0;

    for wptIndex = 2:parameter.vesselInformation.numWaypoints + 1
        timestampBeforeSearch = tic;
        endWpt = initialPointsMatrix(wptIndex, :);

        % Reset per-waypoint bookkeeping and rerun the search from each selected parent.
        parameter.iterationIndex = 0;
        parameter.generation = 1;
        MaxEvaluationPF = budgetPerSearch;
        numGenerations = ceil(budgetPerSearch * length(indexesParetoFront) / populationSize);
        numGenerationsPerSearch = ceil(numGenerations / length(indexesParetoFront));

        paretoFrontPopulations = [];
        currentObjectivesMap = containers.Map();
        currentObjectivesMap('1') = [];
        currentObjectivesMap('2') = [];

        prevWptObjectiveObj1 = prevObjectivesMap('1');
        prevWptObjectiveObj2 = prevObjectivesMap('2');
        mappingOfIndexes = [1:(budgetPerSearch * length(indexesParetoFront)); ...
                            repelem(1:numGenerations, 1, populationSize); ...
                            repelem(indexesParetoFront', 1, budgetPerSearch)]';

        % Each selected Pareto solution becomes the start point of a new sub-search.
        for paretoFrontIndex = indexesParetoFront'
            startWpt = decsions(paretoFrontIndex, :);
            prevWptObjectiveScores = [prevWptObjectiveObj1(paretoFrontIndex, :), prevWptObjectiveObj2(paretoFrontIndex, :)];
            startWptIndex = paretoFrontIndex;

            parameter.startWpt = startWpt;
            parameter.startWptIndex = startWptIndex;
            parameter.endWpt = endWpt;
            parameter.endWptIndex = wptIndex;
            parameter.prevWptObjectiveScores = prevWptObjectiveScores;
            parameter.vesselResultsPath = vesselResultsPathBase;

            platemo('algorithm', algorithm, 'problem', problem, 'N', populationSize, 'maxFE', MaxEvaluationPF, 'save', 0, 'run', 1, 'parameter', parameter);

            [finalPopulation, objectivesWithoutPrev] = loadCombinedPopulation(append(parameter.vesselResultsPath, string(wptIndex)), ...
                                                       parameter.generation:(parameter.generation + numGenerationsPerSearch - 1));

            if isempty(paretoFrontPopulations)
                paretoFrontPopulations = finalPopulation;
            else
                objs = [paretoFrontPopulations.objs; finalPopulation.objs];
                decs = [paretoFrontPopulations.decs; finalPopulation.decs];
                cons = [paretoFrontPopulations.cons; finalPopulation.cons];
                paretoFrontPopulations = SOLUTION(decs, objs, cons);
            end

            currentObjectives = objectivesWithoutPrev;
            currentObjectivesMap('1') = [currentObjectivesMap('1'); ...
                                         (prevWptObjectiveScores(:,1) .* ones(1, size(finalPopulation, 2)))' currentObjectives(:,1)];
            currentObjectivesMap('2') = [currentObjectivesMap('2'); ...
                                         (prevWptObjectiveScores(:,2) .* ones(1, size(finalPopulation, 2)))' currentObjectives(:,2)];

            parameter.iterationIndex = parameter.iterationIndex + size(finalPopulation, 2);
            parameter.generation = parameter.generation + numGenerationsPerSearch;
        end

        prevObjectivesMap('1') = currentObjectivesMap('1');
        prevObjectivesMap('2') = currentObjectivesMap('2');

        % Cluster the combined Pareto front and keep one representative from each cluster.
        paretoFront = paretoFrontPopulations.best;
        paretoFrontObjs = paretoFront.objs;
        if size(paretoFrontObjs, 1) < maxNumberOfSubpathsFromPF
            numberOfMissingObjectives = maxNumberOfSubpathsFromPF - size(paretoFrontObjs, 1);
            tempObjectives = paretoFrontPopulations.objs;
            for i = 1:numberOfMissingObjectives
                randomIndex = randi(size(paretoFrontPopulations, 2));
                randomObjes = tempObjectives(randomIndex, :);
                if isempty(paretoFrontObjs)
                    paretoFrontObjs = randomObjes;
                else
                    while any(ismember(paretoFrontObjs, randomObjes, 'rows'))
                        randomIndex = randi(size(paretoFrontPopulations, 2));
                        randomObjes = tempObjectives(randomIndex, :);
                    end
                    paretoFrontObjs = [paretoFrontObjs; randomObjes];
                end
            end
        end

        [~, selectedObjs] = kmeans(paretoFrontObjs, maxNumberOfSubpathsFromPF);
        indexesParetoFront = zeros(maxNumberOfSubpathsFromPF, 1);
        for i = 1:maxNumberOfSubpathsFromPF
            distances = sqrt(sum((paretoFrontObjs - selectedObjs(i, :)).^2, 2));
            [~, minIndex] = min(distances);
            indexesParetoFront(i) = minIndex;
        end

        selectedObjs = paretoFrontObjs(indexesParetoFront, :);
        isMember = zeros(size(paretoFrontPopulations.objs, 1), 1);
        for selectedObjIdx = 1:size(selectedObjs, 1)
            selectedObj = selectedObjs(selectedObjIdx, :);
            foundMember = ismember(paretoFrontPopulations.objs, selectedObj, 'rows');
            if sum(foundMember) > 1
                firstOneIndex = find(foundMember == 1, 1);
                foundMember = zeros(size(foundMember));
                foundMember(firstOneIndex) = 1;
            end
            isMember = isMember | foundMember;
        end
        indexesParetoFrontFull = find(isMember);

        decsions = paretoFrontPopulations.decs;
        if isempty(indexesParetoFrontFull) || length(indexesParetoFrontFull) > maxNumberOfSubpathsFromPF
            indexesParetoFrontFull = randsample(size(decsions, 1), 1);
        end
        indexesParetoFront = indexesParetoFrontFull;

        timestamp = toc(timestampBeforeSearch);
        save(parameter.vesselResultsPath + "resultsWpt-" + string(wptIndex), "mappingOfIndexes", "paretoFrontPopulations", "indexesParetoFront", "prevObjectivesMap", "timestamp");
    end

    fullSearchTime = toc(initialTimestamp);
    save(append(resultsPath, "/", vesselName, "/", resultsSelectionType, "-exNum", string(experimentNumber), "/finalInformation"), "fullSearchTime", "enviromentRandom");
end
