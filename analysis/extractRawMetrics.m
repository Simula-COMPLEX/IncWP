function extractRawMetrics(vesselName, resultsPath, analysisPath)
% Combine population, class and time rows for the classified experiments.
    baseResultsPath = fullfile(analysisPath,vesselName,'AnalysedResults');
    if ~isfolder(baseResultsPath), mkdir(baseResultsPath); end
    experimentInfoMap = loadExperimentsStatus(vesselName);
    saved = loadAnalysisResults(baseResultsPath,'classification','Variables','selectionTypeClassification','IncludeTimeLimited',false);
    selectionTypeClassification = saved.selectionTypeClassification;
    for approach = string(experimentInfoMap.keys())
        if isKey(selectionTypeClassification,approach)
            classifiedExperiments = selectionTypeClassification(approach);
            experimentInfoMap(approach) = str2double(string(classifiedExperiments.keys()));
        else
            remove(experimentInfoMap,approach);
        end
    end
    settings = loadShipSearchParameters(vesselName);
    populationSize = 10;
    numGenerations = 1000;
    approachSortedInfoMap = containers.Map();
    for approach = string(experimentInfoMap.keys())
        classifiedExperiments = selectionTypeClassification(approach);
        waypointMap = containers.Map();
        for waypoint = 2:settings.numWaypoints+1
            experiments = containers.Map();
            for number = experimentInfoMap(approach)
                population = getPopulation(settings,fullfile(resultsPath,vesselName),[],[],approach,number,waypoint);
                decisions = population.decs; objectives = population.objs; constraints = population.cons;
                timestamps = getWaypointTimestamp(vesselName, approach, number, populationSize, ...
                    numGenerations, settings.numWaypoints+1, waypoint, resultsPath);
                timestamps = timestamps(:);
                classified = classifiedExperiments(string(number));
                classMap = classified('classes');
                classes = string(classMap(string(waypoint))); classes = classes(:);
                assert(size(decisions,1)==numel(timestamps) && size(decisions,1)==numel(classes), ...
                    'Analysis:RowAlignment','Population, classes and timestamps differ for %s experiment %d waypoint %d.',approach,number,waypoint);
                experiments(string(number)) = containers.Map( ...
                    {'classes','decisions','objectives,','constraints','timestamp'}, ...
                    {classes,decisions,objectives,constraints,timestamps});
            end
            waypointMap(string(waypoint)) = experiments;
        end
        approachSortedInfoMap(approach) = waypointMap;
    end
    values = struct('approachSortedInfoMap',approachSortedInfoMap,'experimentInfoMap',experimentInfoMap);
    saveAnalysisResults(baseResultsPath,'candidates',values);
end

function timestamps = getWaypointTimestamp(vesselName, approachName, experimentNumber, populationSize, numGenerations, numInitialWaypoints, wptIndex, resultsPath)
    % Read the timestamp information for one waypoint in one experiment.
    vesselResultsPath = append(resultsPath, "/", vesselName,"/", approachName, "-exNum", string(experimentNumber),"/WptIdx-");
 
    approachInfo = analysisApproachInfo(approachName);
    if approachInfo.isFullWP
        filepath = append(vesselResultsPath,"resultsWpt-",string(numInitialWaypoints));
        load(filepath, "timestamps");
    elseif approachName == "RandomSearch"
        numGenerations = 1;
        load(vesselResultsPath + string(wptIndex) + "-paths" +"-g"+string(numGenerations),"timestamps", "missingPathLabel");
    elseif approachInfo.isKmeans
        if wptIndex == 2
            maxNumberOfSubpathsFromPF = 1;
        else
            maxNumberOfSubpathsFromPF = approachInfo.branches;
        end

        timeStampsList = [];
        lastTimeStamp = 0;
        for subpathsearch = 1:maxNumberOfSubpathsFromPF
            subpathDivision = approachInfo.branches;
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
