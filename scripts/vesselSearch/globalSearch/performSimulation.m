function [fullpath, subPaths, transitionIndices, angles, numberOfPointsReached] = performSimulation(listOfPoints, obj)
    % Simulate one full waypoint sequence for the selected vessel.
    numPoints = length(listOfPoints)/obj.pointDimension;
    pointsMatrix = reshape(listOfPoints, [obj.pointDimension, numPoints])';

    if obj.shipName == "mariner"
        wpt.pos.x = [0; pointsMatrix(:,1)];
        wpt.pos.y = [0; pointsMatrix(:,2)];

        [simdata, ~, ~] = marinerPath(wpt, obj.R_switch, obj.enviromentRandom);
        [angles, fullpath] = extractAnglesAndPath(simdata, [], obj.shipName);
    elseif obj.shipName == "remus100"
        wpt.pos.x = [0; pointsMatrix(:,1)];
        wpt.pos.y = [0; pointsMatrix(:,2)];
        wpt.pos.z = [0; pointsMatrix(:,3)];

        [simdata, ALOSdata, ~] = remus100path(wpt, obj.R_switch, obj.enviromentRandom);
        [angles, fullpath] = extractAnglesAndPath(simdata, ALOSdata, obj.shipName);
    elseif obj.shipName == "nspauv"
        wpt.pos.x = [0; pointsMatrix(:,1)];
        wpt.pos.y = [0; pointsMatrix(:,2)];
        wpt.pos.z = [0; pointsMatrix(:,3)];

        [simdata, ALOSdata, ~] = npsauvPath(wpt, obj.R_switch, obj.enviromentRandom);
        [angles, fullpath] = extractAnglesAndPath(simdata, ALOSdata, obj.shipName);
    end

    % Split the full path back into subpaths between waypoints.
    [transitionIndices, subPaths, numberOfPointsReached] = splitDataBetweenWaypoints(pointsMatrix, obj.R_switch, fullpath);
end
