function [finalPopulation, objectivesWithoutPrev] = loadCombinedPopulation(vesselResultsPath,numGenerationsList)
    decsions = [];
    objectives = [];
    constaints = [];
    objectivesWithoutPrev = [];
    
    if isscalar(numGenerationsList)
        numGenerationsList = 1:numGenerationsList;
    %else
    %    numGenerationsList
    end
    
    for gen = numGenerationsList %% TODO might be an error here
        populationFileLocation = append(vesselResultsPath, "-population-g", string(gen));
        load(populationFileLocation,"Population", "objectivesWithoutPrevList");
        decs = Population.decs;
        objs = Population.objs;
        cons = Population.cons;
        decsions = [decsions; decs];
        objectives = [objectives; objs];
        constaints = [constaints; cons];
        objectivesWithoutPrev = [objectivesWithoutPrev; objectivesWithoutPrevList];
    end
    
    
    finalPopulation = SOLUTION(decsions,objectives, constaints);

end


