function calculatePathForEachApproach(vesselName, resultsPath, analysisPath, usedSave)
    if nargin < 4
        usedSave = true;
    end
    resultsPath = char(resultsPath);
    analysisPath = char(analysisPath);

    experimentInfoMap = loadExperimentsStatus(vesselName);
    for approach = string(experimentInfoMap.keys())
        if endsWith(approach,"_TimeCutoff")
            remove(experimentInfoMap,approach);
        end
    end

    baseResultsPath = append(analysisPath,"/", vesselName, "/AnalysedResults/");
    if ~isfolder(baseResultsPath)
        mkdir(baseResultsPath);
    end

    if usedSave && analysisResultStatus(baseResultsPath,'classification')
        fprintf('Using saved classification results.\n');
        return;
    end

    % Classify paths
    display("Currently classifying paths")
    selectionTypeClassification = calculatePathClassification(vesselName, experimentInfoMap, resultsPath, usedSave);
    values = struct('selectionTypeClassification',selectionTypeClassification, ...
        'experimentInfoMap',experimentInfoMap);
    saveAnalysisResults(baseResultsPath,'classification',values);
end
