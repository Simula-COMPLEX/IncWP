function calculatePathForEachApproach(vesselName, resultsPath, analysisPath)
    resultsPath = char(resultsPath);
    analysisPath = char(analysisPath);

    experimentInfoMap = loadExperimentsStatus(vesselName);

    baseResultsPath = append(analysisPath,"/", vesselName, "/AnalysedResults/");
    if ~isfolder(baseResultsPath)
        mkdir(baseResultsPath);
    end

    % Classify paths
    display("Currently classifying paths")
    ClassresultsPath = append(baseResultsPath,"ClassificationResults");
    [selectionTypeClassification, distancesRanges, selectionTypeClassificationWithBrackets, selectionResultsDistributionMap, resultsMatrix, precentageResultsMap] = calculatePathClassification(vesselName, experimentInfoMap, resultsPath);
    save(ClassresultsPath, "distancesRanges", "selectionTypeClassification", "selectionTypeClassificationWithBrackets", "experimentInfoMap", "selectionResultsDistributionMap", "resultsMatrix", "precentageResultsMap");

end
