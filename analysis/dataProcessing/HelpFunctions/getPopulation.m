function population = getPopulation(vesselInformation, vesselResultsPathBase, populationSize, numGenerations, selectionName, experimentNumber, wptIndex)
    % Reconstruct the population data for one waypoint in one experiment.
    %
    % Full-path search loads the stored final population directly.
    % Incremental approaches rebuild one combined population from the
    % saved per-generation population files.
    vesselResultsPathApproach = append(vesselResultsPathBase, selectionName,"-exNum");
    maxValueCONST = 999999999;
    vesselResultsPathExperiment = append(vesselResultsPathApproach, string(experimentNumber), "/",  "WptIdx-resultsWpt-" + string(wptIndex));
    vesselResultsPathPopulation = append(vesselResultsPathApproach, string(experimentNumber), "/",  "WptIdx-" + string(wptIndex), "-population-g");

    if selectionName == "FullWP"
        vesselResultsPathExperiment = append(vesselResultsPathApproach, string(experimentNumber), "/",  "WptIdx-resultsWpt-" + string(wptIndex),"-population");
        load(vesselResultsPathExperiment, "finalPopulation","distancesWpt","subPathDistanceMatrixWpt", "prevObjectives", "missingPathsFlag");
        population = finalPopulation;
    else
        vesselResultsPathApproach = append(vesselResultsPathBase, selectionName,"-exNum", string(experimentNumber),"/WptIdx-", string(wptIndex));

        if selectionName == "IncWP_Kmeans"
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

        objs = [];
        decs = [];
        cons = [];
        
        for gen = 1:numberOfGenerationsPerSubsearch
            populationFileLocation = append(vesselResultsPathApproach, "-population-g", string(gen));
            load(populationFileLocation,"Population", "objectivesWithoutPrevList");
            load(vesselResultsPathPopulation+string(gen),"Population", "objectivesWithoutPrevList");
        
             decs = [decs; Population.decs];
             cons = [cons; Population.cons];

             genObjs = Population.objs;
             [missingPathsFlag, nonMissingPathsFlag] = getIndexesOfMissingPaths(objectivesWithoutPrevList);
             genObjs(missingPathsFlag,1) = -maxValueCONST;
             objs = [objs; genObjs];
        end
        objs(:,2) = objs(:,2)/(wptIndex-1);

        population = SOLUTION(decs,objs,cons);
    end
end