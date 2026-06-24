function selectionTypeTimeStamps = calculateTimeusagePerformance(vesselName, experimentInfoMap, resultsPath)
    % Build the timestamp information needed for the time-usage analysis.
    %
    % Output:
    %   selectionTypeTimeStamps: selection type -> experiment -> timestamps.
    %   Full-path search stores one timestamp vector per experiment.
    %   Incremental approaches store one timestamp matrix per waypoint.
    resultsPath = char(resultsPath);
    selectionTypeTimeStamps = containers.Map();
    selectionNames = string(experimentInfoMap.keys());

    vesselInformation = loadShipSearchParameters(vesselName);
    numWaypoints = vesselInformation.numWaypoints+1;


    for selectionType = selectionNames
        experimentTimestampMap = containers.Map();
        if selectionType == "RandomSearch"
            populationSize = 10000; 
            numGenerations = 1;
        elseif selectionType == "FullWP" 
            populationSize = 10; 
            numGenerations = 1000;
        else
            populationSize = 10; 
            numGenerations = 1000;
        end
        experimentList = experimentInfoMap(selectionType);

        for experimentNumber = experimentList
            [~, timeStampMap] = timeUsage(vesselName, selectionType, experimentNumber, populationSize, numGenerations, numWaypoints, resultsPath);
            experimentTimestampMap(string(experimentNumber)) = timeStampMap;
        end
        selectionTypeTimeStamps(selectionType) = experimentTimestampMap;
    end
end

function [timeStampList, timeStampMap] = timeUsage(vesselName, selectionType, experimentNumber, populationSize, numGenerations, numInitialWaypoints, resultsPath)
    % Read the saved timestamp information for one experiment.
    vesselResultsPath = append(resultsPath, "/", vesselName,"/", selectionType, "-exNum", string(experimentNumber),"/WptIdx-");
    timeStampList = [];
    timeStampMap = containers.Map();

    if selectionType == "FullWP"
        filepath = append(vesselResultsPath,"resultsWpt-",string(numInitialWaypoints));
        load(filepath, "timestamps");
        timeStampMap = timestamps;
    else
        for wptIndex  = 2:numInitialWaypoints
            if selectionType == "RandomSearch"
                numGenerations = 1;
                load(vesselResultsPath + string(wptIndex) + "-paths" +"-g"+string(numGenerations),"timestamps", "missingPathLabel");
            elseif selectionType == "IncWP_Kmeans"
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
                    adjustedTimeStamp = timestamps +lastTimeStamp;
                    timeStampsList = [timeStampsList; adjustedTimeStamp];
                    lastTimeStamp = timeStampsList(end);
                end
                timestamps = timeStampsList;
            else
                MaxEvaluation = round((populationSize*numGenerations/(numInitialWaypoints-1))/populationSize)*populationSize;
                numGenerationsTemp = ceil(MaxEvaluation/populationSize);
                load(vesselResultsPath + string(wptIndex) + "-paths" +"-g"+string(numGenerationsTemp),"timestamps", "missingPathLabel");
            end
            timeStampMap(string(wptIndex)) = timestamps;
        end
    end
end
