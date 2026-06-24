function [popDec] = seedPopulation(populationSize,numberOfDecisionVariables, minDistanceBetweenPoints, lowerlimit, upperLimit, pointDimension,initialPoints)
    % Build a seeded population by mutating the initial points.
    popDec = zeros(populationSize, numberOfDecisionVariables);

    numPoints = numberOfDecisionVariables/pointDimension;
    for individNumber = 1:populationSize
        individValid = false;
        while individValid == false 
            tempIndivid = mutate(initialPoints);
            if pointDimension == 2
                 x = tempIndivid(1:numPoints);
                 y = tempIndivid((numPoints+1):end); 
                individValid = round(minDistanceBetweenPoints/2) < min(sqrt( diff(x.^2) + diff(y.^2) )); 
            elseif pointDimension == 3
                 x = tempIndivid(1:numPoints);
                 y = tempIndivid((numPoints+1):(numPoints*2)); 
                 z = tempIndivid((2*numPoints+1):end);
                individValid = round(minDistanceBetweenPoints/2) < min(sqrt( diff(x.^2) + diff(y.^2) + diff(z.^2)));
            end
        end
        popDec(individNumber,:) = tempIndivid;
    end
end

function [mutated] = mutate(indiv)
    % Apply a small random mutation to a waypoint vector.
    mutated = indiv;
    numOfMutations = 0;
    while rand < 0.5^numOfMutations
        point = randi(size(indiv,2));
        deviationMax = 5; %5 meters is fine?
        deviationMin = -deviationMax;
        rnumb = deviationMin + (deviationMax - deviationMin) * rand;
        mutated(point) = mutated(point)+rnumb;
        numOfMutations = numOfMutations+1;
    end
end
