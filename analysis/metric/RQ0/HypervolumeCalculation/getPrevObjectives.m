function objectives = getPrevObjectives(vesselInformation, vesselResultsPathBase,populationSize, numGenerations, selectionName, experimentNumber, wptIndex)
    objectives = [];
    %vesselResultsPath = append(vesselResultsPathBase, string(wptIndex));
    vesselResultsPathApproach = append(vesselResultsPathBase, selectionName,"-exNum", string(experimentNumber),"/WptIdx-", string(wptIndex)); %, string(wptIndex));

   
    if selectionName == 'IncWP_Kmeans'
        if wptIndex == 2
            numberOfSubpathSearches = 1;
        else
            numberOfSubpathSearches = 3;
        end
        maxNumberOfSubpathsFromPF = 3;

        budgetPerSearch = ceil((populationSize*numGenerations/((vesselInformation.numWaypoints-1)*maxNumberOfSubpathsFromPF+1))/populationSize)*populationSize;

        numberOfGenerationsPerSubsearch = ceil(budgetPerSearch*numberOfSubpathSearches/populationSize);

    elseif selectionName == "RandomSearch"
        MaxEvaluation = round((populationSize*numGenerations/vesselInformation.numWaypoints)/populationSize)*populationSize; %NB 0.1
        populationSize = MaxEvaluation;
        numberOfGenerationsPerSubsearch = 1;
    else
        MaxEvaluation = ceil(populationSize*numGenerations/(vesselInformation.numWaypoints*populationSize))*populationSize;
        numberOfGenerationsPerSubsearch = ceil(MaxEvaluation/populationSize);
        
    end
    
    for gen = 1:numberOfGenerationsPerSubsearch
        populationFileLocation = append(vesselResultsPathApproach, "-population-g", string(gen));
        load(populationFileLocation,"Population", "objectivesWithoutPrevList");
        objectives = [objectives; Population.objs];

    end
end