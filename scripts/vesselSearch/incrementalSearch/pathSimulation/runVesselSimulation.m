function [endIteration, reachedWaypoint, lengthOfPath, lastPoint, subpath, angles] = runVesselSimulation(obj, wpt)
    % Dispatch one incremental waypoint simulation to the correct vessel model.
    if obj.vesselName == "mariner"
        [endIteration, reachedWaypoint, lengthOfPath, lastPoint, subpath, angles] = runSubPathMariner(wpt, obj.endWptIndex,obj.R_switch, obj.enviromentRandom, obj.iterationIndex ,obj.startWptIndex, obj.vesselResultsPath);
    elseif obj.vesselName == "nspauv"
        [endIteration , reachedWaypoint, lengthOfPath, lastPoint, subpath, angles] = runSubPathNspauv(wpt, obj.endWptIndex,obj.R_switch, obj.enviromentRandom, obj.iterationIndex ,obj.startWptIndex, obj.vesselResultsPath);
    elseif obj.vesselName == "remus100"
        [endIteration , reachedWaypoint, lengthOfPath, lastPoint, subpath, angles] = runSubPathRemus100(wpt, obj.endWptIndex,obj.R_switch, obj.enviromentRandom, obj.iterationIndex ,obj.startWptIndex, obj.vesselResultsPath);
    end
end
