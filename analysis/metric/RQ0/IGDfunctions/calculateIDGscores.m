function [IGDresultsMap, referencePointMapIGD, combinedPopulationMapIGD] =calculateIDGscores(vesselName, onServer)
    resultsPathInfo = what("ExperimentsResults");
    resultsPath = char(resultsPathInfo.path);
    vesselResultsPathBase = append(resultsPath, "/", vesselName,"/");
    baseResultsPath = append(vesselResultsPathBase, "AnalysedResults/");

    maxValueCONST = 999999999;
    populationSize = 10;
    numGenerations = 1000;
    vesselInformation = loadShipSearchParameters(vesselName);
    % calculate the reference point
    referencePointMapIGD = containers.Map();
    combinedPopulationMapIGD = containers.Map();
    experimentInfoMap = loadExperimentsStatus(vesselName);


    selectionNames = string(experimentInfoMap.keys());
    numberOfExperiments = length(experimentInfoMap(selectionNames(1)));
    useTimedrestrictedResults = false;

    referencePointFileLocation = append(baseResultsPath,"referencePointInfo.mat");
    reloadExperiments = true;
    if exist(referencePointFileLocation)
   
        load(referencePointFileLocation, "referencePointMap","referencePointMatrix","combinedObjectivesMap", "prevexperimentInfoMap")
        if areTheMapsEqual(prevexperimentInfoMap, experimentInfoMap) %prevexperimentInfoMap == experimentInfoMap
            reloadExperiments = false;
        end
    end
        
    reloadExperiments = true
    if reloadExperiments
        [referencePointMap, referencePointMatrix, combinedObjectivesMap, combinedPopulationsMap] = findObjectiveranges(experimentInfoMap,vesselInformation, populationSize, numGenerations, vesselResultsPathBase, maxValueCONST, useTimedrestrictedResults)
        prevexperimentInfoMap = experimentInfoMap;
        save(referencePointFileLocation, "referencePointMap","referencePointMatrix","combinedObjectivesMap", "prevexperimentInfoMap","combinedPopulationsMap")
    end

    IGDresultsMap = calculateIGD(experimentInfoMap,vesselInformation,populationSize, numGenerations, vesselResultsPathBase,referencePointMap,combinedPopulationsMap,maxValueCONST, useTimedrestrictedResults, reloadExperiments)
    save(IGDresultsPath, "IGDmatrix", "referencePointMap","combinedPopulationMap", "experimentInfoMap");
    
        
    
        
end

function IGDresultsMap = calculateIGD(experimentInfoMap,vesselInformation,populationSize, numGenerations, vesselResultsPathBase,referencePointMap, combinedPopulationsMap,maxValueCONST, useTimedrestrictedResults, reloadExperiments)
    selectionNames = string(experimentInfoMap.keys());
    numberOfExperiments = length(experimentInfoMap(selectionNames(3)));
    
    IGDresultsMap = containers.Map();
    for wptIndex = 2:(vesselInformation.numWaypoints+1)
        combinedPopulationsWpt = combinedPopulationsMap(string(wptIndex));
        IGDmatrix = zeros(length(selectionNames), numberOfExperiments);
    
        for selectionIndex = 1:length(selectionNames)
        
            selectionType = selectionNames(selectionIndex);
            experimentList = experimentInfoMap(selectionType);
            %experimentList = experimentListMatrix(selectionIndex,:);
            
            for experimentIdx = 1:length(experimentList)
                experimentNum = experimentList(experimentIdx);

                IGDPath = append(vesselResultsPathBase, selectionType,"-exNum", string(experimentNum),"/WptIdx-", string(wptIndex), "-IGD.mat"); %, string(wptIndex));

                if ~reloadExperiments && (exist(IGDPath) == 2)
                    load(IGDPath, "experimentIGDscore")
                else

                    objectiveLargestValue = referencePointMap(string(wptIndex));
                    objectiveLargestValue = objectiveLargestValue(1);
                    
                    [population] = getPopulation(vesselInformation, vesselResultsPathBase,populationSize,numGenerations,selectionType,experimentNum,wptIndex, useTimedrestrictedResults);
                    exObjs = population.objs;
                    exDecs = population.decs;
                    exCons = population.cons;
                    % nonMissingPathsFlag =  abs(prevObjectives(:,1)) ~= maxValueCONST; 
                    [missingPathsFlag, nonMissingPathsFlag] = getIndexesOfMissingPaths(exObjs);
                    if sum(nonMissingPathsFlag) > 0
                        exDecs = exDecs(nonMissingPathsFlag,:);
                        exObjs = exObjs(nonMissingPathsFlag,:);
                        exCons = exCons(nonMissingPathsFlag,:);
                        exObjs(:,1) = objectiveLargestValue + exObjs(:,1);
                        %exObjs(:,2) = exObjs(:,1); %/(wptIndex-1);
                        shiftedPopulation = SOLUTION(exDecs, exObjs, exCons);
                 
                        %[populationWithMissingPaths, populationWithoutMissingPaths] = switchSignAndRemoveMissingPathsFromObjectives(maxValueCONST, originalPopulation,objectiveLargestValue);
                        paretoFrontObjs = shiftedPopulation.best.objs;
                        if size(paretoFrontObjs,1) == 0
                            paretoFrontObjs = shiftedPopulation.objs;
                            
                            experimentIGDscore= IGD(shiftedPopulation,combinedPopulationsWpt.best.objs);

                        else
                            experimentIGDscore = IGD(shiftedPopulation,combinedPopulationsWpt.best.objs);

                        end
                    else
                        experimentIGDscore  = -1;
                    end

                    save(IGDPath, "experimentIGDscore")
                end
                IGDmatrix(selectionIndex, experimentIdx) = experimentIGDscore; 
                

                    
           
            end
            IGDresultsMap(string(wptIndex)) = IGDmatrix;


        end
    end

end


function [referencePointMap, referencePointMatrix, combinedObjectivesMap, combinedPopulationsMap] = findObjectiveranges(experimentInfoMap,vesselInformation,populationSize, numGenerations, vesselResultsPathBase,maxValueCONST,useTimedrestrictedResults)
    referencePointMap = containers.Map();
    referencePointMatrix = [];
    combinedObjectivesMap = containers.Map();
    combinedPopulationsMap = containers.Map();

    for wptIndex = 2:(vesselInformation.numWaypoints+1)
        [combinedObjectives, combinedDecs, combinedCons] = CombineWptObjectives(wptIndex);
        combinedObjectivesMap(string(wptIndex)) = combinedObjectives;
        %nonMissingObjectivesFlag = abs(prevObjectives(:,1)) ~= maxValueCONST;
        [missingPathsFlag, nonMissingPathsFlag] = getIndexesOfMissingPaths(combinedObjectives);
        combinedObjectivesWithoutMissing = combinedObjectives(nonMissingPathsFlag,:);
        % switch objective 1 values to be non-zero
        objectiveLargestValue = min(combinedObjectivesWithoutMissing(:,1));
        combinedObjectivesWithoutMissing(:,1) = -(objectiveLargestValue -combinedObjectivesWithoutMissing(:,1));
        decs = combinedDecs(nonMissingPathsFlag,:);
        cons = combinedCons(nonMissingPathsFlag,:);
        combinedPopulation =  SOLUTION(decs, combinedObjectivesWithoutMissing, cons); 
        combinedPopulationsMap(string(wptIndex)) = combinedPopulation;

    
        referencePointMap(string(wptIndex)) = [abs(objectiveLargestValue) min(combinedObjectivesWithoutMissing(:,2))];
        referencePointMatrix = [referencePointMatrix; referencePointMap(string(wptIndex))];
    end

    function [objectives, decisions, constraints] = CombineWptObjectives(wptIndex)
        %clear objectives
        objectives = [];
        decisions = [];
        constraints = [];
        selectionNames = string(experimentInfoMap.keys());
        for selectionTypeIdx = 1:length(selectionNames)
            selectionName = selectionNames(selectionTypeIdx);

            experimentList = experimentInfoMap(selectionName);
            vesselResultsPathApproach = append(vesselResultsPathBase, selectionName,"-exNum"); %, string(wptIndex));
            
            for experimentNumber = experimentList
                [population] = getPopulation(vesselInformation, vesselResultsPathBase,populationSize,numGenerations,selectionName,experimentNumber,wptIndex,useTimedrestrictedResults);
                objs = population.objs;
                objectives = [objectives; objs];
                decisions = [decisions; population.decs];
                constraints = [constraints; population.cons];
                
            end

        end
    end
end
