function effenctMetrics(vesselName)
    close all
    vesselName = "remus100"
    resultsPathInfo = what("ExperimentsResults");
    resultsPath = char(resultsPathInfo.path);
    baseResultsPath = append(resultsPath,"/", vesselName, "/AnalysedResults/");

    shipInformation = loadShipSearchParameters(vesselName);
    numberOfWaypoints = shipInformation.numWaypoints;
    classesAndTimeFileLocation = append(baseResultsPath,"WaypointsClassesAndTimestamps.mat");
    load(classesAndTimeFileLocation, "selectionTimeStampAndClassMap", "selectionTimeStampAndClassStruct","selectionTypeTimeStamps","experimentInfoMap", "selectionTypeClassification", "dataInfo", "waypointTimestampMap")

    statisticMatrix = ["wayPointIdx", "selectionType", "firstMissing", "numberMissing", "firstUnstable", "numberUnstable", "timeduration", "missingEffincency", "unstableEffincency"]
    size(statisticMatrix)
    maxMin = 0;
    waypointEfficencyMetrics = containers.Map();
    for wayPointIdx = waypointTimestampMap.keys()
        wayPointIdx = wayPointIdx{1};
        selectionTypeTimestampsMap = waypointTimestampMap(wayPointIdx);
        selectionStatisticsMap = containers.Map();
        for selectionType = selectionTimeStampAndClassMap.keys()
            selectionType = selectionType{1};
            timestampsMap = selectionTypeTimestampsMap(selectionType);

            missingTimestamps = timestampsMap('missingTimestamps');
            stableTimestamps = timestampsMap('stableTimestamps');
            unstableTimestamps = timestampsMap('unstableTimestamps');

            timestampsCombined = [missingTimestamps; stableTimestamps; unstableTimestamps];
            [mintime, maxtime] = bounds(timestampsCombined);
            timeduration = maxtime - mintime;

            missingTimestamps = missingTimestamps - mintime + min(missingTimestamps);
            stableTimestamps = stableTimestamps - mintime +min(stableTimestamps);
            unstableTimestamps = unstableTimestamps - mintime + min(unstableTimestamps);

            numMin = timeduration/60;
            secThreshold = 0;
            minCountMap = containers.Map();
            minCountMatrix = [];
            for minCount = 0:numMin
                secMin = (minCount)*60;
                secMax = (minCount+1)*60;
                missingMin = missingTimestamps(missingTimestamps < secMax);
                stableMin = stableTimestamps( stableTimestamps < secMax);
                unstableMin = unstableTimestamps(unstableTimestamps < secMax);
                missingMinCount = length(missingMin);
                stableMinCount = length(stableMin);
                unstableMinCount = length(unstableMin);
                minCountMap(string(minCount)) = [minCount, missingMinCount, unstableMinCount, stableMinCount];
                minCountMatrix = [minCountMatrix; minCountMap(string(minCount))];
            end
            maxMin = max(maxMin, numMin);

            if size(missingTimestamps, 1) > 0
                firstMissing = missingTimestamps(1);
                numberMissing = (length(missingTimestamps)/length(timestampsCombined))*100;
                missingEffincency = timeduration/numberMissing; 

            else
                firstMissing = 0;
                numberMissing = 0;
                missingEffincency = 0;
            end
            if size(unstableTimestamps, 1) > 0
                firstUnstable = unstableTimestamps(1);
                numberUnstable = (length(unstableTimestamps)/length(timestampsCombined))*100;
                unstableEffincency = timeduration/numberUnstable;


            else
                firstUnstable = 0;
                numberUnstable = 0;
                unstableEffincency = 0;
            end
            
            %averageMissingTime = mean(missingTimestamps);
            %averargeUnstableTime = mean(unstableTimestamps);
            statisticsMap = containers.Map({'firstMissing', 'numberMissing', 'firstUnstable', 'numberUnstable', 'timeduration', 'missingEffincency', 'unstableEffincency', 'minCountMatrix', 'minCountMap'},...
                {firstMissing, numberMissing, firstUnstable, numberUnstable, timeduration, missingEffincency, unstableEffincency, minCountMatrix, minCountMap});
            statisticMatrixSelection = [wayPointIdx, selectionType, string(firstMissing), string(numberMissing), string(firstUnstable), string(numberUnstable), string(timeduration), string(missingEffincency), string(unstableEffincency)];
            statisticMatrixSelection
            statisticMatrix = [statisticMatrix; statisticMatrixSelection];
            selectionStatisticsMap(selectionType) = statisticsMap;


        end
        waypointEfficencyMetrics(wayPointIdx) = selectionStatisticsMap;
    end
    display(statisticMatrix)


    colorOrder = get(groot, 'defaultAxesColorOrder');
    colorMatrix = [
                        0.50, 0.00, 0.00;  % 1. Maroon
                        0.85, 0.65, 0.13;  % 2. Goldenrod
                        0.50, 0.50, 0.00;  % 3. Olive
                        0.00, 0.50, 0.50;  % 4. Teal
                        0.00, 0.00, 0.50;  % 5. Navy
                        0.29, 0.00, 0.51;  % 6. Indigo
                        0.86, 0.08, 0.24;  % 7. Crimson
                        0.27, 0.51, 0.71   % 8. Steel Blue
                    ];
    selectionColorIdx = 1;
    colorMap = containers.Map(); 
    figureNumber = 1;
    lastWaypoint = waypointTimestampMap.keys();
    lastWaypoint = lastWaypoint{end};
    for wayPointIdx = waypointTimestampMap.keys()
        wayPointIdx = wayPointIdx{1};
        selectionStatisticsMap = waypointEfficencyMetrics(wayPointIdx);

        figure(figureNumber)
        set(gcf, 'Position', [100, 100, 1512, 982]); % Set the figure size and position
        legendEntries = {}; 
        
        selectionKeys = selectionTimeStampAndClassMap.keys()
        selectionKeys = setdiff(selectionKeys, "FullWP");
        for selectionType = selectionKeys
            
            selectionType = selectionType{1};

            if selectionType ~= "FullWP"

                if isKey(colorMap, selectionType)
                    currentColor = colorMap(selectionType);
                else
                      
                    currentColor = colorMatrix(selectionColorIdx,:);
                    selectionColorIdx = selectionColorIdx + 1; 
                    colorMap(selectionType) = currentColor;
                end
    
                legendEntries{end+1} = selectionType; 
                statisticsMap = selectionStatisticsMap(selectionType);
                
                ax = gobjects(3, 1); 
                ax(1) = subplot(3,1,1);
                title('Missing Timestamps');
                hold(ax(1), 'on'); % Turn hold on once
                grid on;
                
                ax(2) = subplot(3,1,2); % This line must be executed
                title('Stable Timestamps');
                hold(ax(2), 'on');
                grid on;
                
                ax(3) = subplot(3,1,3);
                title('Unstable Timestamps');
                hold(ax(3), 'on');
                grid on;
                minCountMap = statisticsMap("minCountMap");
                minCountMatrix = statisticsMap("minCountMatrix");
                [minCount,missingMinCount, unstableMinCount, stableMinCount] = deal(minCountMatrix(:,1), minCountMatrix(:,2), minCountMatrix(:,3), minCountMatrix(:,4));
    
                
                stairs(ax(1), 1:length(missingMinCount), missingMinCount, ...
                            'DisplayName', selectionType, ...
                            'Color', currentColor, ...
                            'LineWidth', 1.5);
                
                stairs(ax(2), 1:length(unstableMinCount), unstableMinCount, ...
                            'DisplayName', selectionType, ...
                            'Color', currentColor, ...
                            'LineWidth', 1.5);
                stairs(ax(3), 1:length(stableMinCount), stableMinCount, ...
                            'DisplayName', selectionType, ...
                            'Color', currentColor, ...
                            'LineWidth', 1.5);

    
            end
            linkaxes(ax, 'x');
    
            % --- STEP 2: Add titles and legends AFTER the loop using handles ---
    
            % First, add the main title for the whole figure
            sgtitle(append("WPindex ", wayPointIdx));
    
            % Now, add titles and legends to each specific subplot
            % 📌 Notice how the handle (e.g., ax(1)) is the first argument
            title(ax(1), 'Missing paths');
            ylabel(ax(1), 'Count');
            grid(ax(1), 'on');
    
            title(ax(3), 'Stable paths');
            ylabel(ax(3), 'Count');
            xlabel(ax(3), 'Time');
            grid(ax(3), 'on');
    
            title(ax(2), 'Unstable paths');
            ylabel(ax(3), 'Count');
            grid(ax(2), 'on');
    
            % 📌 STEP 3: Create the legends using the list of names
            % MATLAB will match the entries to the lines in the order they were plotted.
            %legend(ax(1), legendEntries,'Location', 'best');
            %legend(ax(2), legendEntries,'Location', 'best');
            %legend(ax(3), legendEntries,'Location', 'best');
            legend(ax(1),'Location', 'best');
            legend(ax(2),'Location', 'best');
            legend(ax(3),'Location', 'best');
    
            hold(ax(1), 'off');
            hold(ax(2), 'off');
            hold(ax(3), 'off');
    
            figureNumber = figureNumber + 1;
            parentFigure = ax(1).Parent;
        end
    end
    

end
