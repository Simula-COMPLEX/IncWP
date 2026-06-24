function calculateTimeUsageForEachApproach(vesselName, resultsPath, analysisPath)
    % Input:
    %   vesselName: vessel identifier such as "remus100".
    %   resultsPath: root folder containing experiment result folders.
    %   analysisPath: root folder where analysed outputs are saved.
    %
    % Output:
    %   Saves TimeusageResults.mat under analysisPath/<vessel>/AnalysedResults/.
    resultsPath = char(resultsPath);
    analysisPath = char(analysisPath);

    experimentInfoMap = loadExperimentsStatus(vesselName);

    baseResultsPath = append(analysisPath,"/", vesselName, "/AnalysedResults/");
    if ~isfolder(baseResultsPath)
        mkdir(baseResultsPath);
    end

    timeUsageResultsPath =  append(baseResultsPath,"TimeusageResults");
   
    % Build the per-experiment timestamp maps from the saved experiment files.
    selectionTypeTimeStamps = calculateTimeusagePerformance(vesselName, experimentInfoMap, resultsPath);
    save(timeUsageResultsPath, "selectionTypeTimeStamps","experimentInfoMap");

    % Summarise the average total runtime per approach across experiments.
    selectionNames = string(selectionTypeTimeStamps.keys);
    approachtimeusageMatrix = [];
    for selectionName = selectionNames
        if selectionName == "FullWP"
            selectionData = selectionTypeTimeStamps(selectionName);
            experimentsNumbers = selectionData.keys;
            averageTimeUsageMatrix = [];
            for expNum = experimentsNumbers
                experimentTimestamps = selectionData(string(expNum));
                timeUsage = experimentTimestamps(end) - experimentTimestamps(1);
                averageTimeUsageMatrix = [averageTimeUsageMatrix timeUsage];
            end
        else
            selectionData = selectionTypeTimeStamps(selectionName);
            experimentsNumbers = selectionData.keys;
            averageTimeUsageMatrix = [];
            for expNum = experimentsNumbers
                experimentData = selectionData(string(expNum));
                waypointsIdxs = experimentData.keys();
                timeUsage = 0;
                for wptIdx = waypointsIdxs
                    waypointTimestamps = experimentData(string(wptIdx));
                    timeUsage = timeUsage + (waypointTimestamps(end,end) - waypointTimestamps(1,1));
                end
                averageTimeUsageMatrix = [averageTimeUsageMatrix timeUsage];
            end
        end
        approachtimeusageMatrix = [approachtimeusageMatrix string(mean(averageTimeUsageMatrix))];
    end
    approachtimeusageMatrix = [selectionNames; approachtimeusageMatrix];
end
