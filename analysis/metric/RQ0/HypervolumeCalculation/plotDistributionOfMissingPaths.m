function plotDistributionOfMissingPaths(vesselName,onServer)
    experimentInfoMap = loadExperimentsStatus(vesselName);


    resultsPathInfo = what("ExperimentsResults");
    resultsPath = char(resultsPathInfo.path);
    baseResultsPath = append(resultsPath,"/", vesselName, "/AnalysedResults/");
 
    display("Currently looking at missing distribution")
    vesselResultsPathBase = append(resultsPath, "/", vesselName,"/");

    
    maxValueCONST = 999999999;
    populationSize = 10;
    numGenerations = 1000;
    vesselInformation = loadShipSearchParameters(vesselName);
    useTimedrestrictedResults  = true; 
    colors = ['g', 'b','r', 'k', 'y', 'm'];
    missingColor = 'r'
    notMissingColor = 'g'
    selectionNames = string(experimentInfoMap.keys());
    selectionNames = selectionNames(selectionNames ~= "IncWP_Unst")
    selectionNames = selectionNames(selectionNames ~= "IncWP_Prox")
    
    if onServer 
        plotFigure = false;
    else
        plotFigure = true;
    end
    
    if plotFigure == true
        tableCount = zeros( (vesselInformation.numWaypoints),length(selectionNames)*2);

        for wptIndex = 2:(vesselInformation.numWaypoints+1)
            for selectionIndex = 1:length(selectionNames)
                %figure %('Visible', 'off')
                set(gcf, 'Position', [100, 100, 1512, 982]);
                selectionType = selectionNames(selectionIndex)
                
                
                fileNameData = append(baseResultsPath,"missingVSnotMissingPoint-approach-", selectionType, "-WPindex-", string(wptIndex), "matrix.mat");
                load(fileNameData, "exDecsMissing", "exDecsNonMissing")

                if vesselInformation.pointDimension == 2
                    plot(exDecsMissing(:,1),exDecsMissing(:,2), colors(selectionIndex)+"o")
                    hold on
                    plot(exDecsNonMissing(:,1),exDecsNonMissing(:,2), colors(selectionIndex)+"x")

                else
                    %plot3(exDecsMissing(:,3), exDecsMissing(:,1),exDecsMissing(:,2),'o')%, missingColor) %colors(selectionIndex)+"o")
                    %hold on
                    %plot3(exDecsNonMissing(:,3), exDecsNonMissing(:,1),exDecsNonMissing(:,2),'x')%,'x', notMissingColor) %colors(selectionIndex)+"x")
                    %plot3(exDecsMissing(:,3), exDecsMissing(:,1),exDecsMissing(:,2),'o')%, missingColor) %colors(selectionIndex)+"o")
                    %hold on
                    %plot3(exDecsNonMissing(:,3), exDecsNonMissing(:,1),exDecsNonMissing(:,2),'x')%,'x', notMissingColor) %colors(selectionIndex)+"x")
                end
                %grid on
                %hold off;
                %grid on
                %hold off;
                %hold on;
                %title(append("missing points for approach ", selectionType, " for wpt ", string(wptIndex), "with ", string(size(exDecsMissing,1)), " missing points and ", string(size(exDecsNonMissing,1)), " not missing"));
                %title(append("missing points for approach ", selectionType, " for wpt ", string(wptIndex), "with ", string(size(exDecsMissing,1)), " missing points and ", string(size(exDecsNonMissing,1)), " not missing"));
                %legend(selectionNames,"Location","best"); % % TODO double missing points
                %xlabel("length of the path - where smallest is better")
                %ylabel("distance from original WP")
                %fileNameFig = append(baseResultsPath,"missingVSnotMissingPoint-approach-", selectionType, "-WPindex-", string(wptIndex), ".png");
                %exportgraphics(gcf,fileNameFig,'Resolution',300)
                %(selectionIndex*2-1)
                %(selectionIndex*2)
                %fileNameFig = append(baseResultsPath,"missingVSnotMissingPoint-approach-", selectionType, "-WPindex-", string(wptIndex), ".png");
                %exportgraphics(gcf,fileNameFig,'Resolution',300)
                %(selectionIndex*2-1)
                %(selectionIndex*2)
                tableCount(wptIndex-1,(selectionIndex*2-1):(selectionIndex*2)) = [size(exDecsNonMissing,1), size(exDecsMissing,1)]


            end
          
            
        end
        figure
        set(gcf, 'Position', [100, 100, 1512, 982]);
                
        h = heatmap(tableCount)
        pattern = ["not-missing", "missing"];
    
        resultList = arrayfun(@(name) strcat(name, "-", pattern), selectionNames, 'UniformOutput', false);
        resultList = [resultList{:}];
       
    
        h.XDisplayLabels = resultList;
        h.YDisplayLabels = string(2:(vesselInformation.numWaypoints+1));

        fileNameFig = append(baseResultsPath,"missingVSnotMissingPoint-count", ".png");
        exportgraphics(gcf,fileNameFig,'Resolution',300)
                
        
        
        
    else
        prevNonMissingFlagsMap = containers.Map();
        for wptIndex = 2:(vesselInformation.numWaypoints+1)
        
            for selectionIndex = 1:length(selectionNames)
                %figure('Visible', 'off')
                %set(gcf, 'Position', [100, 100, 1512, 982]);
                selectionType = selectionNames(selectionIndex)
                if selectionType == "RandomSearch"
                    populationSize = 10000; 
                    numGenerations = 1;
                elseif selectionType == "FullWP" 
                    populationSize = 10; 
                    numGenerations = 1000;
                else
                    populationSize = 10; 
                    numGenerations = 1000;
                end
                experimentList = experimentInfoMap(selectionType);
                
                exDecsMissing = [];
                exDecsNonMissing = [];
                if (selectionType == "FullWP") &&  wptIndex > 2 % || selectionType == "FullWP_Timelimited")
                    %prevMissingFlagsListTemp = [];
                    prevNonMissingFlagsListTemp = [];
                    
                    for experimentIdx = 1:length(experimentList)
                        experimentNum = experimentList(experimentIdx);

                        [population] = getPopulation(vesselInformation, vesselResultsPathBase,populationSize,numGenerations,selectionType,experimentNum,wptIndex,useTimedrestrictedResults);
                        exObjs = population.objs;
                        exDecs = population.decs;
                        exCons = population.cons;
                        [missingPathsFlagTemp, nonMissingPathsFlagTemp] = getIndexesOfMissingPaths(exObjs);
                        experimentNonMissingFlag = prevNonMissingFlagsMap(selectionType);
                        experimentIdx
                        (experimentIdx-1)*length(missingPathsFlagTemp)+1
                        ((experimentIdx)*length(missingPathsFlagTemp))
                        experimentNonMissingFlag = experimentNonMissingFlag(((experimentIdx-1)*length(missingPathsFlagTemp)+1):((experimentIdx)*length(missingPathsFlagTemp)));
                        size(experimentNonMissingFlag)
                        % only keep the one who were not missing previosuly
                        exObjs = exObjs(experimentNonMissingFlag,:);
                        exDecs = exDecs(experimentNonMissingFlag,:);
                        [missingPathsFlag, nonMissingPathsFlag] = getIndexesOfMissingPaths(exObjs);

                        
                        exDecsMissing = [exDecsMissing; exDecs(missingPathsFlag,:)];
                        exDecsNonMissing = [exDecsNonMissing; exDecs(nonMissingPathsFlag,:)];
                        %prevMissingFlagsListTemp = [prevMissingFlagsListTemp;  missingPathsFlag]
                        prevNonMissingFlagsListTemp = [prevNonMissingFlagsListTemp;  nonMissingPathsFlagTemp];
                    end
                    % update the flag of the non missing
                    prevNonMissingFlagsMap(selectionType) = prevNonMissingFlagsMap(selectionType) & prevNonMissingFlagsListTemp;
                    %prevMissingFlagsList = ~prevNonMissingFlagsList;   
                    %prevMissingFlagsMap(selectionType) = prevNonMissingFlagsList;            

                else 
                    %prevMissingFlagsList = [];
                    prevNonMissingFlagsList = [];
                    for experimentIdx = 1:length(experimentList)
                        experimentNum = experimentList(experimentIdx);

                        [population] = getPopulation(vesselInformation, vesselResultsPathBase,populationSize,numGenerations,selectionType,experimentNum,wptIndex,useTimedrestrictedResults);
                        exObjs = population.objs;
                        exDecs = population.decs;
                        exCons = population.cons;
                        [missingPathsFlag, nonMissingPathsFlag] = getIndexesOfMissingPaths(exObjs);
                        exDecsMissing = [exDecsMissing; exDecs(missingPathsFlag,:)];
                        exDecsNonMissing = [exDecsNonMissing; exDecs(nonMissingPathsFlag,:)];
                        %prevMissingFlagsList = [prevMissingFlagsList;  missingPathsFlag]
                        prevNonMissingFlagsList = [prevNonMissingFlagsList;  nonMissingPathsFlag];
                    end
                    prevNonMissingFlagsMap(selectionType) = prevNonMissingFlagsList;
            
                end
                fileNameData = append(baseResultsPath,"missingVSnotMissingPoint-approach-", selectionType, "-WPindex-", string(wptIndex), "matrix.mat");
                save(fileNameData, "exDecsMissing", "exDecsNonMissing")
                
            end
          

        end
    end
    
    end
