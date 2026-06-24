function [popDec] = randomizePopulation(obj, lower, upper)
    % Sample a random population that satisfies the waypoint spacing constraint.
    populationSize = obj.N;    
    numberOfDecisionVariables = obj.D;
    minDistanceBetweenPoints = (obj.minDistanceBetweenPoints-1)/2;

    popDec = zeros(populationSize, numberOfDecisionVariables);

    numPoints = numberOfDecisionVariables/obj.pointDimension;
    for individNumber = 1:populationSize
        individValid = true;
        while individValid == true 
            tempIndividList = lower + (upper - lower).*rand(1,numberOfDecisionVariables);
            tempIndividMatrix = reshape(tempIndividList, [obj.pointDimension, numPoints])';
            if obj.pointDimension == 2
                x = tempIndividMatrix(:,1);
                y = tempIndividMatrix(:,2); 
                individValid = minDistanceBetweenPoints > min(sqrt( diff(x).^2 + diff(y).^2 )); 
            elseif obj.pointDimension == 3
                x = tempIndividMatrix(:,1);
                y = tempIndividMatrix(:,2); 
                z = tempIndividMatrix(:,3);
                individValid = minDistanceBetweenPoints > min(sqrt( diff(x).^2 + diff(y).^2 + diff(z).^2));
            end
        end
        popDec(individNumber,:) = tempIndividList;
    end
end
