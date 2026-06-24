function displayCalculatedMetricsRelevant(vesselName, resultsPath)
    close all
    if nargin < 2 || isempty(resultsPath)
        projectRoot = fileparts(which("setupProject.m"));
        resultsPath = char(fullfile(projectRoot, "analysisResults", "experimentsData"));
    else
        resultsPath = char(resultsPath);
    end
    baseResultsPath = append(resultsPath,"/", vesselName, "/AnalysedResults/");
    vesselResultsPathBase = append(resultsPath, "/", vesselName,"/");

    
    experimentInfoMap = loadExperimentsStatus(vesselName);

    useTimedrestrictedResults = true;

    vesselInformation = loadShipSearchParameters(vesselName);
    numInitialWaypoints = vesselInformation.numWaypoints+1;
    numGenerations = 1000;

    ClassresultsPath = append(baseResultsPath,"ClassificationResults");
    load(ClassresultsPath, "selectionTypeClassification");

    filelocation = append(baseResultsPath, "/combinedResults.mat");
    load(filelocation,"approachDataMap", "experimentInfoMap", "waypointRangesMap", "combinedsolutionsMap", "approachSortedInfoMap")
    %bracketRangesMap 
    numBrackets = 5;

    filelocation = append(baseResultsPath, "/finalResults.mat");

    load(filelocation, "metrics", "metricsWithoutFullpath", "strangeExperiments")
    usePrecentage = true;

    %metricsNames = ['HV', 'IGD', 'bracketDiscanceDoint', 'bracketsTimeCount']
    %nameLatexMap = containers.Map(...
    %    {'Approach','FullWP','IncWP_KP','IncWP_Unst','IncWP_Prox','RandomSearch','IncWP_Rnd','IncWP_Kmeans', 'fitnessDistWPs','fitnessUnstable'}, ...
    %    {'$\texttt{IncSearch}$', ...
    %    '$\texttt{FullWptSearch}$', ...
    %    '$\texttt{IncSearch}_{KP}$', ...
    %    '$\texttt{IncSearch}_{Max}$', ...
    %    '$\texttt{IncSearch}_{Min}$', ...
    %    '$\texttt{RandomSearch}$', ...
    %    '$\texttt{IncSearch}_{Rnd}$', ...
    %    '$\texttt{IncSearch}_{Kmeans}$', ...
    %    '$\mathit{fit_{distWPs}}$', ...
    %    '$\mathit{fit_{unstable}}$'} ...
    %);
    nameLatexMap = containers.Map(...
        {'Approach','FullWP','IncWP_KP','IncWP_Unst','IncWP_Prox','RandomSearch','IncWP_Rnd','IncWP_Kmeans', 'fitnessDistWPs','fitnessUnstable'}, ...
        {'$\texttt{IncWP}$', ...
        '$\texttt{FullWP}$', ...
        '$\texttt{IncWP}_{KP}$', ...
        '$\texttt{IncWP}_{Unst}$', ...
        '$\texttt{IncWP}_{Prox}$', ...
        '$\texttt{RandomSearch}$', ...
        '$\texttt{IncWP}_{Rnd}$', ...
        '$\texttt{IncWP}_{Kmeans}$', ...
        '$\mathit{fit_{distWPs}}$', ...
        '$\mathit{fit_{unstable}}$'} ...
    );
    nameMapPlot = containers.Map(...
        {'FullWP','IncWP_KP','IncWP_Unst','IncWP_Prox','RandomSearch','IncWP_Rnd','IncWP_Kmeans'}, ...
        {'\fullWptSearch','\KneeSel','\IncWP_Unst','\IncWP_Prox','\RandomSearch','\IncWP_Rnd','\KmeansSel'} ...
    );

    orderOfPlots = ["FullWP", "RandomSearch", "IncWP_KP", "IncWP_Unst", "IncWP_Prox", "IncWP_Rnd" "IncWP_Kmeans" ];
    keys = {'IncWP_Unst', 'IncWP_Prox', 'IncWP_Kmeans', 'RandomSearch', 'IncWP_Rnd', 'FullWP', 'IncWP_KP'};
    values = {
        [0.00, 0.00, 0.55]; % Max (Dark Blue)
        [0.30, 0.75, 0.93]; % Min (Light Blue)
        [0.85, 0.00, 0.00]; % Kmeans (Red)
        [0.49, 0.18, 0.56]; % RandomSearch (Dark Purple)
        [0.72, 0.50, 0.85]; % IncWP_Rnd (Light Purple)
        [0.00, 0.60, 0.00]; % Full (Green)
        [0.93, 0.79, 0.00]  % Knee (Yellow)
    };
    %names = {}
    
    colorMap = containers.Map(keys, values);
    %

    
    
    % displayUniqueClusters(baseResultsPath, approachDataMap, metrics, colorMap, "clusterSize", nameLatexMap, orderOfPlots)
    % 
    % displayHVcombinedPlot(baseResultsPath,metrics, colorMap, nameLatexMap, orderOfPlots) 
    % 
    % displayDistanceSinglePlot(baseResultsPath,metrics, usePrecentage,nameLatexMap, orderOfPlots)
    % displayTimeUsage(baseResultsPath,metrics, vesselName,nameMapPlot, orderOfPlots)
    % displayTimeOnlyFirstCombinedPlot(baseResultsPath, metrics, nameLatexMap, orderOfPlots)
    % latexTimeUsagePerWaypoint(baseResultsPath, metrics, nameLatexMap, orderOfPlots, vesselName)
    % %displayTimecombinedPlot(baseResultsPath,metrics, colorMap,nameLatexMap, orderOfPlots) % old
    % displayTimePlots(baseResultsPath,metrics, colorMap,nameLatexMap, orderOfPlots) % done
    % 
    % 
    % timeUsageNoBracket(baseResultsPath, metrics, nameLatexMap, orderOfPlots, vesselName, approachSortedInfoMap) % done
    % distanceNoBracket(baseResultsPath, metrics, nameLatexMap, orderOfPlots, vesselName, approachSortedInfoMap) % done
    

    %%%%
    % %displayUniquePoints(baseResultsPath, approachDataMap, metrics)
    % 
    % %displayUniquePoints(baseResultsPath, approachDataMap, metrics, colorMap, "unique", nameMap, orderOfPlots)
    %displayUniqueClusters(baseResultsPath, approachDataMap, metrics, colorMap, "numberOfUniqueClusters", nameMap, orderOfPlots)
    %
    % 
    % %displayUniquePoints(baseResultsPath, approachDataMap, metrics, colorMap, "notInOthers",nameMap, orderOfPlots)
    % 
    
    % stat tests
    displayStatistcalTestsRandom(baseResultsPath,metrics, experimentInfoMap,orderOfPlots,vesselName, nameMapPlot)
    displayStatistcalTestsFull(baseResultsPath,metrics, experimentInfoMap,orderOfPlots, vesselName, nameMapPlot)
    %displayStatistcalTestsApproaches(baseResultsPath,metrics, experimentInfoMap,orderOfPlots, vesselName,nameLatexMap)


   


end

% KEEP 
function displayStatistcalTestsFull(baseResultsPath, metrics, experimentInfoMap, orderOfPlots, vesselName, nameMap)
    experimentInfoMap.remove('RandomSearch')
    orderOfPlots(orderOfPlots == "FullWP") = [];
    orderOfPlots(orderOfPlots == "RandomSearch") = [];
    comparedAppraochesMap = copyMap(experimentInfoMap);
   
    addColor = false; 

    leftArrowCommand = "\leftarrowapproach";
    leftArrowColorCommand = "\textcolor{red}{\leftarrowapproach}";
    

   

    resultsTransformed = [];
    approachName =  "FullWP"
    for comparedApproachNameIdx = 1:length(orderOfPlots)
        comparedApproachName = orderOfPlots(comparedApproachNameIdx);    
        singleResultsTransformed = [string(approachName) string(comparedApproachName)];
        for waypointKey = metrics.keys()
            wptIndex = waypointKey{:};
            waypointMetrics = metrics(wptIndex);
            approachName
            comparedApproachName
            StatisticalComparisonResults = waypointMetrics('StatisticalComparisonResults');
            
            currentCompersationResults = StatisticalComparisonResults(StatisticalComparisonResults(:,1)==approachName & StatisticalComparisonResults(:,2)==comparedApproachName,:)
            if isempty(currentCompersationResults)
                currentCompersationResults
                currentCompersationResults = StatisticalComparisonResults(StatisticalComparisonResults(:,1)==comparedApproachName & StatisticalComparisonResults(:,2)==approachName,:)


            end
            %currentCompersationResults
            currentCompersationResults(3:end)
            singleResultsTransformed = [singleResultsTransformed currentCompersationResults(3:end)]
            
        end
        singleResultsTransformed
        tempresultsTransformed = resultsTransformed
        resultsTransformed = [resultsTransformed; singleResultsTransformed];

    end


    
    

    filename = append(baseResultsPath,"/plots/HV/","StatisticalTestsFullWPset.tex");

    fid = fopen(filename, 'w');
    vesselNameLength = size(resultsTransformed,1)

    %fprintf(fid, '\\begin{tabular}{ll');  % 2 left-aligned text columns
    %for w = 2:(length(metrics.keys)+1)
    %    fprintf(fid, 'r');                % numeric columns for waypoints
    %end
    %fprintf(fid, '}\n');
    %fprintf(fid, '\\toprule\n');
    %fprintf(fid, 'Approach Left & Approach Right');
    %for w = 2:(length(metrics.keys)+1)
    %    fprintf(fid, ' & \\waypointGenericIndex{%d}', w);
    %end
    
    %fprintf(fid, ' \\\\ \n');
    
    if vesselName == "remus100"
        vesselText = append("\multirow{", string(vesselNameLength), "}{4em}{\resmus} ")
    elseif vesselName == "nspauv"
        vesselText = append("\multirow{", string(vesselNameLength), "}{4em}{\nspauv} ")
    elseif vesselName == "mariner"
        vesselText = append("\multirow{", string(vesselNameLength), "}{4em}{\mariner} ")

    end

    
    % change strugyure 
    comparedAppraochesMap = experimentInfoMap

    [rowsComaprisation, columsComparisation] = size(resultsTransformed);
    for row = 1:rowsComaprisation
        lineComparisonResults = resultsTransformed(row,:);
        approachLeft = lineComparisonResults(1);
        approachRight = lineComparisonResults(2);
        resultsComperisation = lineComparisonResults(3:end);
        approachLeftLatex = nameMap(approachLeft);
        approachLeftLatex = char(approachLeftLatex);
        approachLeftLatex = string(strrep(approachLeftLatex, '_', '\_'));
        approachRightLatex = nameMap(approachRight);
        approachRightLatex = char(approachRightLatex);
        approachRightLatex = string(strrep(approachRightLatex, '_', '\_'));
        
        if row == 1
            latexText = [vesselText,approachLeftLatex, approachRightLatex];

        else 
            latexText = ["&" approachLeftLatex, approachRightLatex];
        end
        for waypointCompersiationIndex = 1:3:size(resultsComperisation,2)
            waypointCompersiation = resultsComperisation(waypointCompersiationIndex:(waypointCompersiationIndex+2));
            pValue = waypointCompersiation(1);
            a12value = str2double(waypointCompersiation(2));
            chosenApproach = waypointCompersiation(3);
            if chosenApproach ~= "ND"
                if (a12value > 0.44 &&  a12value < 0.56)
                    latexStength = "\Negligible";
                elseif (a12value > 0.34 &&  a12value <= 0.44) || (a12value >= 0.56 &&  a12value < 0.64) 
                    latexStength = "\SmallEffect";
                elseif (a12value > 0.29 &&  a12value <= 0.34) || (a12value >= 0.64 &&  a12value < 0.71) 
                    latexStength = "\MediumEffect";
                elseif (a12value >= 0 &&  a12value <= 0.29) || (a12value >= 0.71 &&  a12value <= 1) 
                    latexStength = "\LargeEffect";
                end
            else
                latexStength = "";
            end
            if chosenApproach == approachLeft
                if addColor
                    latexApproach = leftArrowColorCommand;
                else
                    latexApproach = leftArrowCommand;
                end
            elseif chosenApproach == approachRight
                latexApproach = "\rightarrowapproach";
            elseif chosenApproach == "ND"
                latexApproach = "\noDifference";
            end
            latexText= [latexText append(latexApproach, latexStength)];


        end
        
        % write latex to text
        fprintf(fid, '%s', latexText{1});     % first column

        if row > 1
            fprintf(fid, ' %s', latexText{2});
            for c = 3:numel(latexText)
                fprintf(fid, ' & %s', latexText{c});
            end
        else
            for c = 2:numel(latexText)
                fprintf(fid, ' & %s', latexText{c});
            end
        end
        
        if row ~= rowsComaprisation
            fprintf(fid, ' \\\\ \n');
        else
            fprintf(fid, ' \n');
        end
       
        
    
    end


    %fprintf(fid, '\\bottomrule\n');
    %fprintf(fid, '\\end{tabular}\n');
    
    fclose(fid);

end

% KEEP 
function displayStatistcalTestsRandom(baseResultsPath,metrics, experimentInfoMap,orderOfPlots, vesselName, nameMap)
    experimentInfoMap.remove('FullWP')
    orderOfPlots(orderOfPlots == "FullWP") = [];
    orderOfPlots(orderOfPlots == "RandomSearch") = [];
    comparedAppraochesMap = copyMap(experimentInfoMap);

    addColor = false; 

    leftArrowCommand = "\leftarrowapproach";
    leftArrowColorCommand = "\textcolor{red}{\leftarrowapproach}";
    

   

    resultsTransformed = [];
    approachName =  "RandomSearch"
    for comparedApproachNameIdx = 1:length(orderOfPlots)
        comparedApproachName = orderOfPlots(comparedApproachNameIdx);    
        singleResultsTransformed = [string(approachName) string(comparedApproachName)];
        for waypointKey = metrics.keys()
            wptIndex = waypointKey{:};
            waypointMetrics = metrics(wptIndex);
            StatisticalComparisonResults = waypointMetrics('StatisticalComparisonResults');
            approachName
            comparedApproachName
            currentCompersationResults = StatisticalComparisonResults(StatisticalComparisonResults(:,1)==approachName & StatisticalComparisonResults(:,2)==comparedApproachName,:)
            if isempty(currentCompersationResults)
                currentCompersationResults
                currentCompersationResults = StatisticalComparisonResults(StatisticalComparisonResults(:,1)==comparedApproachName & StatisticalComparisonResults(:,2)==approachName,:)


            end
            %currentCompersationResults
            currentCompersationResults(3:end)
            singleResultsTransformed = [singleResultsTransformed currentCompersationResults(3:end)]
            
        end
        singleResultsTransformed
        tempresultsTransformed = resultsTransformed
        resultsTransformed = [resultsTransformed; singleResultsTransformed];

    end


    
    

    filename = append(baseResultsPath,"/plots/HV/","StatisticalTestsRandom.tex");

    fid = fopen(filename, 'w');
    vesselNameLength = size(resultsTransformed,1)

    %fprintf(fid, '\\begin{tabular}{ll');  % 2 left-aligned text columns
    %for w = 2:(length(metrics.keys)+1)
    %    fprintf(fid, 'r');                % numeric columns for waypoints
    %end
    %fprintf(fid, '}\n');
    %fprintf(fid, '\\toprule\n');
    %fprintf(fid, 'Approach Left & Approach Right');
    %for w = 2:(length(metrics.keys)+1)
    %    fprintf(fid, ' & \\waypointGenericIndex{%d}', w);
    %end
    
    %fprintf(fid, ' \\\\ \n');
    
    if vesselName == "remus100"
        vesselText = append("\multirow{", string(vesselNameLength), "}{4em}{\resmus} ")
    elseif vesselName == "nspauv"
        vesselText = append("\multirow{", string(vesselNameLength), "}{4em}{\nspauv} ")
    elseif vesselName == "mariner"
        vesselText = append("\multirow{", string(vesselNameLength), "}{4em}{\mariner} ")

    end

    
    % change strugyure 
    comparedAppraochesMap = experimentInfoMap

    [rowsComaprisation, columsComparisation] = size(resultsTransformed);
    for row = 1:rowsComaprisation
        lineComparisonResults = resultsTransformed(row,:);
        approachLeft = lineComparisonResults(1);
        approachRight = lineComparisonResults(2);
        resultsComperisation = lineComparisonResults(3:end);
        approachLeftLatex = nameMap(approachLeft);
        approachLeftLatex = char(approachLeftLatex);
        approachLeftLatex = strrep(approachLeftLatex, '_', '\_');
        approachRightLatex = nameMap(approachRight);
        approachRightLatex = char(approachRightLatex);
        approachRightLatex = strrep(approachRightLatex, '_', '\_');
        if row == 1
            latexText = [vesselText,approachLeftLatex, approachRightLatex];

        else 
            latexText = ["&" approachLeftLatex, approachRightLatex];
        end
        for waypointCompersiationIndex = 1:3:size(resultsComperisation,2)
            waypointCompersiation = resultsComperisation(waypointCompersiationIndex:(waypointCompersiationIndex+2));
            pValue = waypointCompersiation(1);
            a12value = str2double(waypointCompersiation(2));
            chosenApproach = waypointCompersiation(3);
            if chosenApproach ~= "ND"
                if (a12value > 0.44 &&  a12value < 0.56)
                    latexStength = "\Negligible"
                elseif (a12value > 0.34 &&  a12value <= 0.44) || (a12value >= 0.56 &&  a12value < 0.64) 
                    latexStength = "\SmallEffect"
                elseif (a12value > 0.29 &&  a12value <= 0.34) || (a12value >= 0.64 &&  a12value < 0.71) 
                    latexStength = "\MediumEffect"
                elseif (a12value >= 0 &&  a12value <= 0.29) || (a12value >= 0.71 &&  a12value <= 1) 
                    latexStength = "\LargeEffect"
                end
            else
                latexStength = ""
            end
            if chosenApproach == approachLeft
                if addColor
                    latexApproach = leftArrowColorCommand;
                else
                    latexApproach = leftArrowCommand;
                end
            elseif chosenApproach == approachRight
                latexApproach = "\rightarrowapproach";
            elseif chosenApproach == "ND"
                latexApproach = "\noDifference";
            end
            latexText= [latexText append(latexApproach, latexStength)];


        end
        
        % write latex to text
        fprintf(fid, '%s', latexText{1});     % first column

        if row > 1
            fprintf(fid, ' %s', latexText{2});
            for c = 3:numel(latexText)
                fprintf(fid, ' & %s', latexText{c});
            end
        else
            for c = 2:numel(latexText)
                fprintf(fid, ' & %s', latexText{c});
            end
        end
        
        if row ~= rowsComaprisation
            fprintf(fid, ' \\\\ \n');
        else
            fprintf(fid, ' \n');
        end
       
        
    
    end


    %fprintf(fid, '\\bottomrule\n');
    %fprintf(fid, '\\end{tabular}\n');
    
    fclose(fid);

end

% KEEP 
function displayStatistcalTestsApproaches(baseResultsPath,metrics, experimentInfoMap,orderOfPlots, vesselName,nameMap)
    experimentInfoMap.remove('FullWP')
    experimentInfoMap.remove('RandomSearch')
    comparedAppraochesMap = copyMap(experimentInfoMap);

   

    for waypointKey = metrics.keys()
        wptIndex = waypointKey{:};
        waypointMetrics = metrics(wptIndex);
        StatisticalComparisonResults = ('StatisticalComparwaypointMetricsisonResults')
        StatisticalComparisonResults
    end

    resultsTransformed = [];
    for approachNameKey = experimentInfoMap.keys
        approachName = approachNameKey{:};
        comparedAppraochesMap.remove(approachName)

        for comparedApproachNameKey = comparedAppraochesMap.keys
            comparedApproachName = comparedApproachNameKey{:};    
            singleResultsTransformed = [string(approachName) string(comparedApproachName)];
            for waypointKey = metrics.keys()
                wptIndex = waypointKey{:};
                waypointMetrics = metrics(wptIndex);
                StatisticalComparisonResults = waypointMetrics('StatisticalComparisonResults');
                approachName
                comparedApproachName
                currentCompersationResults = StatisticalComparisonResults(StatisticalComparisonResults(:,1)==approachName & StatisticalComparisonResults(:,2)==comparedApproachName,:)
                if isempty(currentCompersationResults)
                    currentCompersationResults
                end
                %currentCompersationResults
                currentCompersationResults(3:end)
                singleResultsTransformed = [singleResultsTransformed currentCompersationResults(3:end)]
                
            end
            resultsTransformed = [resultsTransformed; singleResultsTransformed];

        end


    end
    resultsTransformed
    

    filename = append(baseResultsPath,"/plots/HV/","StatisticalTestsApproaches.tex");

    fid = fopen(filename, 'w');
    vesselNameLength = size(resultsTransformed,1)


    N = 7;  % or whatever

    % fprintf(fid, '\\begin{tabular}{ll');  % 2 left-aligned text columns
    % for w = 2:(length(metrics.keys)+1)
    %     fprintf(fid, 'r');                % numeric columns for waypoints
    % end
    % fprintf(fid, '}\n');
    % fprintf(fid, '\\toprule\n');
    % fprintf(fid, 'Approach Left & Approach Right');
    % for w = 2:(length(metrics.keys)+1)
    %     fprintf(fid, ' & \\waypointGenericIndex{%d}', w);
    % end
    % 
    % fprintf(fid, ' \\\\ \\midrule\n');
    if vesselName == "remus100"
        vesselText = append("\multirow{", string(vesselNameLength), "}{4em}{\resmus} ");
    elseif vesselName == "nspauv"
        vesselText = append("\multirow{", string(vesselNameLength), "}{4em}{\nspauv} ");
    elseif vesselName == "mariner"
        vesselText = append("\multirow{", string(vesselNameLength), "}{4em}{\mariner} ");

    end

    
    % change strugyure 
    comparedAppraochesMap = experimentInfoMap

    [rowsComaprisation, columsComparisation] = size(resultsTransformed);
    for row = 1:rowsComaprisation
        lineComparisonResults = resultsTransformed(row,:);
        approachLeft = lineComparisonResults(1);
        approachRight = lineComparisonResults(2);
        resultsComperisation = lineComparisonResults(3:end);
        %latexText = [approachLeft, approachRight];
        approachLeftLatex = nameMap(approachLeft);
        approachLeftLatex = char(approachLeftLatex);
        approachLeftLatex = strrep(approachLeftLatex, '_', '\_');
        approachRightLatex = nameMap(approachRight);
        approachRightLatex = char(approachRightLatex);
        approachRightLatex = strrep(approachRightLatex, '_', '\_');
        if row == 1
            latexText = [vesselText,approachLeftLatex, approachRightLatex];

        else 
            latexText = ["&" approachLeftLatex, approachRightLatex];
        end
        for waypointCompersiationIndex = 1:3:size(resultsComperisation,2)
            waypointCompersiation = resultsComperisation(waypointCompersiationIndex:(waypointCompersiationIndex+2));
            pValue = waypointCompersiation(1);
            a12value = str2double(waypointCompersiation(2));
            chosenApproach = waypointCompersiation(3);
            if chosenApproach ~= "ND"
                if (a12value > 0.44 &&  a12value < 0.56)
                    latexStength = "\Negligible"
                elseif (a12value > 0.34 &&  a12value <= 0.44) || (a12value >= 0.56 &&  a12value < 0.64) 
                    latexStength = "\SmallEffect"
                elseif (a12value > 0.29 &&  a12value <= 0.34) || (a12value >= 0.64 &&  a12value < 0.71) 
                    latexStength = "\MediumEffect"
                elseif (a12value >= 0 &&  a12value <= 0.29) || (a12value >= 0.71 &&  a12value <= 1) 
                    latexStength = "\LargeEffect"
                end
            else
                latexStength = ""
            end
            if chosenApproach == approachLeft
                latexApproach = "\leftarrowapproach"
            elseif chosenApproach == approachRight
                latexApproach = "\rightarrowapproach"
            elseif chosenApproach == "ND"
                latexApproach = "\noDifference";

            end
            latexText= [latexText append(latexApproach, latexStength)];


        end
        
        % write latex to text
        % fprintf(fid, '%s', latexText{1});     % first column
        % 
        % for c = 2:numel(latexText)
        %     fprintf(fid, ' & %s', latexText{c});
        % end
        % 
        % fprintf(fid, ' \\\\ \n');

        fprintf(fid, '%s', latexText{1});     % first column

        if row > 1
            fprintf(fid, ' %s', latexText{2});
            for c = 3:numel(latexText)
                fprintf(fid, ' & %s', latexText{c});
            end
        else
            for c = 2:numel(latexText)
                fprintf(fid, ' & %s', latexText{c});
            end
        end
        
        if row ~= rowsComaprisation
            fprintf(fid, ' \\\\ \n');
        else
            fprintf(fid, ' \n');
        end
       
        
    
    end


    %fprintf(fid, '\\bottomrule\n');
    %fprintf(fid, '\\end{tabular}\n');
    
    fclose(fid);

end

% KEEP 
function displayHVcombinedPlot(baseResultsPath, metrics, colorMap, nameMap, orderOfPlots)

    % ------------------------------------------------------------
    % Plot parameters
    % ------------------------------------------------------------
    numCols = 3;

    figurePosition = [2, 2, 80, 25];
    %figurePosition = [2, 2, 100, 28];
    figureBackgroundColor = 'w';

    tileSpacing = 'compact';
    tilePadding = 'compact';

    boxFaceAlpha = 0.45;
    boxLineWidth = 2; %1.5;
    boxWidth = 0.7; %0.65;
    markerStyle = 'o';
    markerSize = 6;

    titleFontSize = 22;
    titleFontWeight = 'bold';

    %axisFontSize = 14;   % not too big, not too small
    %axisTickInterpreter = 'latex';

    %staggeredLabelFontSize = 18;
    %bottomAxisExpansion = 0.10;        % space below plot
    %staggeredLabelYOffset = 0.015;     % distance from axis
    %staggeredLabelSecondRowOffset = 0.03; % spacing between rows
    axisFontSize = 20;

    ylabelText = 'Hypervolume';
    ylabelFontSize = 24;
    ylabelFontWeight = 'bold';

    legendOrientation = 'horizontal';
    legendInterpreter = 'latex';
    legendTileLocation = 'south';
    legendFontSize = 28;
    legendBox = 'off';

    legendItemTokenSize = [50, 28];


    %finalFontSize = 25;

    exportResolution = 300;
    exportFolder = "/plots/HV/";
    exportFileName = "boxPlotHV.png";

    % ------------------------------------------------------------
    % Collect HV data
    % ------------------------------------------------------------
    metricKeys = metrics.keys();
    numPlots = length(metricKeys);

    dataCell = cell(1, numPlots);
    plotTitles = cell(1, numPlots);

    orderedColors = [];
    names = {};
    addedNames = false;

    

    for waypointIdx = 1:numPlots
        wptIndex = metricKeys{waypointIdx};
        waypointMetrics = metrics(wptIndex);

        if isKey(waypointMetrics, 'StatisticalComparisonResults')
            waypointMetrics.remove('StatisticalComparisonResults');
        end

        waypointHV = [];

        for approachIdx = 1:length(orderOfPlots)
            approachName = orderOfPlots(approachIdx);
            approachMetric = waypointMetrics(approachName);
            approachHV = approachMetric("HV");

            waypointHV = [waypointHV; approachHV'];

            if ~addedNames
                names{end+1} = string(nameMap(approachName));
                orderedColors = [orderedColors; colorMap(approachName)];
            end
        end

        addedNames = true;

        dataCell{waypointIdx} = waypointHV;
        plotTitles{waypointIdx} = append("Waypoint ", wptIndex);
    end

    numApproaches = size(dataCell{1}, 1);

    % ------------------------------------------------------------
    % Figure and layout
    % ------------------------------------------------------------
    numRows = ceil(numPlots / numCols);

    figure('Units', 'centimeters', ...
        'Position', figurePosition, ...
        'Color', figureBackgroundColor);

    t = tiledlayout(2, ceil(numPlots / 2), ...
        'TileSpacing', tileSpacing, ...
        'Padding', tilePadding);

    axHandles = gobjects(1, numPlots);
    legendHandles = gobjects(1, numApproaches);

    % ------------------------------------------------------------
    % Plot each waypoint
    % ------------------------------------------------------------
    for plotIdx = 1:numPlots
        axHandles(plotIdx) = nexttile;
        hold on;

        currentMatrix = dataCell{plotIdx};

        for approachIdx = 1:numApproaches
            approachData = currentMatrix(approachIdx, :)';

            b = boxchart(approachIdx * ones(size(approachData)), approachData);            

            thisColor = orderedColors(approachIdx, :);

            b.BoxFaceColor = thisColor;
            b.BoxFaceAlpha = boxFaceAlpha;
            b.BoxEdgeColor = thisColor;
            b.WhiskerLineColor = thisColor;
            b.MarkerColor = thisColor;

            b.LineWidth = boxLineWidth;
            b.BoxWidth = boxWidth;
            b.MarkerStyle = markerStyle;
            b.MarkerSize = markerSize;

            if plotIdx == 1
                legendHandles(approachIdx) = b;
            end
        end


        % --------------------------------------------------------
        % Axis formatting
        % --------------------------------------------------------
        title(plotTitles{plotIdx}, ...
            'FontSize', titleFontSize, ...
            'FontWeight', titleFontWeight);

        xticks(1:numApproaches);
        xlim([0.5, numApproaches + 0.5]);
        %xlim([spacing/2, spacing * numApproaches + spacing/2]);
        grid on;
        box on;

        xticks(1:numApproaches);

        %isBottomRow = plotIdx > numCols * (numRows - 1);
        
        %if isBottomRow
            %xticklabels(names);
        %    xticklabels({});

        %else
        %    xticklabels({});
        %end
        xticklabels({});

        ax = gca;
        ax.YAxis.FontSize = axisFontSize;
        ax.XAxis.FontSize = axisFontSize;  % optional, keep consistent

        
        %ax = gca;
        %ax.FontSize = axisFontSize;
        %ax.TickLabelInterpreter = axisTickInterpreter;
        %xtickangle(0);
    end

    % ------------------------------------------------------------
    % Shared labels and legend
    % ------------------------------------------------------------
    ylabel(t, ylabelText, ...
        'FontSize', ylabelFontSize, ...
        'FontWeight', ylabelFontWeight);

    lgd = legend(legendHandles, names, ...
    'Orientation', legendOrientation, ...
    'Interpreter', legendInterpreter);

    lgd.Layout.Tile = legendTileLocation;
    
    lgd.FontSize = legendFontSize;
    lgd.NumColumns = numApproaches;   % force single row
    lgd.ItemTokenSize = legendItemTokenSize;
    
    lgd.Box = legendBox;

    % ------------------------------------------------------------
    % Final formatting and export
    % ------------------------------------------------------------
    %set(findall(gcf, '-property', 'FontSize'), 'FontSize', finalFontSize);

    fileName = append(baseResultsPath, exportFolder, exportFileName);
    exportgraphics(gcf, fileName, 'Resolution', exportResolution);

end

function displayTimePlots(baseResultsPath, metrics, colorMap, namesMap, orderOfPlots)

    orderOfPlots(orderOfPlots == "RandomSearch") = [];

    metricKeys = metrics.keys();
    numPlots = length(metricKeys);

    dataCell = cell(1, numPlots);
    plotTitles = cell(1, numPlots);

    accumulatedTimeMap = containers.Map();

    orderedColors = [];
    names = {};
    addedNames = false;

    for waypointIdx = 1:numPlots
        wptIndex = metricKeys{waypointIdx};
        waypointMetrics = metrics(wptIndex);

        if isKey(waypointMetrics, 'StatisticalComparisonResults')
            waypointMetrics.remove('StatisticalComparisonResults');
        end

        timeUsage = [];

        for approachIdx = 1:length(orderOfPlots)
            approachName = orderOfPlots(approachIdx);
            approachMetric = waypointMetrics(approachName);

            wayPointTimeInfo = approachMetric("wayPointTimeInfo");
            approachTimeExperiments = wayPointTimeInfo("approachTimeExperiments");

            if size(approachTimeExperiments,2) > 30
                approachTimeExperiments = approachTimeExperiments(:,1:30);
            end

            finalTimes = approachTimeExperiments(end,:);

            if approachName ~= "FullWP"
                timeUsage = [timeUsage finalTimes'];

                if ~addedNames
                    names{end+1} = char(namesMap(approachName));
                    orderedColors = [orderedColors; colorMap(approachName)];
                end
            end

            if isKey(accumulatedTimeMap, approachName)
                accumulated = accumulatedTimeMap(approachName);
            else
                accumulated = zeros(size(finalTimes));
            end

            if approachName ~= "FullWP"
                accumulated = accumulated + finalTimes/60;
            else
                accumulated = finalTimes/60;
            end

            accumulatedTimeMap(approachName) = accumulated;
        end

        addedNames = true;

        dataCell{waypointIdx} = (timeUsage/60)';
        plotTitles{waypointIdx} = append("Waypoint ", wptIndex);
    end

    plotTimePerWaypointBoxplots(baseResultsPath, dataCell, plotTitles, names, orderedColors);
    plotTotalTimeBoxplot(baseResultsPath, accumulatedTimeMap, colorMap, namesMap);

end

function plotTimePerWaypointBoxplots(baseResultsPath, dataCell, plotTitles, names, orderedColors)

    numCols = 3;

    figurePosition = [2, 2, 80, 25];
    axisFontSize = 20;

    boxFaceAlpha = 0.45;
    boxLineWidth = 2;
    boxWidth = 0.7;
    markerSize = 6;

    legendFontSize = 28;
    legendItemTokenSize = [50, 28];

    numPlots = length(dataCell);
    numApproaches = size(dataCell{1},1);
    numRows = ceil(numPlots / numCols);

    figure('Units','centimeters','Position',figurePosition,'Color','w');

    t = tiledlayout(numRows, numCols, 'TileSpacing','compact','Padding','compact');

    legendHandles = gobjects(1,numApproaches);

    for plotIdx = 1:numPlots
        nexttile;
        hold on;

        currentMatrix = dataCell{plotIdx};

        for i = 1:numApproaches
            data = currentMatrix(i,:)';
            b = boxchart(i * ones(size(data)), data);

            c = orderedColors(i,:);

            b.BoxFaceColor = c;
            b.BoxFaceAlpha = boxFaceAlpha;
            b.BoxEdgeColor = c;
            b.WhiskerLineColor = c;
            b.MarkerColor = c;

            b.LineWidth = boxLineWidth;
            b.BoxWidth = boxWidth;
            b.MarkerSize = markerSize;

            if plotIdx == 1
                legendHandles(i) = b;
            end
        end

        title(plotTitles{plotIdx}, 'FontSize', 22, 'FontWeight','bold');

        xticks(1:numApproaches);
        xlim([0.5, numApproaches+0.5]);
        xticklabels({});

        grid on; box on;

        ax = gca;
        ax.YAxis.FontSize = axisFontSize;
        ax.XAxis.FontSize = axisFontSize;
    end

    ylabel(t,'Time in min','FontSize',24,'FontWeight','bold');

    lgd = legend(legendHandles, names, ...
        'Orientation','horizontal','Interpreter','latex');

    lgd.Layout.Tile = 'south';
    lgd.FontSize = legendFontSize;
    lgd.NumColumns = numApproaches;
    lgd.ItemTokenSize = legendItemTokenSize;
    lgd.Box = 'off';

    exportgraphics(gcf, append(baseResultsPath,"/plots/Time/boxPlotTimeWP.png"), 'Resolution',300);

end


function plotTotalTimeBoxplot(baseResultsPath, accumulatedTimeMap, colorMap, namesMap)

    axisFontSize = 20;
    legendFontSize = 28;
    legendItemTokenSize = [50,28];

    keysList = accumulatedTimeMap.keys();

    matrix = [];
    names = {};
    colors = [];

    for i = 1:length(keysList)
        k = keysList{i};
        matrix = [matrix; accumulatedTimeMap(k)];
        names{end+1} = char(namesMap(k));
        colors = [colors; colorMap(k)];
    end

    numApproaches = size(matrix,1);

    figure('Units','centimeters','Position',[2,2,50,25],'Color','w');
    hold on;

    legendHandles = gobjects(1,numApproaches);

    for i = 1:numApproaches
        data = matrix(i,:)';
        b = boxchart(i * ones(size(data)), data);

        c = colors(i,:);

        b.BoxFaceColor = c;
        b.BoxFaceAlpha = 0.45;
        b.BoxEdgeColor = c;
        b.WhiskerLineColor = c;
        b.MarkerColor = c;

        b.LineWidth = 2;
        b.BoxWidth = 0.7;
        b.MarkerSize = 6;

        legendHandles(i) = b;
    end

    ylabel('Time in min','FontSize',24,'FontWeight','bold');

    xticks(1:numApproaches);
    xlim([0.5, numApproaches+0.5]);
    xticklabels({});

    grid on; box on;

    ax = gca;
    ax.YAxis.FontSize = axisFontSize;
    ax.XAxis.FontSize = axisFontSize;

    lgd = legend(legendHandles, names, ...
        'Orientation','horizontal','Interpreter','latex');

    lgd.Location = 'southoutside';
    lgd.FontSize = legendFontSize;
    lgd.NumColumns = numApproaches;
    lgd.ItemTokenSize = legendItemTokenSize;
    lgd.Box = 'off';

    exportgraphics(gcf, append(baseResultsPath,"/plots/Time/boxPlotTimeAll.png"), 'Resolution',300);

end

% KEEP x2
function displayTimecombinedPlotOld(baseResultsPath, metrics, colorMap, namesMap, orderOfPlots)

    % Remove RandomSearch from time plots
    orderOfPlots(orderOfPlots == "RandomSearch") = [];

    % ------------------------------------------------------------
    % Collect time data
    % ------------------------------------------------------------
    metricKeys = metrics.keys();
    numPlots = length(metricKeys);

    dataCell = cell(1, numPlots);
    plotTitles = cell(1, numPlots);

    accumulatedTimeMap = containers.Map();

    orderedColors = [];
    names = {};
    addedNames = false;

    for waypointIdx = 1:numPlots
        wptIndex = metricKeys{waypointIdx};
        waypointMetrics = metrics(wptIndex);

        if isKey(waypointMetrics, 'StatisticalComparisonResults')
            waypointMetrics.remove('StatisticalComparisonResults');
        end

        timeUsage = [];

        for approachIdx = 1:length(orderOfPlots)
            approachName = orderOfPlots(approachIdx);
            approachMetric = waypointMetrics(approachName);

            wayPointTimeInfo = approachMetric("wayPointTimeInfo");
            approachTimeExperiments = wayPointTimeInfo("approachTimeExperiments");

            if size(approachTimeExperiments, 2) > 30
                approachTimeExperiments = approachTimeExperiments(:, 1:30);
            end

            finalWaypointTimes = approachTimeExperiments(end, :);

            if approachName ~= "FullWP"
                timeUsage = [timeUsage finalWaypointTimes'];

                if ~addedNames
                    names{end+1} = char(namesMap(approachName));
                    orderedColors = [orderedColors; colorMap(approachName)];
                end
            end

            if isKey(accumulatedTimeMap, approachName)
                accumulatedTime = accumulatedTimeMap(approachName);
            else
                accumulatedTime = zeros(size(finalWaypointTimes));
            end

            if approachName ~= "FullWP"
                accumulatedTime = accumulatedTime + finalWaypointTimes / 60;
            else
                accumulatedTime = finalWaypointTimes / 60;
            end

            accumulatedTimeMap(approachName) = accumulatedTime;
        end

        addedNames = true;

        dataCell{waypointIdx} = (timeUsage / 60)';
        plotTitles{waypointIdx} = append("Waypoint ", wptIndex);
    end

    % ------------------------------------------------------------
    % Create plots
    % ------------------------------------------------------------
    plotTimePerWaypoint(baseResultsPath, dataCell, plotTitles, names, orderedColors);

    plotTimeAccumulated(baseResultsPath, accumulatedTimeMap, colorMap, namesMap);

end

function displayTimecombinedPlotPrev(baseResultsPath,metrics, colorMap, namesMap, orderOfPlots)
    orderOfPlots(orderOfPlots == "RandomSearch") = [];
    %orderOfPlots(orderOfPlots == "FullWP") = [];

    accomuatedTimeMap = containers.Map();

    orderedColors = [];
    plotTitles = {};
    HVcellindex = 1;
    names = {};
    addedNames = false;
    for waypointKey = metrics.keys()
        wptIndex = waypointKey{:};
        waypointMetrics = metrics(wptIndex);
        timeUsage = [];
        waypointMetrics.remove('StatisticalComparisonResults');
        %for approachKey = waypointMetrics.keys()
        for approachIdx =  1:length(orderOfPlots) 
            
            %appraochName = approachKey{:};
            appraochName = orderOfPlots(approachIdx); %approachKey{:};
            appraochMetric = waypointMetrics(appraochName);

            wayPointTimeInfo = appraochMetric("wayPointTimeInfo");
            exNums = wayPointTimeInfo('exNums');
            
            approachTimeExperiments = wayPointTimeInfo('approachTimeExperiments');
            if appraochName ~= "FullWP"
                
                if size(approachTimeExperiments(end,:),2) > 30
                    approachTimeExperiments = approachTimeExperiments(:,1:30)
                end
                size(approachTimeExperiments(end,:))
                %approachNamesPlot{end+1} = appraochName
                timeUsage = [timeUsage approachTimeExperiments(end,:)'];
                %namesPlot = [namesPlot; appraochName];
                if addedNames == false
                    names{end+1} = appraochName;
                    orderedColors = [orderedColors; colorMap(appraochName)];
    
                end
            end

            if isKey(accomuatedTimeMap,appraochName)
                accomuatedTime = accomuatedTimeMap(appraochName);
            else
                accomuatedTime = zeros(size(approachTimeExperiments(end,:)));
            end

            if appraochName ~= "FullWP"
                accomuatedTime = accomuatedTime + (approachTimeExperiments(end,:))/60;
            else
                accomuatedTime = approachTimeExperiments(end,:)/60;
            end
            %accomuatedTime = accomuatedTime;
            accomuatedTimeMap(appraochName) = accomuatedTime;

            
        end
        addedNames = true;
        
        timeUsage = timeUsage/60;
        dataCell{HVcellindex} = timeUsage';
        
        plotTitles{end+1} = append("Waypoint ", wptIndex);
        HVcellindex = HVcellindex +1;

    end
    numApproaches = size(dataCell{1},1);
    for n = 1:length(names)
        currentName = names(n);
        latexName = char(namesMap(currentName{:}));
        names(n) = {latexName};
    end
    
    %figure('Color', 'w', 'Position', [100, 100, 625, 490]);
    %figure('Units', 'centimeters', 'Position', [1, 1, 45, 25], 'Color', 'w');
    figure('Units', 'centimeters', 'Position', [2, 2, 50, 20], 'Color', 'w');
    t = tiledlayout(ceil(length(metrics.keys())/2), 2, 'TileSpacing', 'compact', 'Padding', 'compact');
    
    axHandles = gobjects(1, length(metrics.keys()));
    legendHandles = gobjects(1, numApproaches); 
    plotTitles{end+1} = append("Waypoint ", wptIndex);

    
    for plotIdx = 1:length(metrics.keys())
        
        axHandles(plotIdx) = nexttile;
        hold on;
        
        currentMatrix = dataCell{plotIdx}; 
        [nApproaches, nRuns] = size(currentMatrix);
        
        % --- PLOT LOOP (The "Centered & Wide" Method) ---
        for i = 1:numApproaches
            % Extract data for approach 'i'
            approachData = currentMatrix(i, :)';
            
            % Plot at exact integer position X = i
            b = boxchart(i * ones(size(approachData)), approachData);
            
            % --- COLORING & STYLING ---
            thisColor = orderedColors(i, :);
            
            % Fill
            b.BoxFaceColor = thisColor;
            b.BoxFaceAlpha = 0.4;          % Transparent enough to see lines
            
            % Lines (Matching Color)
            b.BoxEdgeColor = thisColor;    % Outline + Median
            b.WhiskerLineColor = thisColor;
            b.MarkerColor = thisColor;
            
            % Sizes
            b.LineWidth = 1.5;
            b.BoxWidth = 0.65;             % Nice and wide
            b.MarkerStyle = 'o';
            b.MarkerSize = 4;
            
            % Save handles from the FIRST plot only (for the Legend later)
            if plotIdx == 1
                legendHandles(i) = b;
            end
        end
        
        % --- SUBPLOT FORMATTING ---
        title(plotTitles{plotIdx}, 'FontSize', 11, 'FontWeight', 'bold');
        xticks(1:numApproaches);
        grid on;
        box on; % Adds the black square frame around the plot
        
        % LOGIC: Only show X-Labels on the bottom row (Plots 5 and 6)
        if plotIdx < (length(metrics.keys()) -1)
            xticklabels({}); % Remove labels for R1, R2, R3, R4
            set(gca, 'TickLabelInterpreter', 'latex');

        else
            xticklabels(names) %, 'Interpreter','latex'); % Keep labels for R5, R6
            xtickangle(0);     % Angle them slightly if they overlap
            set(gca, 'TickLabelInterpreter', 'latex');
        end
        
        % Optional: Standardize Y-Axis limits if data ranges are similar
        % ylim([0 5]); 
    end

    % nexttile([1 2]); 
    
    % hold on;
    %legendHandles = gobjects(1, numApproaches); 
    
    %for i = 1:numApproaches
    %    data = currentMatrix(i, :)';
    %    b = boxchart(i * ones(size(data)), data);
    
    %    legendHandles(i) = b;
    %    thisColor = orderedColors(i, :);
    %    set(b, 'BoxFaceColor', thisColor, 'BoxFaceAlpha', 0.4, ...
    %           'BoxEdgeColor', thisColor, 'WhiskerLineColor', thisColor, ...
    %           'MarkerColor', thisColor, 'LineWidth', 1.5, 'BoxWidth', 0.6);
    %end
    
    %title('Set of waypoints', 'FontSize', 10);
    %grid on; box on;
    
    %xticks(1:length(names));
    %xticklabels(names); 
    %xtickangle(0);
    
    ylabel(t, 'Time in min', 'FontSize', 14, 'FontWeight', 'bold');
    

    lgd = legend(legendHandles, names, 'Orientation', 'horizontal', 'Interpreter','latex');
    lgd.Layout.Tile = 'south'; 
    lgd.FontSize = 10;
    lgd.Box = 'off';

    % Add this at the very end of your script to scale text up
    set(findall(gcf, '-property', 'FontSize'), 'FontSize', 11.3);

    %set(gca, 'TickLabelInterpreter', 'latex');
    fileName = append(baseResultsPath,"/plots/Time/boxPlotTimeWP",".png");
    
    exportgraphics(gcf,fileName,'Resolution',300)

    %plot the overall time
    
    %figure('Units', 'centimeters', 'Position', [1, 1, 40, 25], 'Color', 'w');
    figure('Units', 'centimeters', 'Position', [2, 2, 50, 20], 'Color', 'w');

       

    %set(gcf, 'Position', [100, 100, 1512, 982]); % Set the figure size and position
    %accumatedTimeMatrix

    accumatedTimeMatrix = [];
    names = {};
    orderedColors = [];
    %orderOfPlots(orderOfPlots == "FullWP") = [];

    for approachKey = accomuatedTimeMap.keys()
        appraochName = approachKey{:};
        accumatedTimeMatrix = [accumatedTimeMatrix; accomuatedTimeMap(appraochName)];
        approachData = currentMatrix(i, :)';
        %currentName = names(n);
        %latexName = char(namesMap(currentName{:}))
        %names(n) = {latexName};
        names{end+1} = char(namesMap(appraochName));
        orderedColors = [orderedColors; colorMap(appraochName)];
        
    end
   
    currentMatrix = accumatedTimeMatrix;
    [numApproaches, nRuns] = size(accumatedTimeMatrix);
    hold on;
    legendHandles = gobjects(1, numApproaches); 



    h = gobjects(1, numApproaches); % Initialize an array to store the plot handles
    for i = 1:numApproaches
        currentData = accumatedTimeMatrix(i, :)';

        % Store the plot object in 'h(i)'
        h(i) = boxchart(i * ones(size(currentData)), currentData);
        legendHandles(i) = h(i);
        thisColor = orderedColors(i, :);
        set(h(i), 'BoxFaceColor', thisColor, 'BoxFaceAlpha', 0.4, ...
                  'BoxEdgeColor', thisColor, 'WhiskerLineColor', thisColor, ...
                  'MarkerColor', thisColor, 'MarkerStyle', 'o', ...
                  'MarkerSize', 5, 'LineWidth', 1.5, 'BoxWidth', 0.6);
    end

    % 4. Formatting
    ylabel('Time in min', 'FontSize', 12) % 'FontWeight', 'bold');
    xticks(1:length(names));
    xticklabels(names);
    xtickangle(0); 
    set(gca, 'TickLabelInterpreter', 'latex');

    grid on;
    box on; % Adds the black frame around the plot

   
    lgd = legend(legendHandles, names, 'Orientation', 'horizontal', 'Interpreter','latex');
    set(lgd, 'Location', 'southoutside');
 
    lgd.FontSize = 10;
    lgd.Box = 'off';

    set(findall(gcf, '-property', 'FontSize'), 'FontSize', 14);

    fileName = append(baseResultsPath,"/plots/Time/boxPlotTimeAll.png");
    exportgraphics(gcf,fileName,'Resolution',300)
    
    
end

% KEEP
function displayTimeUsage(baseResultsPath,metrics,vesselName,nameMap, orderOfPlots)
    orderOfPlots(orderOfPlots == "RandomSearch") = [];

    numBrackets = 5;
    figureNum = 50;
    %labelsClasses = ["% Missing", "% Unstable",  "% Stable"];
    
    screenSize = [1 1 1512 982];
    overallMap = containers.Map();
    waypointInfoMatrix = ["Waypoint", "Approach", "MaxTime", "MinTime", "Average Time"]% "Accumlated Time"]

    endTimeAppraochesAndWaypoints = [];
    
    waypointInfoMap = containers.Map();
    approachNamesPlot = [];
    accomuatedTimeMap = containers.Map();

    for waypointKey = metrics.keys()
        names = [];
        wptIndex = waypointKey{:};
        waypointMetrics = metrics(wptIndex);
        numSubplots = length(waypointMetrics.keys());
        appraochNamesList = waypointMetrics.keys();
        %figure(figureNum)
        tempWaypointInfo = [];
        timeUsage = [];
        names = [];
        namesPlot = [];
        waypointMetrics.remove('StatisticalComparisonResults')

        for approachKey = waypointMetrics.keys()
            appraochName = approachKey{:};
            %if any(ismember(appraochName, overallMap.keys()))
            %    overall = overallMap(appraochName);
            %else 
            %    overall = zeros(numBrackets, length(flagCategoriesToIndlcude));
            %end

            names = [names; string(appraochName)];
            appraochMetric = waypointMetrics(appraochName);
            appraochMetric.keys()
            wayPointTimeInfo = appraochMetric("wayPointTimeInfo");
            exNums = wayPointTimeInfo('exNums');
            
            approachTimeExperiments = wayPointTimeInfo('approachTimeExperiments');
            if appraochName ~= "FullWP"
                
                %if size(approachTimeExperiments(end,:),2) > 30
                %    approachTimeExperiments = approachTimeExperiments(:,1:30)
                %end
                size(approachTimeExperiments(end,:))
                approachNamesPlot{end+1} = appraochName
                timeUsage = [timeUsage approachTimeExperiments(end,:)'];
                %namesPlot = [namesPlot; appraochName];
                endTimeAppraochesAndWaypoints = [endTimeAppraochesAndWaypoints; ...
                                                string(wptIndex) appraochName string(exNums); ...
                                                string(wptIndex) appraochName string(approachTimeExperiments(end,:))]
            end
            MaxTime = wayPointTimeInfo('MaxTime')
            MinTime = wayPointTimeInfo('MinTime')
            AverageTime = wayPointTimeInfo('AverageTime');

           

            %approachTimeExperiments = 5;
            %MaxTime = 6; 
            %MinTime = 7;
            %AverageTime = 8; 
            %InfoMatrix = ["Waypoint", "Approach", "MaxTime", "MinTime", "Average Time"]
            if isKey(accomuatedTimeMap,appraochName)
                accomuatedTime = accomuatedTimeMap(appraochName);
            else
                accomuatedTime = zeros(size(approachTimeExperiments(end,:)));
            end

            if appraochName ~= "FullWP"
                accomuatedTime = accomuatedTime + (approachTimeExperiments(end,:))/60;
            else
                accomuatedTime = approachTimeExperiments(end,:)/60;
            end
            accomuatedTimeMap(appraochName) = accomuatedTime; %/60;
            %InfoMatrix = [string(wptIndex), appraochName, string(wayPointTimeInfo(2,2)), string(wayPointTimeInfo(3,2)), string(wayPointTimeInfo(4,2)) string(accomuatedTime)];
            InfoMatrix = [string(wptIndex), appraochName, string(MaxTime), string(MinTime), string(AverageTime)] %, string(accomuatedTime)];
            
            

            waypointInfoMatrix = [waypointInfoMatrix;
                                  InfoMatrix];
            tempWaypointInfo = [tempWaypointInfo; InfoMatrix(2:end)];

            %subplot(ceil(numSubplots/2), 2, find(strcmp(appraochNamesList, appraochName)))
            %heatmap(labelsClasses(flagCategoriesToIndlcude), labelsBrackets, appraochBracket);
            %overallMap(appraochName) = overall;

            %title(append(appraochName));
            %ax = gca; % Get current axes
            %ax.FontSize = 18;
    
            
               
        end
        waypointInfoMap(string(wptIndex)) = tempWaypointInfo;
        
        
        figure(figureNum)
        %set(gcf, 'Position', [100, 100, 1512, 982]); % Set the figure size and position
        set(gcf, 'Position', [2, 2, 50, 20]); % Set the figure size and position
         
        
        %boxplot(timeUsage, 'Whisker', 1.5)
        boxchart(timeUsage) %, 'Whisker', 1.5)
       
        title(append("WPindex ", string(wptIndex)));

        ax = gca; % Get current axes
        ax.FontSize = 18;
        

        ax.XTickLabel = approachNamesPlot; 
        set(gca, 'TickLabelInterpreter', 'latex');
        fileName = append(baseResultsPath,"/plots/Time/boxPlotTimeUsage-WPindex-", string(wptIndex),".png"); % change
        
    
        exportgraphics(ax,fileName,'Resolution',300)


        figureNum = figureNum + 1;

    end
    %% time of accumlated time
    accumatedTimeMatrix = [];
    approachNamesPlot = {}
    for approachKey = accomuatedTimeMap.keys()
        appraochName = approachKey{:};
        approachNamesPlot{end+1} = appraochName;
        accumatedTimeMatrix = [accumatedTimeMatrix; accomuatedTimeMap(appraochName)]
    end

    figure(figureNum)
    set(gcf, 'Position', [100, 100, 1512, 982]); % Set the figure size and position
    accumatedTimeMatrix
    %boxplot(accumatedTimeMatrix', 'Whisker', 1.5)
    boxchart(accumatedTimeMatrix') %, 'Whisker', 1.5)
    
    title("accumulated");
    ax = gca; % Get current axes
    ax.FontSize = 18;

    ax.XTickLabel = waypointMetrics.keys(); 
    set(gca, 'TickLabelInterpreter', 'latex');
    fileName = append(baseResultsPath,"/plots/Time/boxPlotTimeUsage-accumulated.png");

    exportgraphics(ax,fileName,'Resolution',300)


    figureNum = figureNum + 1;

    endTimeAppraochesAndWaypoints

    

    waypointInfoMatrix
    approaches = unique(waypointInfoMatrix(:,2))
    approaches = approaches(2:end)

    %nameMap = containers.Map(...
    %    {'FullWP','IncWP_KP','IncWP_Unst','IncWP_Prox','RandomSearch','IncWP_Rnd','IncWP_Kmeans'}, ...
    %    {'\fullWptSearch','\KneeSel','\IncWP_Unst','\IncWP_Prox','\RandomSearch','\IncWP_Rnd','\KmeansSel'} ...
    %);

    filename = append(baseResultsPath,"/plots/Time/","timeUsage_results_table.tex");

    fid = fopen(filename, 'w');


    % Start tabular
    fprintf(fid, '\\begin{tabular}{c l c c c }\n');
    fprintf(fid, '\\toprule\n');
    fprintf(fid, 'wptIndex & Approach & Max Time & Min Time & Average Time \\\\\n');

    %numApproachesAndWaypoints = size(waypointInfoMatrix, 1);
    
    for waypointKey = waypointInfoMap.keys()
        wptIndex = waypointKey{:}
        fprintf(fid, '\\midrule\n');

        singleWaypointInfo = waypointInfoMap(wptIndex)
        singleWaypointInfo = singleWaypointInfo(2:end,:) %% skip the first since it is "FullWP"
        numApproachesAndWaypoints = size(singleWaypointInfo, 1);


        i = 1 
        approach = nameMap(singleWaypointInfo(i,1));
        approach = char(approach);
        approach = strrep(approach, '_', '\_');
        names = [singleWaypointInfo(i,1)]

        fprintf(fid, ['\\multirow{%d}{*}{%d} & %s & %.0f & %.0f & %.0f  \\\\ \n'], ...
            numApproachesAndWaypoints, ...
            str2double(wptIndex), ...
            approach, ...
            str2double(singleWaypointInfo(i,2)), ...
            str2double(singleWaypointInfo(i,3)), ...
            str2double(singleWaypointInfo(i,4)));
            %str2double(singleWaypointInfo(i,5))); 
         

        
        for i = 2:numApproachesAndWaypoints
            approach = nameMap(singleWaypointInfo(i,1));
            approach = char(approach);
            approach = strrep(approach, '_', '\_');
    
            fprintf(fid, ' & %s & %.0f & %.0f & %.0f  \\\\ \n', ...
                approach, ...
                str2double(singleWaypointInfo(i,2)), ...
                str2double(singleWaypointInfo(i,3)), ...
                str2double(singleWaypointInfo(i,4)));
                %str2double(singleWaypointInfo(i,5)));
            names = [names; singleWaypointInfo(i,1)];
        end

        
        
        

    
    end
    fprintf(fid, '\\bottomrule\n');
    fprintf(fid, '\\end{tabular}\n');
    
    fclose(fid);
    filename = append(baseResultsPath,"/plots/Time/","timeUsage_results_table_accumluated.tex");

    fid = fopen(filename, 'w');


    % Start tabular
    %fprintf(fid, '\\begin{tabular}{l c c c }\n');
    %fprintf(fid, '\\toprule\n');
    %fprintf(fid, ' Approach & Max Time & Min Time & Average Time \\\\\n');

    %fprintf(fid, '\\midrule\n');


    vesselNameLength = size(orderOfPlots,2)
    %notAddedFirst = true
    if vesselName == "remus100"
        vesselText = append("\multirow{", string(vesselNameLength), "}{4em}{\resmus} ")
    elseif vesselName == "nspauv"
        vesselText = append("\multirow{", string(vesselNameLength), "}{4em}{\nspauv} ")
    elseif vesselName == "mariner"
        vesselText = append("\multirow{", string(vesselNameLength), "}{4em}{\mariner} ")

    end

    for approachIdx = 1:length(orderOfPlots) %accomuatedTimeMap.keys()
        approachName = orderOfPlots(approachIdx);
        approach = nameMap(approachName);
        approach = char(approach);
        approach = strrep(approach, '_', '\_');
        accomuatedTime = accomuatedTimeMap(approachName);
        % if notAddedFirst
        %     % First row: include the multirow cell
        %     fprintf(fid, ['\\multirow{%d}{*}{%s} & %s & %.0f & %.0f & %.0f \\\\ \n'], ...
        %         length(accomuatedTimeMap.keys()), ...
        %         'Accumulated time', ...   % text inside the multirow cell
        %         approach, ...
        %         max(accomuatedTime), ...
        %         min(accomuatedTime), ...
        %         mean(accomuatedTime));
        %     notAddedFirst = false;
        % else
            % Remaining rows: first column empty
        if approachIdx == 1
            fprintf(fid, '%s & %s & %.0f & %.0f & %.0f \\\\ \n', ...
                vesselText, ...,
                approach, ...
                max(accomuatedTime), ...
                min(accomuatedTime), ...
                mean(accomuatedTime));
        elseif approachIdx == length(orderOfPlots) 
            fprintf(fid, '& %s & %.0f & %.0f & %.0f  \n', ...
                approach, ...
                max(accomuatedTime), ...
                min(accomuatedTime), ...
                mean(accomuatedTime));
        else 
            fprintf(fid, '& %s & %.0f & %.0f & %.0f \\\\ \n', ...
                approach, ...
                max(accomuatedTime), ...
                min(accomuatedTime), ...
                mean(accomuatedTime));
        end
        %end
    end
 
    


    %fprintf(fid, '\\bottomrule\n');
    %fprintf(fid, '\\end{tabular}\n');
    
    fclose(fid);

end

% KEEP
function timeUsageNoBracket(baseResultsPath, metrics, nameMap, orderOfPlots, vesselName, approachDataMap)

    % ------------------------------------------------------------
    % Plot/data parameters
    % ------------------------------------------------------------
    orderOfPlots(orderOfPlots == "RandomSearch") = [];

    missingValueReplacement = -1;
    timeConversionToMinutes = 60;

    categoryLabels = {'Miss.', 'Unst.', ''};

    % ------------------------------------------------------------
    % Figure parameters
    % ------------------------------------------------------------
    figurePosition = [2, 2, 80, 25];
    figureBackgroundColor = 'w';

    exportResolution = 300;
    exportFolder = "/plots/Time/";
    exportFileName = "Heatmap_minTime.png";

    % ------------------------------------------------------------
    % Heatmap visual parameters
    % ------------------------------------------------------------
    colormapSize = 256;

    blueStart = [0.8, 0.9, 1.0];
    blueEnd   = [0.0, 0.2, 1.0];

    grayColor = [0.85, 0.85, 0.85];

    gridEdgeColorIndex = 10;
    gridLineWidth = 0.5;

    darkTextThresholdIndex = 130;

    dataColumnWidth = 2;
    gapColumnWidth = 0.3;

    categoryBlockSize = 2;
    groupPatternLength = 3;

    % ------------------------------------------------------------
    % Font parameters
    % ------------------------------------------------------------
    cellValueFontSize = 24;
    approachHeaderFontSize = 36;
    axisLabelFontSize = 34;
    xTickFontSize = 30;

    approachHeaderYOffset = -0.1;

    colorbarLabelText = 'Time in min';
    colorbarLabelFontSize = 26;
    colorbarLabelFontWeight = 'bold';

    % ------------------------------------------------------------
    % Calculate mean first occurrence time per waypoint and approach
    % ------------------------------------------------------------
    waypointMean = containers.Map();
    fullSetMissingPrev = containers.Map();

    for waypointKey = metrics.keys()
        wptIndex = waypointKey{:};
        waypointMetrics = metrics(wptIndex);

        if isKey(waypointMetrics, 'StatisticalComparisonResults')
            waypointMetrics.remove('StatisticalComparisonResults');
        end

        approachesMean = containers.Map();

        previousWaypointKey = string(str2double(wptIndex) - 1);

        if isKey(fullSetMissingPrev, previousWaypointKey)
            fullSetMissingWpt = fullSetMissingPrev(previousWaypointKey);
        else
            fullSetMissingWpt = containers.Map();
        end

        for approachIdx = 1:length(orderOfPlots)
            approachName = orderOfPlots(approachIdx);

            approachData = approachDataMap(approachName);
            approachData = approachData(wptIndex);

            approachMetric = waypointMetrics(approachName);
            wayPointTimeInfo = approachMetric("wayPointTimeInfo");
            exNums = wayPointTimeInfo('exNums'); %#ok<NASGU>

            experimentsFirst = [];

            for exNumKey = approachData.keys
                exNum = exNumKey{:};
                experimentData = approachData(exNum);

                exClasses = experimentData('classes');
                exTimes = experimentData('timestamp');

                if approachName == "FullWP"
                    if isKey(fullSetMissingWpt, string(exNum))
                        fullSetMissingList = fullSetMissingWpt(string(exNum));
                    else
                        fullSetMissingList = zeros(size(exClasses, 1), 1);
                    end

                    newMissing = (exClasses == "missing");

                    exClasses = exClasses(~fullSetMissingList, :);
                    exTimes = exTimes(~fullSetMissingList, :);

                    fullSetMissingList = newMissing | (fullSetMissingList == 1);
                    fullSetMissingWpt(string(exNum)) = fullSetMissingList;
                end

                idxMissing = find(exClasses == "missing")';
                idxUnstable = find(exClasses == "unstable")';

                if size(idxMissing) > 0
                    timesMissing = exTimes(idxMissing);
                    firstMissing = min(timesMissing);
                else
                    firstMissing = NaN;
                end

                if size(idxUnstable) > 0
                    timesUnstable = exTimes(idxUnstable);
                    firstUnstable = min(timesUnstable);
                else
                    firstUnstable = NaN;
                end

                experimentsFirst = [experimentsFirst; [firstMissing firstUnstable]];
            end

            missingTimes = experimentsFirst(:, 1);
            missingTimes = missingTimes(~isnan(missingTimes));

            if size(missingTimes) > 0
                meanMissing = mean(missingTimes);
            else
                meanMissing = NaN;
            end

            unstableTimes = experimentsFirst(:, 2);
            unstableTimes = unstableTimes(~isnan(unstableTimes));

            if size(unstableTimes) > 0
                meanUnstable = mean(unstableTimes);
            else
                meanUnstable = NaN;
            end

            meanFirst = [meanMissing, meanUnstable];

            approachesMean(approachName) = meanFirst / timeConversionToMinutes;
        end

        fullSetMissingPrev(wptIndex) = fullSetMissingWpt;
        waypointMean(wptIndex) = approachesMean;
    end

    % ------------------------------------------------------------
    % Convert means into matrix
    % ------------------------------------------------------------
    meanMatrix = [];
    namesAdded = false;
    names = [];

    for waypointKey = waypointMean.keys()
        wptIndex = waypointKey{:};
        approachesMean = waypointMean(wptIndex);

        wptMean = [];

        for approachIdx = 1:length(orderOfPlots)
            approachName = orderOfPlots(approachIdx);
            approachMean = approachesMean(approachName);

            if sum(isnan(approachMean)) > 0
                approachMean(isnan(approachMean)) = missingValueReplacement * ones(1, sum(isnan(approachMean)));
            end

            wptMean = [wptMean approachMean NaN];

            if ~namesAdded
                names = [names; string(nameMap(string(approachName)))];
            end
        end

        namesAdded = true;
        meanMatrix = [meanMatrix; wptMean];
    end

    globalMin = min(meanMatrix(:));
    globalMax = max(meanMatrix(:));

    [numWayPoints, numColApproaches] = size(meanMatrix); %#ok<NASGU>

    % ------------------------------------------------------------
    % Create colormap
    % ------------------------------------------------------------
    blues = [
        linspace(blueStart(1), blueEnd(1), colormapSize)', ...
        linspace(blueStart(2), blueEnd(2), colormapSize)', ...
        linspace(blueStart(3), blueEnd(3), colormapSize)'
    ];

    % ------------------------------------------------------------
    % Create figure
    % ------------------------------------------------------------
    figure('Units', 'centimeters', ...
        'Position', figurePosition, ...
        'Color', figureBackgroundColor);

    data = meanMatrix;
    [rows, cols] = size(data);

    isGap = all(isnan(data));

    xLeft = zeros(1, cols);
    xRight = zeros(1, cols);
    xCenter = zeros(1, cols);

    x = 0;

    for colIdx = 1:cols
        columnWidth = dataColumnWidth;

        if isGap(colIdx)
            columnWidth = gapColumnWidth;
        end

        xLeft(colIdx) = x;
        xRight(colIdx) = x + columnWidth;
        xCenter(colIdx) = (xLeft(colIdx) + xRight(colIdx)) / 2;

        x = xRight(colIdx);
    end

    % ------------------------------------------------------------
    % Draw heatmap cells
    % ------------------------------------------------------------
    for rowIdx = 1:rows
        for colIdx = 1:cols
            value = data(rowIdx, colIdx);

            if isnan(value)
                continue;
            end

            if value < 0
                cellColor = grayColor;
                colorIdx = 0;
            else
                colorValue = (value - globalMin) / (globalMax - globalMin);
                colorValue = max(0, min(1, colorValue));

                colorIdx = max(1, min(colormapSize, ...
                    round(1 + colorValue * (colormapSize - 1))));

                cellColor = blues(colorIdx, :);
            end

            y0 = rowIdx - 1;
            y1 = rowIdx;

            patch([xLeft(colIdx) xRight(colIdx) xRight(colIdx) xLeft(colIdx)], ...
                  [y0 y0 y1 y1], ...
                  cellColor, ...
                  'EdgeColor', blues(gridEdgeColorIndex, :), ...
                  'LineWidth', gridLineWidth);

            if value >= 0
                if colorIdx > darkTextThresholdIndex
                    txtColor = 'w';
                else
                    txtColor = 'k';
                end

                text(xCenter(colIdx), (y0 + y1) / 2, sprintf('%.2f', value), ...
                    'HorizontalAlignment', 'center', ...
                    'VerticalAlignment', 'middle', ...
                    'FontSize', cellValueFontSize, ...
                    'Color', txtColor);
            end
        end
    end

    % ------------------------------------------------------------
    % Add approach headers
    % ------------------------------------------------------------
    numGroups = floor(cols / groupPatternLength);

    for groupIdx = 1:numGroups
        colStart = (groupIdx - 1) * groupPatternLength + 1;
        colEnd = colStart + groupPatternLength - 2;

        groupCenter = mean(xCenter(colStart:colEnd));
        headerLabel = names(groupIdx);

        text(groupCenter, approachHeaderYOffset, headerLabel, ...
            'HorizontalAlignment', 'center', ...
            'VerticalAlignment', 'bottom', ...
            'FontWeight', 'bold', ...
            'FontSize', approachHeaderFontSize, ...
            'Interpreter', 'latex');
    end

    % ------------------------------------------------------------
    % Axis labels
    % ------------------------------------------------------------
    numWpt = cols / groupPatternLength;

    customLabelsArray = {};

    for wptIdx = 2:numWpt + 1
        customLabelsArray{end+1} = append('$wp_{', num2str(wptIdx), '}$');
    end

    axis tight;
    set(gca, 'YDir', 'reverse');

    set(gca, ...
        'YTick', (0:numWpt - 1) + 0.5, ...
        'YTickLabel', customLabelsArray, ...
        'TickLabelInterpreter', 'latex', ...
        'FontSize', axisLabelFontSize);

    labelsPattern = repmat(categoryLabels, 1, length(names));

    set(gca, ...
        'XTick', xCenter, ...
        'XTickLabel', labelsPattern, ...
        'FontSize', xTickFontSize, ...
        'TickLabelInterpreter', 'latex');

    xtickangle(0);

    ax = gca;
    ax.YAxis.FontSize = axisLabelFontSize;

    % ------------------------------------------------------------
    % Colorbar
    % ------------------------------------------------------------
    colormap(gca, blues);
    clim([globalMin globalMax]);

    cb = colorbar;

    ylabel(cb, colorbarLabelText, ...
        'FontSize', colorbarLabelFontSize, ...
        'FontWeight', colorbarLabelFontWeight);

    % ------------------------------------------------------------
    % Export
    % ------------------------------------------------------------
    fileName = append(baseResultsPath, exportFolder, exportFileName);
    exportgraphics(gcf, fileName, 'Resolution', exportResolution);

end

% KEEP
function distanceNoBracket(baseResultsPath, metrics, nameMap, orderOfPlots, vesselName, approachDataMap)

    % ------------------------------------------------------------
    % Plot/data parameters
    % ------------------------------------------------------------
    orderOfPlots(orderOfPlots == "RandomSearch") = [];

    missingValueReplacement = -1;
    percentageScale = 100;
    %timeConversionToMinutes = 60;
    %maxExperimentsToUse = 30;

    categoryLabels = {'Miss.', 'Unst.', 'Stab.', ''};
    %categoryNames = ["missing", "unstable", "stable"];

    % ------------------------------------------------------------
    % Figure parameters
    % ------------------------------------------------------------
    figurePosition = [2, 2, 80, 25];
    figureBackgroundColor = 'w';

    exportResolution = 300;
    exportFolder = "/plots/Distance/";
    exportFileName = "Heatmap_distance.png";

    % ------------------------------------------------------------
    % Heatmap visual parameters
    % ------------------------------------------------------------
    colormapSize = 256;

    blueStart = [0.8, 0.9, 1.0];
    blueEnd   = [0.0, 0.2, 1.0];

    grayColor = [0.85, 0.85, 0.85];
    lightBlueHighlight = [0.9, 0.95, 1.0];

    gridEdgeColorIndex = 10;
    gridLineWidth = 0.5;

    valueThreshold = 0.1;
    darkTextThresholdIndex = 130;
    whiteTextValueThreshold = 50;

    dataColumnWidth = 2;
    gapColumnWidth = 0.3;

    categoryBlockSize = 3;
    groupPatternLength = 4;

    % ------------------------------------------------------------
    % Font parameters
    % ------------------------------------------------------------
    cellValueFontSize = 24;
    approachHeaderFontSize = 36;
    axisLabelFontSize = 34;
    xTickFontSize = 30;

    approachHeaderYOffset = -0.1;

    colorbarLabelText = '% of all individuals';
    colorbarLabelFontSize = 26;
    colorbarLabelFontWeight = 'bold';

    % ------------------------------------------------------------
    % Calculate means per waypoint and approach
    % ------------------------------------------------------------
    waypointMean = containers.Map();
    fullSetMissingPrev = containers.Map();

    for waypointKey = metrics.keys()
        wptIndex = waypointKey{:};
        waypointMetrics = metrics(wptIndex);

        if isKey(waypointMetrics, 'StatisticalComparisonResults')
            waypointMetrics.remove('StatisticalComparisonResults');
        end

        approachesMean = containers.Map();

        previousWaypointKey = string(str2double(wptIndex) - 1);

        if isKey(fullSetMissingPrev, previousWaypointKey)
            fullSetMissingWpt = fullSetMissingPrev(previousWaypointKey);
        else
            fullSetMissingWpt = containers.Map();
        end

        for approachIdx = 1:length(orderOfPlots)
            approachName = orderOfPlots(approachIdx);

            approachData = approachDataMap(approachName);
            approachData = approachData(wptIndex);

            approachMetric = waypointMetrics(approachName);
            wayPointTimeInfo = approachMetric("wayPointTimeInfo");
            exNums = wayPointTimeInfo('exNums'); 

            experimentsFirst = [];

            for exNumKey = approachData.keys
                exNum = exNumKey{:};
                experimentData = approachData(exNum);

                exClasses = experimentData('classes');

                if approachName == "FullWP"
                    if isKey(fullSetMissingWpt, string(exNum))
                        fullSetMissingList = fullSetMissingWpt(string(exNum));
                    else
                        fullSetMissingList = zeros(size(exClasses, 1), 1);
                    end

                    newMissing = (exClasses == "missing");

                    exClasses = exClasses(~fullSetMissingList, :);

                    fullSetMissingList = newMissing | (fullSetMissingList == 1);
                    fullSetMissingWpt(string(exNum)) = fullSetMissingList;
                end

                idxMissing = find(exClasses == "missing")';
                idxUnstable = find(exClasses == "unstable")';
                idxStable = find(exClasses == "stable")';

                if size(idxMissing) > 0
                    firstMissing = size(idxMissing, 2);
                else
                    firstMissing = NaN;
                end

                if size(idxUnstable) > 0
                    firstUnstable = size(idxUnstable, 2);
                else
                    firstUnstable = NaN;
                end

                if size(idxStable) > 0
                    firstStable = size(idxStable, 2);
                else
                    firstStable = NaN;
                end

                experimentsFirst = [experimentsFirst; [firstMissing firstUnstable firstStable]];
            end

            missingList = experimentsFirst(:, 1);
            missingNotNan = missingList(~isnan(missingList));
            totalMissing = sum(missingNotNan);

            unstableList = experimentsFirst(:, 2);
            unstableNotNan = unstableList(~isnan(unstableList));
            totalUnstable = sum(unstableNotNan);

            stableList = experimentsFirst(:, 3);
            stableNotNan = stableList(~isnan(stableList));
            totalStable = sum(stableNotNan);

            total = totalMissing + totalUnstable + totalStable;

            if totalMissing > 0
                meanMissing = totalMissing / total;
            else
                meanMissing = NaN;
            end

            if totalUnstable > 0
                meanUnstable = totalUnstable / total;
            else
                meanUnstable = NaN;
            end

            if totalStable > 0
                meanStable = totalStable / total;
            else
                meanStable = NaN;
            end

            meanFirst = [meanMissing, meanUnstable, meanStable];

            approachesMean(approachName) = meanFirst * percentageScale;
        end

        fullSetMissingPrev(wptIndex) = fullSetMissingWpt;
        waypointMean(wptIndex) = approachesMean;
    end

    % ------------------------------------------------------------
    % Convert means into matrix
    % ------------------------------------------------------------
    meanMatrix = [];
    namesAdded = false;
    names = [];

    for waypointKey = waypointMean.keys()
        wptIndex = waypointKey{:};
        approachesMean = waypointMean(wptIndex);

        wptMean = [];

        for approachIdx = 1:length(orderOfPlots)
            approachName = orderOfPlots(approachIdx);
            approachMean = approachesMean(approachName);

            if sum(isnan(approachMean)) > 0
                approachMean(isnan(approachMean)) = missingValueReplacement * ones(1, sum(isnan(approachMean)));
            end

            wptMean = [wptMean approachMean NaN];

            if ~namesAdded
                names = [names; string(nameMap(string(approachName)))];
            end
        end

        namesAdded = true;
        meanMatrix = [meanMatrix; wptMean];
    end

    globalMin = min(meanMatrix(:));
    globalMax = max(meanMatrix(:));

    [numWayPoints, numColApproaches] = size(meanMatrix); 

    % ------------------------------------------------------------
    % Create colormap
    % ------------------------------------------------------------
    blues = [
        linspace(blueStart(1), blueEnd(1), colormapSize)', ...
        linspace(blueStart(2), blueEnd(2), colormapSize)', ...
        linspace(blueStart(3), blueEnd(3), colormapSize)'
    ];

    % ------------------------------------------------------------
    % Create figure
    % ------------------------------------------------------------
    figure('Units', 'centimeters', ...
        'Position', figurePosition, ...
        'Color', figureBackgroundColor);

    data = meanMatrix;
    [rows, cols] = size(data);

    isGap = all(isnan(data));

    xLeft = zeros(1, cols);
    xRight = zeros(1, cols);
    xCenter = zeros(1, cols);

    x = 0;

    for colIdx = 1:cols
        columnWidth = dataColumnWidth;

        if isGap(colIdx)
            columnWidth = gapColumnWidth;
        end

        xLeft(colIdx) = x;
        xRight(colIdx) = x + columnWidth;
        xCenter(colIdx) = (xLeft(colIdx) + xRight(colIdx)) / 2;

        x = xRight(colIdx);
    end

    % ------------------------------------------------------------
    % Draw heatmap cells
    % ------------------------------------------------------------
    for rowIdx = 1:rows
        for colIdx = 1:cols
            value = data(rowIdx, colIdx);

            if isnan(value)
                continue;
            end

            blockStart = floor((colIdx - 1) / categoryBlockSize) * categoryBlockSize + 1;
            rowTriplet = data(rowIdx, blockStart:blockStart + categoryBlockSize - 1);

            currentCategoryIdx = colIdx - blockStart + 1;
            otherValues = rowTriplet((1:categoryBlockSize) ~= currentCategoryIdx);
            tinyValueExists = any(otherValues > 0 & otherValues < valueThreshold);

            if value < 0
                cellColor = grayColor;
                colorIdx = 0;
                displayStr = "";
            elseif value == 0
                cellColor = grayColor;
                colorIdx = 0;
                displayStr = "";
                txtColor = 'k';
            elseif value < valueThreshold
                displayStr = append("<", string(valueThreshold));
                txtColor = 'k';

                colorValue = (value - globalMin) / (globalMax - globalMin);
                colorValue = max(0, min(1, colorValue));
                colorIdx = max(1, min(colormapSize, round(1 + colorValue * (colormapSize - 1))));

                cellColor = lightBlueHighlight;
            else
                colorValue = (value - globalMin) / (globalMax - globalMin);
                colorValue = max(0, min(1, colorValue));
                colorIdx = max(1, min(colormapSize, round(1 + colorValue * (colormapSize - 1))));

                cellColor = blues(colorIdx, :);

                if value > (percentageScale - valueThreshold) && tinyValueExists
                    displayStr = sprintf('%.1f', percentageScale - valueThreshold);
                else
                    displayStr = sprintf('%.1f', value);
                end

                if value > whiteTextValueThreshold
                    txtColor = 'w';
                else
                    txtColor = 'k';
                end
            end

            y0 = rowIdx - 1;
            y1 = rowIdx;

            patch([xLeft(colIdx) xRight(colIdx) xRight(colIdx) xLeft(colIdx)], ...
                  [y0 y0 y1 y1], ...
                  cellColor, ...
                  'EdgeColor', blues(gridEdgeColorIndex, :), ...
                  'LineWidth', gridLineWidth);

            if value >= 0
                if colorIdx > darkTextThresholdIndex
                    txtColor = 'w';
                else
                    txtColor = 'k';
                end

                text(xCenter(colIdx), (y0 + y1) / 2, displayStr, ...
                    'HorizontalAlignment', 'center', ...
                    'VerticalAlignment', 'middle', ...
                    'FontSize', cellValueFontSize, ...
                    'Color', txtColor);
            end
        end
    end

    % ------------------------------------------------------------
    % Add approach headers
    % ------------------------------------------------------------
    numGroups = floor(cols / groupPatternLength);

    for groupIdx = 1:numGroups
        colStart = (groupIdx - 1) * groupPatternLength + 1;
        colEnd = colStart + groupPatternLength - 2;

        groupCenter = mean(xCenter(colStart:colEnd));
        headerLabel = names(groupIdx);

        text(groupCenter, approachHeaderYOffset, headerLabel, ...
            'HorizontalAlignment', 'center', ...
            'VerticalAlignment', 'bottom', ...
            'FontWeight', 'bold', ...
            'FontSize', approachHeaderFontSize, ...
            'Interpreter', 'latex');
    end

    % ------------------------------------------------------------
    % Axis labels
    % ------------------------------------------------------------
    numWpt = cols / categoryBlockSize;

    customLabelsArray = {};

    for wptIdx = 2:numWpt + 1
        customLabelsArray{end+1} = append('$wp_{', num2str(wptIdx), '}$');
    end

    axis tight;
    set(gca, 'YDir', 'reverse');

    set(gca, ...
        'YTick', (0:numWpt - 1) + 0.5, ...
        'YTickLabel', customLabelsArray, ...
        'TickLabelInterpreter', 'latex', ...
        'FontSize', axisLabelFontSize);

    %set(gca, 'FontSize', axisLabelFontSize);

    labelsPattern = repmat(categoryLabels, 1, length(names));

    set(gca, ...
        'XTick', xCenter, ...
        'XTickLabel', labelsPattern, ...
        'FontSize', xTickFontSize, ...
        'TickLabelInterpreter', 'latex');

    xtickangle(0);

    ax = gca;
    ax.YAxis.FontSize = axisLabelFontSize;
    % ------------------------------------------------------------
    % Colorbar
    % ------------------------------------------------------------
    colormap(gca, blues);
    clim([globalMin globalMax]);

    cb = colorbar;

    ylabel(cb, colorbarLabelText, ...
        'FontSize', colorbarLabelFontSize, ...
        'FontWeight', colorbarLabelFontWeight);

    

    % ------------------------------------------------------------
    % Export
    % ------------------------------------------------------------
    fileName = append(baseResultsPath, exportFolder, exportFileName);
    exportgraphics(gcf, fileName, 'Resolution', exportResolution);

end

function str = formatPercentage(v, total_vals)
    threshold = 0.1;
    
    if isnan(v) || v == 0
        str = ''; % Keep it clean for zeros/NaNs
    elseif v < threshold
        str = sprintf('<%.1f', threshold);
    elseif v > (100 - threshold) && any(total_vals > 0 & total_vals < threshold)
        % FORCE it to 99.9 if other categories exist but are tiny
        % This prevents the "100.0 + <0.1" paradox
        str = '99.9';
    else
        % Standard rounding for everything else
        str = sprintf('%.1f', v);
    end
end

% KEEP 
function latexTimeUsagePerWaypoint(baseResultsPath, metrics, nameMap, orderOfPlots, vesselName)
    orderOfPlots(orderOfPlots == "RandomSearch") = [];
    %orderOfPlots(orderOfPlots == "FullWP") = [];
    
    

    numBrackets = 5;
    figureNum = 50;
    %labelsClasses = ["% Missing", "% Unstable",  "% Stable"];
    
    screenSize = [1 1 1512 982];
    overallMap = containers.Map();
    %waypointInfoMatrix = ["Waypoint", "Approach", "MaxTime", "MinTime", "Average Time"]% "Accumlated Time"]

   
    waypointTimes = [];

    for waypointKey = metrics.keys()
        names = [];
        wptIndex = waypointKey{:}
        waypointMetrics = metrics(wptIndex);
        numSubplots = length(waypointMetrics.keys());
        appraochNamesList = waypointMetrics.keys();
        %figure(figureNum)
        tempWaypointInfo = [];
        timeUsage = [];
        names = [];
        namesPlot = [];
        waypointMetrics.remove('StatisticalComparisonResults')
        averageTime = []; %[string(wptIndex)];

        for approachIdx = 1:length(orderOfPlots)
            appraochName = orderOfPlots(approachIdx);
            
            %if any(ismember(appraochName, overallMap.keys()))
            %    overall = overallMap(appraochName);
            %else 
            %    overall = zeros(numBrackets, length(flagCategoriesToIndlcude));
            %end

            names = [names; string(appraochName)];
            appraochMetric = waypointMetrics(appraochName);
            appraochMetric.keys()
            wayPointTimeInfo = appraochMetric("wayPointTimeInfo");
            exNums = wayPointTimeInfo('exNums');
            
            approachTimeExperiments = wayPointTimeInfo('approachTimeExperiments');
            if appraochName == "FullWP"
             
                averageTime = [averageTime; -60];

            else
                averageTime = [averageTime; mean(approachTimeExperiments(end,:))];
            end
            
        end
        waypointTimes = [waypointTimes; averageTime'];


    end

    setWptTime = [];
    for approachIdx = 1:length(orderOfPlots)
        appraochName = orderOfPlots(approachIdx);
        prevTime = [];
        for waypointKey = metrics.keys()
            wptIndex = waypointKey{:};
            waypointMetrics = metrics(wptIndex);

            exNums = wayPointTimeInfo('exNums');
            appraochMetric = waypointMetrics(appraochName);
            appraochMetric.keys()
            wayPointTimeInfo = appraochMetric("wayPointTimeInfo");
            
            approachTimeExperiments = wayPointTimeInfo('approachTimeExperiments');
            if isempty(prevTime)
                prevTime = zeros(size(approachTimeExperiments(end,:)));
            end
            
            if appraochName == "FullWP"
                prevTime = approachTimeExperiments(end,:); 
            else
                prevTime =  prevTime + approachTimeExperiments(end,:);
            end
            
        end
        setWptTime = [setWptTime; mean(prevTime)/60]


    end
    
    %for wptIdx = 1:(size(waypointTimes,1)-1)
    %    waypointTimes(wptIdx,:) = waypointTimes(wptIdx,:) -waypointTimes(wptIdx+1,:);
    %end
    

    filename = append(baseResultsPath,"/plots/Time/","timeUsage_per_wpt.tex");

    fid = fopen(filename, 'w');

    vesselNameLength = size(waypointTimes,1);
    waypointTimes = round(waypointTimes/60);
    setWptTime = round(setWptTime);

  
    if vesselName == "remus100"
        vesselText = append("\multirow{", string(vesselNameLength), "}{4em}{\resmus} ");
        waypointTimes = [waypointTimes; setWptTime']

    elseif vesselName == "nspauv"
        vesselText = append("\multirow{", string(vesselNameLength), "}{4em}{\nspauv} ");
         waypointTimes = [waypointTimes; setWptTime']
    elseif vesselName == "mariner"
        vesselText = append("\multirow{", string(vesselNameLength), "}{4em}{\mariner} ");
        emptyArray = strings(size(setWptTime));
        waypointTimes = [waypointTimes; emptyArray'; setWptTime']
    end
    %waypointTimes(waypointTimes<0) = "-"
    waypointTimes = string(waypointTimes)
    
      
    waypointTimes = waypointTimes';

    [rowsComaprisation, columsComparisation] = size(waypointTimes);

    for row = 1:rowsComaprisation
        approachName = nameMap(orderOfPlots(row));
        approachWptTime = waypointTimes(row,:);

        
        waypointText = [];
        for wptIdx = 1:columsComparisation
            if str2double(approachWptTime(wptIdx)) < 0
                approachWptTime(wptIdx) = "-"
            end
            waypointText = [waypointText, approachWptTime(wptIdx)];
            
        end
        

        %lineComparisonResults = resultsTransformed(row,:);
        %approachLeft = lineComparisonResults(1);
        %approachRight = lineComparisonResults(2);
        %resultsComperisation = lineComparisonResults(3:end);
        %approachLeftLatex = nameMap(approachLeft);
        %approachLeftLatex = char(approachLeftLatex);
        %approachLeftLatex = strrep(approachLeftLatex, '_', '\_');
        %approachRightLatex = nameMap(approachRight);
        %approachRightLatex = char(approachRightLatex);
        %approachRightLatex = strrep(approachRightLatex, '_', '\_');
        if row == 1
            latexText = [vesselText,approachName, waypointText];

        else 
            latexText = ["&" approachName, waypointText];
        end
      
        % write latex to text
        fprintf(fid, '%s', latexText{1});     % first column

        if row > 1
            fprintf(fid, ' %s', latexText{2});
            for c = 3:numel(latexText)
                fprintf(fid, ' & %s', latexText{c});
            end
        else
            for c = 2:numel(latexText)
                fprintf(fid, ' & %s', latexText{c});
            end
        end
        
        if row ~= rowsComaprisation
            fprintf(fid, ' \\\\ \n');
        else
            fprintf(fid, ' \n');
        end
       
        
    
    end

    
    fclose(fid);



end


% KEEP
function displayTimeOnlyFirstCombinedPlot(baseResultsPath, metrics, nameMap, orderOfPlots)
    orderOfPlots(orderOfPlots == "RandomSearch") = [];

    %maxOfLastMap = containers.Map();

    % --- CONFIGURATION ---
    numBrackets = 5;
    flagCategoriesToIndlcude = [1, 2]; % firstMissing, firstUnstable
    
    % Colors: Light (Index 1) -> Dark (Index 256)
    blues = [linspace(0.8, 0.0, 256)', linspace(0.9, 0.2, 256)', ones(256,1)];
    
    % Gray for missing data (-1) AND grid lines
    grayColor = [0.85, 0.85, 0.85]; 
    
    % UPDATED Font Sizes
    fontSizeNumers   = 12;   
    fontSizeApproach = 18;
    fontSizeLabels   = 12;

    % --- 1. GLOBAL RANGE CALCULATION ---
    globalMin = Inf;
    globalMax = -Inf;
    
    unsortedKeys = metrics.keys();
    try
        numericKeys = cellfun(@str2double, unsortedKeys);
        [~, sortIdx] = sort(numericKeys);
        sortedKeys = unsortedKeys(sortIdx);
    catch
        sortedKeys = sort(unsortedKeys);
    end
    numWaypoints = length(sortedKeys);
    
    for k = 1:numWaypoints
        wptMetrics = metrics(sortedKeys{k});
        

        %for appKey = wptMetrics.keys()
        %    appName = appKey{:};
        for approachIdx = 1:length(orderOfPlots)
            appName = orderOfPlots(approachIdx);

            if strcmp(appName, 'StatisticalComparisonResults'), continue; end

            % if isKey(maxOfLastMap,appName) && appName ~= "FullWP"  
            %     maxOfLast = maxOfLastMap(appName);
            % else
            %     maxOfLast = 0;
            % end

            

        
            
            appMetricObj = wptMetrics(appName); 
            bracket = appMetricObj("bracketsTimeCount");
            bracket = bracket/60;

            %if appName == "FullWP"  
            %    bracket
            %end

            
            vals = bracket(:, flagCategoriesToIndlcude);
            validVals = vals(~isnan(vals)); % + maxOfLast*ones(size(vals(~isnan(vals))));
            
            if ~isempty(validVals)
                realVals = validVals(validVals >= 0); 
                if ~isempty(realVals)
                    globalMin = min(globalMin, min(realVals));
                    globalMax = max(globalMax, max(realVals));
                end
            end
            % if appName ~= "FullWP"  
            %     maxOfLast = max(validVals); 
            %     maxOfLastMap(appName) = maxOfLast;
            % else
            %      maxOfLastMap(appName) = 0;
            % end
        end
    end
    if isinf(globalMax), globalMax = 1; globalMin = 0; end

    % --- 2. FIGURE SETUP ---
    % Larger figure size to fit bigger fonts comfortably inside cells
    figure('Units', 'centimeters', 'Position', [2, 2, 50, 20], 'Color', 'w');

    colsGrid = 2; 
    rowsGrid = ceil(numWaypoints / colsGrid);
    t = tiledlayout(rowsGrid, colsGrid, 'TileSpacing', 'compact', 'Padding', 'compact');

    % --- 3. PLOTTING LOOP ---
    %maxOfLastMap = containers.Map();

    for k = 1:numWaypoints
        wptIndex = sortedKeys{k};
        nexttile; 
        hold on;
        
        waypointMetrics = metrics(wptIndex);
        if isKey(waypointMetrics, 'StatisticalComparisonResults')
            waypointMetrics.remove('StatisticalComparisonResults');
        end
        
        combinedResults = [];
        names = [];
        
        for approachIdx = 1:length(orderOfPlots)
            appraochName = orderOfPlots(approachIdx);
            %approachKey = waypointMetrics.keys()
            %appraochName = approachKey{:};
            names = [names; string(nameMap(string(appraochName)))];
            % if isKey(maxOfLastMap,appraochName) && appraochName ~= "FullWP"
            %     maxOfLast = maxOfLastMap(appraochName);
            % else
            %     maxOfLast = 0;
            % end
            
            appraochMetric = waypointMetrics(appraochName);
            appraochBracket = appraochMetric("bracketsTimeCount");
            
            dataChunk = appraochBracket(:, flagCategoriesToIndlcude);
            dataChunk = dataChunk/60;
            %dataChunk(~isnan(dataChunk)) = dataChunk(~isnan(dataChunk)) + maxOfLast*ones(size(dataChunk(~isnan(dataChunk))));
            
            dataChunk(isnan(dataChunk)) = -1;

            combinedResults = [combinedResults dataChunk nan(numBrackets,1)]; 

            % if appraochName ~= "FullWP"
            %     maxOfLast = max(dataChunk(:)); 
            %     maxOfLastMap(appraochName) = maxOfLast;
            % else
            %      maxOfLastMap(appraochName) = 0;
            % end
        end
        
        data = combinedResults;
        [rows, cols] = size(data);
        isGap = all(isnan(data)); 
        
        wData = 2; wGap = 0.3;    
        xLeft = zeros(1,cols); xRight = zeros(1,cols); xCenter = zeros(1,cols);
        x = 0;
        for j = 1:cols
            w = wData;
            if isGap(j), w = wGap; end
            xLeft(j) = x; xRight(j) = x + w;
            xCenter(j) = (xLeft(j)+xRight(j))/2;
            x = xRight(j);
        end
        
        % --- DRAW PATCHES ---
        for r = 1:rows
            for j = 1:cols
                v = data(r,j);
                if isnan(v), continue; end
                
                if v < 0
                    col = grayColor; 
                    idx = 0; 
                else
                    t = (v - globalMin) / (globalMax - globalMin);
                    t = max(0, min(1, t));
                    idx = max(1, min(256, round(1 + t*(256-1))));
                    col = blues(idx,:);
                end
                
                y0 = r-1; y1 = r;
                % Grid lines now match the grayColor
                patch([xLeft(j) xRight(j) xRight(j) xLeft(j)], ...
                      [y0 y0 y1 y1], col, ...
                      'EdgeColor', grayColor, 'LineWidth', 0.5);
                  
                if v >= 0
                    % --- CONTRAST LOGIC (FIXED) ---
                    % idx 1 = White/Lightest
                    % idx 256 = Blue/Darkest
                    
                    % If cell is DARK (idx > 130), make text WHITE
                    if idx > 130 
                        txtColor = 'w'; 
                    % If cell is LIGHT (idx <= 130), make text BLACK
                    else
                        txtColor = 'k'; 
                    end
                    
                    text(xCenter(j),(y0+y1)/2, sprintf('%.2f',v), ...
                        'HorizontalAlignment','center', ...
                        'VerticalAlignment','middle', ...
                        'FontSize', fontSizeNumers, ...
                        'Color', txtColor); 
                    % 'FontWeight', 'bold', ...

                end
            end
        end
        
        axis tight;
        set(gca, 'YDir', 'reverse');
        set(gca, 'YTick', (0:rows-1)+0.5, 'YTickLabel', 1:rows);
        set(gca, 'FontSize', fontSizeLabels);
        %title(['Waypoint ', wptIndex], 'FontWeight', 'bold');
        
        if k <= colsGrid
            title({['Waypoint ', wptIndex],''}, 'FontWeight', 'bold');

            patternLength = length(flagCategoriesToIndlcude) + 1;
            numGroups = floor(cols / patternLength);
            
            for g = 1:numGroups
                colStart = (g-1)*patternLength + 1;
                colEnd   = colStart + length(flagCategoriesToIndlcude) - 1;
                groupCenter = mean(xCenter(colStart:colEnd));
                
                % FIX: Use ONLY the Approach Name to avoid repeating "Waypoint X" 7 times
                headerLabel = names(g); 
                
                text(groupCenter, -0.1, headerLabel, ...
                    'HorizontalAlignment', 'center', ...
                    'VerticalAlignment', 'bottom', ...
                    'FontWeight', 'bold', ...
                    'FontSize', fontSizeApproach, ...
                    'Interpreter', 'latex'); 
            end
        else 
            title({['Waypoint ', wptIndex]}, 'FontWeight', 'bold');

        end

        if k > numWaypoints - colsGrid 
            labelsPattern = repmat({'Miss.', 'Unst.', ''}, 1, length(names)); 
            set(gca, 'XTick', xCenter, 'XTickLabel', labelsPattern, 'FontSize', 28, 'TickLabelInterpreter', 'latex');
            xtickangle(0);
        else
            set(gca, 'XTick', []);
        end
        
        colormap(gca, blues);
        clim([globalMin globalMax]); 
    end

    cb = colorbar;
    cb.Layout.Tile = 'east'; 
    ylabel(cb, 'Time in min', 'FontSize', 14, 'FontWeight', 'bold');
    
    fileName = append(baseResultsPath, "/plots/Time/AllWaypoints_Heatmap-accumluated.png");
    exportgraphics(gcf, fileName, 'Resolution', 300);
end


% KEEP
function displayDistanceSinglePlot(baseResultsPath, metrics, usePrecentage, nameMap, orderOfPlots)
    % --- CONFIGURATION ---
    numBrackets = 5+1+1; 
    
    % Categories: Missing, Unstable, Stable (Columns)
    colLabelsPattern = {'Miss.', 'Unst.', 'Stab.', ''}; 
    
    % Colors: Light -> Dark Blue
    blues = [linspace(0.8, 0.0, 256)', linspace(0.9, 0.2, 256)', ones(256,1)];
    grayColor = [0.85, 0.85, 0.85]; 
    
    % Adjusted Font Sizes (Smaller to fit inside cells)
    fontSizeNumers   = 12;   % Reduced from 10
    fontSizeApproach = 12;
    fontSizeLabels   = 12;
    
    % Filter Plot Order
    orderOfPlots(orderOfPlots == "RandomSearch") = [];
    
    % --- 1. GLOBAL RANGE CALCULATION ---
    globalMin = Inf;
    globalMax = -Inf;
    
    unsortedKeys = metrics.keys();
    try
        numericKeys = cellfun(@str2double, unsortedKeys);
        [~, sortIdx] = sort(numericKeys);
        sortedKeys = unsortedKeys(sortIdx);
    catch
        sortedKeys = sort(unsortedKeys);
    end
    numWaypoints = length(sortedKeys);
    
    for k = 1:numWaypoints
        wptMetrics = metrics(sortedKeys{k});
        for approachIdx = 1:length(orderOfPlots)
            appName = orderOfPlots(approachIdx);
            if isKey(wptMetrics, appName)
                appMetricObj = wptMetrics(appName);
                bracket = appMetricObj("bracketsDistanceCount");
               
                if usePrecentage
                    bracket = bracket / sum(bracket, 'all') * 100;
                    
                end
                if ~isempty(bracket)
                    globalMin = min(globalMin, min(bracket(:)));
                    globalMax = max(globalMax, max(bracket(:)));
                end
                bracket = [bracket; sum(bracket,1)];

            end
        end
    end
    if isinf(globalMax), globalMax = 1; globalMin = 0; end
    
    % --- 2. FIGURE SETUP ---
    % Use a wide figure canvas
    figure('Units', 'centimeters', 'Position', [2, 2, 50, 20], 'Color', 'w');
    
    colsGrid = 2; 
    rowsGrid = ceil(numWaypoints / colsGrid);
    t = tiledlayout(rowsGrid, colsGrid, 'TileSpacing', 'compact', 'Padding', 'compact');
    
    % --- 3. PLOTTING LOOP ---
    for k = 1:numWaypoints
        wptIndex = sortedKeys{k};
        nexttile; 
        hold on;
        
        waypointMetrics = metrics(wptIndex);
        if isKey(waypointMetrics, 'StatisticalComparisonResults')
            waypointMetrics.remove('StatisticalComparisonResults');
        end
        
        combinedResults = [];
        names = [];
        
        % Build Data Matrix (Rows=Distance 1-5, Cols=Categories)
        for approachIdx = 1:length(orderOfPlots)
            appName = orderOfPlots(approachIdx);
            names = [names; string(nameMap(string(appName)))];
            
            if isKey(waypointMetrics, appName)
                appMetricObj = waypointMetrics(appName);
                bracket = appMetricObj("bracketsDistanceCount");
                
                if usePrecentage
                    bracket = bracket / sum(bracket, 'all') * 100;
                end
                bracket = [bracket; nan(1,length(colLabelsPattern)-1); sum(bracket,1)];
                
                % Append Data + NaN Gap
                % We do NOT transpose here, keeping 5 rows.
                combinedResults = [combinedResults bracket nan(numBrackets,1)]; 
            else
                 combinedResults = [combinedResults zeros(numBrackets,3) nan(numBrackets,1)];
            end
        end
        
        data = combinedResults;
        [rows, cols] = size(data);
        isGap = all(isnan(data)); 
        
        % Variable Column Widths
        wData = 2.5; wGap = 0.3;
        hDataNaN = 0.03;
        xLeft = zeros(1,cols); xRight = zeros(1,cols); xCenter = zeros(1,cols);
        x = 0;
        for j = 1:cols
            w = wData;
            if isGap(j), w = wGap; end
            
            xLeft(j) = x; xRight(j) = x + w;
            xCenter(j) = (xLeft(j)+xRight(j))/2;
            x = xRight(j);
        end

        isRowGap = all(isnan(data), 2); 
        hData = 1.0; hGap = 0.1; % Normal height vs Padding height
        yBottom = zeros(1,rows); yTop = zeros(1,rows); yCenter = zeros(1,rows);
        y = 0;
        for r = 1:rows
            h = hData;
            if isRowGap(r), h = hGap; end
            
            yBottom(r) = y;
            yTop(r) = y + h;
            yCenter(r) = y + h/2;
            y = yTop(r);
        end
        
        threshold = 0.1;
        useBold = false;
        
        % --- DRAW HEATMAP PATCHES ---
        for r = 1:rows
            for j = 1:cols
                v = data(r,j);
                if isnan(v), continue; end
                
                
                if v == 0 %|| v < 0.01
                    col = grayColor;
                    displayStr = ""; 
                    txtColor = 'k';
                elseif v < threshold
                    %col = grayColor;
                    displayStr = append("$< $", string(threshold)); 
                    txtColor = 'k';
                    t = (v - globalMin) / (globalMax - globalMin);
                    t = max(0, min(1, t));
                    idx = max(1, min(256, round(1 + t*(256-1))));
                    col = blues(idx,:);
                    col = [0.9 0.95 1];
                else
                    t = (v - globalMin) / (globalMax - globalMin);
                    t = max(0, min(1, t));
                    idx = max(1, min(256, round(1 + t*(256-1))));
                    col = blues(idx,:);
                    %if v < 0.1
                    %    displayStr = sprintf('%.2f', v);
                    %else
    
                    displayStr = sprintf('%.1f', v);
                    %end
                    
                    if idx > 90 
                        txtColor = 'w'; 
                    else
                        txtColor = 'k'; 
                    end
                end
        
                %y0 = r-1; y1 = r;
                y0 = yBottom(r); 
                y1 = yTop(r);
                
                patch([xLeft(j) xRight(j) xRight(j) xLeft(j)], ...
                      [y0 y0 y1 y1], col, ...
                      'EdgeColor', grayColor, 'LineWidth', 0.5);
                
                % Text centered in the cell
                %text(xCenter(j),(y0+y1)/2, displayStr, ...
                if useBold

                    text(xCenter(j),yCenter(r), displayStr, ...
                        'HorizontalAlignment','center', ...
                        'VerticalAlignment','middle', ...
                        'FontSize', fontSizeNumers, ...
                        'FontWeight', 'bold', ...
                        'Color', txtColor, ...
                        'Interpreter','latex');
                else
                    text(xCenter(j),yCenter(r), displayStr, ...
                    'HorizontalAlignment','center', ...
                    'VerticalAlignment','middle', ...
                    'FontSize', fontSizeNumers, ...
                    'Color', txtColor, ...
                    'Interpreter','latex');
                end

            end
        end
        
        % --- CRITICAL FIX: ASPECT RATIO ---
        axis tight;
        set(gca, 'YDir', 'reverse');

        set(gca, 'Clipping', 'off')
        
        % Force the plot to be Wide (Width 2.5 : Height 1)
        % This stretches the X-axis to fill the white space
        %pbaspect([2.5 1 1]); 
        
        % Y-Axis: Shows 1, 2, 3, 4, 5
        customLabels = {'1', '2', '3', '4', '5',' Sum', ''};
        set(gca, 'YTick', (0:rows-1)+0.5, 'YTickLabel', customLabels);
        %set(gca, 'YTick', (0:rows-1)+0.5, 'YTickLabel', 1:rows);
        set(gca, 'FontSize', fontSizeLabels);
        
        
        % --- LABELS ---
        % Top Row: Approach Headers
        if k <= colsGrid
            %ylim([-1, rows])
            title({['Waypoint ', wptIndex],''}, 'FontWeight', 'bold');

            patternLength = 4; % 3 Data + 1 Gap
            numGroups = floor(cols / patternLength);
            for g = 1:numGroups
                colStart = (g-1)*patternLength + 1;
                colEnd   = colStart + 3 - 1; 
                groupCenter = mean(xCenter(colStart:colEnd));
                
                text(groupCenter, -0.1, names(g), ...
                    'HorizontalAlignment', 'center', ...
                    'VerticalAlignment', 'bottom', ...
                    'FontWeight', 'bold', ...
                    'FontSize', fontSizeApproach, ...
                    'Interpreter','Latex'); 
            end
        else
            title({['Waypoint ', wptIndex]}, 'FontWeight', 'bold');

        end
        
        % Bottom Row: Categories (Miss, Unst, Stab)
        if k > numWaypoints - colsGrid 
            labelsPattern = repmat(colLabelsPattern, 1, length(names)); 
            set(gca, 'XTick', xCenter, 'XTickLabel', labelsPattern,'FontSize', 12);
            xtickangle(0);
        else
            set(gca, 'XTick', []);
        end
        
        colormap(gca, blues);
        clim([globalMin globalMax]); 
    end
    
    % --- COLORBAR ---
    cb = colorbar;
    cb.Layout.Tile = 'east'; 
    ylabel(cb, 'Distance Count (%)', 'FontSize', 12, 'FontWeight', 'bold');
    
    fileName = append(baseResultsPath, "/plots/Distance/AllWaypoints_Distance.png");
    exportgraphics(gcf, fileName, 'Resolution', 300);
end

function newMap = copyMap(originalMap)
    k = originalMap.keys;
    v = originalMap.values;
    newMap = containers.Map(k, v);
end



% Helper to extract data using your specific structure
function [combinedCounts, allClusterSizes, currentColors, currentDisplayNames, bulkMax, outlierMin, allValues] = getWptData(wptIdx, metrics, orderOfPlots, nameMap, colorMap)
    waypointInfoMap = metrics(wptIdx);
    combinedCounts = []; allClusterSizes = {}; currentColors = []; currentDisplayNames = {}; allValues = [];
    for k = 1:length(orderOfPlots)
        approachName = orderOfPlots(k);
        approachInfo = waypointInfoMap(approachName);
        stats = approachInfo('clusterData');
        approachClusterData = stats('approachClusterData');
        
        % Specific map access
        o = approachClusterData('overallStats'); s = approachClusterData('stableStats');
        u = approachClusterData('unstableStats'); m = approachClusterData('missingStats');
        
        combinedCounts = [combinedCounts; [o('nClustersOverall'), s('nClustersStable'), u('nClustersUnstable'), m('nClustersMissing')]];
        sizes = {o('clusterSizes'), s('clusterSizes'), u('clusterSizes'), m('clusterSizes')};
        allClusterSizes{k} = sizes;
        for j = 1:4, cur = sizes{j}; allValues = [allValues; cur(:)]; end
        currentColors = [currentColors; colorMap(approachName)];
        currentDisplayNames{end+1} = nameMap(approachName);
    end
    bulkMax = prctile(allValues, 90); if isnan(bulkMax) || bulkMax == 0, bulkMax = 10; end
    outliers = allValues(allValues > bulkMax);
    outlierMin = min(outliers); if isempty(outlierMin), outlierMin = bulkMax; end
end

function drawGroupedBoxes(ax, allSizes, colors)
    numApps = length(allSizes);
    offsets = linspace(-0.3, 0.3, numApps);
    for catIdx = 1:4
        for appIdx = 1:numApps
            data = allSizes{appIdx}{catIdx};
            if isempty(data), data = 0; end
            boxplot(ax, data, 'Positions', catIdx + offsets(appIdx), 'Widths', 0.08, 'Colors', colors(appIdx,:), 'Symbol', 'o');
        end
    end
end

% KEEP 
function displayUniqueClusters(baseResultsPath, approachDataMap, metrics, colorMap, uniqueCategoryType, nameMap, orderOfPlots)

    % ------------------------------------------------------------
    % Plot/data parameters
    % ------------------------------------------------------------
    orderOfPlots(orderOfPlots == "FullWP") = [];
    orderOfPlots(orderOfPlots == "RandomSearch") = [];

    categoryNames = ["Overall", "Stable", "Unstable", "Missing"];

    fallbackColor = [0.5, 0.5, 0.5];

    % ------------------------------------------------------------
    % Figure parameters
    % ------------------------------------------------------------
    numRows = 2;
    numCols = 3;

    figurePosition = [2, 2, 80, 25];
    figureBackgroundColor = 'w';

    tileSpacing = 'compact';
    tilePadding = 'compact';

    exportResolution = 300;
    exportFolder = "/plots/Unique/";
    exportFileName = append(uniqueCategoryType, ".png");

    % ------------------------------------------------------------
    % Bar plot visual parameters
    % ------------------------------------------------------------
    barFaceAlpha = 0.6;
    barEdgeColor = 'none';
    barWidth = 0.8;

    gridAlpha = 0.3;

    xAxisMin = 0.5;
    xAxisMax = length(categoryNames) + 0.5;

    % ------------------------------------------------------------
    % Font parameters
    % ------------------------------------------------------------
    titleFontSize = 22;
    titleFontWeight = 'bold';

    axisFontSize = 20;
    xTickFontSize = 20;
    yTickFontSize = 20;

    ylabelFontSize = 24;
    ylabelFontWeight = 'bold';

    tickLabelInterpreter = 'latex';

    legendFontSize = 28;
    legendOrientation = 'horizontal';
    legendInterpreter = 'latex';
    legendTileLocation = 'south';
    legendBox = 'off';
    legendItemTokenSize = [50, 28];

    % ------------------------------------------------------------
    % Choose y-axis label
    % ------------------------------------------------------------
    if uniqueCategoryType == "uniqeClusters" || uniqueCategoryType == "numberOfuniqeClusters"
        valueText = "Number of unique clusters";
    elseif uniqueCategoryType == "clusterSize"
        valueText = "Number of clusters";
    elseif uniqueCategoryType == "notInOthers" || uniqueCategoryType == "NotInOthers"
        valueText = "Percentage of points not in other approaches";
    else
        valueText = string(uniqueCategoryType);
    end

    % ------------------------------------------------------------
    % Figure and layout
    % ------------------------------------------------------------
    metricKeys = metrics.keys();
    numPlots = length(metricKeys);

    figure('Units', 'centimeters', ...
        'Position', figurePosition, ...
        'Color', figureBackgroundColor);

    t = tiledlayout(numRows, numCols, ...
        'TileSpacing', tileSpacing, ...
        'Padding', tilePadding);

    currentDisplayNames = {};
    currentColors = [];

    % ------------------------------------------------------------
    % Plot each waypoint
    % ------------------------------------------------------------
    for plotIndex = 1:numPlots
        wptIndex = metricKeys{plotIndex};
        waypointInfoMap = metrics(wptIndex);

        nexttile;
        hold on;

        combinedStats = [];
        currentDisplayNames = {};
        currentColors = [];

        if isKey(waypointInfoMap, 'StatisticalComparisonResults')
            waypointInfoMap.remove('StatisticalComparisonResults');
        end

        for approachIdx = 1:length(orderOfPlots)
            approachName = orderOfPlots(approachIdx);
            approachInfo = waypointInfoMap(approachName);

            stats = approachInfo('clusterData');

            countOfuniqueClusterMissing = stats('countOfuniqueClusterMissing');
            countOfuniqueClusterOverall = stats('countOfuniqueClusterOverall');
            countOfuniqueClusterStable = stats('countOfuniqueClusterStable');
            countOfuniqueClusterUnstable = stats('countOfuniqueClusterUnstable');

            approachClusterData = stats('approachClusterData');

            overallStats = approachClusterData('overallStats');
            overallClusterSizes = overallStats('clusterSizes');
            nClustersOverall = overallStats('nClustersOverall');

            stableStats = approachClusterData('stableStats');
            stableClusterSizes = stableStats('clusterSizes');
            nClustersStable = stableStats('nClustersStable');

            unstableStats = approachClusterData('unstableStats');
            unstableClusterSizes = unstableStats('clusterSizes');
            nClustersUnstable = unstableStats('nClustersUnstable');

            missingStats = approachClusterData('missingStats');
            missingClusterSizes = missingStats('clusterSizes');
            nClustersMissing = missingStats('nClustersMissing');

            if uniqueCategoryType == "numberOfuniqeClusters" || uniqueCategoryType == "uniqeClusters"
                dataRow = [ ...
                    countOfuniqueClusterOverall, ...
                    countOfuniqueClusterStable, ...
                    countOfuniqueClusterUnstable, ...
                    countOfuniqueClusterMissing ...
                ];

            elseif uniqueCategoryType == "clusterSize"
                dataRow = [ ...
                    nClustersOverall, ...
                    nClustersStable, ...
                    nClustersUnstable, ...
                    nClustersMissing ...
                ];

            elseif uniqueCategoryType == "NotInOthers" || uniqueCategoryType == "notInOthers"
                dataRow = containers.Map( ...
                    {'overallClusterSizes', 'stableClusterSizes', 'unstableClusterSizes', 'missingClusterSizes'}, ...
                    {overallClusterSizes, stableClusterSizes, unstableClusterSizes, missingClusterSizes} ...
                );
            end

            combinedStats = [combinedStats; dataRow];

            if isKey(nameMap, approachName)
                currentDisplayNames{end+1} = nameMap(approachName);
            else
                currentDisplayNames{end+1} = approachName;
            end

            if isKey(colorMap, approachName)
                currentColors = [currentColors; colorMap(approachName)];
            else
                currentColors = [currentColors; fallbackColor];
            end
        end

        % --------------------------------------------------------
        % Bar chart
        % --------------------------------------------------------
        b = bar(combinedStats', 'grouped');

        for barIdx = 1:length(b)
            b(barIdx).FaceColor = currentColors(barIdx, :);
            b(barIdx).FaceAlpha = barFaceAlpha;
            b(barIdx).EdgeColor = barEdgeColor;
        end

        set(b, 'BarWidth', barWidth);

        % --------------------------------------------------------
        % Axis formatting
        % --------------------------------------------------------
        title(append("Waypoint ", wptIndex), ...
            'FontSize', titleFontSize, ...
            'FontWeight', titleFontWeight);

        grid on;
        box on;

        ax = gca;
        ax.GridAlpha = gridAlpha;
        ax.TickLabelInterpreter = tickLabelInterpreter;
        ax.FontSize = axisFontSize;
        ax.XAxis.FontSize = xTickFontSize;
        ax.YAxis.FontSize = yTickFontSize;

        xlim([xAxisMin, xAxisMax]);

        xticks(1:length(categoryNames));

        %isBottomRow = plotIndex > numCols * (numRows - 1);
        isBottomRow = plotIndex + numCols > numPlots;

        if isBottomRow
            xticklabels(categoryNames);
            xtickangle(0);
        else
            xticklabels({});
        end
    end

    % ------------------------------------------------------------
    % Shared y-label
    % ------------------------------------------------------------
    ylabel(t, valueText, ...
        'FontSize', ylabelFontSize, ...
        'FontWeight', ylabelFontWeight);

    % ------------------------------------------------------------
    % Legend
    % ------------------------------------------------------------
    dummyHandles = gobjects(1, length(currentDisplayNames));

    for approachIdx = 1:length(currentDisplayNames)
        dummyHandles(approachIdx) = bar(nan, ...
            'FaceColor', currentColors(approachIdx, :), ...
            'FaceAlpha', barFaceAlpha, ...
            'EdgeColor', barEdgeColor);
    end

    lgd = legend(dummyHandles, currentDisplayNames, ...
        'Orientation', legendOrientation, ...
        'Interpreter', legendInterpreter);

    lgd.Layout.Tile = legendTileLocation;
    lgd.FontSize = legendFontSize;
    lgd.NumColumns = length(currentDisplayNames);
    lgd.ItemTokenSize = legendItemTokenSize;
    lgd.Box = legendBox;

    % ------------------------------------------------------------
    % Export
    % ------------------------------------------------------------
    fileName = append(baseResultsPath, exportFolder, exportFileName);
    exportgraphics(gcf, fileName, 'Resolution', exportResolution);

end
