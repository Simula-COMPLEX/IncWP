function [selectionTypeClassification, distancesIntervall, selectionTypeClassificationWithBrackets, selectionResultsDistributionMap, resultsMatrix, precentageResultsMap] = calculatePathClassification(vesselName, experimentInfoMap, resultsPath)
    % Input:
    %   vesselName: vessel identifier such as "remus100".
    %   experimentInfoMap: containers.Map from selection type to experiment numbers.
    %   resultsPath: root folder containing experiment result folders.
    %
    % Output:
    %   selectionTypeClassification: selection type -> experiment -> classification data.
    %   distancesIntervall: min/max waypoint-distance range across all experiments.
    %   selectionTypeClassificationWithBrackets: classification data split into distance brackets.
    %   selectionResultsDistributionMap, resultsMatrix, precentageResultsMap:
    %       aggregated class counts used later in the analysis.
    resultsPath = char(resultsPath);

    pythonScriptPathInfo = what("analysis");
    pythonScriptPathInfo = char(pythonScriptPathInfo.path);
    if count(py.sys.path, pythonScriptPathInfo) == 0
        insert(py.sys.path, int32(0), pythonScriptPathInfo);
    end
    peak_analysis = py.importlib.import_module('calculate_number_of_peaks');
    py.importlib.reload(peak_analysis);

    vesselInformation = loadShipSearchParameters(vesselName);
    numWaypoints = vesselInformation.numWaypoints+1;

    % These maps are keyed by selection type, then by experiment number,
    % and later by waypoint index inside each experiment entry.
    selectionTypeClassification = containers.Map();
    distancesIntervall = [inf 0].*ones(numWaypoints-1,1);
    selectionNames = string(experimentInfoMap.keys());

    % Classify each experiment and track the global distance range per waypoint.
    for selectionTypeIdx = 1:length(selectionNames)
        selectionType = selectionNames(selectionTypeIdx);

        experimentList = experimentInfoMap(selectionType);
        experimentsClassificationMap = containers.Map();
        populationSize = 10; 
        numGenerations = 1000;

        for experimentNumber = experimentList
            [numPeaksMap, classesMap, distanceMap, ExpDistancesRanges] = calculatePerformancePerSubpath(vesselName, selectionType, experimentNumber, populationSize, numGenerations, numWaypoints, peak_analysis, resultsPath);
            experimentsClassificationMap(string(experimentNumber)) = containers.Map({'numberOfPeaks' 'classes', 'distances'},{numPeaksMap, classesMap, distanceMap});

            for wptIndex = 2:numWaypoints    
                distancesIntervall(wptIndex-1,1) = min([ExpDistancesRanges(wptIndex-1,1); distancesIntervall(wptIndex-1,1)]);
                distancesIntervall(wptIndex-1,2) = max([ExpDistancesRanges(wptIndex-1,2); distancesIntervall(wptIndex-1,2)]);
            end
        end
        selectionTypeClassification(selectionType) = experimentsClassificationMap;    
    end

    numberOfBrackets = 5;
    selectionTypeClassificationWithBrackets = splitIntoBrackes(selectionTypeClassification, distancesIntervall, experimentInfoMap, numWaypoints, numberOfBrackets);
    [selectionResultsDistributionMap, resultsMatrix, precentageResultsMap] = countClassificationPathsWithBrackets(selectionTypeClassification, experimentInfoMap, numWaypoints);
end

function [numPeaksMap, classesMap, distanceMap, distancesRanges] = calculatePerformancePerSubpath(vesselName, selectionType, experimentNumber, populationSize, numGenerations, numInitialWaypoints, peak_analysis, resultsPath)
    % Build per-waypoint classification results for one experiment.
    %
    % numPeaksMap: waypoint index -> per-individual peak counts.
    % classesMap: waypoint index -> "missing" / "unstable" / "stable".
    % distanceMap: waypoint index -> distance from the original waypoint.
    % distancesRanges: min/max distance range per waypoint in this experiment.
    vesselInformation = loadShipSearchParameters(vesselName);
    intialPointsMatrix = [zeros(1,vesselInformation.pointDimension); ...
                          reshape(vesselInformation.initialPoints,[vesselInformation.pointDimension, vesselInformation.numWaypoints])'];

    basepath = append(resultsPath, '/', vesselName,'/', selectionType, "-exNum", string(experimentNumber));
    maxNumberOfSubpathsFromPF = 3;

    distancesRanges = [inf 0].*ones(numInitialWaypoints-1,1);

    numPeaksMap = containers.Map();
    classesMap = containers.Map();
    distanceMap = containers.Map();
    classesCountMatrix = [];
    filepath = append(resultsPath, '/', vesselName,'/', selectionType, "-exNum", string(experimentNumber), "/classificiation.mat");
    if exist(filepath) == 2
        load(filepath,"numPeaksMap","classesMap", "classesCountMatrix","distanceMap", "distancesRanges");

    else
        % Classify each stored subpath from the saved replay/experiment files.
        for subpathIdx = 2:numInitialWaypoints
            if selectionType == "IncWP_Kmeans"
                if subpathIdx == 2
                    numberOfSubpathSearches = 1;
                else
                    numberOfSubpathSearches = 3;
                end
                budgetPerSearch = ceil((populationSize*numGenerations/((vesselInformation.numWaypoints-1)*maxNumberOfSubpathsFromPF+1))/populationSize)*populationSize;
                numberOfIndividuals = ceil(budgetPerSearch*numberOfSubpathSearches/populationSize)*populationSize; 
            else
                numberOfIndividuals = round((populationSize*numGenerations/vesselInformation.numWaypoints)/populationSize)*populationSize;
            end

            numPeaksMatrix = [];
            individualClassList = [];
            distancesFromInitialWaypointsList = [];

            vesselResultsPath = append(resultsPath, "/", vesselName,"/", selectionType, "-exNum", string(experimentNumber),"/WptIdx-");

            if selectionType == "FullWP"
                load(vesselResultsPath + "resultsWpt-" + string(subpathIdx), "finalPopulation","distancesWpt","subPathDistanceMatrixWpt","individualClassMatrixWpt","numPeaksMatrixWpt", "timestamps");
            elseif selectionType == "IncWP_Kmeans"
                load(vesselResultsPath + "resultsWpt-" + string(subpathIdx),"mappingOfIndexes", "paretoFrontPopulations", "indexesParetoFront", "prevObjectivesMap", "timestamp");
                finalPopulation = paretoFrontPopulations;
            else
                load(vesselResultsPath + "resultsWpt-" + string(subpathIdx), "finalPopulation", "indexOfBestIteration", "prevWptObjectiveScores", "timestamp");
            end
        
            decs = finalPopulation.decs;
            if selectionType == "FullWP"
                % Full-path search already stores class and distance data in
                % the resultsWpt file, so no per-individual iter-file scan is needed.
                numPeaksMatrix = [numPeaksMatrix; numPeaksMatrixWpt'];
                individualClassList = [individualClassList; individualClassMatrixWpt];
                distancesFromInitialWaypointsList = [distancesFromInitialWaypointsList; distancesWpt];
        
            else
                intialPoint = intialPointsMatrix(subpathIdx,:);

                % Standard incremental approaches classify each individual from
                % its saved iter file by counting oscillation peaks in the angles.
                for individualIndex = 1:numberOfIndividuals
        
                    iterationPath = append(basepath, "/WptIdx-", string(subpathIdx),"-iter",string(individualIndex));
                    load(iterationPath, "angles", "reachedWaypoint");
                    
                    numAngles = size(angles,2);
                    individualNumAngles = [];
                    if reachedWaypoint == true
                        
                        for angIdx = 1:numAngles
                            individualNumAngles = [individualNumAngles; calculateNumberOfPeaks(angles(:,angIdx), true, peak_analysis)];
                        end
        
                        if all(individualNumAngles == 0)
                            individualClass = "stable";
                        else
                            individualClass = "unstable";
                        end
                    else 
                        individualNumAngles = -1*ones(numAngles,1);
                        individualClass = "missing";
        
                    end
                    numPeaksMatrix = [numPeaksMatrix; individualNumAngles'];
                    individualClassList = [individualClassList; individualClass];

                    distanceFromInitialWpt  = pdist2(intialPoint,decs(individualIndex,:),'euclidean');
                    distancesFromInitialWaypointsList = [distancesFromInitialWaypointsList; distanceFromInitialWpt];
                end
            end

            distancesRanges(subpathIdx-1,1)  = min([min(distancesFromInitialWaypointsList); distancesRanges(subpathIdx-1,1)]);
            distancesRanges(subpathIdx-1,2)  = max([max(distancesFromInitialWaypointsList); distancesRanges(subpathIdx-1,2)]);

            numPeaksMap(string(subpathIdx)) = numPeaksMatrix;
            classesMap(string(subpathIdx)) = individualClassList;
            distanceMap(string(subpathIdx)) = distancesFromInitialWaypointsList;
            classesCountList = [sum(individualClassList == "missing") sum(individualClassList == "unstable") sum(individualClassList == "stable")];
            classesCountMatrix = [classesCountMatrix; classesCountList];
        end

        filepath = append(resultsPath, '/', vesselName,'/', selectionType, "-exNum", string(experimentNumber), "/classificiation.mat");
        if ~isfolder(fileparts(char(filepath)))
            mkdir(fileparts(char(filepath)));
        end
        save(filepath, "numPeaksMap","classesMap", "classesCountMatrix", "distanceMap", "distancesRanges");
    end
end



function selectionTypeClassification = splitIntoBrackes(selectionTypeClassification, distancesIntervall, experimentInfoMap, numInitialWaypoints, numbrackets)
    % Add a bracketed view of the classifications, where each waypoint's
    % individuals are grouped by distance from the original waypoint.
    bracketeRange = (distancesIntervall(:,2)-distancesIntervall(:,1))/numbrackets;
    selectionNames = string(experimentInfoMap.keys());
    tolerance = 1e-5;
 
    % Split each waypoint's distances into brackets for later aggregation.
    for selectionType = selectionNames
        experimentsClassificationMap = selectionTypeClassification(selectionType);
        experimentList = experimentInfoMap(selectionType);

        for experimentNumber = experimentList
            experimentsClassification = experimentsClassificationMap(string(experimentNumber));
            numPeaksMap = experimentsClassification('numberOfPeaks');
            classesMap = experimentsClassification('classes');
            distanceMap = experimentsClassification('distances');
            
            bracketClassMapWP = containers.Map();
            for wptIndex = 2:numInitialWaypoints
                bracketClassMap = containers.Map();
                classes = classesMap(string(wptIndex));
                distancesFromInitialWaypoints = distanceMap(string(wptIndex));
                distanceclassification = [distancesFromInitialWaypoints classes];
                startDistance = distancesIntervall(wptIndex-1,1);
                countedindividuals = [];
                individualsCounted = 0;

                for bracketsIdx = 1:numbrackets
                    endDistance = startDistance + bracketeRange(wptIndex-1);
                    bracketClassMap(string(bracketsIdx)) = distanceclassification((distancesFromInitialWaypoints <= (endDistance + tolerance)) & (distancesFromInitialWaypoints >= (startDistance - tolerance)),:);
                    startDistance = endDistance;
                    individualsCounted = individualsCounted + size(bracketClassMap(string(bracketsIdx)),1);
                    countedindividuals = [countedindividuals; bracketClassMap(string(bracketsIdx))];
                end

                if individualsCounted < length(distancesFromInitialWaypoints)
                    [elementsInAbutNotInB,ia] = setdiff(distanceclassification(:,1), countedindividuals(:,1));
                    missingElements = distancesFromInitialWaypoints(ia,1);
                    if any(missingElements < distancesIntervall(wptIndex-1,1)) || missingElements  > distancesIntervall(wptIndex-1,2)
                        distancesIntervall(wptIndex-1,1);
                    end
                    size(elementsInAbutNotInB);
                end

                bracketClassMapWP(string(wptIndex)) = bracketClassMap;
            end

            experimentsClassificationMap(string(experimentNumber)) = containers.Map({'numberOfPeaks' 'classes', 'distances', 'bracketClassMap'},{numPeaksMap, classesMap, distanceMap, bracketClassMapWP});
        end
        selectionTypeClassification(selectionType) = experimentsClassificationMap;
    end
end
