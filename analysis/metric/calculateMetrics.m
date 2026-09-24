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
    vesselResultsPathBase = fullfile(resultsPath,vesselName);
    vesselInformation = loadShipSearchParameters(vesselName);
    filelocation = fullfile(baseResultsPath,'combinedResults.mat');
    load(filelocation,'approachDataMap','experimentInfoMap','waypointRangesMap', ...
        'combinedsolutionsMap','approachSortedInfoMap');
    
    % Build the metric maps in the same order they are later displayed.
    metrics = containers.Map();
    metrics = calculateClassificationAndTime(metrics, experimentInfoMap, waypointRangesMap, approachDataMap, approachSortedInfoMap);
    [metrics, strangeExperiments] = calculateHV(metrics, experimentInfoMap, vesselResultsPathBase, vesselInformation, approachSortedInfoMap, waypointRangesMap);
    metrics = calculateStatistaltests(metrics, experimentInfoMap, waypointRangesMap);
    metrics = calculateUniquePoints(metrics, approachDataMap);
    metricsWithoutFullpath = containers.Map();

    filelocation = fullfile(baseResultsPath,'finalResults.mat');
    save(filelocation,'metrics','metricsWithoutFullpath','strangeExperiments');
    metrics = calculateUniqueClusters(metrics, approachDataMap);
    save(filelocation,'metrics','metricsWithoutFullpath','strangeExperiments');
end

function metrics = calculateClassificationAndTime(metrics, experimentInfoMap, waypointRangesMap, approachDataMap, approachSortedInfoMap)
% Exclude FullWP candidates that missed an earlier waypoint.
    for waypoint = string(waypointRangesMap.keys())
        waypointMetrics = containers.Map();
        for approach = string(experimentInfoMap.keys())
            approachInfo = analysisApproachInfo(approach);
            dataByWaypoint = approachDataMap(approach); data = dataByWaypoint(waypoint);
            sorted = approachSortedInfoMap(approach); runs = sorted(waypoint);
            counts = zeros(1,3);
            names = ["missing","unstable","stable"];
            for number = experimentInfoMap(approach)
                run = runs(string(number));
                classes = string(run('classes'));
                if approachInfo.isFullWP
                    missingEarlier = false(size(classes));
                    for previousWaypoint = 2:str2double(waypoint)-1
                        previousRuns = sorted(string(previousWaypoint));
                        previousRun = previousRuns(string(number));
                        missingEarlier = missingEarlier | string(previousRun('classes')) == "missing";
                    end
                    classes = classes(~missingEarlier);
                end
                for c = 1:3
                    counts(c) = counts(c)+sum(classes==names(c));
                end
            end
            endTimes = data('approachTimeExperiments');
            timeInfo = containers.Map({'approachTimeExperiments','MaxTime','MinTime','AverageTime','exNums'}, ...
                {endTimes,max(endTimes),min(endTimes),mean(endTimes),experimentInfoMap(approach)});
            waypointMetrics(approach) = containers.Map({'classificationCounts','wayPointTimeInfo'}, ...
                {counts,timeInfo});
        end
        metrics(waypoint) = waypointMetrics;
    end
end

function [metrics, strangeExperiments] = calculateHV(metrics, experimentInfoMap, vesselResultsPathBase, vesselInformation, approachSortedInfoMap, waypointRangesMap)
% Experiments without an eligible candidate do not receive a metric score.
    strangeExperiments = strings(0,4);
    for waypoint = string(waypointRangesMap.keys())
        waypointMetrics = metrics(waypoint); ranges = waypointRangesMap(waypoint);
        for approach = string(experimentInfoMap.keys())
            numbers = experimentInfoMap(approach);
            hv = []; scoredNumbers = [];
            sorted = approachSortedInfoMap(approach); runs = sorted(waypoint);
            for k = 1:numel(numbers)
                run = runs(string(numbers(k)));
                if contains(approach,"_TimeCutoff")
                    objectives = run('objectives,');
                    decisions = run('decisions');
                    constraints = run('constraints');
                else
                    population = getPopulation(vesselInformation,vesselResultsPathBase, ...
                        [],[],approach,numbers(k),str2double(waypoint));
                    objectives = population.objs;
                    decisions = population.decs;
                    constraints = population.cons;
                end
                eligible = all(isfinite(objectives),2) & abs(objectives(:,1))<=1e8;
                if ~any(eligible)
                    strangeExperiments(end+1,:) = ["0",approach,waypoint,string(numbers(k))];
                    continue;
                end
                population = SOLUTION(decisions(eligible,:),objectives(eligible,:),constraints(eligible,:));
                front = population.best.objs;
                if isempty(front)
                    strangeExperiments(end+1,:) = ["0",approach,waypoint,string(numbers(k))];
                    continue;
                end
                % Translate both candidate coordinates and the HV reference consistently.
                shifted = front; shifted(:,1) = shifted(:,1)-ranges(3);
                reference = [-ranges(3),ranges(5)];
                if all(reference>0) && all(isfinite(reference))
                    hv(end+1,1) = hypervolume(shifted,reference,10000);
                else
                    hv(end+1,1) = NaN; % zero-volume reference box
                end
                scoredNumbers(end+1,1) = numbers(k);
            end
            values = waypointMetrics(approach);
            values('HV') = hv; values('experimentNumbers') = scoredNumbers;
            waypointMetrics(approach) = values;
        end
        metrics(waypoint) = waypointMetrics;
    end
end

function metrics = calculateStatistaltests(metrics, experimentInfoMap, waypointRangesMap)
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
                a = HVmetricAppraoch(isfinite(HVmetricAppraoch));
                b = HVmetricComperisation(isfinite(HVmetricComperisation));
                mannWhitneyUtestValue = NaN; a12value = NaN;
                if ~isempty(a) && ~isempty(b)
                    mannWhitneyUtestValue = ranksum(a,b);
                    a12value = a12(a,b);
                end

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
        idx = zeros(0,1);
        correpts = zeros(0,size(wptInApproach,2));
        nClustersOverall = 0;
        clusterCenters = zeros(0,size(wptInApproach,2));
        clusterSizes = zeros(0,1);
    end
end
