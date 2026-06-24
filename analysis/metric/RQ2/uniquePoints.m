function uniquePoints(vesselName)
    onServer = runningOnServer();
    %vesselName = "remus100"
    runningInddex = 3

    resultsPathInfo = what("ExperimentsResults");
    resultsPath = char(resultsPathInfo.path);
    baseResultsPath = append(resultsPath,"/", vesselName, "/AnalysedResults/");

    experimentInfoMap = loadExperimentsStatus(vesselName);

    vesselResultsPathBase = append(resultsPath, "/", vesselName,"/");

    vesselInformation = loadShipSearchParameters(vesselName);

    filelocation = append(baseResultsPath, "/combinedResults.mat");
    load(filelocation,"approachDataMap", "experimentInfoMap", "waypointRangesMap", "combinedsolutionsMap")
    approachDataMap.keys()
    approachDataMap
    uniqueData = ["approach", "waypointIdx", "numUniquePoints"]

    for waypointIdx = 2:(vesselInformation.numWaypoints+1)
        for selectionType = approachDataMap.keys()
            selectionType = selectionType{1};
            approachData = approachDataMap(selectionType);
            waypointInfo = approachData(string(waypointIdx));
            decs = waypointInfo('decisions');
            uniqueDecs = unique(decs, 'rows');
            uniquePrecentage = size(uniqueDecs,1) / size(decs,1) *100;
            uniqueData = [uniqueData; [selectionType, string(waypointIdx), string(uniquePrecentage)]];
           
        end
    end
   
      
    uniqueData

    headers = uniqueData(1, :);
    dataRows = uniqueData(2:end, :);
    colorMatrix = [
        0.50, 0.00, 0.00;  % 1. Maroon
        0.85, 0.65, 0.13;  % 2. Goldenrod
        0.50, 0.50, 0.00;  % 3. Olive
        0.00, 0.50, 0.50;  % 4. Teal
        0.00, 0.00, 0.50;  % 5. Navy
        0.29, 0.00, 0.51;  % 6. Indigo
        0.86, 0.08, 0.24;  % 7. Crimson
        % 0.27, 0.51, 0.71;  % 8. Steel Blue (Not needed as you have 7 series)
    ];

    approach = dataRows(:, 1); % This is already string data, which is fine
    waypointIdx = str2double(dataRows(:, 2)); % Convert waypoint strings to numbers
    numUniquePoints = str2double(dataRows(:, 3)); % Convert points strings to numbers

    % 3. Create a table with the cleaned data
    % A table is the best format for mixed data types.
    T = table(approach, waypointIdx, numUniquePoints);

    wideTable = unstack(T, 'numUniquePoints', 'approach');

    Y_data = wideTable{:, 2:end};
    x_categories = wideTable.waypointIdx;
    legend_labels = wideTable.Properties.VariableNames(2:end);

    figure;
    set(gcf, 'Position', [100, 100, 1512, 982]); % Set the figure size and position 
    bar(x_categories, Y_data);
    ax = gca; % Get current axes
    ax.ColorOrder = colorMatrix; % Apply your color matrix


    % 7. Add labels and a title for clarity
    title('Comparison of Approaches by Waypoint Index');
    xlabel('Waypoint Index');
    ylabel('Number of Unique Points');
    legend(legend_labels, 'Location', 'best');
    grid on;

    % make a bar plot showing this

    fileName = append(baseResultsPath,"plots/Unique/uniquePoints", ".png")
    exportgraphics(gcf,fileName,'Resolution',300)

    filepath = append(baseResultsPath,"/plots/uniquePointsStats.mat");
    save(filepath,"uniqueData")

    
    

end
