function calculateMetrics(vesselName, resultsPath, analysisPath)
    % Input:
    %   vesselName: vessel identifier such as "remus100".
    %   resultsPath: root folder containing experiment result folders.
    %   analysisPath: root folder where analysed outputs are saved.
    %
    % Output:
    %   Saves finalResults.mat under analysisPath/<vessel>/AnalysedResults/.
    resultsPath = char(resultsPath);
    analysisPath = char(analysisPath);
    baseResultsPath = append(analysisPath,"/", vesselName, "/AnalysedResults/");
    if ~isfolder(baseResultsPath)
        mkdir(baseResultsPath);
    end
    vesselResultsPathBase = append(resultsPath, "/", vesselName,"/");

    vesselInformation = loadShipSearchParameters(vesselName);

    ClassresultsPath = append(baseResultsPath,"ClassificationResults");
    load(ClassresultsPath, "selectionTypeClassification");

    filelocation = append(baseResultsPath, "/combinedResults.mat");
    load(filelocation,"approachDataMap", "experimentInfoMap", "waypointRangesMap", "combinedsolutionsMap", "approachSortedInfoMap");
    numBrackets = 5;
    
    % Build the metric maps in the same order they are later displayed.
    metrics = containers.Map();
    metrics = calculateBracketsForDistanceAndTime(metrics, experimentInfoMap, waypointRangesMap, approachDataMap, numBrackets, approachSortedInfoMap);
    [metrics, strangeExperiments] = calculateHVandIGD(metrics, experimentInfoMap, vesselResultsPathBase, vesselInformation, waypointRangesMap, combinedsolutionsMap);
    metrics = calculateStatistaltests(metrics, experimentInfoMap, vesselResultsPathBase, vesselInformation, waypointRangesMap, combinedsolutionsMap);
    metrics = calculateUniquePoints(metrics, approachDataMap);
    metricsWithoutFullpath = containers.Map();

    filelocation = append(baseResultsPath, "/finalResults.mat");
    save(filelocation, "metrics", "metricsWithoutFullpath", "strangeExperiments");

    metrics = calculateUniqueClusters(metrics, approachDataMap);
    save(filelocation, "metrics", "metricsWithoutFullpath", "strangeExperiments");
end

function metrics = calculateBracketsForDistanceAndTime(metrics, experimentInfoMap, waypointRangesMap, approachDataMap, numBrackets, approachSortedInfoMap)
    % Aggregate class counts and first-occurrence times in distance brackets.
    maxTimeOfLastMap = containers.Map();
    useAccumulatedTime = false;
    fullSetMissingPrev = containers.Map();

    for waypointKey = waypointRangesMap.keys()
        wptIndex = waypointKey{:};
        waypointRanges = waypointRangesMap(wptIndex);

        maxDistanceRange = waypointRanges(5);
        minDistanceRange = waypointRanges(6);
        bracketRangesList = [minDistanceRange (1:numBrackets)*(maxDistanceRange/numBrackets)];
        bracketMin = bracketRangesList(1:(numBrackets));
        bracketMax = bracketRangesList(2:(numBrackets+1));

        waypointMetrics = containers.Map();

        if isKey(fullSetMissingPrev, string(str2double(wptIndex)-1))
            fullSetMissingWpt = fullSetMissingPrev(string(str2double(wptIndex)-1));
        else
            fullSetMissingWpt = containers.Map();
        end

        for approachKey = experimentInfoMap.keys()
            approachName = approachKey{:};

            if isKey(maxTimeOfLastMap,approachName) 
                expMaxTimeOfLastMap = maxTimeOfLastMap(approachName);
            else
                expMaxTimeOfLastMap = containers.Map();
            end

            waypointDataMap = approachDataMap(approachName);
            approachSortedData = approachSortedInfoMap(approachName);
            waypointSortedData = approachSortedData(wptIndex);
            
            dataMap = waypointDataMap(wptIndex);

            objectives = dataMap('objectives');
            contraints = dataMap('contraints');
            decisions = dataMap('decisions');
            timestamp = dataMap('timestamp');
            approachTimeExperiments = dataMap('approachTimeExperiments');
            experimentsnumList = dataMap('experimentsnumList');
            missingPathsFlag = dataMap('missingPathsFlag');
            classes = dataMap('classes');
            nonMissingPathsFlag = ~missingPathsFlag;

            indexToIngoreFullwpt = [];
            indexToIngoreStart = 0;
            timeExerpimentsBrackets = containers.Map();
            for exNumKey = waypointSortedData.keys
                exNum = exNumKey{:};
                experimentSorted = waypointSortedData(exNum);
                classesEx = experimentSorted('classes');
                decsEx = experimentSorted('decisions');
                objsEx = experimentSorted('objectives,');
                timestampEx = experimentSorted('timestamp');

                if approachName == "FullWP" 
                    if isKey(fullSetMissingWpt, string(exNum))
                        fullSetMissingList = fullSetMissingWpt(string(exNum));
                    else
                        fullSetMissingList = zeros(size(classesEx,1),1);
                    end

                    indexToIngoreFullwpt = [indexToIngoreFullwpt; indexToIngoreStart+ find(fullSetMissingList)];
                    indexToIngoreStart = indexToIngoreStart + size(fullSetMissingList,1);

                    newMissing = (classesEx == "missing");
                    classesEx = classesEx(~fullSetMissingList,:);
                    decsEx = decsEx(~fullSetMissingList,:);
                    objsEx = objsEx(~fullSetMissingList,:);
                    timestampEx = timestampEx(~fullSetMissingList,:);

                    fullSetMissingList = newMissing | (fullSetMissingList == 1);
                    fullSetMissingWpt(string(exNum)) = fullSetMissingList;
                end

                if isKey(expMaxTimeOfLastMap,exNum) && approachName ~= "FullWP" && useAccumulatedTime 
                    expMaxTimeOfLast = expMaxTimeOfLastMap(exNum);
                else
                    expMaxTimeOfLast = 0;
                end

                timestampEx = timestampEx + expMaxTimeOfLast;
                matrixExperiment = [objsEx(:,2) timestampEx, classesEx];

                for bracketNum = 1:numBrackets
                    if timeExerpimentsBrackets.isKey(string(bracketNum))
                        bracketExperimentData = timeExerpimentsBrackets(string(bracketNum));
                        missingBracket= bracketExperimentData('missingExperiment');
                        unstableBracket= bracketExperimentData('unstableExperiment');
                        stableBracket= bracketExperimentData('stableExperiment');
                    else
                        missingBracket = [];
                        unstableBracket = [];
                        stableBracket = [];
                    end
                    indexOfIndividualsInThisBracket = ((objsEx(:,2) >= bracketMin(bracketNum)) & (objsEx(:,2) < bracketMax(bracketNum)));
                    bracketMatrix = matrixExperiment(indexOfIndividualsInThisBracket,:);
                    
                    missingExperiment =  bracketMatrix(bracketMatrix(:,3) == "missing", 2);
                    unstableExperiment =  bracketMatrix(bracketMatrix(:,3) == "unstable", 2);  
                    stableExperiment =  bracketMatrix(bracketMatrix(:,3) == "stable",2);

                    missingBracket = [missingBracket; min(str2double(missingExperiment))];
                    unstableBracket = [unstableBracket; min(str2double(unstableExperiment))];
                    stableBracket = [stableBracket; min(str2double(stableExperiment))];
                    bracketExperimentData = containers.Map({'missingExperiment', 'unstableExperiment', 'stableExperiment'}, {missingBracket, unstableBracket, stableBracket});
                    timeExerpimentsBrackets(string(bracketNum)) = bracketExperimentData;

                end
                expMaxTimeOfLastMap(exNum) = max(timestampEx);
            end

            maxTimeOfLastMap(approachName) = expMaxTimeOfLastMap;
            if approachName == "FullWP" && str2double(wptIndex) > 2
                objectives(indexToIngoreFullwpt,:) = [];
                timestamp(indexToIngoreFullwpt,:) = []; 
                classes(indexToIngoreFullwpt,:) = [];
            end

            bracketsDistanceCount = [];
            bracketsTimeCount = [];
            indivudalsCount = 0;
            indexes = zeros(size(objectives(:,2)));
            for bracketNum = 1:numBrackets

                if bracketNum == numBrackets
                    indexOfIndividualsInThisBracket = ((objectives(:,2) >= bracketMin(bracketNum)) & (objectives(:,2) <= bracketMax(bracketNum) + 1e-1));
                else 
                    indexOfIndividualsInThisBracket = ((objectives(:,2) >= bracketMin(bracketNum)) & (objectives(:,2) < bracketMax(bracketNum)));
                end
                indexesNex = indexes + indexOfIndividualsInThisBracket;
                indexes = indexesNex;
                indivudalsCount = indivudalsCount + sum(indexOfIndividualsInThisBracket);
                classesInThisBracket = classes(indexOfIndividualsInThisBracket);

                indexesMissing = (classesInThisBracket == "missing");
                indexesUnstable = (classesInThisBracket == "unstable");
                indexesStable = (classesInThisBracket == "stable");

                countMissing = sum(indexesMissing);
                countUnstable = sum(indexesUnstable);
                countStable =sum(indexesStable);

                bracketsDistanceCount = [bracketsDistanceCount; countMissing, countUnstable, countStable];

                barcketNumTime = timeExerpimentsBrackets(string(bracketNum));
                missingBracket= barcketNumTime('missingExperiment');
                unstableBracket= barcketNumTime('unstableExperiment');
                stableBracket= barcketNumTime('stableExperiment');
                averageMissing = mean(missingBracket);
                averageUnstable = mean(unstableBracket);
                averageStable = mean(stableBracket);
                bracketsTimeCount = [bracketsTimeCount; [averageMissing averageUnstable averageStable]];
            end

            endTimeExperiments = approachTimeExperiments(end,:);
            wayPointTimeInfo = containers.Map();
            wayPointTimeInfo('approachTimeExperiments') = approachTimeExperiments;
            wayPointTimeInfo('MaxTime') = max(endTimeExperiments);
            wayPointTimeInfo('MinTime') = min(endTimeExperiments);
            wayPointTimeInfo('AverageTime') = mean(endTimeExperiments);
            wayPointTimeInfo('exNums') = experimentsnumList;
            waypointMetrics(approachName) = containers.Map({'bracketsDistanceCount', 'bracketsTimeCount', 'wayPointTimeInfo'}, {bracketsDistanceCount, bracketsTimeCount, wayPointTimeInfo});
        end
        fullSetMissingPrev(wptIndex) = fullSetMissingWpt;
        metrics(wptIndex) = waypointMetrics;
    end
end

function [metrics, strangeExperiments] = calculateHVandIGD(metrics, experimentInfoMap, vesselResultsPathBase, vesselInformation, waypointRangesMap, combinedsolutionsMap)
    % Calculate hypervolume and IGD for each approach and waypoint.
    numGenerationsTotal = 1000;
    populationSize = 10;
    numInitialWaypoints = vesselInformation.numWaypoints+1;
    strangeExperiments = [];

    for waypointKey = waypointRangesMap.keys()
        wptIndex = waypointKey{:};
        waypointMetrics = metrics(wptIndex);
        waypointRanges = waypointRangesMap(wptIndex);

        waypointSolutionMap = combinedsolutionsMap(string(wptIndex));
        allObjs = waypointSolutionMap("objs");
        allCons = waypointSolutionMap("cons");
        allDecs =  waypointSolutionMap("decs");
        allMissingFlag = waypointSolutionMap("missingFlag");
        nonMissingPathsFlag = ~allMissingFlag;

        allObjs = allObjs(nonMissingPathsFlag,:);
        allDecs = allDecs(nonMissingPathsFlag,:);
        allCons = allCons(nonMissingPathsFlag,:);
        combinedPopulations =  SOLUTION(allDecs, allObjs, allCons);
        combinedParetoFront = combinedPopulations.best.objs;
        

        for approachKey = experimentInfoMap.keys()
            approachName = approachKey{:};

            if approachName == "FullWP"
                numGenerations = 1000;
            elseif approachName == "RandomSearch"
                numGenerations = 1; 
            elseif approachName == "IncWP_Kmeans" 
                if wptIndex == 2
                    maxNumberOfSubpathsFromPF = 1;
                else
                    maxNumberOfSubpathsFromPF = 3;
                end
                subpathDivision = 3;

                budgetPerSearch = ceil((populationSize*numGenerationsTotal/((numInitialWaypoints-2)*subpathDivision+1))/populationSize)*populationSize;

                maxEvaluation = round((populationSize*numGenerationsTotal/(numInitialWaypoints-1))/populationSize)*populationSize;
                numGenerations = ceil(budgetPerSearch*maxNumberOfSubpathsFromPF/populationSize);
               

            else
                maxEvaluation = round((populationSize*numGenerationsTotal/(numInitialWaypoints-1))/populationSize)*populationSize;
                numGenerations = ceil(maxEvaluation/populationSize);
            end
            experimentInfo = experimentInfoMap(approachName);
            referencePoint = [-waypointRanges(3) waypointRanges(5)];
            approachHV = [];
            approachIGD = [];

            for exNum = experimentInfo
                population = getPopulation(vesselInformation, vesselResultsPathBase, populationSize, numGenerations, approachName, exNum, wptIndex);

                objs = population.objs;
                decs = population.decs;
                cons = population.cons;
                [missingPathsFlag, nonMissingPathsFlag] = getIndexesOfMissingPaths(objs);
                exObjs = objs(nonMissingPathsFlag,:);
                exDecs = decs(nonMissingPathsFlag,:);
                exCons = cons(nonMissingPathsFlag,:);

                exObjs(:,1) = -waypointRanges(3) + exObjs(:,1);
                if size(exObjs,1) > 0 
                    shiftedPopulation = SOLUTION(exDecs, exObjs, exCons);
                    paretoFrontObjs = shiftedPopulation.best.objs;

                    if size(paretoFrontObjs,1)> 0
                        HVscore = hypervolume(paretoFrontObjs, referencePoint,10000);
                        IGDscore =  IGD(shiftedPopulation,combinedParetoFront);
                        approachHV = [approachHV; HVscore];
                        approachIGD = [approachIGD; IGDscore];
                        if HVscore == 0
                            strangeExperiments = [strangeExperiments; [string(size(paretoFrontObjs,1)) string(approachName),  string(wptIndex), string(exNum)]];

                        end
                    else
                        strangeExperiments = [strangeExperiments; [string(size(paretoFrontObjs,1)) string(approachName),  string(wptIndex), string(exNum)]];
                    end
                else
                    strangeExperiments = [strangeExperiments; ["0" string(approachName), string(wptIndex), string(exNum)]];
                end
            end
            approachMetric = waypointMetrics(approachName);
            approachMetric('HV') = approachHV;
            approachMetric('IGD') = approachIGD;
            waypointMetrics(approachName) = approachMetric;
        end
        metrics(wptIndex) = waypointMetrics;
    end
end

function metrics = calculateStatistaltests(metrics, experimentInfoMap, vesselResultsPathBase, vesselInformation, waypointRangesMap, combinedsolutionsMap)
    % Compare the HV distributions pairwise using ranksum and A12.
    experimentInfoMap = copyMap(experimentInfoMap);
    
    for waypointKey = waypointRangesMap.keys()
        wptIndex = waypointKey{:};
        waypointMetrics =  metrics(wptIndex);
        comparedAppraochesMap = copyMap(experimentInfoMap);
        comparisonResults = ["appraoch A" "appraoch B" "Mann-Whitney U test p-value" "A12 value" "Final vote"];
        
        for approachKey = experimentInfoMap.keys()
            approachName = approachKey{:};
            approachMetric = waypointMetrics(approachName);
            HVmetricAppraoch = approachMetric('HV');
            comparedAppraochesMap.remove(approachName);
           
            for comperisationAppraochKey = comparedAppraochesMap.keys()
                comperisationAppraochName = comperisationAppraochKey{:};
                approachMetric = waypointMetrics(comperisationAppraochName);
                HVmetricComperisation = approachMetric('HV');
                mannWhitneyUtestValue = ranksum(HVmetricAppraoch, HVmetricComperisation);
                a12value = a12(HVmetricAppraoch, HVmetricComperisation);

                if mannWhitneyUtestValue < 0.05 && a12value > 0.5
                    finalVote = approachName;
                elseif mannWhitneyUtestValue < 0.05 && a12value < 0.5
                    finalVote = comperisationAppraochName;
                elseif mannWhitneyUtestValue >= 0.05 || a12value == 0.5
                    finalVote = "ND"; 
                else
                    finalVote = "";
                end
                singleCoparisonResult = [approachName comperisationAppraochName string(mannWhitneyUtestValue) string(a12value) string(finalVote)];
                comparisonResults = [comparisonResults; singleCoparisonResult];
            end
        end

        waypointMetrics('StatisticalComparisonResults') = comparisonResults;
        metrics(wptIndex) = waypointMetrics;
    end
end

function newMap = copyMap(originalMap)
    k = originalMap.keys;
    v = originalMap.values;
    newMap = containers.Map(k, v);
end



function metrics = calculateUniquePoints(metrics, approachDataMap)
    % Measure repeated points and points that are not seen in other approaches.
    wayPointData = containers.Map();
    for approachKey = approachDataMap.keys()
        approachName = approachKey{:};
        approachInfo = approachDataMap(approachName);

        for wptIndexKey = approachInfo.keys
            wptIndex = wptIndexKey{:};
            waypointInfoMap = approachInfo(wptIndex);
            classes = waypointInfoMap('classes');
            waypoints = waypointInfoMap('decisions');
            if isKey(wayPointData,wptIndex)
                tempWaypointInfo = wayPointData(wptIndex);
                allwaypoints = tempWaypointInfo("allwaypoints");
            else
                tempWaypointInfo = containers.Map();
                allwaypoints = [];
            end
            allwaypoints = [allwaypoints;  ...
                           repmat(string(approachName),size(classes,1),1) waypoints classes];
            tempWaypointInfo(approachName) = containers.Map({'decs', 'classes'}, {waypoints,classes});
            tempWaypointInfo("allwaypoints") = allwaypoints;

            wayPointData(wptIndex) = tempWaypointInfo;
        end
    end

    for wptIndexKey = wayPointData.keys
        wptIndex = wptIndexKey{:};
        wayPointInfo = wayPointData(wptIndex);
        allwaypoints = wayPointInfo('allwaypoints');
        wayPointInfo.remove('allwaypoints');
        waypointMetric = metrics(wptIndex);
        for approachNameKey = wayPointInfo.keys
            approachName = approachNameKey{:};
            approachInfo = wayPointInfo(approachName);
            approachMetric = waypointMetric(approachName);

            wptInApproach = approachInfo('decs');
            classesInApproach = approachInfo('classes');
            combinedWaypointClass = [wptInApproach classesInApproach];

            waypointsStable = str2double(combinedWaypointClass(combinedWaypointClass(:,end) == "stable",1:end-1));
            waypointsMissing =str2double(combinedWaypointClass(combinedWaypointClass(:,end) == "missing",1:end-1));
            waypointsUnstable = str2double(combinedWaypointClass(combinedWaypointClass(:,end) == "unstable",1:end-1));

            % unique waypoints
            % [overall stable unstable missing]
            wptInApproach = round(wptInApproach,1);
            waypointsStable = round(waypointsStable,1);
            waypointsMissing = round(waypointsMissing,1);
            waypointsUnstable = round(waypointsUnstable,1);
        
            [Ca] = unique(wptInApproach,'rows');
            presUnique = size(Ca,1)/size(wptInApproach,1)*100;
            [Cs] = unique(waypointsStable,'rows');
            presUniqueStable = size(Cs,1)/size(waypointsStable,1)*100;
            [Cu] = unique(waypointsUnstable,'rows');
            presUniqueUnstable = size(Cu,1)/size(waypointsUnstable,1)*100;
            [Cm] = unique(waypointsMissing,'rows');
            presUniqueMissing = size(Cm,1)/size(waypointsMissing,1)*100;
            uniqueStats = ["uniquePoints" presUnique presUniqueStable presUniqueUnstable presUniqueMissing];

            waypointsNotInThisApproach = allwaypoints(allwaypoints(:,1)~=approachName,2:end);
            overallNotInThisApproach =  round(str2double(waypointsNotInThisApproach(:,1:end-1)),1);
            stableNotInApproach = round(str2double(waypointsNotInThisApproach(waypointsNotInThisApproach(:,end) == "stable",1:end-1)),1);
            unstableNotInApproach = round(str2double(waypointsNotInThisApproach(waypointsNotInThisApproach(:,end) == "unstable",1:end-1)),1);
            missingNotInApproach = round(str2double(waypointsNotInThisApproach(waypointsNotInThisApproach(:,end) == "missing",1:end-1)),1);

            numNotInApproach = size(overallNotInThisApproach,1);
            numStableNotInApproach =  size(stableNotInApproach,1);
            numUnstableNotInApproach =  size(unstableNotInApproach,1);
            numMissingNotInApproach =  size(missingNotInApproach,1);

            overallNotInThisApproach = sum(ismember(wptInApproach,overallNotInThisApproach,'rows')); 
            stableNotInApproach = sum(ismember(waypointsStable,stableNotInApproach,'rows')); 
            unstableNotInApproach = sum(ismember(waypointsUnstable,unstableNotInApproach,'rows'));
            missingNotInApproach = sum(ismember(waypointsMissing,missingNotInApproach,'rows'));

            notInOthersStats = ["notInOthers" overallNotInThisApproach/numNotInApproach*100 stableNotInApproach/numStableNotInApproach*100 unstableNotInApproach/numUnstableNotInApproach*100 missingNotInApproach/numMissingNotInApproach*100];

            approachMetric("uniqueStats") = [uniqueStats; notInOthersStats];
            waypointMetric(approachName) = approachMetric;
        end
        metrics(wptIndex) = waypointMetric;
    end
end


function metrics = calculateUniqueClusters(metrics, approachDataMap)
    % Cluster the waypoint decisions and count clusters unique to one approach.
    if isKey(approachDataMap, 'FullWP')
        approachDataMap.remove('FullWP');
    end
    if isKey(approachDataMap, 'RandomSearch')
        approachDataMap.remove('RandomSearch');
    end

    wayPointData = containers.Map();
    for approachKey = approachDataMap.keys()
        approachName = approachKey{:};
        approachInfo = approachDataMap(approachName);

        for wptIndexKey = approachInfo.keys
            wptIndex = wptIndexKey{:};
            waypointInfoMap = approachInfo(wptIndex);
            classes = waypointInfoMap('classes');
            waypoints = waypointInfoMap('decisions');
            if isKey(wayPointData,wptIndex)
                tempWaypointInfo = wayPointData(wptIndex);
                allwaypoints = tempWaypointInfo("allwaypoints");
            else
                tempWaypointInfo = containers.Map();
                allwaypoints = [];
            end
            allwaypoints = [allwaypoints;  ...
                           repmat(string(approachName),size(classes,1),1) waypoints classes];
            tempWaypointInfo(approachName) = containers.Map({'decs', 'classes'}, {waypoints,classes});
            tempWaypointInfo("allwaypoints") = allwaypoints;

            wayPointData(wptIndex) = tempWaypointInfo;
        end
    end

    waypointClusterData = containers.Map(); 
    approachNamesList = [];
    for wptIndexKey = wayPointData.keys
        wptIndex = wptIndexKey{:};
        wayPointInfo = wayPointData(wptIndex);
        allwaypoints = wayPointInfo('allwaypoints');
        wayPointInfo.remove('allwaypoints');
        waypointMetric = metrics(wptIndex);
        approachClusterData = containers.Map(); 

        for approachNameKey = wayPointInfo.keys
            approachName = approachNameKey{:};
            approachInfo = wayPointInfo(approachName);
            approachMetric = waypointMetric(approachName);
            approachNamesList = [approachNamesList string(approachName)];

            wptInApproach = approachInfo('decs');
            classesInApproach = approachInfo('classes');
            combinedWaypointClass = [wptInApproach classesInApproach];

            waypointsStable = str2double(combinedWaypointClass(combinedWaypointClass(:,end) == "stable",1:end-1));
            waypointsMissing =str2double(combinedWaypointClass(combinedWaypointClass(:,end) == "missing",1:end-1));
            waypointsUnstable = str2double(combinedWaypointClass(combinedWaypointClass(:,end) == "unstable",1:end-1));

            % unique waypoints
            % [overall stable unstable missing]
            wptInApproach = round(wptInApproach,1);
            waypointsStable = round(waypointsStable,1);
            waypointsMissing = round(waypointsMissing,1);
            waypointsUnstable = round(waypointsUnstable,1);
        
            eps = 5;
            minPts = 10;
            [idxOverall, correptsOverall, nClustersOverall, clusterCentersOverall, clusterSizesOverall] = calculateClusterData(wptInApproach, eps, minPts);
            [idxStable, correptsStable, nClustersStable, clusterCentersStable, clusterSizesStable] = calculateClusterData(waypointsStable, eps, minPts);
            [idxUnstable, correptsUnstable, nClustersUnstable, clusterCentersUnstable, clusterSizesUnstable] = calculateClusterData(waypointsUnstable, eps, minPts);
            [idxMissing, correptsMissing, nClustersMissing, clusterCentersMissing, clusterSizesMissing] = calculateClusterData(waypointsMissing, eps, minPts);

            overallStats =  containers.Map({'idx', 'correpts', 'nClustersOverall', 'clusterCenters', 'clusterSizes'}, {idxOverall, correptsOverall, nClustersOverall, clusterCentersOverall, clusterSizesOverall});
            stableStats =  containers.Map({'idx', 'correpts', 'nClustersStable', 'clusterCenters', 'clusterSizes'}, {idxStable, correptsStable, nClustersStable, clusterCentersStable, clusterSizesStable});
            unstableStats =  containers.Map({'idx', 'correpts', 'nClustersUnstable', 'clusterCenters', 'clusterSizes'}, {idxUnstable, correptsUnstable, nClustersUnstable, clusterCentersUnstable, clusterSizesUnstable});
            missingStats =  containers.Map({'idx', 'correpts', 'nClustersMissing', 'clusterCenters', 'clusterSizes'}, {idxMissing, correptsMissing, nClustersMissing, clusterCentersMissing, clusterSizesMissing});

            approachClusterData(approachName) = containers.Map({'overallStats', 'stableStats', 'unstableStats', 'missingStats'}, {overallStats, stableStats, unstableStats, missingStats});
        end

        waypointClusterData(wptIndex) = approachClusterData;
    end

    approachNamesList = unique(approachNamesList);
    for wptIndexKey = waypointClusterData.keys
        wptIndex = wptIndexKey{:};
        wayPointInfo = waypointClusterData(wptIndex);
        waypointMetric = metrics(wptIndex);

        
        for approachNameKey = wayPointInfo.keys
            approachName = approachNameKey{:};
            approachClusterData = wayPointInfo(approachName);
            approachMetric = waypointMetric(approachName);
            otherApproachNamesList = approachNamesList(approachNamesList~=approachName);

            approachOverallData = approachClusterData('overallStats');           
            approachStableData = approachClusterData('stableStats');
            approachUnstableData = approachClusterData('unstableStats');
            approachMissingData = approachClusterData('missingStats');

            idxOverall = approachOverallData('idx'); 
            correptsOverall = approachOverallData('correpts');
            clusterCentersOverall = approachOverallData('clusterCenters');
            clusterSizesOverall = approachOverallData('clusterSizes');

            idxStable = approachStableData('idx'); 
            correptsStable = approachStableData('correpts');
            clusterCentersStable = approachStableData('clusterCenters');
            clusterSizesStable = approachStableData('clusterSizes');

            idxUnstable = approachUnstableData('idx'); 
            correptsUnstable = approachUnstableData('correpts');
            clusterCentersUnstable = approachUnstableData('clusterCenters');
            clusterSizesUnstable = approachUnstableData('clusterSizes');

            idxMissing = approachMissingData('idx');
            correptsMissing = approachMissingData('correpts');
            clusterCentersMissing = approachMissingData('clusterCenters');
            clusterSizesMissing = approachMissingData('clusterSizes');

            

            otherOverall = [];
            otherStable = [];
            otherUnstable = [];
            otherMissing = [];
            for otherApprachIdx = 1:length(otherApproachNamesList)
                otherApprach = otherApproachNamesList(otherApprachIdx);
                otherApproachClusterData = wayPointInfo(otherApprach);

                other_approachOverallData = otherApproachClusterData('overallStats');           
                other_approachStableData = otherApproachClusterData('stableStats');
                other_approachUnstableData = otherApproachClusterData('unstableStats');
                other_approachMissingData = otherApproachClusterData('missingStats');

                other_clusterCentersOverall = other_approachOverallData('clusterCenters');
                other_clusterCentersStable = other_approachStableData('clusterCenters');
                other_clusterCentersUnstable = other_approachUnstableData('clusterCenters');
                other_clusterCentersMissing = other_approachMissingData('clusterCenters');
                
                otherOverall = [otherOverall; other_clusterCentersOverall];
                otherStable = [otherStable; other_clusterCentersStable];
                otherUnstable = [otherUnstable; other_clusterCentersUnstable];
                otherMissing = [otherMissing; other_clusterCentersMissing];

            end
            countOfuniqueClusterOverall = countOfuniqueCluster(clusterCentersOverall, otherOverall, eps);
            countOfuniqueClusterStable = countOfuniqueCluster(clusterCentersStable, otherStable, eps);
            countOfuniqueClusterUnstable = countOfuniqueCluster(clusterCentersUnstable, otherUnstable, eps);
            countOfuniqueClusterMissing = countOfuniqueCluster(clusterCentersMissing, otherMissing, eps);

              
            approachMetric("clusterData") = containers.Map({'approachClusterData', 'countOfuniqueClusterOverall', 'countOfuniqueClusterStable', 'countOfuniqueClusterUnstable', 'countOfuniqueClusterMissing'}, ...
                                                            {approachClusterData, countOfuniqueClusterOverall, countOfuniqueClusterStable, countOfuniqueClusterUnstable, countOfuniqueClusterMissing});
            waypointMetric(approachName) = approachMetric;
        end
        metrics(wptIndex) = waypointMetric;
    end
end

function countOfuniqueCluster = countOfuniqueCluster(approachCenters, otherCenters, eps)
    countOfuniqueCluster = 0;
    for centerIdx = 1:size(approachCenters,1)
        centerPoint = approachCenters(centerIdx, :);
        distanceSmallerThanEps = false;
        otherCenterIdx = 1;
        while distanceSmallerThanEps == false && otherCenterIdx <= size(otherCenters,1)

            otherCenterPoint = otherCenters(otherCenterIdx, :);
            distance = pdist2(centerPoint,otherCenterPoint);
            
            distanceSmallerThanEps = any(distance < eps);
            otherCenterIdx = otherCenterIdx + 1;
        end
        if distanceSmallerThanEps == false
            countOfuniqueCluster = countOfuniqueCluster + 1;
        end
    end
end

function [idx, correpts, nClustersOverall, clusterCenters, clusterSizes] = calculateClusterData(wptInApproach, eps, minPts)
    if size(wptInApproach,1)> 0
        [idx, correpts] = dbscan(wptInApproach, eps, minPts);
        correpts = wptInApproach(correpts,:);
        nClustersOverall = numel(unique(idx(idx > 0)));

        clusterCenters = zeros(nClustersOverall, size(wptInApproach,2));
        clusterSizes = zeros(nClustersOverall,1);

        for iCluster = 1:nClustersOverall
            clusterPoints = wptInApproach(idx == iCluster, :);
            clusterCenters(iCluster, :) = mean(clusterPoints,1);
            clusterSizes(iCluster) = size(clusterPoints,1);
        end
    else
        idx = 0;
        correpts = [];
        nClustersOverall = 0;
        clusterCenters = [];
        clusterSizes = [];
    end
end
