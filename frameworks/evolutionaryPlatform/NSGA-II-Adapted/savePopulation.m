function obj = savePopulation(obj, Population, parameter)
    %global shipResultsPath
    vesselResultsPath = parameter.vesselResultsPath;
    
   
    paths = obj.pathsMap;
    if obj.searchType == "fullPathSearch"
        pathsFileLocation = append(vesselResultsPath,obj.populationType,"-paths-g", string(obj.generation));
        populationFileLocation = append(vesselResultsPath,obj.populationType, "-population-g", string(obj.generation));

        timestamps = obj.timestampList;
        missingPathLabel = obj.missingPathLabel;
        subPathDistanceMatrix = obj.subPathDistanceMatrix;
        pathMissingFlagsMatrix = obj.pathMissingFlagsMatrix;

        save(pathsFileLocation,"paths", "timestamps", "missingPathLabel", "subPathDistanceMatrix", "pathMissingFlagsMatrix");
        save(populationFileLocation,"Population");
    else
        pathsFileLocation = append(vesselResultsPath,string(parameter.endWptIndex),"-paths-g", string(obj.generation));
        populationFileLocation = append(vesselResultsPath,string(parameter.endWptIndex), "-population-g", string(obj.generation));

        timestamps = obj.timestampList;
        missingPathLabel = obj.missingPathLabel;
        objectivesWithoutPrevList = obj.objectivesWithoutPrevList;

        %enviromentRandom = obj.enviromentRandom;

        %save(pathsFileLocation,"paths");
        save(pathsFileLocation,"timestamps", "missingPathLabel", "paths");
        %save(pathsFileLocation,"timestamps", "missingPathLabel");
        save(populationFileLocation,"Population", "objectivesWithoutPrevList");

    end

    obj.generation = obj.generation + 1;
    obj.pathsMap = containers.Map();
end