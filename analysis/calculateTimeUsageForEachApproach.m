function calculateTimeUsageForEachApproach(vesselName, resultsPath, analysisPath)
    % Input:
    %   vesselName: vessel identifier such as "remus100".
    %   resultsPath: root folder containing experiment result folders.
    %   analysisPath: root folder where analysed outputs are saved.
    %
    % Output:
    %   Saves timing results under analysisPath/<vessel>/AnalysedResults/results/timing/.
    resultsPath = char(resultsPath);
    analysisPath = char(analysisPath);

    baseResultsPath = append(analysisPath,"/", vesselName, "/AnalysedResults/");
    if ~isfolder(baseResultsPath)
        mkdir(baseResultsPath);
    end

    classified = loadAnalysisResults(baseResultsPath,'classification', ...
        'Variables','experimentInfoMap','IncludeTimeLimited',false);
    experimentInfoMap = classified.experimentInfoMap;

    selectionTypeTimeStamps = calculateTimeusagePerformance(vesselName,experimentInfoMap,resultsPath);
    values = struct('selectionTypeTimeStamps',selectionTypeTimeStamps,'experimentInfoMap',experimentInfoMap);
    saveAnalysisResults(baseResultsPath,'timing',values);

    % Summarise the average total runtime per approach across experiments.
    selectionNames = string(selectionTypeTimeStamps.keys);
    approachtimeusageMatrix = [];
    for selectionName = selectionNames
        approachInfo = analysisApproachInfo(selectionName);
        if approachInfo.isFullWP
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
