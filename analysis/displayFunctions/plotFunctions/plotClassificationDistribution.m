function plotClassificationDistribution(selectionResultsDistributionMap, resultsMatrix, precentageResultsMap, numBrackets, numClasses, baseResultsPath)

    %selectionNames = string(selectionResultsDistributionMap.keys);
    %waypoints = string(keys(selectionResultsDistributionMap(selectionNames(1))));
    selectionNames = string(precentageResultsMap.keys);
    waypoints = string(keys(precentageResultsMap(selectionNames(1))));
    
    figureNumber = 10
    %screenSize = get(0, 'ScreenSize');
    screenSize = [1 1 1512 982];
    resultsPathInfo = what("ExperimentsResults");
    resultsPath = char(resultsPathInfo.path);
    labelsClasses = ["% Missing", "% Unstable",  "% Stable"];
    labelsBrackets = string(1:numBrackets);


    splitBySection = false
    if splitBySection == true

        for selectionName = selectionNames
            %bracketDistributionSelection = selectionResultsDistributionMap(selectionName);
            bracketDistributionSelection = precentageResultsMap(selectionName)
            figure(figureNumber)
    
            labelsClasses = ["% Missing", "% Unstable",  "% Stable"];
    
            
            labelsBrackets = string(1:numBrackets);
            for wptIndex = waypoints
                subplot(length(waypoints)/3,3,find(selectionNames == selectionName))
                bracketDistribution = bracketDistributionSelection(wptIndex);
                heatmap(labelsClasses , labelsBrackets, bracketDistribution)
    
                title(append("WPindex ", string(wptIndex)));
                ax = gca; % Get current axes
                ax.FontSize = 18;
    
            end
            sgtitle(append(selectionName))
            figureNumber = figureNumber +1;
            f = gcf; % Get current figure handle
            set(f, 'Position', screenSize);
            fileName = append(baseResultsPath,"heatmap-classification-PerApproach-", selectionName,".png");
            exportgraphics(f,fileName,'Resolution',300)
    
    
        end
    else

        for wptIndex = waypoints
            figure(figureNumber)
    
    
            % for selectionName = selectionNames
            %     subplot(ceil(length(selectionNames)/2),2,find(selectionNames == selectionName))
            %     bracketDistributionSelection = precentageResultsMap(selectionName);
            %     bracketDistribution = bracketDistributionSelection(wptIndex);
            % 
            %     bar(labelsClasses,bracketDistribution', 'stacked')
            %     title(append(selectionName));
            %     ax = gca; % Get current axes
            %     ax.FontSize = 18;
            % 
            % 
            % 
            % end
            % sgtitle(append("WPIndex", wptIndex))
            % f = gcf; % Get current figure handle
            % set(f, 'Position', screenSize);
            % fileName = append(baseResultsPath,"barplot-classification-PerWP", string(wptIndex),".png");
            % 
            % exportgraphics(f,fileName,'Resolution',300)
            % figureNumber = figureNumber +1;
    
    
            for selectionName = selectionNames
    
                subplot(ceil(length(selectionNames)/2),2,find(selectionNames == selectionName))
                bracketDistributionSelection = precentageResultsMap(selectionName);
                bracketDistribution = bracketDistributionSelection(wptIndex);
                heatmap(labelsClasses , labelsBrackets, bracketDistribution);
                title(append(selectionName));
                ax = gca; % Get current axes
                ax.FontSize = 18;
    
            end
            sgtitle(append("WPIndex", wptIndex))
            figureNumber = figureNumber +1;
            f = gcf; % Get current figure handle
            set(f, 'Position', screenSize);
            fileName = append(baseResultsPath,"heatmap-classification-PerWP",  string(wptIndex),".png");
            exportgraphics(f,fileName,'Resolution',300)
    
        end
    end


    % todo add saving
    % the plots should probalby be % - not the count - there is so manny
    % issues qhat is the problem in the calcuations

end