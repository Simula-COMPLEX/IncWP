function [selectionResultsDistributionMap, resultsMatrix, precentageResultsMap] = countClassificationPathsWithBrackets(selectionTypeClassification, experimentInfoMap, numInitialWaypoints)
    %% display classifyed paths
    numbrackets = 5;

    resultsMatrix = ["Approach", "wptIndex", "bracket", "% missing", "% unstable", "% stable"];
    precentageResultsMap = containers.Map();
    selectionResultsDistributionMap = containers.Map();
    selectionNames = string(keys(experimentInfoMap));
    for selectionType = selectionNames
        
        experimentList = experimentInfoMap(selectionType);

        experimentsClassificationMap = selectionTypeClassification(selectionType) ;
        WPresultsDistributionMap = containers.Map();
        WPresultsMap = containers.Map();
        for wptIndex = 2:numInitialWaypoints
            countWpIndex = zeros(5, 3); 
            
            for experimentNumber = experimentList
                experimentsClassification = experimentsClassificationMap(string(experimentNumber));
                numPeaksMap = experimentsClassification('numberOfPeaks');
                classesMap = experimentsClassification('classes');
                distanceMap = experimentsClassification('distances');
                bracketClassMapWP = experimentsClassification('bracketClassMap');
                bracketClassMap = bracketClassMapWP(string(wptIndex));
                %bracketClassMap = bracketClassMapWP(string(wptIndex))
                

                %classes = classesMap(string(wptIndex));
                %distancesFromInitialWaypoints = distanceMap(string(wptIndex));
                %distanceclassification = [distancesFromInitialWaypoints classes];
                
                for bracketsIdx = 1:numbrackets
                    distanceclassificationBrackage = bracketClassMap(string(bracketsIdx));
                    distanceclassificationBrackageClasses = distanceclassificationBrackage(:,2);
                    if ~isempty(distanceclassificationBrackage)
                        countClasses = [sum(distanceclassificationBrackageClasses == "missing") ...
                                        sum(distanceclassificationBrackageClasses == "unstable") ...
                                        sum(distanceclassificationBrackageClasses == "stable")];
                        
                     
                       countWpIndex(bracketsIdx,:) = countWpIndex(bracketsIdx,:) + countClasses;
                    else
                        countWpIndex(bracketsIdx,:) = countWpIndex(bracketsIdx,:);
                    end
                end
                
            end
            if sum(countWpIndex(:)) ~= 0
                precentageWpIndex = countWpIndex/sum(countWpIndex(:))*100;
            else
                precentageWpIndex = countWpIndex;
            end

            bracketsResults = containers.Map();
            bracketsResults = [];
            for bracketsIdx = 1:numbrackets
                bracketsPrecentageResults = precentageWpIndex(bracketsIdx,:);
                resultsMatrix = [resultsMatrix; ...
                                 selectionType string(wptIndex) string(bracketsIdx) string(bracketsPrecentageResults)];
                %bracketsResults(string(bracketsIdx)) = bracketsPrecentageResults;
                bracketsResults = [bracketsResults; bracketsPrecentageResults];

            end
            WPresultsMap(string(wptIndex)) = bracketsResults;
            WPresultsDistributionMap(string(wptIndex)) = countWpIndex;

        end
        selectionResultsDistributionMap(string(selectionType)) = WPresultsDistributionMap;
        precentageResultsMap(string(selectionType)) = WPresultsMap;
        
    end
 
         
    % this should be plotted
end
