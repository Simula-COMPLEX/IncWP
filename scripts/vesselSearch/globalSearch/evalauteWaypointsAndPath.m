function [totalDistanceBetweenWaypoints, meanSubpathDistances, subPathDistances,pathMissingFlagsList] = evalauteWaypointsAndPath(initialPoints, intialPath, newPoints, fullpath, subPaths,transitionIndices, numberOfPointsReached)
    pointDimension = size(fullpath,2);
    numPoints = length(newPoints)/pointDimension;
    if pointDimension == 2
        initialPointsMatrix = [[0 0]; reshape(initialPoints, [pointDimension, numPoints])'];
        newPointsMatrix  = [[0 0]; reshape(newPoints, [pointDimension, numPoints])'];

    elseif pointDimension == 3
        initialPointsMatrix = [[0 0 0]; reshape(initialPoints, [pointDimension, numPoints])'];
        newPointsMatrix  = [[0 0 0]; reshape(newPoints, [pointDimension, numPoints])'];
    end

    % distance between initial and new waypoints 
    distanceBetweenWaypoints  = zeros(size(newPointsMatrix,1),1);
    for pointIndex = 1:size(newPointsMatrix,1)
        distanceBetweenWaypoints(pointIndex) = pdist2(initialPointsMatrix(pointIndex,:), newPointsMatrix(pointIndex,:),'euclidean');
    end
    totalDistanceBetweenWaypoints = abs(sum(distanceBetweenWaypoints));
    
    pathMissingFlagsList = zeros(numPoints,1);
    if length(transitionIndices) < numPoints
        for missingPathsIndex = length(transitionIndices):numPoints
            pathMissingFlagsList(missingPathsIndex) = 1;
    
        end
    end


    transitionIndices = [1; transitionIndices]; 
    subPathDistances = zeros(length(transitionIndices)-1,1);
    if numberOfPointsReached == (length(transitionIndices)-1)
        numberOfPathslengthToEvaluate = length(transitionIndices)-1;
    else 
        numberOfPathslengthToEvaluate = numberOfPointsReached;
    end

    prevTotalLength = [];
    summedSubPathDistance = 0;
    for pointIndex = 1:numberOfPathslengthToEvaluate %length(transitionIndices)-1 
        startPoint = fullpath(transitionIndices(pointIndex),:);
        %endPoint = fullpath(transitionIndices(pointIndex+1),:);
        endPoint = initialPointsMatrix(pointIndex+1,:);
        subpath = fullpath(transitionIndices(pointIndex):transitionIndices(pointIndex+1),:);
        totalPathLength = 0;
        for i = 1:(size(subpath,1)-1)
            totalPathLength = totalPathLength + pdist2(subpath(i,:),subpath(i+1,:),'euclidean');
        end
        totalPathLengthPenalized = totalPathLength/pdist2(startPoint,endPoint);
        summedSubPathDistance = summedSubPathDistance + totalPathLengthPenalized; 
        prevTotalLength = [prevTotalLength; totalPathLengthPenalized];

        %subPathDistances(pointIndex) = totalPathLength/pdist2(startPoint,endPoint);
        subPathDistances(pointIndex) = mean(prevTotalLength);
        
    end
 

    meanSubpathDistances = summedSubPathDistance/numPoints; %% dont use mean

    
    
end