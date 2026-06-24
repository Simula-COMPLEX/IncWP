function compareHVresultsForEachApproach(vesselName, onServer)

    experimentInfoMap = loadExperimentsStatus(vesselName);

    vesselInformation = loadShipSearchParameters(vesselName);

    resultsPathInfo = what("ExperimentsResults");
    resultsPath = char(resultsPathInfo.path);
    baseResultsPath = append(resultsPath,"/", vesselName, "/AnalysedResults/");

    display("Currently calculating hypervolume and comperisation of HV")
    HVresultsPath = append(baseResultsPath,"HVresults");
    %recalculateHV = true;
    useTimedrestrictedResults = true;
    [HVresultsMap, referencePointMap, combinedPopulation] = HypervolumeScores(vesselName,experimentInfoMap, useTimedrestrictedResults);

    %[HVresultsMap, referencePointMap, combinedPopulation] = calculateHypervolumeScores(vesselName, experimentInfoMap);
    comperisationResults = compareHVresults(vesselName, HVresultsMap, experimentInfoMap);
    save(HVresultsPath, "HVresultsMap", "referencePointMap","combinedPopulation", "comperisationResults", "experimentInfoMap");
    plotHVresults(vesselName)

    
end
