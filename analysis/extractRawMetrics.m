function extractRawMetrics(vesselName, resultsPath, analysisPath)
    % Input:
    %   vesselName: vessel identifier such as "remus100".
    %   resultsPath: root folder containing experiment result folders.
    %   analysisPath: root folder where analysed outputs are saved.
    %
    % Output:
    %   Saves combinedResults.mat under analysisPath/<vessel>/AnalysedResults/.
    resultsPath = char(resultsPath);
    analysisPath = char(analysisPath);
    baseResultsPath = append(analysisPath,"/", vesselName, "/AnalysedResults/");
    if ~isfolder(baseResultsPath)
        mkdir(baseResultsPath);
    end

    experimentInfoMap = loadExperimentsStatus(vesselName);

    ClassresultsPath = append(baseResultsPath,"ClassificationResults");
    load(ClassresultsPath, "selectionTypeClassification");

    [approachDataMap, experimentInfoMap, waypointRangesMap, combinedsolutionsMap, approachSortedInfoMap] = extractForSpecificApproaches(vesselName, experimentInfoMap, selectionTypeClassification, resultsPath);
    filelocation = append(baseResultsPath, "/combinedResults.mat");
    save(filelocation,"approachDataMap", "experimentInfoMap", "waypointRangesMap", "combinedsolutionsMap", "approachSortedInfoMap");
end

function [approachDataMap, experimentInfoMap, waypointRangesMap, combinedsolutionsMap, approachSortedInfoMap] = extractForSpecificApproaches(vesselName, experimentInfoMap, selectionTypeClassification, resultsPath)
    % Combine the raw population, timestamp, and classification data into
    % per-approach and per-waypoint maps used by the later metric scripts.
    vesselResultsPathBase = append(resultsPath, "/", vesselName,"/");
    vesselInformation = loadShipSearchParameters(vesselName);
    numInitialWaypoints = vesselInformation.numWaypoints+1;
    numGenerations = 1000;
    populationSize = 10;

    approachDataMap = containers.Map();
    waypointRangesMap = containers.Map();
    combinedsolutionsMap = containers.Map();
    approachIndex = ismember(experimentInfoMap.keys(), selectionTypeClassification.keys());
    approachesList = experimentInfoMap.keys();
    approachesList = approachesList(approachIndex);
    approachSortedInfoMap = containers.Map(); 

    for approachKey = approachesList
        approachName = approachKey{:};
        experimentsClassification = selectionTypeClassification(approachName);
        experimentsnumList = experimentsClassification.keys();
        experimentsnumList = cellfun(@str2double, experimentsnumList);

        waypointDataMap = containers.Map();
        waypointRanges = [];
        waypointSortedInfoMap = containers.Map();

        for wptIndex = 2:(vesselInformation.numWaypoints+1)
            if any(ismember(string(wptIndex), waypointRangesMap.keys()))
                waypointRanges = waypointRangesMap(string(wptIndex));
            else
                waypointRanges = [];
            end

            if any(ismember(string(wptIndex), combinedsolutionsMap.keys()))
                waypointSolutionMap = combinedsolutionsMap(string(wptIndex));
                allObjs = waypointSolutionMap("objs");
                allCons = waypointSolutionMap("cons");
                allDecs =  waypointSolutionMap("decs");
                allMissingFlag = waypointSolutionMap("missingFlag");
            else
                allObjs = [];
                allCons = [];
                allDecs = [];
                allMissingFlag = [];
            end
            
            

            objectives = [];
            contraints = [];
            decisions = [];
            timestampsList = [];
                classesList = [];
                approachTimeExperiments = [];
                experimentSortedInfoMap = containers.Map();
            for experimentNum = experimentsnumList

                population = getPopulation(vesselInformation, vesselResultsPathBase, populationSize, numGenerations, approachName, experimentNum, wptIndex);
                objs = population.objs;
                decs = population.decs;
                cons = population.cons;
                objectives = [objectives; objs];
                contraints = [contraints; cons];
                decisions = [decisions; decs];

                timestamps = getWaypointTimestamp(vesselName, approachName, experimentNum, populationSize, numGenerations, numInitialWaypoints, wptIndex, resultsPath);
                timestampsList = [timestampsList; timestamps(:)];
                approachTimeExperiments = [approachTimeExperiments timestamps(:)];

                classesExperiment = experimentsClassification(string(experimentNum));
                classesExperiment = classesExperiment("classes");
                classeswaypoint = classesExperiment(string(wptIndex));
                classesList = [classesList; classeswaypoint];
                experimentSortedInfoMap(string(experimentNum)) = containers.Map({'classes', 'decisions','objectives,' 'timestamp'}, ... 
                    {classeswaypoint, decs, objs, timestamps(:)});
            end
            waypointSortedInfoMap(string(wptIndex)) = experimentSortedInfoMap;

            [missingPathsFlag, nonMissingPathsFlag] = getIndexesOfMissingPaths(objectives);
            validObjectives = objectives(nonMissingPathsFlag,:);

            maxObjectives = max(validObjectives);
            minObjectives = min(validObjectives);
            if isempty(waypointRanges)
                waypointRanges = [maxObjectives minObjectives max(objectives(:,2)) min(objectives(:,2))];
            else
                waypointRanges(1) = max(waypointRanges(1), maxObjectives(1));
                waypointRanges(2) = max(waypointRanges(2), maxObjectives(2));
                waypointRanges(3) = min(waypointRanges(3), minObjectives(1));
                waypointRanges(4) = min(waypointRanges(4), minObjectives(2));
                waypointRanges(5) = max(waypointRanges(5), max(objectives(:,2)));
                waypointRanges(6) = min(waypointRanges(6), min(objectives(:,2)));
            end 

            allObjs = [allObjs; objectives;];
            allCons = [allCons; contraints];
            allDecs = [allDecs; decisions];
            allMissingFlag = [allMissingFlag; missingPathsFlag];
            
            waypointDataMap(string(wptIndex)) = containers.Map({'objectives', 'contraints', 'decisions', 'timestamp', 'missingPathsFlag', 'classes','approachTimeExperiments', 'experimentsnumList'}, ... 
                {objectives, contraints, decisions, timestampsList, missingPathsFlag, classesList, approachTimeExperiments, experimentsnumList});

            combinedsolutionsMap(string(wptIndex)) = containers.Map({'objs', 'cons', 'decs', 'missingFlag'}, ... 
                {allObjs, allCons, allDecs, allMissingFlag});

            waypointRangesMap(string(wptIndex)) = waypointRanges;
        end
        approachDataMap(approachName) = waypointDataMap;
        approachSortedInfoMap(approachName) = waypointSortedInfoMap;
    end
end

function timestamps = getWaypointTimestamp(vesselName, approachName, experimentNumber, populationSize, numGenerations, numInitialWaypoints, wptIndex, resultsPath)
    % Read the timestamp information for one waypoint in one experiment.
    vesselResultsPath = append(resultsPath, "/", vesselName,"/", approachName, "-exNum", string(experimentNumber),"/WptIdx-");
 
    if approachName == "FullWP"
        filepath = append(vesselResultsPath,"resultsWpt-",string(numInitialWaypoints));
        load(filepath, "timestamps");
    elseif approachName == "RandomSearch"
        numGenerations = 1;
        load(vesselResultsPath + string(wptIndex) + "-paths" +"-g"+string(numGenerations),"timestamps", "missingPathLabel");
    elseif approachName == "IncWP_Kmeans"
        if wptIndex == 2
            maxNumberOfSubpathsFromPF = 1;
        else
            maxNumberOfSubpathsFromPF = 3;
        end

        timeStampsList = [];
        lastTimeStamp = 0;
        for subpathsearch = 1:maxNumberOfSubpathsFromPF
            subpathDivision = 3;
            budgetPerSearch = ceil((populationSize*numGenerations/((numInitialWaypoints-2)*subpathDivision+1))/populationSize)*populationSize;
            numGenerationsTemp = ceil(budgetPerSearch*subpathsearch/populationSize);

            load(vesselResultsPath + string(wptIndex) + "-paths" +"-g"+string(numGenerationsTemp),"timestamps", "missingPathLabel");
            adjustedTimeStamp = timestamps + lastTimeStamp;
            timeStampsList = [timeStampsList adjustedTimeStamp];
            lastTimeStamp = timeStampsList(end);
        end
        timestamps = timeStampsList;
    else 
        MaxEvaluation = round((populationSize*numGenerations/(numInitialWaypoints-1))/populationSize)*populationSize;
        numGenerationsTemp = ceil(MaxEvaluation/populationSize);
        load(vesselResultsPath + string(wptIndex) + "-paths" +"-g"+string(numGenerationsTemp),"timestamps", "missingPathLabel");
    end
end
