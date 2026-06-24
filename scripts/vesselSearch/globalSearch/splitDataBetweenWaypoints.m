function [transitionIndices, pathSegments, numberOfPointsReached] = splitDataBetweenWaypoints(pointsMatrix, R_switch,path)
    % Split one simulated full path into per-waypoint path segments.
    transitionIndices = [];
    pathSegments = [];
    current_start_idx = 1;
    numberOfPointsReached = 0;
    for pointIndex = 1:length(pointsMatrix)
        endPoint = pointsMatrix(pointIndex,:);
        pointNotFound = true;
        for pathPoints = current_start_idx:size(path,1)
            dist_to_end =  pdist2(path(pathPoints,:), endPoint);
            
            if dist_to_end < R_switch
                % Store the current segment and move to the next waypoint.
                transitionIndices = [transitionIndices; pathPoints];
                pathSegments{end+1} = path(current_start_idx:pathPoints,:);
                current_start_idx = pathPoints + 1;
                pointNotFound = false;
                numberOfPointsReached = numberOfPointsReached+1;
                break;
            end
        end
        if pointNotFound == true
            break;
        end
    end

    if current_start_idx <= size(path, 1) 
        if isempty(pathSegments)
            pathSegments{1} =  path(current_start_idx:size(path, 1),:);
            transitionIndices = size(path,1);
        else 
            if pointNotFound == true
                pathSegments{end+1} = path(current_start_idx:size(path, 1),:);
                transitionIndices = [transitionIndices; size(path,1)];
            else
                pathSegments{end} = [pathSegments{end}; path(current_start_idx:size(path, 1),:)];
                transitionIndices(end) = size(path,1);
            end
        end
    end
end
