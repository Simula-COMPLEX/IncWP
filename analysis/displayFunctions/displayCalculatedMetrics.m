function displayCalculatedMetrics(vesselName, resultsPath)
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
        '$\texttt{IncWP}_{Max}$', ...
        '$\texttt{IncWP}_{Min}$', ...
        '$\texttt{RS}$', ...
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

    %displayUniqueClustersLines(baseResultsPath, approachDataMap, metrics, colorMap, "numberOfClusters", nameLatexMap, orderOfPlots)
    %displayUniqueClusters(baseResultsPath, approachDataMap, metrics, colorMap, "clusterSize", nameLatexMap, orderOfPlots)

    displayHVcombinedPlot(baseResultsPath,metrics, colorMap, nameLatexMap, orderOfPlots)
    
    %displayDistanceSinglePlot(baseResultsPath,metrics, usePrecentage,nameLatexMap, orderOfPlots)
    %displayTimeUsage(baseResultsPath,metrics, vesselName,nameMapPlot, orderOfPlots)
    %%displayTimeOnlyFirstCombinedPlot(baseResultsPath, metrics, nameLatexMap, orderOfPlots)
    %latexTimeUsagePerWaypoint(baseResultsPath, metrics, nameLatexMap, orderOfPlots, vesselName)
    %displayTimecombinedPlot(baseResultsPath,metrics, colorMap,nameLatexMap, orderOfPlots)

    %%timeUsageNoBracket(baseResultsPath, metrics, nameLatexMap, orderOfPlots, vesselName, approachSortedInfoMap)
    %distanceNoBracket(baseResultsPath, metrics, nameLatexMap, orderOfPlots, vesselName, approachSortedInfoMap)
    

    %%%%
    % %displayUniquePoints(baseResultsPath, approachDataMap, metrics)
    % 
    % %displayUniquePoints(baseResultsPath, approachDataMap, metrics, colorMap, "unique", nameMap, orderOfPlots)
    %displayUniqueClusters(baseResultsPath, approachDataMap, metrics, colorMap, "numberOfUniqueClusters", nameMap, orderOfPlots)
    %
    % 
    % %displayUniquePoints(baseResultsPath, approachDataMap, metrics, colorMap, "notInOthers",nameMap, orderOfPlots)
    % 
    

    % displayStatistcalTestsRandom(baseResultsPath,metrics, experimentInfoMap,orderOfPlots,vesselName, nameMap)
    % displayStatistcalTestsFull(baseResultsPath,metrics, experimentInfoMap,orderOfPlots, vesselName, nameMap)
    % displayStatistcalTestsApproaches(baseResultsPath,metrics, experimentInfoMap,orderOfPlots, vesselName,nameMap)
    % %displayStatistcalTests(baseResultsPath,metrics, experimentInfoMap,orderOfPlots)
    % 
    % %displayHV(baseResultsPath,metrics, colorMap)
    % %HVlatex(baseResultsPath,metrics)
    % 
    
    % %displayIGD(baseResultsPath,metricsWithoutFullpath)
    % 
    % %displayDistanceLatex(baseResultsPath,metrics, usePrecentage)
    % %displayDistance(baseResultsPath,metrics, usePrecentage)
    % 
    % 
    % %displayTimeLatex(baseResultsPath,metrics)
    % %displayTime(baseResultsPath,metrics)
    % displayTimeOnlyFirst(baseResultsPath,metrics, nameMap, orderOfPlots) % TODO mariner
    


end


function displayStatistcalTestsFull(baseResultsPath,metrics, experimentInfoMap,orderOfPlots, vesselName, nameMap)
    experimentInfoMap.remove('RandomSearch')
    orderOfPlots(orderOfPlots == "FullWP") = [];
    orderOfPlots(orderOfPlots == "RandomSearch") = [];
    comparedAppraochesMap = copyMap(experimentInfoMap);
    

   

    resultsTransformed = [];
    approachName =  "FullWP"
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
                latexApproach = "\leftarrowapproach";
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

function displayStatistcalTestsRandom(baseResultsPath,metrics, experimentInfoMap,orderOfPlots, vesselName, nameMap)
    experimentInfoMap.remove('FullWP')
    orderOfPlots(orderOfPlots == "FullWP") = [];
    orderOfPlots(orderOfPlots == "RandomSearch") = [];
    comparedAppraochesMap = copyMap(experimentInfoMap);
    

   

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
                latexApproach = "\leftarrowapproach"
            elseif chosenApproach == approachRight
                latexApproach = "\rightarrowapproach"
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


function displayStatistcalTestsApproaches(baseResultsPath,metrics, experimentInfoMap,orderOfPlots, vesselName,nameMap)
    experimentInfoMap.remove('FullWP')
    experimentInfoMap.remove('RandomSearch')
    comparedAppraochesMap = copyMap(experimentInfoMap);

   

    for waypointKey = metrics.keys()
        wptIndex = waypointKey{:};
        waypointMetrics = metrics(wptIndex);
        StatisticalComparisonResults = waypointMetrics('StatisticalComparisonResults')
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

function displayStatistcalTests(baseResultsPath,metrics, experimentInfoMap)
    comparedAppraochesMap = copyMap(experimentInfoMap);

   

    for waypointKey = metrics.keys()
        wptIndex = waypointKey{:};
        waypointMetrics = metrics(wptIndex);
        StatisticalComparisonResults = waypointMetrics('StatisticalComparisonResults')
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
    

    filename = append(baseResultsPath,"/plots/HV/","StatisticalTests.tex");

    fid = fopen(filename, 'w');

    N = 7;  % or whatever

    fprintf(fid, '\\begin{tabular}{ll');  % 2 left-aligned text columns
    for w = 2:(length(metrics.keys)+1)
        fprintf(fid, 'r');                % numeric columns for waypoints
    end
    fprintf(fid, '}\n');
    fprintf(fid, '\\toprule\n');
    fprintf(fid, 'Approach Left & Approach Right');
    for w = 2:(length(metrics.keys)+1)
        fprintf(fid, ' & \\waypointGenericIndex{%d}', w);
    end
    
    fprintf(fid, ' \\\\ \\midrule\n');

    
    % change strugyure 
    comparedAppraochesMap = experimentInfoMap

    [rowsComaprisation, columsComparisation] = size(resultsTransformed);
    for row = 1:rowsComaprisation
        lineComparisonResults = resultsTransformed(row,:);
        approachLeft = lineComparisonResults(1);
        approachRight = lineComparisonResults(2);
        resultsComperisation = lineComparisonResults(3:end);
        latexText = [approachLeft, approachRight];
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
        fprintf(fid, '%s', latexText{1});     % first column

        for c = 2:numel(latexText)
            fprintf(fid, ' & %s', latexText{c});
        end
        
        fprintf(fid, ' \\\\ \n');
       
        
    
    end


    fprintf(fid, '\\bottomrule\n');
    fprintf(fid, '\\end{tabular}\n');
    
    fclose(fid);

end

function displayHVcombinedPlot(baseResultsPath,metrics, colorMap, nameMap, orderOfPlots)
    HVcell = cell(1, length(metrics.keys()));
    
    orderedColors = [];
    plotTitles = {};
    HVcellindex = 1;
    names = {};
    addedNames = false;
    for waypointKey = metrics.keys()
        wptIndex = waypointKey{:};
        waypointMetrics = metrics(wptIndex);
        waypointHV = [];
        waypointMetrics.remove('StatisticalComparisonResults');
        for appraochNameIdx = 1:length(orderOfPlots)
            appraochName = orderOfPlots(appraochNameIdx); %approachKey = waypointMetrics.keys()
            %appraochName = approachKey{:};
            appraochMetric = waypointMetrics(appraochName);
            appraochHV = appraochMetric("HV");
            waypointHV = [waypointHV; appraochHV'];
            if addedNames == false
                names{end+1} = string(nameMap(appraochName));
                orderedColors = [orderedColors; colorMap(appraochName)];

            end
        end
        addedNames = true;
        
  
        dataCell{HVcellindex} = waypointHV;
        plotTitles{end+1} = append("Waypoint ", wptIndex);
        HVcellindex = HVcellindex +1;

    end
    numApproaches = size(dataCell{1},1);
    
    %figure('Color', 'w', 'Position', [100, 100, 625, 490]);
    figure('Units', 'centimeters', 'Position', [1, 1, 45, 25], 'Color', 'w');
    t = tiledlayout(ceil(length(metrics.keys())/2), 2, 'TileSpacing', 'compact', 'Padding', 'compact');
    
    axHandles = gobjects(1, length(metrics.keys()));
    legendHandles = gobjects(1, numApproaches); 
    
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
        title(plotTitles{plotIdx}, 'FontSize', 12, 'FontWeight', 'bold');
        xticks(1:numApproaches);
        grid on;
        box on; % Adds the black square frame around the plot
        
        % LOGIC: Only show X-Labels on the bottom row (Plots 5 and 6)
        if plotIdx < (length(metrics.keys()) - 1)
            xticklabels({}); % Remove labels for R1, R2, R3, R4
            set(gca, 'TickLabelInterpreter', 'latex');
        else
            xticklabels(names); % Keep labels for R5, R6
            xtickangle(0);     % Angle them slightly if they overlap
            set(gca, 'TickLabelInterpreter', 'latex');
        end
        
        % Optional: Standardize Y-Axis limits if data ranges are similar
        % ylim([0 5]); 
    end
    
    ylabel(t, 'Hypervolume', 'FontSize', 16, 'FontWeight', 'bold');
    
    
    % B. Shared Legend (Attached to the TiledLayout)
    % We pass the handles we saved from the first plot so colors match perfectly
    lgd = legend(legendHandles, names, 'Orientation', 'horizontal', 'Interpreter', 'latex');
    lgd.Layout.Tile = 'south'; % Moves legend to the outer right sidebar
    %lgd.Title.String = 'Approaches';
    lgd.FontSize = 50;
    lgd.Box = 'off';

    % Add this at the very end of your script to scale text up
    set(findall(gcf, '-property', 'FontSize'), 'FontSize', 15);

    %set(gca, 'TickLabelInterpreter', 'latex');
    fileName = append(baseResultsPath,"/plots/HV/boxPlotHV",".png");
    
    exportgraphics(gcf,fileName,'Resolution',300)


    
    % C. Global Title (Optional, remove if not needed for paper)
    % title(t, 'Hypervolume Comparison Across 6 Experiments', 'FontSize', 16);
    
    % =========================================================================
    % OPTIONAL: Link Axes
    % If all your experiments share the same scale (e.g., 0 to 1), uncomment this:
    % linkaxes(axHandles, 'y');
end

function displayHV(baseResultsPath,metrics, colorMap)
    figureNum = 1;
    HVresultsMap = containers.Map();
    for waypointKey = metrics.keys()
        names = [];
        HVmatrix = [];
        wptIndex = waypointKey{:};
        waypointMetrics = metrics(wptIndex);
        waypointMetrics.remove('StatisticalComparisonResults')
        colorMarix = [];
                    


        for approachKey = waypointMetrics.keys()
            appraochName = approachKey{:};
            
            names = [names; string(appraochName)];
            appraochMetric = waypointMetrics(appraochName);
            appraochHV = appraochMetric("HV");
            wayPointTimeInfo = appraochMetric("wayPointTimeInfo");
            exNums = wayPointTimeInfo('exNums');
            colorMarix = [colorMarix; colorMap(appraochName)];
            if any(appraochHV == 0)

                appraochHV
                appraochName
                wptIndex
                
                close all
                HVmatrix

            end
            if isempty(HVmatrix)
                HVmatrix = appraochHV';
            elseif size(HVmatrix,2) < size(appraochHV,1)
                numMissingExperiments = size(appraochHV,1) - size(HVmatrix,2);
                HVmatrixtemp = [HVmatrix NaN(size(HVmatrix,1),numMissingExperiments)];
                HVmatrix = [HVmatrixtemp; appraochHV'];

            elseif size(HVmatrix,2) > size(appraochHV,1)
                numMissingExperiments = size(HVmatrix,2) - size(appraochHV,1);
                appraochHV = [appraochHV; NaN(numMissingExperiments,1)];
                HVmatrix = [HVmatrix; appraochHV'];

            else
                HVmatrix = [HVmatrix; appraochHV'];
            end
            

               
        end
        HVmatrix
        %data = [data; nonZeroValues(:)];
            
        % Repeat the corresponding group name for each value
        %group = [group; repmat(selectionNames(i), numel(nonZeroValues), 1)];
        figure(figureNum) %, 'Color', 'w')
        set(gcf, 'Position', [100, 100, 1512, 982]); % Set the figure size and position
        %boxplot(HVmatrix', 'Whisker', 1.5)
        hold on; % Crucial: allows us to add boxes one by one

        % 2. Loop through each approach and plot individually
        % This prevents MATLAB from reserving empty "slots" for other colors
        [nApproaches, nRuns] = size(HVmatrix); % Assuming 7x30 matrix
        
        for i = 1:7
            % Extract data for the current approach (Row i)
            currentData = HVmatrix(i, :)'; 
            
            % Plot at numeric position X = i
            % We use 'ones' to position all data points at X = i
            b = boxchart(i * ones(size(currentData)), currentData);
            
           % --- THE KEY PART: ALL COLORS MATCH ---
            thisColor = colorMarix(i, :); % Extract color for this approach
            
            % 1. Fill Color (Make it transparent so lines are visible)
            b.BoxFaceColor = thisColor; 
            b.BoxFaceAlpha = 0.3;          % Lighter fill so the solid lines pop out
            
            % 2. Line Colors (Set everything to the same color)
            b.BoxEdgeColor = thisColor;    % Outline + Median becomes this color
            b.WhiskerLineColor = thisColor;% Whiskers become this color
            b.MarkerColor = thisColor;     % Outliers become this color
            
            % --- WIDTH & THICKNESS ---
            b.LineWidth = 2.0;             % Make lines thick to see them clearly
            b.BoxWidth = 0.6; 
            b.MarkerStyle = 'o';
            b.MarkerSize = 6;
        end
        
        % 3. Fix the Axes (Map numbers 1-7 back to Names)
        xticks(1:7);                % Set ticks at 1, 2, 3...
        xticklabels(names);         % Label them with your names
        grid on;
        
        % 4. Add Legend (Trick to make legend appear correctly)
        % Since we plotted 7 separate items, we can just add a dummy legend
        % or use the handles. But the simplest way now is:
        lgd = legend(names);
        %lgd.Title.String = 'Approaches';
        lgd.Position = [0.85 0.6 0.1 0.3]; % Move legend to the side
        
        % 5. Titles and Labels
        ylabel('HV value', 'FontSize', 14, 'FontWeight', 'bold');
        %title('Accumulated Results', 'FontSize', 16);
        set(gca, 'FontSize', 20); % Make tick labels readable
        
        %ylabel('Accumulated Value');
        %title('accumulated', 'FontWeight', 'bold');
        
        % Add the legend
        % Because we used 'GroupByColor', legend() works automatically
        %lgd = legend;
        %lgd.Title.String = 'Approaches';
        %ax = gca; % Get current axes
        %ax.FontSize = 18;

        %ax.XTickLabel = names; 
        set(gca, 'TickLabelInterpreter', 'latex');
        fileName = append(baseResultsPath,"/plots/HV/boxPlotHV-WPindex-", string(wptIndex),".png");
    
        exportgraphics(ax,fileName,'Resolution',300)


        figureNum = figureNum + 1;
        

    end
    
end

function HVlatex(baseResultsPath,metrics)
    figureNum = 1;
    HVresultsMap = containers.Map();
    HVmatrixTotal = ["waypoint" "appraoch" string(1:30)]

    for waypointKey = metrics.keys()
        names = [];
        HVmatrix = [];
        wptIndex = waypointKey{:};
        waypointMetrics = metrics(wptIndex);
        for approachKey = waypointMetrics.keys()
            appraochName = approachKey{:};
            
            names = [names; string(appraochName)];
            appraochMetric = waypointMetrics(appraochName);
            appraochHV = appraochMetric("HV");
            if isempty(HVmatrix)
                HVmatrix = appraochHV';
            elseif size(HVmatrix,2) < size(appraochHV,1)
                numMissingExperiments = size(appraochHV,1) - size(HVmatrix,2);
                HVmatrixtemp = [HVmatrix zeros(size(HVmatrix,1),numMissingExperiments)];
                HVmatrix = [HVmatrixtemp; appraochHV'];

            elseif size(HVmatrix,2) > size(appraochHV,1)
                numMissingExperiments = size(HVmatrix,2) - size(appraochHV,1);
                appraochHV = [appraochHV; zeros(numMissingExperiments,1)];
                HVmatrix = [HVmatrix; appraochHV'];

            else
                HVmatrix = [HVmatrix; appraochHV'];
            end
            HVmatrixTotal = [HVmatrixTotal; [string(wptIndex) appraochName string(appraochHV')]]


               
        end
        HVmatrixTotal
        %data = [data; nonZeroValues(:)];
            
        % Repeat the corresponding group name for each value
        %group = [group; repmat(selectionNames(i), numel(nonZeroValues), 1)];
        
        

    end
    HVmatrixTotal
    
end

function displayIGD(baseResultsPath,metrics)
    figureNum = 10;
    HVresultsMap = containers.Map();
    for waypointKey = metrics.keys()
        names = [];
        IGDmatrix = [];
        wptIndex = waypointKey{:};
        waypointMetrics = metrics(wptIndex);
        for approachKey = waypointMetrics.keys()
            appraochName = approachKey{:};
            names = [names; string(appraochName)];
            appraochMetric = waypointMetrics(appraochName);
            appraochMetric.keys()
            appraochIGD = appraochMetric("IGD");
            if isempty(IGDmatrix)
                IGDmatrix = appraochIGD';
            elseif size(IGDmatrix,2) < size(appraochIGD,1)
                numMissingExperiments = size(appraochIGD,1) - size(IGDmatrix,2);
                IGDmatrix = [IGDmatrix zeros(size(IGDmatrix,1),numMissingExperiments)];
                IGDmatrix = [IGDmatrix; appraochIGD'];
            elseif size(IGDmatrix,2) > size(appraochIGD,1)
                numMissingExperiments = size(IGDmatrix,2) - size(appraochIGD,1);
                appraochIGD = [appraochIGD; zeros(numMissingExperiments,1)];
                IGDmatrix = [IGDmatrix; appraochIGD'];

            else
                IGDmatrix = [IGDmatrix; appraochIGD'];
            end

               
        end
        %data = [data; nonZeroValues(:)];
            
        % Repeat the corresponding group name for each value
        %group = [group; repmat(selectionNames(i), numel(nonZeroValues), 1)];
        figure(figureNum)
        set(gcf, 'Position', [100, 100, 1512, 982]); % Set the figure size and position
        boxplot(IGDmatrix', 'Whisker', 1.5)
        boxchart(IGDmatrix') %, 'Whisker', 1.5)
        title(append("WPindex ", string(wptIndex)));
        ax = gca; % Get current axes
        ax.FontSize = 18;

        ax.XTickLabel = names; 
        set(gca, 'TickLabelInterpreter', 'latex');
        fileName = append(baseResultsPath,"/plots/IGD/boxPlotIGD-WPindex-", string(wptIndex),".png");
    
        exportgraphics(ax,fileName,'Resolution',300)


        figureNum = figureNum + 1;
        

    end
end


function displayTimecombinedPlot(baseResultsPath,metrics, colorMap, namesMap, orderOfPlots)
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
    figure('Units', 'centimeters', 'Position', [1, 1, 45, 25], 'Color', 'w');
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
    
    figure('Units', 'centimeters', 'Position', [1, 1, 40, 25], 'Color', 'w');

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


function timePerWaypoint(baseResultsPath,metrics,vesselName,nameMap, orderOfPlots)
    orderOfPlots(orderOfPlots == "RandomSearch") = [];
    orderOfPlots(orderOfPlots == "FullWP") = [];
    waypointTimes = [];
    waypointTimesMatrix = [];
    approachNames = ["Approaches"; orderOfPlots'];
    for waypointKey = metrics.keys()
        wptIndex = waypointKey{:};
        waypointMetrics = metrics(wptIndex);
        numSubplots = length(waypointMetrics.keys());
        appraochNamesList = waypointMetrics.keys();
        waypointMetrics.remove('StatisticalComparisonResults')
        waypointTimes =  [wptIndex];
        for approachIdx = 1:length(orderOfPlots)
            appraochName = orderOfPlots(approachIdx);
            appraochMetric = waypointMetrics(appraochName);
            appraochMetric.keys()
            wayPointTimeInfo = appraochMetric("wayPointTimeInfo");
            exNums = wayPointTimeInfo('exNums');
            
            approachTimeExperiments = wayPointTimeInfo('approachTimeExperiments');
            size(approachTimeExperiments)
            timeExperiments = mean(max(approachTimeExperiments))/60;
            waypointTimes = [waypointTimes; string(timeExperiments)];
            
        end
        waypointTimesMatrix = [waypointTimesMatrix waypointTimes];
        
    end
    
    waypointTimesMatrix = [approachNames waypointTimesMatrix];

end

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
        set(gcf, 'Position', [100, 100, 1512, 982]); % Set the figure size and position
        
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

function timeUsageNoBracket(baseResultsPath, metrics, nameMap, orderOfPlots, vesselName, approachDataMap)
    orderOfPlots(orderOfPlots == "RandomSearch") = [];
    %orderOfPlots(orderOfPlots == "FullWP") = [];
    
    screenSize = [1 1 1512 982];
    waypointMean = containers.Map();
    waypointTimes = [];
    fullSetMissingPrev = containers.Map();

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
        averageTime = []; %[string(wptIndex)];
        approachesMean =  containers.Map();

        if isKey(fullSetMissingPrev, string(str2double(wptIndex)-1))
            fullSetMissingWpt = fullSetMissingPrev(string(str2double(wptIndex)-1));
        else
            fullSetMissingWpt = containers.Map();
        end

        for approachIdx = 1:length(orderOfPlots)
            appraochName = orderOfPlots(approachIdx);
            approachData = approachDataMap(appraochName);
            approachData = approachData(wptIndex);
            
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
            
            %approachTimeExperiments = wayPointTimeInfo('approachTimeExperiments');
            %numInd = size(approachTimeExperiments,1);
            %numExp = size(approachTimeExperiments,2);
            %classesMatrix = reshape(classesList, numInd,numExp);
            %unique(classesList)
            %find(classesList == "missing")
            experimentsFirst = [];
            for exNumKey = approachData.keys
                exNum = exNumKey{:};
                experimentData = approachData(exNum);
                exClasses = experimentData('classes');
                exTimes = experimentData('timestamp');
                %classesList =approachData('classes');

                if appraochName == "FullWP" 
                    if isKey(fullSetMissingWpt, string(exNum))
                        fullSetMissingList = fullSetMissingWpt(string(exNum));
                    else
                        fullSetMissingList = zeros(size(exClasses,1),1);
                    end

                    %indexToIngoreFullwpt = [indexToIngoreFullwpt; indexToIngoreStart+ find(fullSetMissingList)];
                    %indexToIngoreStart = indexToIngoreStart + size(fullSetMissingList,1);

                    newMissing = (exClasses == "missing");
                    %newMissingIdx = find(newMissing) + indexToIngoreStart;
                    
                    exClasses = exClasses(~fullSetMissingList,:);
                    exTimes = exTimes(~fullSetMissingList,:);
                    

                    fullSetMissingList = newMissing | (fullSetMissingList == 1); %% this need to be updated after
                    fullSetMissingWpt(string(exNum)) = fullSetMissingList;
                    
                    

                    % remove prev missing
                    % update the list for the next experiments
                    % remeber to update for the next waypoint too
                end
                %exTimes = approachTimeExperiments(:,exNum);
                %exClasses = classesMatrix(:,exNum);
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
            missingTimes = experimentsFirst(:,1);
            missingTimes = missingTimes(~isnan(missingTimes));
            if size(missingTimes) > 0
                meanMissing = mean(missingTimes);
            else
                meanMissing = NaN;
            end

            unstableTimes = experimentsFirst(:,2);
            unstableTimes = unstableTimes(~isnan(unstableTimes));
            if size(unstableTimes) > 0
                meanUnstable = mean(unstableTimes);
            else
                meanUnstable = NaN;
            end
            
            meanFirst = [meanMissing, meanUnstable];
            
            approachesMean(appraochName) = meanFirst/60;
        end
        fullSetMissingPrev(wptIndex) = fullSetMissingWpt;
        waypointMean(wptIndex) = approachesMean;


    end
    % make it into a matrix
    meanMatrix = [];
    namesAdded = false;
    names = [];

    for waypointKey = waypointMean.keys()
        wptIndex = waypointKey{:};
        approachesMean = waypointMean(wptIndex);
        wptMean = []; %[str2double(wptIndex)];
        for approachIdx = 1:length(orderOfPlots)
           appraochName = orderOfPlots(approachIdx);
           aMean = approachesMean(appraochName);
           if sum(isnan(aMean)) > 0
               isnan(aMean)
                aMean(isnan(aMean)) = -1*ones(1,sum(isnan(aMean)));
           end
          
           wptMean = [wptMean aMean NaN];
           if namesAdded == false
                names = [names; string(nameMap(string(appraochName)))];
           end
        end
        namesAdded = true;
        
        meanMatrix = [meanMatrix; wptMean];


    end
    %meanMatrix = meanMatrix(:,1:end-1);
    %names = orderOfPlots;

    % make the heatmap 
    % add the names on top correctly
    % make the NaN gray
    % have the left be the wpt2 etc
    globalMin = min(meanMatrix(:));
    globalMax = max(meanMatrix(:));
    



    meanMatrix
    [numWayPoints, numColApproaches] = size(meanMatrix);
    %flagCategoriesToIndlcude = [1, 2]; % firstMissing, firstUnstable
    
    % Colors: Light (Index 1) -> Dark (Index 256)
    blues = [linspace(0.8, 0.0, 256)', linspace(0.9, 0.2, 256)', ones(256,1)];
    
    % Gray for missing data (-1) AND grid lines
    grayColor = [0.85, 0.85, 0.85]; 
    
    % UPDATED Font Sizes
    fontSizeNumers   = 14;   
    fontSizeApproach = 18;
    fontSizeLabels   = 18;

    % --- 1. GLOBAL RANGE CALCULATION ---
   
    figure('Units', 'centimeters', 'Position', [2, 2, 50, 20], 'Color', 'w');

  
    %t = tiledlayout(rowsGrid, colsGrid, 'TileSpacing', 'compact', 'Padding', 'compact');

    data = meanMatrix;
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
            %patch([xLeft(j) xRight(j) xRight(j) xLeft(j)], ...
            %      [y0 y0 y1 y1], col, ...
            %      'EdgeColor', grayColor, 'LineWidth', 0.5);
            patch([xLeft(j) xRight(j) xRight(j) xLeft(j)], ...
                  [y0 y0 y1 y1], col, ...
                  'EdgeColor', blues(10,:), 'LineWidth', 0.5);
            
              
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
    patternLength = 3;
    numGroups = floor(cols/ patternLength);
    
    for g = 1:numGroups
        colStart = (g-1)*patternLength + 1
        colEnd   = colStart + patternLength  - 2

        
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
    %waypointText = '$\ensuremath{\mathit{wp}}\xspace$';
    %customLabels = []
    %customLabelsArray = {};
    numWpt = cols/3;
    %for wptIdx = 2:numWpt+1
        %customLabels = [customLabels;  append('$\ensuremath{\mathit{wp_',char(wptIdx), '}}\xspace$')];
        %customLabelsArray{end+1} = append('$\ensuremath{\mathit{wp_',char(wptIdx), '}}\xspace$');
    %    customLabelsArray{end+1} = append('$wp_',char(wptIdx), '$');
    %end
    customLabelsArray = {}; % Initialize
    for wptIdx = 2:numWpt+1
        % Use num2str to get the actual digit '2', '3', etc.
        customLabelsArray{end+1} = append('$wp_{', num2str(wptIdx), '}$');
    end

    
    
    %'$\mathit{fit_{unstable}}$'
    
    axis tight;
    set(gca, 'YDir', 'reverse');
    set(gca, 'FontSize', fontSizeLabels+4);
    %customLabels = {'2', '3', '4', '5', '6','7'};
    %set(gca, 'YTick', (0:rows-1)+0.5, 'YTickLabel', customLabelsArray,  'TickLabelInterpreter', 'latex');
    set(gca, 'YTick', (0:numWpt-1)+0.5, ...
         'YTickLabel', customLabelsArray, ...
         'TickLabelInterpreter', 'latex');
    set(gca, 'FontSize', fontSizeLabels+4);
    labelsPattern = repmat({'Miss.', 'Unst.', ''}, 1, length(names)); 
    set(gca, 'XTick', xCenter, 'XTickLabel', labelsPattern, 'FontSize', 20, 'TickLabelInterpreter', 'latex');
    xtickangle(0);

    

    colormap(gca, blues);
    clim([globalMin globalMax]);
    cb = colorbar;
    %cb.Layout.Tile = 'east'; 
    ylabel(cb, 'Time in min', 'FontSize', 16, 'FontWeight', 'bold');
    
    fileName = append(baseResultsPath, "/plots/Time/Heatmap_minTime.png");
    exportgraphics(gcf, fileName, 'Resolution', 300);


end

function distanceNoBracket(baseResultsPath, metrics, nameMap, orderOfPlots, vesselName, approachDataMap)
    orderOfPlots(orderOfPlots == "RandomSearch") = [];
    %orderOfPlots(orderOfPlots == "FullWP") = [];
    
    screenSize = [1 1 1512 982];
    waypointMean = containers.Map();
    waypointTimes = [];
    fullSetMissingPrev = containers.Map();

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
        averageTime = []; %[string(wptIndex)];
        approachesMean =  containers.Map();

        if isKey(fullSetMissingPrev, string(str2double(wptIndex)-1))
            fullSetMissingWpt = fullSetMissingPrev(string(str2double(wptIndex)-1));
        else
            fullSetMissingWpt = containers.Map();
        end

        for approachIdx = 1:length(orderOfPlots)
            appraochName = orderOfPlots(approachIdx);
            approachData = approachDataMap(appraochName);
            approachData = approachData(wptIndex);
            
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
            
            %approachTimeExperiments = wayPointTimeInfo('approachTimeExperiments');
            %numInd = size(approachTimeExperiments,1);
            %numExp = size(approachTimeExperiments,2);
            %classesMatrix = reshape(classesList, numInd,numExp);
            %unique(classesList)
            %find(classesList == "missing")
            experimentsFirst = [];
            for exNumKey = approachData.keys
                exNum = exNumKey{:};
                experimentData = approachData(exNum);
                %exObjs = experimentData('objectives,')
                exClasses = experimentData('classes');
                %exTimes = experimentData('timestamp');
                %classesList =approachData('classes');

                if appraochName == "FullWP" 
                    if isKey(fullSetMissingWpt, string(exNum))
                        fullSetMissingList = fullSetMissingWpt(string(exNum));
                    else
                        fullSetMissingList = zeros(size(exClasses,1),1);
                    end

                    %indexToIngoreFullwpt = [indexToIngoreFullwpt; indexToIngoreStart+ find(fullSetMissingList)];
                    %indexToIngoreStart = indexToIngoreStart + size(fullSetMissingList,1);

                    newMissing = (exClasses == "missing");
                    %newMissingIdx = find(newMissing) + indexToIngoreStart;
                    
                    exClasses = exClasses(~fullSetMissingList,:);
                    %exTimes = exTimes(~fullSetMissingList,:);
                    

                    fullSetMissingList = newMissing | (fullSetMissingList == 1); %% this need to be updated after
                    fullSetMissingWpt(string(exNum)) = fullSetMissingList;
                    
                    

                    % remove prev missing
                    % update the list for the next experiments
                    % remeber to update for the next waypoint too
                end
                %exTimes = approachTimeExperiments(:,exNum);
                %exClasses = classesMatrix(:,exNum);
                idxMissing = find(exClasses == "missing")';
                idxUnstable = find(exClasses == "unstable")';
                idxStable = find(exClasses == "stable")';
               
                
                if size(idxMissing) > 0  
                    firstMissing = size(idxMissing,2);
                else
                    firstMissing = NaN;
                end

                if size(idxUnstable) > 0  
                    firstUnstable = size(idxUnstable,2);
                else
                    firstUnstable = NaN;
                end

                if size(idxStable) > 0  
                    firstStable = size(idxStable,2);
                else
                    firstStable = NaN;
                end
                

                experimentsFirst = [experimentsFirst; [firstMissing firstUnstable firstStable]];
                
            end
            % find the count - devide by the total
            missingList =  experimentsFirst(:,1);
            missingNotNan = missingList(~isnan(missingList));
            totalMissing = sum(missingNotNan);

            unstableList =  experimentsFirst(:,2);
            unstableNotNan = unstableList(~isnan(unstableList));
            totalUnstable = sum(unstableNotNan);

            stableList =  experimentsFirst(:,3);
            stableNotNan = stableList(~isnan(stableList));
            totalStable = sum(stableNotNan);


            total = totalMissing + totalUnstable + totalStable;
            if totalMissing > 0 
                meanMissing = totalMissing/total;
            else
                meanMissing = NaN;
            end

            if totalUnstable > 0 
                meanUnstable = totalUnstable/total;
            else
                meanUnstable = NaN;
            end

            if totalStable > 0 
                meanStable = totalStable/total;
            else
                meanStable = NaN;
            end

            

            
            meanFirst = [meanMissing, meanUnstable meanStable];
            
            approachesMean(appraochName) = meanFirst*100;
        end
        fullSetMissingPrev(wptIndex) = fullSetMissingWpt;
        waypointMean(wptIndex) = approachesMean;


    end
    % make it into a matrix
    meanMatrix = [];
    namesAdded = false;
    names = [];

    for waypointKey = waypointMean.keys()
        wptIndex = waypointKey{:};
        approachesMean = waypointMean(wptIndex);
        wptMean = []; %[str2double(wptIndex)];
        for approachIdx = 1:length(orderOfPlots)
           appraochName = orderOfPlots(approachIdx);
           aMean = approachesMean(appraochName);
           if sum(isnan(aMean)) > 0
                aMean(isnan(aMean)) = -1*ones(1,sum(isnan(aMean)));
           end
          
           wptMean = [wptMean aMean NaN];
           if namesAdded == false
                names = [names; string(nameMap(string(appraochName)))];
           end
        end
        namesAdded = true;
        
        meanMatrix = [meanMatrix; wptMean];


    end
    %meanMatrix = meanMatrix(:,1:end-1);
    %names = orderOfPlots;

    % make the heatmap 
    % add the names on top correctly
    % make the NaN gray
    % have the left be the wpt2 etc
    globalMin = min(meanMatrix(:));
    globalMax = max(meanMatrix(:));
    



    meanMatrix
    [numWayPoints, numColApproaches] = size(meanMatrix);
    %flagCategoriesToIndlcude = [1, 2]; % firstMissing, firstUnstable
    
    % Colors: Light (Index 1) -> Dark (Index 256)
    blues = [linspace(0.8, 0.0, 256)', linspace(0.9, 0.2, 256)', ones(256,1)];
    
    % Gray for missing data (-1) AND grid lines
    grayColor = [0.85, 0.85, 0.85]; 
    
    % UPDATED Font Sizes
    fontSizeNumers   = 14;   
    fontSizeApproach = 18;
    fontSizeLabels   = 18;
    threshold = 0.1;

    % --- 1. GLOBAL RANGE CALCULATION ---
   
    figure('Units', 'centimeters', 'Position', [2, 2, 50, 20], 'Color', 'w');

  
    %t = tiledlayout(rowsGrid, colsGrid, 'TileSpacing', 'compact', 'Padding', 'compact');

    data = meanMatrix;
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
            
            % --- NEW: IDENTIFY THE TRIPLET GROUP ---
            % This finds the start column of the current 3-category block
            blockStart = floor((j-1)/3)*3 + 1; 
            rowTriplet = data(r, blockStart : blockStart+2);
            
            % Check if any other value in this specific row/group is "tiny"
            otherValues = rowTriplet( [1:3] ~= (j - blockStart + 1) );
            tinyValueExists = any(otherValues > 0 & otherValues < threshold);
            % ---------------------------------------
    
            if v < 0
                col = grayColor; 
                idx = 0; 
                displayStr = "";
            elseif v == 0
                col = grayColor;
                idx = 0; % Fixed: you had idx=v, but v is 0 here
                displayStr = ""; 
                txtColor = 'k';
            elseif v < threshold
                displayStr = append("<", string(threshold)); 
                txtColor = 'k';
                t = (v - globalMin) / (globalMax - globalMin);
                t = max(0, min(1, t));
                idx = max(1, min(256, round(1 + t*(256-1))));
                col = [0.9 0.95 1]; % Your light blue highlight
            else
                t = (v - globalMin) / (globalMax - globalMin);
                t = max(0, min(1, t));
                idx = max(1, min(256, round(1 + t*(256-1))));
                col = blues(idx,:);
                
                % Smart Rounding: 
                % If v is e.g. 99.96, it would normally round to 100.0.
                % If a neighbor is <0.1, we force v to display as 99.9.
                if v > (100 - threshold) && tinyValueExists
                    displayStr = sprintf('%.1f', 100 - threshold);
                else
                    displayStr = sprintf('%.1f', v);
                end
                
                % Dynamic text color for readability against dark blue
                if v > 50, txtColor = 'w'; else, txtColor = 'k'; end
            end
            
            % The displayStr is now already a string from the logic above, 
            % so we don't need the final isstring check unless you prefer it.
            
        
                
            
            y0 = r-1; y1 = r;
            % Grid lines now match the grayColor
            %patch([xLeft(j) xRight(j) xRight(j) xLeft(j)], ...
            %      [y0 y0 y1 y1], col, ...
            %      'EdgeColor', grayColor, 'LineWidth', 0.5);
            patch([xLeft(j) xRight(j) xRight(j) xLeft(j)], ...
                  [y0 y0 y1 y1], col, ...
                  'EdgeColor', blues(10,:), 'LineWidth', 0.5);
            
              
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

                %if isnan(displayStr)
                %    displayStr
                %end
                
                text(xCenter(j),(y0+y1)/2, displayStr, ...
                    'HorizontalAlignment','center', ...
                    'VerticalAlignment','middle', ...
                    'FontSize', fontSizeNumers, ...
                    'Color', txtColor); 
                % 'FontWeight', 'bold', ...
                %text(xCenter(j),(y0+y1)/2, sprintf('%.2f',displayStr), ...
                %    'HorizontalAlignment','center', ...
                %    'VerticalAlignment','middle', ...
                %    'FontSize', fontSizeNumers, ...
                %    'Color', txtColor, ...
                %    'Interpreter','latex');

            end
        end
    end
    patternLength = 4;
    numGroups = floor(cols/ patternLength);
    
    for g = 1:numGroups
        colStart = (g-1)*patternLength + 1
        colEnd   = colStart + patternLength  - 2

        
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
    %waypointText = '$\ensuremath{\mathit{wp}}\xspace$';
    %customLabels = []
    %customLabelsArray = {};
    numWpt = cols/3;
    %for wptIdx = 2:numWpt+1
        %customLabels = [customLabels;  append('$\ensuremath{\mathit{wp_',char(wptIdx), '}}\xspace$')];
        %customLabelsArray{end+1} = append('$\ensuremath{\mathit{wp_',char(wptIdx), '}}\xspace$');
    %    customLabelsArray{end+1} = append('$wp_',char(wptIdx), '$');
    %end
    customLabelsArray = {}; % Initialize
    for wptIdx = 2:numWpt+1
        % Use num2str to get the actual digit '2', '3', etc.
        customLabelsArray{end+1} = append('$wp_{', num2str(wptIdx), '}$');
    end

    
    
    %'$\mathit{fit_{unstable}}$'
    
    axis tight;
    set(gca, 'YDir', 'reverse');
    set(gca, 'FontSize', fontSizeLabels+4);
    %customLabels = {'2', '3', '4', '5', '6','7'};
    %set(gca, 'YTick', (0:rows-1)+0.5, 'YTickLabel', customLabelsArray,  'TickLabelInterpreter', 'latex');
    set(gca, 'YTick', (0:numWpt-1)+0.5, ...
         'YTickLabel', customLabelsArray, ...
         'TickLabelInterpreter', 'latex');
    set(gca, 'FontSize', fontSizeLabels+4);
    labelsPattern = repmat({'Miss.', 'Unst.','Stab.' , ''}, 1, length(names)); 
    set(gca, 'XTick', xCenter, 'XTickLabel', labelsPattern, 'FontSize', 20, 'TickLabelInterpreter', 'latex');
    xtickangle(0);

    

    colormap(gca, blues);
    clim([globalMin globalMax]);
    cb = colorbar;
    %cb.Layout.Tile = 'east'; 
    ylabel(cb, '% of population', 'FontSize', 16, 'FontWeight', 'bold');
    
    fileName = append(baseResultsPath, "/plots/Distance/Heatmap_distance.png");
    
    exportgraphics(gcf, fileName, 'Resolution', 300);


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
            set(gca, 'XTick', xCenter, 'XTickLabel', labelsPattern, 'FontSize', 15, 'TickLabelInterpreter', 'latex');
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

function displayTimeOnlyFirst(baseResultsPath,metrics, nameMap, orderOfPlots)
    orderOfPlots(orderOfPlots == "RandomSearch") = [];

    orderOfPlots
    numBrackets = 5;
    figureNum = 30;
    %labelsClasses = ["timespan", "firstMissing", "lastMissing", "missingEfficency", "firstUnstable", "lastUnstable", ...
    %                "unstableEfficency", "firstStable", "lastStable", "stableEfficency"];
    labelsClasses = ["average first missing", "average first unstable", "average first stable"];
    %flagCategoriesToIndlcude = [1, ...        % timespan  
    %                            2, 4, ...  %firstMissing", "lastMissing", "missingEfficency"
    %                            5, 7 ...  %"firstUnstable", "lastUnstable",  "unstableEfficency"
    %                            8, 10];     % "firstStable", "lastStable", "stableEfficency"
                                
    %flagCategoriesToIndlcude = [2, ...  %firstMissing", 
    %                            5] ;  %"firstUnstable", "
    flagCategoriesToIndlcude = [1, ...  %firstMissing", 
                                2] ;  %"firstUnstable", "
                                
    labelsBrackets = string(1:numBrackets);

    screenSize = [1 1 1512 400];
    overallMap = containers.Map();
    % Original names

    labelOffset = 0 %-0.1;
    xOffset     = 0.005;        % horizontal fine-tune; >0 → right, <0 → left
    nameBoxW    = 0.02;
    nameBoxH    = 0.02;

    baseOffset    = 0.03;     % + right, - left (same for all)
    driftPerGroup = 0.0006;  % try small values: -0.002, -0.001, 0.001, ...

   fontSizeNumers = 12;
   fontSizeApproach = 14;
   fontSizeLabels = 13;

    for waypointKey = metrics.keys()
        names = [];
        HVmatrix = [];
        wptIndex = waypointKey{:};
        waypointMetrics = metrics(wptIndex);
        numSubplots = length(waypointMetrics.keys());
        appraochNamesList = waypointMetrics.keys();
        figure(figureNum)
        waypointMetrics.remove('StatisticalComparisonResults')
        combinedResults = [];

        %for approachKey = waypointMetrics.keys()
        %    appraochName = approachKey{:};

        for approachIdx = 1:length(orderOfPlots) %waypointMetrics.keys())
            appraochName = orderOfPlots(approachIdx);
            if any(ismember(appraochName, overallMap.keys()))
                overall = overallMap(appraochName);
            else 
                overall = zeros(numBrackets, length(flagCategoriesToIndlcude));
            end

            names = [names; string(appraochName)];
            appraochMetric = waypointMetrics(appraochName);
            appraochMetric.keys()
            appraochBracket = appraochMetric("bracketsTimeCount");
            wayPointTimeInfo = appraochMetric("wayPointTimeInfo");
            %size(appraochBracket)
            appraochBracket = appraochBracket(:,flagCategoriesToIndlcude);
            appraochBracket(isnan(appraochBracket)) = -1;
            appraochBracket

            %size(appraochBracket)


            %subplot(ceil(numSubplots/2), 2, find(strcmp(appraochNamesList, appraochName)))
            %heatmap(labelsClasses(flagCategoriesToIndlcude), labelsBrackets, appraochBracket);
            overallMap(appraochName) = overall;

            %title(append(appraochName));
            %ax = gca; % Get current axes
            %ax.FontSize = 18;
            combinedResults = [combinedResults appraochBracket nan(numBrackets,1)];

    
            
               
        end
        data = combinedResults;                     % your data with NaN separators
        [rows, cols] = size(data);
        isGap = all(isnan(data));            % which columns are NaN separators?
        
        wData = 1;                           % width of normal columns
        wGap  = 0.3;                         % narrower width for NaN columns
        
        % --- compute x positions for each column (variable widths) ---
        xLeft   = zeros(1,cols);
        xRight  = zeros(1,cols);
        xCenter = zeros(1,cols);
        
        x = 0;
        for j = 1:cols
            w = wData;
            if isGap(j), w = wGap; end
            xLeft(j)   = x;
            xRight(j)  = x + w;
            xCenter(j) = (xLeft(j)+xRight(j))/2;
            x = xRight(j);
        end
        
        % --- colour mapping ---
        validVals = data(~isnan(data));
        vmin = min(validVals);
        vmax = max(validVals);
        
        %cmap = parula(256);
        %blues = [linspace(0.9,0.1,256)'  linspace(0.9,0.1,256)'  ones(256,1)];
        blues = [ ...
                linspace(0.8, 0.0, 256)' ...   % R: light to 0
                linspace(0.9, 0.2, 256)' ...   % G: light to 0.2
                ones(256,1) ...                % B: stays strong
            ];
                    
        figure(figureNum); clf; hold on;
        
        
        % --- draw rectangles (no patch for NaN → real narrow gap) ---
        for r = 1:rows
            for j = 1:cols
                if isnan(data(r,j)), continue; end
        
                v = data(r,j);
                if v < 0
                    col = [0.95 0.95 0.95];    % gray cell
                else
                    t = (v - vmin) / (vmax - vmin);
                    idx = max(1, min(256, round(1 + t*(256-1))));
                    col = blues(idx,:);
                end
        
                % --- DRAW CELL ---
                y0 = r-1;  y1 = r;
                patch([xLeft(j) xRight(j) xRight(j) xLeft(j)], ...
                      [y0 y0 y1 y1], col, ...
                      'EdgeColor',[0.95 0.95 0.95]);
        
                % --- DRAW TEXT (ONLY IF NON-NEGATIVE) ---
                if v >= 0
                    text(xCenter(j),(y0+y1)/2, sprintf('%.1f',v), ...
                        'HorizontalAlignment','center', ...
                        'VerticalAlignment','middle', ...
                        'FontSize', fontSizeNumers);
                end
            end
        end
        
        %axis equal tight;
        %set(gca,'YDir','reverse');
        axis tight;                % Removes 'equal' constraint so Y can stretch
        pbaspect([cols rows*0.6 1]); % Manually force aspect ratio (Width, Height, Depth)
                                   % Increasing the middle number makes rows taller.
                                   % Try 0.6, 0.8, or 1.0 depending on preference.
        
        set(gca, 'YDir', 'reverse');
        
        % --- ticks & labels ---
        set(gca,'YTick',(0:rows-1)+0.5,'YTickLabel',1:rows);
        
        pattern = {'missing','unstable',''};
        numGroups = cols/length(pattern);                  % 3 data + 1 gap each
        xlab = repmat(pattern,1,numGroups);
        set(gca,'XTick',xCenter,'XTickLabel',xlab);
        %ax.YRuler.FontSize = fontSizeLabels;
        set(gca,'FontSize',fontSizeLabels); 
        xtickangle(0); 
        colormap(blues);
        caxis([vmin vmax]);
        colorbar;
        
        % --- approach titles ABOVE the axes ---
        ax  = gca;
        pos = get(ax,'Position');
        f = gcf; % Get current figure handle

        set(gca,'TickLength',[0 0]);

        set(f, 'Position', screenSize);
        

        %pos = get(gca,'Position');
        %pos(2) = 0.25;   % move axis up
        %pos(4) = 0.55;
        %set(gca,'Position',pos);
        


        groupCenters = zeros(1,numGroups);
        for g = 1:numGroups
            colStart          = (g-1)*length(pattern) + 1;
            colEnd            = colStart + 2;
            groupCenters(g)   = mean(xCenter(colStart:colEnd));
        end
        
        for g = 1:numGroups
            nx = (groupCenters(g) - xLeft(1)) / (xRight(end) - xLeft(1));
        
            xNorm = pos(1) + nx*pos(3) - nameBoxW/2 ...
                    + baseOffset + driftPerGroup*(g-1);
            yNorm = pos(2) + pos(4) + labelOffset;
        
            annotation('textbox', ...
                [xNorm, yNorm, nameBoxW, nameBoxH], ...
                'String', names(g), ...
                'HorizontalAlignment','center', ...
                'VerticalAlignment','bottom', ...
                'FontWeight','bold', ...
                'FontSize',fontSizeApproach, ...
                'LineStyle','none');
        end

        % save
        fileName = append(baseResultsPath,"/plots/Time/heatmap-timeusage-PerWP",  string(wptIndex),".png");
        exportgraphics(f,fileName,'Resolution',300)

        figureNum = figureNum +1;

        % sgtitle(append("WPIndex", wptIndex))
        % figureNum = figureNum +1;
        % f = gcf; % Get current figure handle
        % set(f, 'Position', screenSize);
        % fileName = append(baseResultsPath,"/plots/Time/heatmap-timeusage-PerWP",  string(wptIndex),".png");
        % exportgraphics(f,fileName,'Resolution',300)

    end

    % figure(figureNum)
    % sgtitle("Overall ")
    % for approachKey = waypointMetrics.keys()
    %     appraochName = approachKey{:};
    %     overall = overallMap(appraochName);
    % 
    % 
    %     names = [names; string(appraochName)];
    %     appraochBracket = overallMap(appraochName);
    % 
    % 
    % 
    %     subplot(ceil(numSubplots/2), 2, find(strcmp(appraochNamesList, appraochName)))
    %     heatmap(labelsClasses(flagCategoriesToIndlcude), labelsBrackets, appraochBracket);
    % 
    %     title(append(appraochName));
    %     ax = gca; % Get current axes
    %     ax.FontSize = 18;
    % 
    % 
    % 
    % end
    % sgtitle("Overall")
    % figureNum = figureNum +1;
    % f = gcf; % Get current figure handle
    % set(f, 'Position', screenSize);
    % fileName = append(baseResultsPath,"/plots/Time/heatmap-timeusage-Overall",".png");
    % exportgraphics(f,fileName,'Resolution',300)

end

function displayTime(baseResultsPath,metrics)

    numBrackets = 5;
    figureNum = 30;
    %labelsClasses = ["% Missing", "% Unstable",  "% Stable"];
    labelsClasses = ["timespan", "firstMissing", "lastMissing", "missingEfficency", "firstUnstable", "lastUnstable", ...
                    "unstableEfficency", "firstStable", "lastStable", "stableEfficency"];
    flagCategoriesToIndlcude = [1, ...        % timespan  
                                2, 4, ...  %firstMissing", "lastMissing", "missingEfficency"
                                5, 7 ...  %"firstUnstable", "lastUnstable",  "unstableEfficency"
                                8, 10];     % "firstStable", "lastStable", "stableEfficency"
                                
    labelsBrackets = string(1:numBrackets);
    screenSize = [1 1 1512 982];
    overallMap = containers.Map();

    for waypointKey = metrics.keys()
        names = [];
        HVmatrix = [];
        wptIndex = waypointKey{:};
        waypointMetrics = metrics(wptIndex);
        numSubplots = length(waypointMetrics.keys());
        appraochNamesList = waypointMetrics.keys();
        figure(figureNum)

        for approachKey = waypointMetrics.keys()
            appraochName = approachKey{:};
            if any(ismember(appraochName, overallMap.keys()))
                overall = overallMap(appraochName);
            else 
                overall = zeros(numBrackets, length(flagCategoriesToIndlcude));
            end

            names = [names; string(appraochName)];
            appraochMetric = waypointMetrics(appraochName);
            appraochMetric.keys()
            appraochBracket = appraochMetric("bracketsTimeCount");
            wayPointTimeInfo = appraochMetric("wayPointTimeInfo");
            size(appraochBracket)
            appraochBracket = appraochBracket(:,flagCategoriesToIndlcude)
            size(appraochBracket)


            subplot(ceil(numSubplots/2), 2, find(strcmp(appraochNamesList, appraochName)))
            heatmap(labelsClasses(flagCategoriesToIndlcude), labelsBrackets, appraochBracket);
            %overall(:,1) = max([overall(:,1) appraochBracket(:,1)])
            %overall = overall + appraochBracket(flagCategoriesToIndlcude);
            overallMap(appraochName) = overall;

            title(append(appraochName));
            ax = gca; % Get current axes
            ax.FontSize = 18;
    
            
               
        end

        sgtitle(append("WPIndex", wptIndex))
        figureNum = figureNum +1;
        f = gcf; % Get current figure handle
        set(f, 'Position', screenSize);
        fileName = append(baseResultsPath,"/plots/Time/heatmap-timeusage-PerWP",  string(wptIndex),".png");
        exportgraphics(f,fileName,'Resolution',300)

    end

    figure(figureNum)
    sgtitle("Overall ")
    for approachKey = waypointMetrics.keys()
        appraochName = approachKey{:};
        overall = overallMap(appraochName);
       

        names = [names; string(appraochName)];
        appraochBracket = overallMap(appraochName);
        


        subplot(ceil(numSubplots/2), 2, find(strcmp(appraochNamesList, appraochName)))
        heatmap(labelsClasses(flagCategoriesToIndlcude), labelsBrackets, appraochBracket);
        
        title(append(appraochName));
        ax = gca; % Get current axes
        ax.FontSize = 18;

        
           
    end
    sgtitle("Overall")
    figureNum = figureNum +1;
    f = gcf; % Get current figure handle
    set(f, 'Position', screenSize);
    fileName = append(baseResultsPath,"/plots/Time/heatmap-timeusage-Overall",".png");
    exportgraphics(f,fileName,'Resolution',300)

end

function displayTimeLatex(baseResultsPath,metrics)

    numBrackets = 5;
    %labelsClasses = ["% Missing", "% Unstable",  "% Stable"];
    labelsClasses = ["timespan", "firstMissing", "lastMissing", "missingEfficency", "firstUnstable", "lastUnstable", ...
                    "unstableEfficency", "firstStable", "lastStable", "stableEfficency"];
    flagCategoriesToIndlcude = [1, ...        % timespan  
                                2, 4, ...  %firstMissing", "lastMissing", "missingEfficency"
                                5, 7 ...  %"firstUnstable", "lastUnstable",  "unstableEfficency"
                                8, 10];     % "firstStable", "lastStable", "stableEfficency"
    labelsClasses = labelsClasses(flagCategoriesToIndlcude);
                                
    labelsBrackets = string(1:numBrackets);
    screenSize = [1 1 1512 982];
    overallMap = containers.Map();
    nameMap = containers.Map(...
        {'FullWP','IncWP_KP','IncWP_Unst','IncWP_Prox','RandomSearch','IncWP_Rnd','IncWP_Kmeans'}, ...
        {'\fullWptSearch','\KneeSel','\IncWP_Unst','\IncWP_Prox','\RandomSearch','\IncWP_Rnd','\KmeansSel'} ...
    );

    combinedWaypoints = [];
    for waypointKey = metrics.keys()
        names = [];
        wptIndex = waypointKey{:};
        waypointMetrics = metrics(wptIndex);
        numSubplots = length(waypointMetrics.keys());
        appraochNamesList = waypointMetrics.keys();
        
        combinedResults = [];

        for approachKey = waypointMetrics.keys()
            appraochName = approachKey{:};
            if any(ismember(appraochName, overallMap.keys()))
                overall = overallMap(appraochName);
            else 
                overall = zeros(numBrackets, length(flagCategoriesToIndlcude));
            end

            names = [names; string(appraochName)];
            appraochMetric = waypointMetrics(appraochName);
            appraochMetric.keys()
            appraochBracket = appraochMetric("bracketsTimeCount");
            size(appraochBracket)
            appraochBracket = appraochBracket(:,flagCategoriesToIndlcude)
            size(appraochBracket)

            combinedResults = [combinedResults; appraochBracket];

            
               
        end
        combinedWaypoints = [combinedWaypoints combinedResults];



        
    end

    numWaypoints = length(metrics.keys());
    fileName = append(baseResultsPath,"/plots/Time/","time_results_table.tex");

        
    fid = fopen(fileName,'w');
    
    %fprintf(fid, '\\begin{tabular}{l c |%s}\n', repmat(' r', 1, numWaypoints));
    % Build tabular column spec for (6 waypoints × 3 classes)
    colSpec = 'l c |';
    for w = 1:numWaypoints
        for c = 1:numel(labelsClasses)
            colSpec = [colSpec ' r'];
        end
        %if w < numWaypoints
        %    colSpec = [colSpec ' @{\hspace{6pt}}'];  % optional space between waypoint groups too
        %end
        %if w < numWaypoints
        %    colSpec = [colSpec ' :'];  % dashed line between waypoint blocks
        %end
    end
    fprintf(fid, '\\resizebox{\\textwidth}{!}{%%\n');  
    fprintf(fid, '\\begin{tabular}{%s}\n', colSpec);
    %fprintf(fid, '\\adlbegin\n');

    % Row 1: Waypoint titles
    fprintf(fid, 'Approach & Bracket');
    %fprintf(fid, 'Approach & Bracket\\hspace{6pt}');
    for w = 2:(numWaypoints+1)
        fprintf(fid, '& \\multicolumn{%d}{c}{Waypoint%d}', numel(labelsClasses), w);
    end
    fprintf(fid, ' \\\\\n');
    
    
    colStart = 3;
    for w = 1:(numWaypoints)
        colEnd = colStart + numel(labelsClasses) - 1;
        fprintf(fid, '\\cmidrule(lr){%d-%d}\n', colStart, colEnd);
        colStart = colEnd + 1;

    end
    
    % --------- HEADER ROW 2: missing / unstable / stable labels ---------
    fprintf(fid, ' & ');
    for w = 1:numWaypoints
        for c = 1:numel(labelsClasses)
            if isstring(labelsClasses)
                lab = labelsClasses(c);
            else
                lab = labelsClasses{c};
            end
            fprintf(fid, ' & %s', strrep(lab, '%', '\%'));
        end
    end
    fprintf(fid, ' \\\\\n');
    fprintf(fid, '\\hline\n');
    %fprintf(fid, '\\adlend\n');

    
    row = 1;
    for i = 1:numel(names)
        for j = 1:numBrackets
            algoCmd = nameMap(names(i));  % get LaTeX-safe algorithm name
            if j == 1
                fprintf(fid, '\\multirow{%d}{*}{%s} & %d', numBrackets, algoCmd, j);
            else
                fprintf(fid, ' & %d', j);
            end
            % print each waypoint result
            fprintf(fid, ' & %.4f', combinedWaypoints(row, 1:(numWaypoints*length(labelsClasses))));
            fprintf(fid, ' \\\\\n');
            row = row + 1;
        end
        fprintf(fid, '\\midrule\n');
    end
   
    
    fprintf(fid, '\\end{tabular}\n');
    fprintf(fid, '}\n');
    fclose(fid);

end

function displayDistanceLatex(baseResultsPath,metrics, usePrecentage)
    numBrackets = 5;
    figureNum = 20;
    labelsClasses = ["% Missing", "% Unstable",  "% Stable"];
    labelsBrackets = string(1:numBrackets);
    screenSize = [1 1 1512 982];
    overallMap = containers.Map();
    % Original names
        
    % Mapping to LaTeX commands
    % Correct mapping using cell arrays of char vectors
    nameMap = containers.Map(...
        {'FullWP','IncWP_KP','IncWP_Unst','IncWP_Prox','RandomSearch','IncWP_Rnd','IncWP_Kmeans'}, ...
        {'\fullWptSearch','\KneeSel','\IncWP_Unst','\IncWP_Prox','\RandomSearch','\IncWP_Rnd','\KmeansSel'} ...
    );

    combinedWaypoints = [];
    for waypointKey = metrics.keys()
        names = [];
        HVmatrix = [];
        wptIndex = waypointKey{:};
        waypointMetrics = metrics(wptIndex);
        numSubplots = length(waypointMetrics.keys());
        appraochNamesList = waypointMetrics.keys();
        %figure(figureNum)

        combinedResults = [];
        for approachKey = waypointMetrics.keys()
            appraochName = approachKey{:};
            if any(ismember(appraochName, overallMap.keys()))
                overall = overallMap(appraochName);
            else 
                overall = zeros(numBrackets, length(labelsClasses));
            end
            %names
            %appraochName
            names = [names; string(appraochName)];
            appraochMetric = waypointMetrics(appraochName)
            appraochMetric.keys()
            appraochBracket = appraochMetric("bracketsDistanceCount");
            overall = overall + appraochBracket;
            overallMap(appraochName) = overall;
            if usePrecentage  == true
                appraochBracket = appraochBracket/sum(appraochBracket,'all')*100;
            end
            combinedResults = [combinedResults; appraochBracket]
        end
        combinedWaypoints = [combinedWaypoints combinedResults];

    end
    combinedWaypoints

    numWaypoints = length(metrics.keys());
    fileName = append(baseResultsPath,"/plots/Distance/distances-PerWP","distances_results_table.tex");

        
    fid = fopen(fileName,'w');
    
    %fprintf(fid, '\\begin{tabular}{l c |%s}\n', repmat(' r', 1, numWaypoints));
    % Build tabular column spec for (6 waypoints × 3 classes)
    colSpec = 'l c |';
    for w = 1:numWaypoints
        for c = 1:numel(labelsClasses)
            colSpec = [colSpec ' r'];
        end
        %if w < numWaypoints
        %    colSpec = [colSpec ' @{\hspace{6pt}}'];  % optional space between waypoint groups too
        %end
        %if w < numWaypoints
        %    colSpec = [colSpec ' :'];  % dashed line between waypoint blocks
        %end
    end
    fprintf(fid, '\\resizebox{\\textwidth}{!}{%%\n');  
    fprintf(fid, '\\begin{tabular}{%s}\n', colSpec);
    %fprintf(fid, '\\adlbegin\n');

    % Row 1: Waypoint titles
    fprintf(fid, 'Approach & Bracket');
    %fprintf(fid, 'Approach & Bracket\\hspace{6pt}');
    for w = 2:(numWaypoints+1)
        fprintf(fid, '& \\multicolumn{%d}{c}{Waypoint%d}', numel(labelsClasses), w);
    end
    fprintf(fid, ' \\\\\n');
    
    
    colStart = 3;
    for w = 1:numWaypoints
        colEnd = colStart + numel(labelsClasses) - 1;
        fprintf(fid, '\\cmidrule(lr){%d-%d}\n', colStart, colEnd);
        colStart = colEnd + 1;

    end
    
    % --------- HEADER ROW 2: missing / unstable / stable labels ---------
    fprintf(fid, ' & ');
    for w = 1:numWaypoints
        for c = 1:numel(labelsClasses)
            if isstring(labelsClasses)
                lab = labelsClasses(c);
            else
                lab = labelsClasses{c};
            end
            fprintf(fid, ' & %s', strrep(lab, '%', '\%'));
        end
    end
    fprintf(fid, ' \\\\\n');
    fprintf(fid, '\\hline\n');
    %fprintf(fid, '\\adlend\n');

    
    row = 1;
    for i = 1:numel(names)
        for j = 1:numBrackets
            algoCmd = nameMap(names(i));  % get LaTeX-safe algorithm name
            if j == 1
                fprintf(fid, '\\multirow{%d}{*}{%s} & %d', numBrackets, algoCmd, j);
            else
                fprintf(fid, ' & %d', j);
            end
            % print each waypoint result
            fprintf(fid, ' & %.4f', combinedWaypoints(row, 1:(numWaypoints*length(labelsClasses))));
            fprintf(fid, ' \\\\\n');
            row = row + 1;
        end
        fprintf(fid, '\\midrule\n');
    end
   
    
    fprintf(fid, '\\end{tabular}\n');
    fprintf(fid, '}\n');
    fclose(fid);


    
end

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

function displayDistance(baseResultsPath,metrics, usePrecentage)
    numBrackets = 5;
    figureNum = 20;
    labelsClasses = ["% Missing", "% Unstable",  "% Stable"];
    labelsBrackets = string(1:numBrackets);
    screenSize = [1 1 1512 400];
    overallMap = containers.Map();
    % Original names

    labelOffset = -0.1;
    xOffset     = 0.005;        % horizontal fine-tune; >0 → right, <0 → left
    nameBoxW    = 0.12;
    nameBoxH    = 0.03;

    baseOffset    = 0.01;     % + right, - left (same for all)
    driftPerGroup = 0.01;  % try small values: -0.002, -0.001, 0.001, ...

   fontSizeNumers = 12;
   fontSizeApproach = 14;
   fontSizeLabels = 13;
        
    % Mapping to LaTeX commands
    % Correct mapping using cell arrays of char vectors
    nameMap = containers.Map(...
        {'FullWP','IncWP_KP','IncWP_Unst','IncWP_Prox','RandomSearch','IncWP_Rnd','IncWP_Kmeans'}, ...
        {'\fullWptSearch','\KneeSel','\IncWP_Unst','\IncWP_Prox','\RandomSearch','\IncWP_Rnd','\KmeansSel'} ...
    );




    for waypointKey = metrics.keys()
        names = [];
        HVmatrix = [];
        wptIndex = waypointKey{:};
        waypointMetrics = metrics(wptIndex);
        waypointMetrics.remove('StatisticalComparisonResults')

        numSubplots = length(waypointMetrics.keys());
        appraochNamesList = waypointMetrics.keys();

        combinedResults = [];


        for approachKey = waypointMetrics.keys()
            appraochName = approachKey{:}
            if any(ismember(appraochName, overallMap.keys()))
                overall = overallMap(appraochName);
            else 
                overall = zeros(numBrackets, length(labelsClasses));
            end
            %names
            %appraochName
            names = [names; string(appraochName)];
            appraochMetric = waypointMetrics(appraochName)
            appraochMetric.keys()
            appraochBracket = appraochMetric("bracketsDistanceCount");
            overall = overall + appraochBracket;
            overallMap(appraochName) = overall;
            if usePrecentage  == true
                appraochBracket = appraochBracket/sum(appraochBracket,'all')*100;
            end
            combinedResults = [combinedResults appraochBracket nan(numBrackets,1)]
                
            %subplot(ceil(numSubplots/2), 2, find(strcmp(appraochNamesList, appraochName)))
            

            
    
            
               
        end

        data = combinedResults;                     % your data with NaN separators
        [rows, cols] = size(data);
        isGap = all(isnan(data));            % which columns are NaN separators?
        
        wData = 2;                           % width of normal columns
        wGap  = 0.3;                         % narrower width for NaN columns
        
        % --- compute x positions for each column (variable widths) ---
        xLeft   = zeros(1,cols);
        xRight  = zeros(1,cols);
        xCenter = zeros(1,cols);
        
        x = 0;
        for j = 1:cols
            w = wData;
            if isGap(j), w = wGap; end
            xLeft(j)   = x;
            xRight(j)  = x + w;
            xCenter(j) = (xLeft(j)+xRight(j))/2;
            x = xRight(j);
        end
        
        % --- colour mapping ---
        validVals = data(~isnan(data));
        vmin = min(validVals);
        vmax = max(validVals);
        
        %cmap = parula(256);
        %blues = [linspace(0.9,0.1,256)'  linspace(0.9,0.1,256)'  ones(256,1)];
        blues = [ ...
                linspace(0.8, 0.0, 256)' ...   % R: light to 0
                linspace(0.9, 0.2, 256)' ...   % G: light to 0.2
                ones(256,1) ...                % B: stays strong
            ];
                    
        figure(figureNum); clf; hold on;
        
        
        % --- draw rectangles (no patch for NaN → real narrow gap) ---
        for r = 1:rows
            for j = 1:cols
                if isnan(data(r,j)), continue; end
        
                v = data(r,j);
                t = (v - vmin) / (vmax - vmin);
                idx = max(1, min(256, round(1 + t*(256-1))));
                col = blues(idx,:);
        
                y0 = r-1;  y1 = r;
                patch([xLeft(j) xRight(j) xRight(j) xLeft(j)], ...
                      [y0 y0 y1 y1], col, ...
                      'EdgeColor',[0.8 0.8 0.8]);
        
                text(xCenter(j),(y0+y1)/2,sprintf('%.1f',v), ...
                    'HorizontalAlignment','center', ...
                    'VerticalAlignment','middle', ...
                    'FontSize',fontSizeNumers);
            end
        end
        
        axis equal tight;
        set(gca,'YDir','reverse');
        
        
        % --- ticks & labels ---
        set(gca,'YTick',(0:rows-1)+0.5,'YTickLabel',1:rows);
        
        pattern = {'missing','unstable','stable',''};
        numGroups = cols/4;                  % 3 data + 1 gap each
        xlab = repmat(pattern,1,numGroups);
        set(gca,'XTick',xCenter,'XTickLabel',xlab);
        %ax.YRuler.FontSize = fontSizeLabels;
        set(gca,'FontSize',fontSizeLabels); 
        xtickangle(0); 
        colormap(blues);
        caxis([vmin vmax]);
        colorbar;
        
        % --- approach titles ABOVE the axes ---
        ax  = gca;
        pos = get(ax,'Position');
        f = gcf; % Get current figure handle

        set(gca,'TickLength',[0 0]);

        set(f, 'Position', screenSize);
        

        %pos = get(gca,'Position');
        %pos(2) = 0.25;   % move axis up
        %pos(4) = 0.55;
        %set(gca,'Position',pos);
        


        groupCenters = zeros(1,numGroups);
        for g = 1:numGroups
            colStart          = (g-1)*4 + 1;
            colEnd            = colStart + 2;
            groupCenters(g)   = mean(xCenter(colStart:colEnd));
        end
        
        for g = 1:numGroups
            nx = (groupCenters(g) - xLeft(1)) / (xRight(end) - xLeft(1));
        
            xNorm = pos(1) + nx*pos(3) - nameBoxW/2 ...
                    + baseOffset + driftPerGroup*(g-1);
            yNorm = pos(2) + pos(4) + labelOffset;
        
            annotation('textbox', ...
                [xNorm, yNorm, nameBoxW, nameBoxH], ...
                'String', names(g), ...
                'HorizontalAlignment','center', ...
                'VerticalAlignment','bottom', ...
                'FontWeight','bold', ...
                'FontSize',fontSizeApproach, ...
                'LineStyle','none');
        end

        % save

        set(f, 'Position', screenSize);
        fileName = append(baseResultsPath,"/plots/Distance/heatmap-classification-wpt", wptIndex,".png");
        exportgraphics(f,fileName,'Resolution',300)




        figureNum = figureNum + 1;

       
        
        runOld = false
    end
        % if runOld
        %     numRows = size(combinedResults, 1);
        %     %yLabels = compose("Row %d", 1:numRows);
        %     nckets = numel(labelsBrackets);
        %     %nRows       = numNames * numBrackets;
        % 
        %     %yLabels = labelsBrackets(mod(0:numRows-1, numBrackets) + 1) + "_" + string(1:numRows);
        %     numNames = numel(names);
        %     %numBrackets = numel(labelsBrackets);
        %     yLabels = strings(numNames * (numBrackets + 1), 1);  % +1 per group for blank
        %     combinedResultsSpaced = NaN(numNames * (numBrackets + 1), size(combinedResults,2)); % pad data with NaN rows
        % 
        %     yLabels = strings(numNames * numBrackets, 1);
        % 
        %     for i = 1:numNames
        %         for j = 1:numBrackets
        %             idx = (i-1)*numBrackets + j;
        %             yLabels(idx) = names(i) + "_" + labelsBrackets(j);
        %         end
        %     end
        % 
        % 
        %     heatmap(labelsClasses, yLabels, combinedResults);
        %     %heatmap(labelsClasses ,  repmat(labelsBrackets,1,length(names)), combinedResults);
        %     title(append("Distances for waypoint ", string(wptIndex)));
        %     ax = gca; % Get current axes
        %     ax.FontSize = 18;
        % 
        %     %sgtitle(append("WPIndex", wptIndex))
        %     figureNum = figureNum +1;
        %     f = gcf; % Get current figure handle
        %     set(f, 'Position', screenSize);
        %     fileName = append(baseResultsPath,"/plots/Distance/heatmap-classification-PerWP",  string(wptIndex),".png");
        %     exportgraphics(f,fileName,'Resolution',300)
        % 
        % 
        %     rowLabels = strings(size(combinedResults,1),1);
        %     row = 1;
        %     for i = 1:numel(names)
        %         for j = 1:numel(labelsBrackets)
        %             if row <= size(combinedResults,1)
        %                 rowLabels(row) = names(i) + "_" + labelsBrackets(j);
        %                 row = row + 1;
        %             end
        %         end
        %     end
        %     fileName = append(baseResultsPath,"/plots/Distance/distances-PerWP",  string(wptIndex),"_distances_results_table.tex");
        % 
        %     %% Export LaTeX table
        %     fid = fopen(fileName,'w');
        %     fprintf(fid,'\\begin{tabular}{l c |r r r}\n');  % l = multirow label, l = bracket number, ccc = 3 columns
        %     fprintf(fid,'Approach & Bracket & %s & %s & %s \\\\\n', ...
        %         strrep(labelsClasses(1),'%','\%'), ...
        %         strrep(labelsClasses(2),'%','\%'), ...
        %         strrep(labelsClasses(3),'%','\%'));
        %     fprintf(fid,'\\hline\n');
        % 
        %     row = 1;
        %     for i = 1:numel(names)
        %         for j = 1:numBrackets
        %             algoCmd = nameMap(names(i));  % get LaTeX command
        %             if j == 1
        %                 fprintf(fid,'\\multirow{%d}{*}{%s} & %d & %.4f & %.4f & %.4f \\\\\n', ...
        %                     numBrackets, algoCmd, j, combinedResults(row,:));
        %             else
        %                 fprintf(fid,' & %d & %.4f & %.4f & %.4f \\\\\n', j, combinedResults(row,:));
        %             end
        %             row = row + 1;
        %         end
        %         fprintf(fid,'\\midrule\n');
        %     end
        % 
        %     fprintf(fid,'\\end{tabular}\n');
        %     fclose(fid);
        %     end

        

       


   
    
    
    % figure(figureNum)
    % %sgtitle("Overall ")
    % overallCombined = [];
    % names = [];
    % for approachKey = waypointMetrics.keys()
    %     appraochName = approachKey{:};
    %     overall = overallMap(appraochName);
    % 
    %     names = [names; string(appraochName)];
    %     appraochBracket = overallMap(appraochName);
    % 
    %     if usePrecentage  == true
    %         appraochBracket = appraochBracket/sum(appraochBracket,'all')*100;
    %     end
    %     overallCombined = [overallCombined;  appraochBracket]
    % 
    %     %subplot(ceil(numSubplots/2), 2, find(strcmp(appraochNamesList, appraochName)))
    %         %bracketDistributionSelection = precentageResultsMap(selectionName);
    %         %bracketDistribution = bracketDistributionSelection(wptIndex);
    %     %heatmap(labelsClasses , labelsBrackets, appraochBracket);
    %     %title(append(appraochName));
    %     %ax = gca; % Get current axes
    %     %ax.FontSize = 18;
    % 
    % 
    % 
    % end
    % numRows = size(overallCombined, 1);
    % %yLabels = compose("Row %d", 1:numRows);
    % numBrackets = numel(labelsBrackets);
    % %nRows       = numNames * numBrackets;
    % 
    % %yLabels = labelsBrackets(mod(0:numRows-1, numBrackets) + 1) + "_" + string(1:numRows);
    % numNames = numel(names);
    % %numBrackets = numel(labelsBrackets);
    % 
    % 
    % yLabels = strings(numNames * numBrackets, 1);
    % row = 1;
    % for i = 1:numNames
    %     for j = 1:numBrackets
    %         if j == 1
    %             % First bracket: show algorithm name + bracket number
    %             yLabels(row) = names(i) + " " + labelsBrackets(j);
    %         else
    %             % Add spaces visually but include a hidden unique suffix
    %             yLabels(row) = "   " + labelsBrackets(j) + "_(" + names(i) + ")";
    %         end
    %         row = row + 1;
    %     end
    % end
    % 
    % 
    % heatmap(labelsClasses, yLabels, overallCombined);
    % %heatmap(labelsClasses ,  repmat(labelsBrackets,1,length(names)), combinedResults);
    % title("Distances for all waypoints ");
    % ax = gca; % Get current axes
    % ax.FontSize = 18;
    % 
    % %sgtitle("Overall")
    % figureNum = figureNum +1;
    % f = gcf; % Get current figure handle
    % set(f, 'Position', screenSize);
    % fileName = append(baseResultsPath,"/plots/Distance/heatmap-classification-Overall",".png");
    % exportgraphics(f,fileName,'Resolution',300)
    % end


end



function newMap = copyMap(originalMap)
    k = originalMap.keys;
    v = originalMap.values;
    newMap = containers.Map(k, v);
end

function displayUniquePoints(baseResultsPath, approachDataMap, metrics, colorMap, uniqueCategoryType, nameMap, orderOfPlots)
    orderOfPlots(orderOfPlots == "FullWP") = [];
    orderOfPlots(orderOfPlots == "RandomSearch") = [];

    figureNum = 100;
    screenSize = [1, 1, 45, 25] %[1 1 1512 982]; 
    %nameMap = containers.Map(...
    %    {'FullWP','IncWP_KP','IncWP_Unst','IncWP_Prox','RandomSearch','IncWP_Rnd','IncWP_Kmeans'}, ...
    %    {'\fullWptSearch','\KneeSel','\IncWP_Unst','\IncWP_Prox','\RandomSearch','\IncWP_Rnd','\KmeansSel'} ...
    %);
    
    categoryNames = ["Overall", "Stable", "Unstable", "Missing"];
    figure('Units', 'centimeters', 'Position', screenSize, 'Color', 'w')
    t = tiledlayout(ceil(length(metrics.keys())/2), 2, 'TileSpacing', 'compact', 'Padding', 'compact');

    plotTitles = {};
    plotIndex = 1;
    for wptIndexKey = metrics.keys
        wptIndex = wptIndexKey{:};
        waypointInfoMap = metrics(wptIndex);
        
        % Move to next tile
        nexttile;
        hold on;
        
        % Prepare data containers for this subplot
        combinedStats = [];
        currentDisplayNames = {}; % Store the pretty names for Legend
        currentColors = [];       % Store the colors for this plot's bars
        
        % Temporary removal to avoid iterating over comparison results
        if isKey(waypointInfoMap, 'StatisticalComparisonResults')
            waypointInfoMap.remove('StatisticalComparisonResults');
        end
        
        % Gather data for all approaches in this Waypoint
        keysList = waypointInfoMap.keys();

        for k = 1:length(orderOfPlots)
            approachName = orderOfPlots(k) %keysList{k};
            approachInfo = waypointInfoMap(approachName);
            
            % Extract Stats
            stats = approachInfo('uniqueStats');
            uniqueStats = str2double(stats(1,2:end));
            clusterStats = str2double(stats(2,2:end));
            notInOthersStats = str2double(stats(2,2:end));
            
            % Select which Data to Plot
            if uniqueCategoryType == "unique"
                dataRow = uniqueStats;
            elseif uniqueCategoryType == "clusters"
                dataRow = clusterStats;
            elseif uniqueCategoryType == "notInOthers"
                dataRow = notInOthersStats;
            end
            
            % Stack data: Rows = Approaches, Cols = Categories
            combinedStats = [combinedStats; dataRow];
            
            % Get correct display name and color
            if isKey(nameMap, approachName)
                currentDisplayNames{end+1} = nameMap(approachName);
            else
                currentDisplayNames{end+1} = approachName; % Fallback
            end
            
            if isKey(colorMap, approachName)
                currentColors = [currentColors; colorMap(approachName)];
            else
                currentColors = [currentColors; [0.5 0.5 0.5]]; % Fallback Gray
            end
        end
        
        % ---------------------------------------------------------------------
        % PLOTTING THE BAR CHART
        % ---------------------------------------------------------------------
        % Transpose combinedStats so that:
        % Groups (X-axis) = Categories (Overall, Stable...)
        % Bars inside group = Approaches
        b = bar(combinedStats', 'grouped'); 
        
        % APPLY MODERN STYLING
        for i = 1:length(b)
            % 1. Set Color
            b(i).FaceColor = currentColors(i, :);
            
            % 2. Modern Look: Translucent & No Outline
            b(i).FaceAlpha = 0.6;  % Semi-transparent
            b(i).EdgeColor = 'none'; % Remove black border
        end
        
        % ---------------------------------------------------------------------
        % FORMATTING SUBPLOT
        % ---------------------------------------------------------------------
        title(['Waypoint ', wptIndex], 'FontSize', 11);
        
        grid on;
        set(gca, 'GridAlpha', 0.3); % Make grid subtle
        xlim([0.5, 4.5]);
        set(b, 'BarWidth', 0.8);        
        % Set X-Axis labels to be the CATEGORIES ("Overall", "Stable"...)
        % instead of approach names (since legend handles approach names)
        xticks(1:length(categoryNames));
        xticklabels(categoryNames);
        
        % Only show X-labels on bottom plots to save space
        if plotIndex < (length(metrics.keys()) - 1) % Adjust logic based on total number of plots
            xtickangle(0);
        else
            xticklabels({});
        end
        
        
        plotIndex = plotIndex + 1;        
    
        

    end
    

    if uniqueCategoryType == "unique"
        titleText = ""
        valueText = "Percentage unique points"
    elseif uniqueCategoryType == "clusters"
        titleText = ""
        valueText = "Number of clusters"
    elseif uniqueCategoryType == "notInOthers"
        titleText = ""
        valueText = "Percentage of points not in other approaches"
        
    end
    hold on;
    dummyHandles = gobjects(1, length(currentDisplayNames));
    for k = 1:length(currentDisplayNames)
        dummyHandles(k) = bar(nan, 'FaceColor', currentColors(k,:), ...
            'FaceAlpha', 0.6, 'EdgeColor', 'none'); 
    end
    
    %lgd = legend(dummyHandles, currentDisplayNames, 'Orientation', 'horizontal');
    %lgd.Layout.Tile = 'south'; 
    %lgd.Title.String = 'Approaches';

    lgd = legend(dummyHandles, currentDisplayNames, 'Orientation', 'horizontal');
    lgd.Layout.Tile = 'south'; % Moves legend to the outer right sidebar
    %lgd.Title.String = 'Approaches';
    lgd.FontSize = 10;
    lgd.Box = 'off';
    

    ylabel(t, valueText, 'FontSize', 14, 'FontWeight', 'bold');

 
    f = gcf; % Get current figure handle
    fileName = append(baseResultsPath,"/plots/Unique/",uniqueCategoryType,".png");
    exportgraphics(f,fileName,'Resolution',300)
    
    
     figureNum = figureNum +1;
   
   
end


function displayUniqueClustersLines(baseResultsPath, approachDataMap, metrics, colorMap, uniqueCategoryType, nameMap, orderOfPlots)
    orderOfPlots(orderOfPlots == "FullWP") = [];
    orderOfPlots(orderOfPlots == "RandomSearch") = [];
    
    categoryNames = ["Overall", "Stable", "Unstable", "Missing"];
    screenSize = [1, 1, 50, 45]; % Larger size for 2x8 grid
    figure('Units', 'centimeters', 'Position', screenSize, 'Color', 'w')
    
    allWptKeys = metrics.keys;
    numWpts = length(allWptKeys);
    
    % 2 Columns. Rows = (Number of Waypoints / 2) * 3 rows per waypoint
    rowsPerWpt = 3;
    totalRows = ceil(numWpts / 2) * rowsPerWpt;
    t = tiledlayout(totalRows, 2, 'TileSpacing', 'tight', 'Padding', 'compact');
    
    % We iterate 2 waypoints at a time to fill the columns
    for i = 1:2:numWpts
        % Determine indices for Left and Right columns
        wptsInRow = [i, i+1];
        
        % Step 1: Line Plots for both columns
        for w = wptsInRow
            if w <= numWpts
                [counts, sizes, colors, names, bMax, oMin, raw] = getWptData(allWptKeys{w}, metrics, orderOfPlots, nameMap, colorMap);
                ax = nexttile; hold on;
                for rowIdx = 1:size(counts, 1)
                    plot(1:4, counts(rowIdx,:), '-o', 'Color', colors(rowIdx,:), 'MarkerFaceColor', colors(rowIdx,:), 'LineWidth', 1.2);
                end
                title(['Waypoint ', allWptKeys{w}], 'FontSize', 10);
                ylabel('N Clusters'); grid on; set(gca, 'XTickLabel', {}, 'GridAlpha', 0.2); xlim([0.5, 4.5]);
                wData(w).sizes = sizes; wData(w).colors = colors; wData(w).bMax = bMax; wData(w).oMin = oMin; wData(w).raw = raw;
            else
                nexttile; axis off; % Empty tile if odd number of waypoints
            end
        end
        
        % Step 2: Boxplot Upper (Outliers) for both columns
        for w = wptsInRow
            if w <= numWpts
                ax = nexttile; hold on;
                drawGroupedBoxes(ax, wData(w).sizes, wData(w).colors);
                ylim([wData(w).oMin * 0.9, max(wData(w).raw) * 1.1]);
                ylabel('Outliers'); grid on; set(gca, 'XTickLabel', {}, 'GridAlpha', 0.2); xlim([0.5, 4.5]);
            else
                nexttile; axis off;
            end
        end
        
        % Step 3: Boxplot Lower (Bulk) for both columns
        for w = wptsInRow
            if w <= numWpts
                ax = nexttile; hold on;
                drawGroupedBoxes(ax, wData(w).sizes, wData(w).colors);
                ylim([0, wData(w).bMax * 1.2]);
                ylabel('Bulk'); grid on; set(gca, 'GridAlpha', 0.2);
                xticks(1:4); xticklabels(categoryNames); xlim([0.5, 4.5]);
            else
                nexttile; axis off;
            end
        end
    end
    
    % Legend logic using dummy bars
    dummyHandles = gobjects(1, length(orderOfPlots));
    for k = 1:length(orderOfPlots)
        dummyHandles(k) = bar(nan, 'FaceColor', colorMap(orderOfPlots(k)), 'FaceAlpha', 0.6, 'EdgeColor', 'none'); 
    end
    lgd = legend(dummyHandles, cellfun(@(x) nameMap(x), cellstr(orderOfPlots)), 'Orientation', 'horizontal', 'Interpreter','latex');
    lgd.Layout.Tile = 'south'; lgd.Box = 'off';

    exportgraphics(gcf, append(baseResultsPath,"/plots/Unique/",uniqueCategoryType,".png"), 'Resolution', 300);
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

function displayUniqueClusters(baseResultsPath, approachDataMap, metrics, colorMap, uniqueCategoryType, nameMap, orderOfPlots)
    orderOfPlots(orderOfPlots == "FullWP") = [];
    orderOfPlots(orderOfPlots == "RandomSearch") = [];

    figureNum = 100;
    screenSize = [1, 1, 45, 25] %[1 1 1512 982]; 
    %nameMap = containers.Map(...
    %    {'FullWP','IncWP_KP','IncWP_Unst','IncWP_Prox','RandomSearch','IncWP_Rnd','IncWP_Kmeans'}, ...
    %    {'\fullWptSearch','\KneeSel','\IncWP_Unst','\IncWP_Prox','\RandomSearch','\IncWP_Rnd','\KmeansSel'} ...
    %);
    
    categoryNames = ["Overall", "Stable", "Unstable", "Missing"];
    figure('Units', 'centimeters', 'Position', screenSize, 'Color', 'w')
    t = tiledlayout(ceil(length(metrics.keys())/2), 2, 'TileSpacing', 'compact', 'Padding', 'compact');

    plotTitles = {};
    plotIndex = 1;
    for wptIndexKey = metrics.keys
        wptIndex = wptIndexKey{:};
        waypointInfoMap = metrics(wptIndex);
        
        % Move to next tile
        nexttile;
        hold on;
        
        % Prepare data containers for this subplot
        combinedStats = [];
        currentDisplayNames = {}; % Store the pretty names for Legend
        currentColors = [];       % Store the colors for this plot's bars
        
        % Temporary removal to avoid iterating over comparison results
        if isKey(waypointInfoMap, 'StatisticalComparisonResults')
            waypointInfoMap.remove('StatisticalComparisonResults');
        end
        
        % Gather data for all approaches in this Waypoint
        keysList = waypointInfoMap.keys();

        for k = 1:length(orderOfPlots)
            approachName = orderOfPlots(k); %keysList{k};
            approachInfo = waypointInfoMap(approachName);
            
            % Extract Stats
            stats = approachInfo('clusterData');
            %approachClusterData = stats('approachClusterData')
            countOfuniqueClusterMissing = stats('countOfuniqueClusterMissing');
            countOfuniqueClusterOverall = stats('countOfuniqueClusterOverall');
            countOfuniqueClusterStable = stats('countOfuniqueClusterStable');
            countOfuniqueClusterUnstable = stats('countOfuniqueClusterUnstable');
            %uniqueStats = str2double(stats(1,2:end));
            %clusterStats = str2double(stats(2,2:end));
            %notInOthersStats = str2double(stats(2,2:end));
            dataRow = [countOfuniqueClusterOverall countOfuniqueClusterStable countOfuniqueClusterUnstable countOfuniqueClusterMissing];
            
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
            missinglusterSizes = missingStats('clusterSizes');
            nClustersMissing = missingStats('nClustersMissing');
            
            % Select which Data to Plot
            if uniqueCategoryType == "numberOfuniqeClusters"
                %dataRow = uniqueStats;
                dataRow = [countOfuniqueClusterOverall countOfuniqueClusterStable countOfuniqueClusterUnstable countOfuniqueClusterMissing];

            elseif uniqueCategoryType == "clusterSize" % this is number of clusters
                dataRow = [nClustersOverall nClustersStable nClustersUnstable nClustersMissing];
            elseif uniqueCategoryType == "NotInOthers"
                dataRow = container.Map({'overallClusterSizes','stableClusterSizes','unstableClusterSizes', 'missinglusterSizes'}, ...
                                        {overallClusterSizes,stableClusterSizes, unstableClusterSizes, missinglusterSizes});
                % boxplot
            end
            
            % Stack data: Rows = Approaches, Cols = Categories
            combinedStats = [combinedStats; dataRow];
            
            % Get correct display name and color
            if isKey(nameMap, approachName)
                currentDisplayNames{end+1} = nameMap(approachName);
            else
                currentDisplayNames{end+1} = approachName; % Fallback
            end
            
            if isKey(colorMap, approachName)
                currentColors = [currentColors; colorMap(approachName)];
            else
                currentColors = [currentColors; [0.5 0.5 0.5]]; % Fallback Gray
            end
        end
        
        % ---------------------------------------------------------------------
        % PLOTTING THE BAR CHART
        % ---------------------------------------------------------------------
        % Transpose combinedStats so that:
        % Groups (X-axis) = Categories (Overall, Stable...)
        % Bars inside group = Approaches
        b = bar(combinedStats', 'grouped'); 
        
        % APPLY MODERN STYLING
        for i = 1:length(b)
            % 1. Set Color
            b(i).FaceColor = currentColors(i, :);
            
            % 2. Modern Look: Translucent & No Outline
            b(i).FaceAlpha = 0.6;  % Semi-transparent
            b(i).EdgeColor = 'none'; % Remove black border
        end
        
        % ---------------------------------------------------------------------
        % FORMATTING SUBPLOT
        % ---------------------------------------------------------------------
        title(['Waypoint ', wptIndex], 'FontSize', 11);
        
        grid on;
        set(gca, 'GridAlpha', 0.3); % Make grid subtle
        xlim([0.5, 4.5]);
        set(b, 'BarWidth', 0.8);        
        % Set X-Axis labels to be the CATEGORIES ("Overall", "Stable"...)
        % instead of approach names (since legend handles approach names)
        xticks(1:length(categoryNames));
        xticklabels(categoryNames);
        set(gca, 'TickLabelInterpreter', 'latex');
        
        % Only show X-labels on bottom plots to save space
        if plotIndex >= (length(metrics.keys) -1) % Adjust logic based on total number of plots
            xtickangle(0);
        else
            xticklabels({});
        end
        
        plotIndex = plotIndex + 1;        
    
        

    end
    

    if uniqueCategoryType == "uniqeClusters"
        titleText = ""
        valueText = "number of unique clusters"
    elseif uniqueCategoryType == "clusterSize"
        titleText = ""
        valueText = "Number of clusters"
    elseif uniqueCategoryType == "notInOthers"
        titleText = ""
        valueText = "Percentage of points not in other approaches"
        
    end
    hold on;
    dummyHandles = gobjects(1, length(currentDisplayNames));
    for k = 1:length(currentDisplayNames)
        dummyHandles(k) = bar(nan, 'FaceColor', currentColors(k,:), ...
            'FaceAlpha', 0.6, 'EdgeColor', 'none'); 
    end
    
    %lgd = legend(dummyHandles, currentDisplayNames, 'Orientation', 'horizontal');
    %lgd.Layout.Tile = 'south'; 
    %lgd.Title.String = 'Approaches';

    lgd = legend(dummyHandles, currentDisplayNames, 'Orientation', 'horizontal', 'Interpreter','latex');
    lgd.Layout.Tile = 'south'; % Moves legend to the outer right sidebar
    %lgd.Title.String = 'Approaches';
    lgd.FontSize = 10;
    lgd.Box = 'off';
    

    ylabel(t, valueText, 'FontSize', 14, 'FontWeight', 'bold');

 
    f = gcf; % Get current figure handle
    fileName = append(baseResultsPath,"/plots/Unique/",uniqueCategoryType,".png");
    exportgraphics(f,fileName,'Resolution',300)
    
    
     figureNum = figureNum +1;
   
   
end

function metrics = displayUniquePointsOld(baseResultsPath, approachDataMap, metrics)
    figureNum = 100;
    screenSize = [1 1 1512 982];
    nameMap = containers.Map(...
        {'FullWP','IncWP_KP','IncWP_Unst','IncWP_Prox','RandomSearch','IncWP_Rnd','IncWP_Kmeans'}, ...
        {'\fullWptSearch','\KneeSel','\IncWP_Unst','\IncWP_Prox','\RandomSearch','\IncWP_Rnd','\KmeansSel'} ...
    );

    categoryNames = ["Overall", "Stable", "Unstable", "Missing"]
    for wptIndexKey = metrics.keys
        wptIndex = wptIndexKey{:};
        waypointInfoMap = metrics(wptIndex);
        combinedUniqueStats = [];
        combinedClusterStats = [];
        combinedNotInOthersStats = [];
        approachNames = [];
        waypointInfoMap.remove('StatisticalComparisonResults')
        for approachKey = waypointInfoMap.keys()
            approachName = approachKey{:};
            approachInfo = waypointInfoMap(approachName);
            stats = approachInfo('uniqueStats');
            uniqueStats = str2double(stats(1,2:end));
            clusterStats = str2double(stats(2,2:end));
            notInOthersStats = str2double(stats(3,2:end));
            combinedUniqueStats = [combinedUniqueStats; uniqueStats];
            combinedClusterStats = [combinedClusterStats; clusterStats];
            combinedNotInOthersStats = [combinedNotInOthersStats; notInOthersStats];
            approachNames = [approachNames string(approachName)];
        end
        figureNum = figureNum +1;
        
        figure(figureNum)
        bar(combinedUniqueStats', 'grouped')

        set(gca, 'XTick', 1:numel(categoryNames), ...
            'XTickLabel', categoryNames, ...
            'FontSize', 12);
        
        xlabel('Category of unique');  
        ylabel('Percentage of unique points');   % or your metric name


        title(append("Waypoint ", wptIndex,  " Unique points"));
        
        legend(approachNames, 'Location', 'northeastoutside');
        grid on;

        f = gcf; % Get current figure handle
        set(f, 'Position', screenSize);
        fileName = append(baseResultsPath,"/plots/Unique/uniquePoints-wpt-", wptIndex,".png");
        exportgraphics(f,fileName,'Resolution',300)
    
        figureNum = figureNum +1;
        
        figure(figureNum)
        bar(combinedClusterStats', 'grouped')

        set(gca, 'XTick', 1:numel(categoryNames), ...
            'XTickLabel', categoryNames, ...
            'FontSize', 12);
        
        xlabel('Category');
        ylabel('Number of clusters');   % or your metric name
        title(append("Waypoint ", wptIndex,  " number of clusters"));  % adjust as needed
        
        legend(approachNames, 'Location', 'northeastoutside');
        grid on;
        
        f = gcf; % Get current figure handle
        set(f, 'Position', screenSize);
        fileName = append(baseResultsPath,"/plots/Unique/clusters-wpt-", wptIndex,".png");
        exportgraphics(f,fileName,'Resolution',300)


        figureNum = figureNum +1;
        
        figure(figureNum)
        bar(combinedNotInOthersStats', 'grouped')

        set(gca, 'XTick', 1:numel(categoryNames), ...
            'XTickLabel', categoryNames, ...
            'FontSize', 12);
        
        xlabel('Category');
        ylabel('Percentage of points found that are not in other approaches');   % or your metric name
        title(append("Waypoint ", wptIndex,  " percentage of points not found by other approaches"));  % adjust as needed
        
        legend(approachNames, 'Location', 'northeastoutside');
        grid on;

        f = gcf; % Get current figure handle
        set(f, 'Position', screenSize);
        fileName = append(baseResultsPath,"/plots/Unique/notInOthers-wpt-", wptIndex,".png");
        exportgraphics(f,fileName,'Resolution',300)

    end
    


    




end
