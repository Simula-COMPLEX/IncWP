function plotHVresults(vesselName)
    resultsPathInfo = what("ExperimentsResults");
    resultsPath = char(resultsPathInfo.path);
    baseResultsPath = append(resultsPath,"/", vesselName, "/AnalysedResults/");

    
    % % %Hypervolume
    HVresultsPath = append(baseResultsPath,"HVresults");
    load(HVresultsPath,  "HVresultsMap", "referencePointMap","combinedPopulation", "comperisationResults", "experimentInfoMap");
    selectionNames = string(keys(experimentInfoMap));
    
    %selectionNames = selectionNames(selectionNames~="WPgenRnd")
    %HVresultsMap
    %comperisationResults
    vesselInformation = loadShipSearchParameters(vesselName);
    for wptIndex = 2:(vesselInformation.numWaypoints+1)
        HVmatrix = HVresultsMap(string(wptIndex))
        HVmatrix(HVmatrix < 0) = 0;

        data = [];    % to hold all non-zero values
        group = [];   % to hold group labels
        
        for i = 1:size(HVmatrix,1)
            % Get the non-zero entries in the current row
            nonZeroValues = HVmatrix(i, HVmatrix(i,:) > 0);
            
            % Append these values to the data array
            data = [data; nonZeroValues(:)];
            
            % Repeat the corresponding group name for each value
            group = [group; repmat(selectionNames(i), numel(nonZeroValues), 1)];
        end
        %size(HVmatrix)
        %groupMatrix = 
        
        %HVmatrix = HVmatrix(rows,HVmatrix ~= -1);
        
        size(HVmatrix)
        %HVmatrix = HVmatrix(1:length(selectionNames),:);
    
        figure
        set(gcf, 'Position', [100, 100, 1512, 982]); % Set the figure size and position

        if isvector(HVmatrix)
          
            offset = 0.5; % Define an offset to move the points to the right
            scatter((1:length(HVmatrix)) + offset, HVmatrix, 'filled'); % Plot each value with offset
            ax = gca; % Get current axes
            ax.FontSize = 18;
            ax.XTick = (1:length(HVmatrix)) + offset; % Set X-ticks
            grid;
           
        else
            %boxplot(HVmatrix', 'Whisker', 1.5)
            boxplot(data, group, 'Whisker', 1.5)
            title(append("WPindex ", string(wptIndex)));
            ax = gca; % Get current axes
            ax.FontSize = 18;
        end

        ax.XTickLabel = selectionNames; 
    
        set(gca, 'TickLabelInterpreter', 'latex');
        fileName = append(baseResultsPath,"boxPlot-WPindex-", string(wptIndex),".png");
    
        exportgraphics(ax,fileName,'Resolution',300)
    end
end