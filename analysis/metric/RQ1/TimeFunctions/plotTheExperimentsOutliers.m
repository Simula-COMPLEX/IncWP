function plotTheExperimentsOutliers(listOfExperiments, listOfWaypoints, appraochOutliersMap,listOfOutlierExperiments)
     listOfWaypoints = listOfWaypoints+1;
     %listOfExperiments
     numWPtAndExPerApproach = length(listOfWaypoints)*listOfExperiments;
    
     approachNames = [];
     listOfOutlierExperimentsAll = [];
     %appraochOutliersMap.remove("FullWP");
     for approachNameKey = appraochOutliersMap.keys
         if approachNameKey{:} == "FullWP"
             listOfOutlierExperimentsAll = [listOfOutlierExperimentsAll; ...
                                    [repmat(string(approachNameKey{:}),length(1)*length(listOfExperiments),1) ...
                                     repmat(listOfWaypoints(end),length(listOfExperiments),1) ...
                                     repmat(listOfExperiments',length(1),1)]];
         else 
    
             %approachNames = [approachNames; approachNameKey{:}];
             listOfOutlierExperimentsAll = [listOfOutlierExperimentsAll; ...
                                        [repmat(string(approachNameKey{:}),length(listOfWaypoints)*length(listOfExperiments),1) ...
                                         repelem(listOfWaypoints',length(listOfExperiments)) ...
                                         repmat(listOfExperiments',length(listOfWaypoints),1)]];
         end
         
     end
     listOfOutlierExperimentsAll
     appraochOutliersMap
    
     listOfOutlierExperiments
     listOfOutlierExperiments
     uniqueApproaches = unique(listOfOutlierExperiments(:,1));
     for approachName = uniqueApproaches'
         if  approachName == "IncWP_Kmeans"
    
         else 
            appraochTimestamps = selectionTypeTimeStamps(approachName);
            indexesInList = (listOfOutlierExperimentsAll(:,1) == approachName);
            approachExperiments = listOfOutlierExperimentsAll(indexesInList,2:end);
            uniqueWaypoints = unique(approachExperiments(:,1));
            %uniqueExpeirment = unique(approachExperiments(:,2));
            approachIndividualOutliersMap = containers.Map();
            wptIndividualOutliersMap = containers.Map();
            for wptIdx = uniqueWaypoints' % this is the reason
                if isKey(waypointsOutliersTimestampsMap, wptIdx)
                    approachOutliersTimestampsMap = waypointsOutliersTimestampsMap(wptIdx);
    
                else
                    approachOutliersTimestampsMap = containers.Map();
    
                end

            end
         end
    end

end
