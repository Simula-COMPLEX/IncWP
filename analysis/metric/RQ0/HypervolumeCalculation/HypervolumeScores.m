function [HVresultsMap, referencePointMap, combinedPopulation] = HypervolumeScores(vesselName,experimentInfoMap, useTimedrestrictedResults)
    resultsPathInfo = what("ExperimentsResults");
    resultsPath = char(resultsPathInfo.path);
    vesselResultsPathBase = append(resultsPath, "/", vesselName,"/");
    baseResultsPath = append(vesselResultsPathBase, "AnalysedResults/");

    maxValueCONST = 999999999;
    populationSize = 10;
    numGenerations = 1000;
    vesselInformation = loadShipSearchParameters(vesselName);
    % calculate the reference point
    referencePointMap = containers.Map();
    combinedPopulationMap = containers.Map();
    
    referencePointFileLocation = append(baseResultsPath,"referencePointInfo.mat");
    reloadExperiments = true;
    if exist(referencePointFileLocation)
   
        load(referencePointFileLocation, "referencePointMap","referencePointMatrix","combinedObjectivesMap", "prevexperimentInfoMap")
        if areTheMapsEqual(prevexperimentInfoMap, experimentInfoMap) %prevexperimentInfoMap == experimentInfoMap
            reloadExperiments = false;
        end
    end
        
    %reloadExperiments = true
    if reloadExperiments
        [referencePointMap, referencePointMatrix, combinedObjectivesMap] = findObjectiveranges(experimentInfoMap,vesselInformation, populationSize, numGenerations, vesselResultsPathBase, maxValueCONST, useTimedrestrictedResults)
        prevexperimentInfoMap = experimentInfoMap;
        save(referencePointFileLocation, "referencePointMap","referencePointMatrix","combinedObjectivesMap", "prevexperimentInfoMap")
    end


    
    HVresultsMap = CalculateHypervolume(experimentInfoMap,vesselInformation,populationSize, numGenerations, vesselResultsPathBase,referencePointMap,maxValueCONST,useTimedrestrictedResults, reloadExperiments)
    HVresultsMap
    %plotObjectivesDistribution(vesselName,experimentInfoMap, referencePointMap,useTimedrestrictedResults)
    combinedPopulation = [];

    
end

function HVresultsMap = CalculateHypervolume(experimentInfoMap,vesselInformation,populationSize, numGenerations, vesselResultsPathBase,referencePointMap,maxValueCONST, useTimedrestrictedResults, reloadExperiments)
    selectionNames = string(experimentInfoMap.keys());
    numberOfExperiments = length(experimentInfoMap(selectionNames(3)));
    
    HVresultsMap = containers.Map();
    for wptIndex = 2:(vesselInformation.numWaypoints+1)

        HVmatrix = zeros(length(selectionNames), numberOfExperiments);
    
        for selectionIndex = 1:length(selectionNames)
        
            selectionType = selectionNames(selectionIndex);
            experimentList = experimentInfoMap(selectionType);
            %experimentList = experimentListMatrix(selectionIndex,:);
            
            for experimentIdx = 1:length(experimentList)
                experimentNum = experimentList(experimentIdx);

                hypervolumePath = append(vesselResultsPathBase, selectionType,"-exNum", string(experimentNum),"/WptIdx-", string(wptIndex), "-HV.mat"); %, string(wptIndex));

                if ~reloadExperiments && (exist(hypervolumePath) == 2)
                    load(hypervolumePath, "experimentHVscore")
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
                            experimentHVscore = hypervolume(paretoFrontObjs, referencePointMap(string(wptIndex)),10000);

                            %experimentHVscore  = -1;
                        else
                            experimentHVscore = hypervolume(paretoFrontObjs, referencePointMap(string(wptIndex)),10000);
                        end
                    else
                        experimentHVscore  = -1;
                    end

                    save(hypervolumePath, "experimentHVscore")
                end
                HVmatrix(selectionIndex, experimentIdx) = experimentHVscore; %hypervolume(paretoFrontObjs, referencePointMap(string(wptIndex)),10000);

                    
           
            end
            HVresultsMap(string(wptIndex)) = HVmatrix;


        end
    end
end

function [referencePointMap, referencePointMatrix, combinedObjectivesMap] = findObjectiveranges(experimentInfoMap,vesselInformation,populationSize, numGenerations, vesselResultsPathBase,maxValueCONST,useTimedrestrictedResults)
    referencePointMap = containers.Map();
    referencePointMatrix = [];
    combinedObjectivesMap = containers.Map();

    for wptIndex = 2:(vesselInformation.numWaypoints+1)
        [combinedObjectives] = CombineWptObjectives(wptIndex);
        combinedObjectivesMap(string(wptIndex)) = combinedObjectives;
        %nonMissingObjectivesFlag = abs(prevObjectives(:,1)) ~= maxValueCONST;
        [missingPathsFlag, nonMissingPathsFlag] = getIndexesOfMissingPaths(combinedObjectives);
        combinedObjectivesWithoutMissing = combinedObjectives(nonMissingPathsFlag,:);
        % switch objective 1 values to be non-zero
        objectiveLargestValue = min(combinedObjectivesWithoutMissing(:,1));
        combinedObjectivesWithoutMissing(:,1) = -(objectiveLargestValue -combinedObjectivesWithoutMissing(:,1));
    
        referencePointMap(string(wptIndex)) = [abs(objectiveLargestValue) max(combinedObjectivesWithoutMissing(:,2))];
        referencePointMatrix = [referencePointMatrix; referencePointMap(string(wptIndex))];
    end

    function [objectives] = CombineWptObjectives(wptIndex)
        %clear objectives
        objectives = [];
        selectionNames = string(experimentInfoMap.keys());
        for selectionTypeIdx = 1:length(selectionNames)
            selectionName = selectionNames(selectionTypeIdx);

            experimentList = experimentInfoMap(selectionName);
            vesselResultsPathApproach = append(vesselResultsPathBase, selectionName,"-exNum"); %, string(wptIndex));

            for experimentNumber = experimentList
                [population] = getPopulation(vesselInformation, vesselResultsPathBase,populationSize,numGenerations,selectionName,experimentNumber,wptIndex,useTimedrestrictedResults);
                objs = population.objs;
                objectives = [objectives; objs];
                
            end

        end
    end
end

function plotObjectivesDistribution(vesselName,experimentInfoMap, referencePointMap, useTimedrestrictedResults)
    
    resultsPathInfo = what("ExperimentsResults");
    resultsPath = char(resultsPathInfo.path);
    vesselResultsPathBase = append(resultsPath, "/", vesselName,"/");
    baseResultsPath = append(vesselResultsPathBase, "AnalysedResults/");

    maxValueCONST = 999999999;
    populationSize = 10;
    numGenerations = 1000;
    vesselInformation = loadShipSearchParameters(vesselName);
    selectionNames = string(experimentInfoMap.keys());

    colors = ['g', 'b','r', 'k', 'y'];
    numberOfExperiments = length(experimentInfoMap(selectionNames(1)));
    HVresultsMap = containers.Map();
    for wptIndex = 2:(vesselInformation.numWaypoints+1)

        HVmatrix = zeros(length(selectionNames), numberOfExperiments);
        figure('Visible', 'off')
        set(gcf, 'Position', [100, 100, 1512, 982]); % Set the figure size and position

        for selectionIndex = 1:length(selectionNames)
        
            selectionType = selectionNames(selectionIndex);
            experimentList = experimentInfoMap(selectionType);
            %experimentList = experimentListMatrix(selectionIndex,:);
            
            selectionObjectives = [];
            selectionAllObjecitves = [];

            for experimentIdx = 1:length(experimentList)
                experimentNum = experimentList(experimentIdx);
                objectiveLargestValue = referencePointMap(string(wptIndex));
                objectiveLargestValue = objectiveLargestValue(1);
                
                [population] = getPopulation(vesselInformation, vesselResultsPathBase,populationSize,numGenerations,selectionType,experimentNum,wptIndex,useTimedrestrictedResults);
                exObjs = population.objs;
                exDecs = population.decs;
                exCons = population.cons;
               % nonMissingPathsFlag =  abs(prevObjectives(:,1)) ~= maxValueCONST; 
                [missingPathsFlag, nonMissingPathsFlag] = getIndexesOfMissingPaths(exObjs);
                exDecs = exDecs(nonMissingPathsFlag,:);
                exObjs = exObjs(nonMissingPathsFlag,:);
                exCons = exCons(nonMissingPathsFlag,:);
                exObjs(:,1) = objectiveLargestValue + exObjs(:,1);
                %exObjs(:,2) = exObjs(:,1);%/(wptIndex-1);
                shiftedPopulation = SOLUTION(exDecs, exObjs, exCons); 

                %[populationWithMissingPaths, populationWithoutMissingPaths] = switchSignAndRemoveMissingPathsFromObjectives(maxValueCONST, originalPopulation,objectiveLargestValue);
                paretoFrontObjs = shiftedPopulation.best.objs;
                
                selectionObjectives = [selectionObjectives; paretoFrontObjs];

                selectionAllObjecitves = [selectionAllObjecitves; shiftedPopulation.objs];
           
            end
            subplot(1,2,1)
            plot(selectionObjectives(:,1),selectionObjectives(:,2), colors(selectionIndex)+"o")
            hold on;
            grid on;
            subplot(1,2,2)
            hold on
            grid on;
            
            plot(selectionAllObjecitves(:,1),selectionAllObjecitves(:,2), colors(selectionIndex)+"o")
            

        end
        subplot(1,2,1)
        title(append("Pareto front"));
        legend(selectionNames,"Location","best"); 
        xlabel("length of the path - where smallest is better")
        ylabel("distance from original WP")

        subplot(1,2,2)
        title(append("All individuals "));

        %ax = gca; % Get current axes
        %ax.FontSize = 18;
        legend(selectionNames,"Location","best"); 
        xlabel("length of the path - where smallest is better")
        ylabel("distance from original WP")

        %set(gca, 'TickLabelInterpreter', 'latex');
        sgtitle(append('Objectives distribution for wpt ', string(wptIndex))) 
        fileName = append(baseResultsPath,"objectivesDistribution-WPindex-", string(wptIndex),".png");
        %ax = gca; % Get current axes
        %set(ax, 'Position', screenSize);
        
        %set(ax, 'Position', [1 1 1512 982]);
        
       

        exportgraphics(gcf,fileName,'Resolution',300)
    end
    
    

end