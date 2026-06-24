function plotTimeClassification(vesselName)
    close all
    %clear all
    %vesselName = "remus100"
    resultsPathInfo = what("ExperimentsResults");
    resultsPath = char(resultsPathInfo.path);
    baseResultsPath = append(resultsPath,"/", vesselName, "/AnalysedResults/");

    shipInformation = loadShipSearchParameters(vesselName);
    numberOfWaypoints = shipInformation.numWaypoints;
    % % %Hypervolume
    %plotHVresults(vesselName)

    %%Classify paths
    classesAndTimeFileLocation = append(baseResultsPath,"classesAndTimestamps.mat");
        
    load(classesAndTimeFileLocation, "selectionTimeStampAndClassMap", "selectionTimeStampAndClassStruct","selectionTypeTimeStamps","experimentInfoMap", "selectionTypeClassification", "dataInfo")
    selectionTimeStampAndClassMap;
    selectionTimeStampAndClassMap.keys;
    waypointTimestampMap = containers.Map();

    
    for wayPointIdx = 2:(numberOfWaypoints+1)
        wayPointIdx = string(wayPointIdx);%{1};

        selectionTypeTimestampsMap = containers.Map();

        for selectionType = selectionTimeStampAndClassMap.keys()
            selectionType = selectionType{1};
            if selectionType == "FullWP" 
                %selectiontMap = selectionTimeStampAndClassMap(selectionType);
                

            else
               
                selectiontMap = selectionTimeStampAndClassMap(selectionType);

                missingTimestamps = [];
                stableTimestamps = [];
                unstableTimestamps = [];
                for experimentNumber = selectiontMap.keys()

                    

                    experimentNumber = experimentNumber{1};
                    experimentMap = selectiontMap(experimentNumber);

                    experimentMap.keys;
                    wayPointIdx;
                    waypointMap = experimentMap(wayPointIdx);
                    
                    classification = waypointMap('classification');    
                    waypointMap.keys;
                    timestamps = waypointMap('timestamp'); 

                    missingFlags = (classification == "missing");
                    stableFlags = (classification == "stable");
                    unstableFlags = (classification == "unstable");
                    missingTimestamps = [missingTimestamps; timestamps(missingFlags)];
                    stableTimestamps = [stableTimestamps; timestamps(stableFlags)];
                    unstableTimestamps = [unstableTimestamps; timestamps(unstableFlags)];

                end
                missingTimestamps = sort(missingTimestamps);
                stableTimestamps = sort(stableTimestamps);
                unstableTimestamps = sort(unstableTimestamps);

                


                selectionTypeTimestampsMap(selectionType) = containers.Map({'missingTimestamps', 'stableTimestamps','unstableTimestamps'}, {missingTimestamps,stableTimestamps,unstableTimestamps});
              
 
            end

        end

        
        %waypointTimestampMap(wayPointIdx) = selectionTypeTimestampsMap;

    end
    
    
    usepreviousTime = true;
    waypointSelectionMaxTimeMap = containers.Map();
    selectionTypeFullTimestamps = containers.Map();

    lastTimestampMap = containers.Map();
    %wayPointIdx = string(numberOfWaypoints+1)
    for wayPointIdx = 2:(numberOfWaypoints+1)
        wayPointIdx = string(wayPointIdx);
        selectionTypeTimestampsMap = containers.Map();
        selectionMaxTimeMap = containers.Map();
        
        for selectionType = selectionTimeStampAndClassMap.keys()
            selectionType = selectionType{1};
            selectiontMap = selectionTimeStampAndClassMap(selectionType);

            if any(ismember(selectionType, lastTimestampMap.keys()))
                experimentLastTimestamp = lastTimestampMap(selectionType);

            else                     
                experimentLastTimestamp = containers.Map();
            end 
    
            missingTimestamps = [];
            stableTimestamps = [];
            unstableTimestamps = [];
            maxTimeWpt = 0;

            for experimentNumber = selectiontMap.keys()
                experimentNumber = experimentNumber{1};
                experimentMap = selectiontMap(experimentNumber);
                waypointMap = experimentMap(wayPointIdx);
                
                classification = waypointMap('classification');    
                waypointMap.keys;
                timestamps = waypointMap('timestamp');
                maxTimeWpt = max([maxTimeWpt; timestamps]);
                
                if usepreviousTime

                    if any(ismember(experimentNumber, experimentLastTimestamp.keys()))
                        lastTimestamp = experimentLastTimestamp(experimentNumber);
    
                    else 
                        lastTimestamp = 0;
    
                    end
    
                    if selectionType == "FullWP" 
                        lastInd = lastTimestamp;
                        currentInd = 1; %lastInd+1; %1
                        lastInd =lastInd + length(timestamps); % currentInd + length(classification);
    
                        %timestamps = timestamps(currentInd:lastInd);
    
                        experimentLastTimestamp(experimentNumber) = lastInd;
                    else
                        timestamps = waypointMap('timestamp'); 
                        timestamps =  timestamps + lastTimestamp;
                        experimentLastTimestamp(experimentNumber) = timestamps(end);
    
                    end
                    
                end

                missingFlags = (classification == "missing");
                stableFlags = (classification == "stable");
                unstableFlags = (classification == "unstable");
                missingTimestamps = [missingTimestamps; timestamps(missingFlags)];
                stableTimestamps = [stableTimestamps; timestamps(stableFlags)];
                unstableTimestamps = [unstableTimestamps; timestamps(unstableFlags)];

            end
            selectionMaxTimeMap(selectionType) = maxTimeWpt;
            
            lastTimestampMap(selectionType) = experimentLastTimestamp;

            missingTimestamps = sort(missingTimestamps);
            stableTimestamps = sort(stableTimestamps);
            unstableTimestamps = sort(unstableTimestamps);
            selectionTypeTimestampsMap(selectionType) = containers.Map({'missingTimestamps', 'stableTimestamps','unstableTimestamps'}, {missingTimestamps,stableTimestamps,unstableTimestamps});

            if any(ismember(selectionType, selectionTypeFullTimestamps.keys()))
                categoriesFullpathMap = selectionTypeFullTimestamps(selectionType);
                missingFull = categoriesFullpathMap("missingTimestamps");
                unstableFull = categoriesFullpathMap("unstableTimestamps");
                stableFull = categoriesFullpathMap("stableTimestamps");
                tempSelectionMaxTimeMap = waypointSelectionMaxTimeMap(string(str2double(wayPointIdx)-1)) 
                
                maxTimeWpt = tempSelectionMaxTimeMap(selectionType)  
                maxTime = max([missingFull; unstableFull; stableFull])
                minTime = min([missingTimestamps; stableTimestamps; unstableTimestamps])

                if usepreviousTime == true %% TODO Make true again
                    maxTime = 0;
                    
                    missingFull = [missingFull; maxTime+ missingTimestamps];
                    unstableFull = [unstableFull; maxTime+unstableTimestamps];
                    stableFull = [stableFull; maxTime+stableTimestamps];

                else
                    maxTime = max([missingFull; unstableFull; stableFull])

                    missingFull = [missingFull; maxTime+ missingTimestamps];
                    unstableFull = [unstableFull; maxTime+unstableTimestamps];
                    stableFull = [stableFull; maxTime+stableTimestamps];

                end
                missingFull = sort(missingFull);
                unstableFull = sort(unstableFull);
                stableFull = sort(stableFull);

                
                selectionTypeFullTimestamps(selectionType) = containers.Map({'missingTimestamps', 'stableTimestamps','unstableTimestamps'}, {missingFull,stableFull,unstableFull});
                

       

            else                     
                selectionTypeFullTimestamps(selectionType) = containers.Map({'missingTimestamps', 'stableTimestamps','unstableTimestamps'}, {missingTimestamps,stableTimestamps,unstableTimestamps});


            end 
        end
        waypointSelectionMaxTimeMap(wayPointIdx) = selectionMaxTimeMap
        waypointTimestampMap(wayPointIdx) = selectionTypeTimestampsMap;

    end
    classesAndTimeFileLocation = append(baseResultsPath,"WaypointsClassesAndTimestamps.mat");
    save(classesAndTimeFileLocation, "selectionTimeStampAndClassMap", "selectionTimeStampAndClassStruct","selectionTypeTimeStamps","experimentInfoMap", "selectionTypeClassification", "dataInfo", "waypointTimestampMap")




    %% PLOTTING
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
    lastWaypoint = experimentMap.keys();
    lastWaypoint = lastWaypoint{end};
    %statistics = []
    statistics = ["Waypoint", "approach", "category", "starttime", "endtime" "count"]
    for wayPointIdx = experimentMap.keys()
        wayPointIdx = wayPointIdx{1};
        selectionTypeTimestampsMap = waypointTimestampMap(wayPointIdx);

        figure(figureNumber)
        set(gcf, 'Position', [100, 100, 1512, 982]); % Set the figure size and position
       
         
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
        legendEntries = {}; 
        
                for selectionType = selectionTimeStampAndClassMap.keys()
            selectionType = selectionType{1};
            if isKey(colorMap, selectionType)
                currentColor = colorMap(selectionType);
            else
                  
                currentColor = colorMatrix(selectionColorIdx,:);
                selectionColorIdx = selectionColorIdx + 1; 
                colorMap(selectionType) = currentColor;
            end

            if false %wayPointIdx == lastWaypoint || wayPointIdx == (lastWaypoint -1)
                if (selectionType == "FullWP" ) 
                    legendEntries{end+1} = selectionType; 
                    timestampsMap = selectionTypeTimestampsMap(selectionType);
                else
                    legendEntries{end+1} = selectionType; 
                    timestampsMap = selectionTypeFullTimestamps(selectionType);
                    
                end

                 missingTimestamps = timestampsMap('missingTimestamps');
                stableTimestamps = timestampsMap('stableTimestamps');
                unstableTimestamps = timestampsMap('unstableTimestamps');
                
                

                
                % Plot Missing Data (if it exists)
                if ~isempty(missingTimestamps)
                    plot(ax(1), missingTimestamps, 1:length(missingTimestamps), ...
                        'DisplayName', selectionType, ...
                        'Color', currentColor, ...
                        'LineWidth', 1.5);
                end
                
                % Plot Stable Data (if it exists)
                if ~isempty(stableTimestamps)
                    plot(ax(3), stableTimestamps, 1:length(stableTimestamps), ...
                        'DisplayName', selectionType, ...
                        'Color', currentColor, ...
                        'LineWidth', 1.5);
                end
                
                % Plot Unstable Data (if it exists)
                if ~isempty(unstableTimestamps)
                    plot(ax(2), unstableTimestamps, 1:length(unstableTimestamps), ...
                        'DisplayName', selectionType, ...
                        'Color', currentColor, ...
                        'LineWidth', 1.5);
                end
                statisticsInfoMissing = [wayPointIdx selectionType "missing" string(missingTimestamps(1)) string(missingTimestamps(2)) length(missingTimestamps)];
                statisticsInfoUnstable = [wayPointIdx selectionType "unstable" string(unstableTimestamps(1)) string(unstableTimestamps(2)) length(unstableTimestamps)];
                statisticsInfoStable = [wayPointIdx selectionType "stable" string(stableTimestamps(1)) string(stableTimestamps(2)) length(stableTimestamps)];
                statistics  = [statistics; statisticsInfoMissing; statisticsInfoUnstable; statisticsInfoStable;]

             

            elseif true %~(selectionType == "FullWP") 
                legendEntries{end+1} = selectionType; 
                timestampsMap = selectionTypeTimestampsMap(selectionType);
                
                 missingTimestamps = timestampsMap('missingTimestamps');
                stableTimestamps = timestampsMap('stableTimestamps');
                unstableTimestamps = timestampsMap('unstableTimestamps');
                numInd = length(missingTimestamps) + length(stableTimestamps)+ length(unstableTimestamps);
                missingPrecentage = length(missingTimestamps)/numInd*100;
                stablePrecentage = length(stableTimestamps)/numInd*100;
                unstablePrecentage = length(unstableTimestamps)/numInd*100;

                usePresentage = true;
                if usePresentage
                    missingYaxis = linspace(0,missingPrecentage, length(missingTimestamps));
                    stableYaxis = linspace(0,stablePrecentage, length(stableTimestamps));
                    unstableYaxis = linspace(0,unstablePrecentage, length(unstableTimestamps));
                else
                    missingYaxis = 1:length(missingTimestamps);
                    stableYaxis = 1:length(stableTimestamps);
                    unstableYaxis = 1:length(unstableTimestamps);

                end

                

                
                % Plot Missing Data (if it exists)
                if ~isempty(missingTimestamps)
                    plot(ax(1), missingTimestamps, missingYaxis, ...
                        'DisplayName', selectionType, ...
                        'Color', currentColor, ...
                        'LineWidth', 1.5);
                    statisticsInfoMissing = [wayPointIdx selectionType "missing" string(missingTimestamps(1)) string(missingTimestamps(end)) length(missingTimestamps)];
                else
                    statisticsInfoMissing = [wayPointIdx selectionType "missing" "-" "-" "-"];
                end
                
                % Plot Stable Data (if it exists)
                if ~isempty(stableTimestamps)
                    plot(ax(3), stableTimestamps, stableYaxis, ...
                        'DisplayName', selectionType, ...
                        'Color', currentColor, ...
                        'LineWidth', 1.5);
                    statisticsInfoStable = [wayPointIdx selectionType "stable" string(stableTimestamps(1)) string(stableTimestamps(end)) length(stableTimestamps)];

                else
                    statisticsInfoStable = [wayPointIdx selectionType "stable" "-" "-" "-"];

                end
                
                % Plot Unstable Data (if it exists)
                if ~isempty(unstableTimestamps)
                    plot(ax(2), unstableTimestamps, unstableYaxis, ...
                        'DisplayName', selectionType, ...
                        'Color', currentColor, ...
                        'LineWidth', 1.5);
                    statisticsInfoUnstable = [wayPointIdx selectionType "unstable" string(unstableTimestamps(1)) string(unstableTimestamps(end)) length(unstableTimestamps)];

                else
                    statisticsInfoUnstable = [wayPointIdx selectionType "unstable" "-" "-" "-"];

                end
                    

                statistics  = [statistics; statisticsInfoMissing; statisticsInfoUnstable; statisticsInfoStable;];

            end
            % ["Waypoint", "approach", "category", "starttime", "endtime"]
           
           
        end
        linkaxes(ax, 'x');

        % --- STEP 2: Add titles and legends AFTER the loop using handles ---

        % First, add the main title for the whole figure
        sgtitle(append("WPindex ", wayPointIdx));

        % Now, add titles and legends to each specific subplot
        % 📌 Notice how the handle (e.g., ax(1)) is the first argument
        title(ax(1), 'Missing paths');
        ylabel(ax(1), 'Precentage');
        grid(ax(1), 'on');

        title(ax(3), 'Stable paths');
        ylabel(ax(3), 'Precentage');
        xlabel(ax(3), 'Time');
        grid(ax(3), 'on');

        title(ax(2), 'Unstable paths');
        ylabel(ax(2), 'Precentage');
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
        fileName = append(baseResultsPath,"plots/Time/timeRangesWpt", wayPointIdx, ".png")
        exportgraphics(parentFigure,fileName,'Resolution',300)

       
    end
   
    filepath = append(baseResultsPath,"/plots/timeRangesAndCount");
    save(filepath,"statistics")

    

    %% Plot the last waypoints
    wayPointIdx = lastWaypoint
    selectionTypeTimestampsMap = waypointTimestampMap(wayPointIdx);

    figure(figureNumber)
    set(gcf, 'Position', [100, 100, 1512, 982]); % Set the figure size and position
   
     
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
    legendEntries = {}; 
        for selectionType = selectionTimeStampAndClassMap.keys()
        selectionType = selectionType{1};
        if isKey(colorMap, selectionType)
            currentColor = colorMap(selectionType);
        else
              
            currentColor = colorMatrix(selectionColorIdx,:);
            selectionColorIdx = selectionColorIdx + 1; 
            colorMap(selectionType) = currentColor;
        end

        if (selectionType == "FullWP" ) 
            legendEntries{end+1} = selectionType; 
            timestampsMap = selectionTypeTimestampsMap(selectionType);
        else
            legendEntries{end+1} = selectionType; 
            timestampsMap = selectionTypeFullTimestamps(selectionType);
            
        end

        missingTimestamps = timestampsMap('missingTimestamps');
        stableTimestamps = timestampsMap('stableTimestamps');
        unstableTimestamps = timestampsMap('unstableTimestamps');

        numInd = length(missingTimestamps) + length(stableTimestamps)+ length(unstableTimestamps);
        missingPrecentage = length(missingTimestamps)/numInd*100;
        stablePrecentage = length(stableTimestamps)/numInd*100;
        unstablePrecentage = length(unstableTimestamps)/numInd*100;

        usePresentage = true;
        if usePresentage
            missingYaxis = linspace(0,missingPrecentage, length(missingTimestamps));
            stableYaxis = linspace(0,stablePrecentage, length(stableTimestamps));
            unstableYaxis = linspace(0,unstablePrecentage, length(unstableTimestamps));
        else
            missingYaxis = 1:length(missingTimestamps);
            stableYaxis = 1:length(stableTimestamps);
            unstableYaxis = 1:length(unstableTimestamps);

        end
        
        

        
        % Plot Missing Data (if it exists)
        if ~isempty(missingTimestamps)
            plot(ax(1), missingTimestamps, missingYaxis, ...
                'DisplayName', selectionType, ...
                'Color', currentColor, ...
                'LineWidth', 1.5);
            %statisticsInfoMissing = [wayPointIdx selectionType "missing" string(missingTimestamps(1)) string(missingTimestamps(end)) length(missingTimestamps)];
        else
            %statisticsInfoMissing = [wayPointIdx selectionType "missing" "-" "-" "-"];
        end
        
        % Plot Stable Data (if it exists)
        if ~isempty(stableTimestamps)
            plot(ax(3), stableTimestamps, stableYaxis, ...
                'DisplayName', selectionType, ...
                'Color', currentColor, ...
                'LineWidth', 1.5);
            %statisticsInfoStable = [wayPointIdx selectionType "stable" string(stableTimestamps(1)) string(stableTimestamps(end)) length(stableTimestamps)];

        else
            %statisticsInfoStable = [wayPointIdx selectionType "stable" "-" "-" "-"];

        end
        
        % Plot Unstable Data (if it exists)
        if ~isempty(unstableTimestamps)
            plot(ax(2), unstableTimestamps, unstableYaxis, ...
                'DisplayName', selectionType, ...
                'Color', currentColor, ...
                'LineWidth', 1.5);
            %statisticsInfoUnstable = [wayPointIdx selectionType "unstable" string(unstableTimestamps(1)) string(unstableTimestamps(end)) length(unstableTimestamps)];

        else
            %statisticsInfoUnstable = [wayPointIdx selectionType "unstable" "-" "-" "-"];

        end
        %statisticsInfoMissing = [wayPointIdx selectionType "missing" string(missingTimestamps(1)) string(missingTimestamps(2)) length(missingTimestamps)];
        %statisticsInfoUnstable = [wayPointIdx selectionType "unstable" string(unstableTimestamps(1)) string(unstableTimestamps(2)) length(unstableTimestamps)];
        %statisticsInfoStable = [wayPointIdx selectionType "stable" string(stableTimestamps(1)) string(stableTimestamps(2)) length(stableTimestamps)];
        %statistics  = [statistics; statisticsInfoMissing; statisticsInfoUnstable; statisticsInfoStable;]
        
    end

    linkaxes(ax, 'x');

    % --- STEP 2: Add titles and legends AFTER the loop using handles ---

    % First, add the main title for the whole figure
    sgtitle("All waypoints");

    % Now, add titles and legends to each specific subplot
    % 📌 Notice how the handle (e.g., ax(1)) is the first argument
    title(ax(1), 'Missing paths');
    ylabel(ax(1), 'Precentage');
    grid(ax(1), 'on');

    title(ax(3), 'Stable paths');
    ylabel(ax(3), 'Precentage');
    xlabel(ax(3), 'Time');
    grid(ax(3), 'on');

    title(ax(2), 'Unstable paths');
    ylabel(ax(2), 'Precentage');
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
    fileName = append(baseResultsPath,"plots/time/timeRangesLast", ".png")
    exportgraphics(parentFigure,fileName,'Resolution',300)
    



end
 
