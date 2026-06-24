function [lower, upper, PopDec] =  generateWaypoint(obj) 
    % Build the local search box and initial population for one waypoint.
    currentInitialWaypoint = obj.endWpt;
    if obj.vesselName == "mariner" 
        lower = currentInitialWaypoint - ones(size(currentInitialWaypoint))*400;
        upper = currentInitialWaypoint + ones(size(currentInitialWaypoint))*400;
    elseif obj.vesselName == "remus100" || obj.vesselName == "nspauv"
        lower = currentInitialWaypoint - ones(size(currentInitialWaypoint))*150;
        upper = currentInitialWaypoint + ones(size(currentInitialWaypoint))*150;
        if lower(:,3) < 0
            lower(:,3) = 0;
        end
    end

    PopDec = zeros(obj.N,obj.D);
    PopDec(1,:) = currentInitialWaypoint;
    PopDec(2:round(obj.N/2),:) =  seedPopulation(round(obj.N/2)-1,obj.D, obj.R_switch, lower, upper, obj.pointDimension, currentInitialWaypoint);

    for individNumber = (round(obj.N/2)+1):obj.N
        mutatedPoint = lower + (upper - lower) .* rand(1, obj.D);
        while ismember(mutatedPoint,PopDec,'rows')
            mutatedPoint = lower + (upper - lower) .* rand(1, obj.D);
        end
        PopDec(individNumber,:) = mutatedPoint;
    end
end
