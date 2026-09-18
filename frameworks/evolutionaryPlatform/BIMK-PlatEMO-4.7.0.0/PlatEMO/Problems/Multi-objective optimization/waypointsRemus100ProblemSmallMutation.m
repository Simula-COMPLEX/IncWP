classdef waypointsRemus100ProblemSmallMutation < PROBLEM
    properties
        points
        minDistanceBetweenPoints
        %startPoint
        %endPoint
        validPath
        initialPoints 
    end
    methods
        % Default settings of the problem
        function Setting(obj)

            obj.minDistanceBetweenPoints = 5*2+1;  
            obj.M = 6;                                     % Set number of objectives
            obj.D = 6*3;                                % Set number of decision variables
            obj.lower = ones(1,obj.D)*(-400); 
            obj.lower(13:end) = obj.lower(13:end)*0;
            obj.upper = ones(1,obj.D)*(2400);  
            obj.upper(13:end) = ones(1,6)*(150);
            obj.encoding = ones(obj.D,1); 
            %obj.startPoint = [0 0 0]
            %obj.endPoint = [400 2200 50
            obj.validPath = ones(obj.D, 1);

            
        end
        
        function Population = Initialization(obj,N)
            if nargin < 2
                N = obj.N;
            end
            PopDec = zeros(N, obj.D);
            xinitial =  [0  -20 -100   0  200, 200  400];
            %xinitial = [0 -125 -198 66 302 86 400]
            yinitial =  [0  200  600 950 1300 1800 2200];
            %yinitial = [0 168 561 929   1370    1771    2200]
            zinitial =  [0   10  100 100   50   50   50];
            InitalPoints = [xinitial(:,2:end) yinitial(:,2:end) zinitial(:,2:end)];
            obj.initialPoints = InitalPoints;

            obj.lower = InitalPoints - ones(size(InitalPoints))*150;
            obj.lower(13:end) = obj.lower(13:end)*0;
            obj.upper = InitalPoints + ones(size(InitalPoints))*150;
            

            obj.D = length(InitalPoints);
            PopDec =  InitalPoints.*ones(N,1);
            Population = obj.Evaluation(PopDec);

        end

        function PopObj = CalObj(obj, PopDec)
            R_switch = 5;
            

            PopObj = zeros(obj.N,obj.M);
            for individualIndex = 1:size(PopDec,1)
                
                
                %[pointMatrix, wpt] = createWaypointsFromList(PopDec(individualIndex,:))

       

                individual = PopDec(individualIndex,:);
                numPoints = length(individual)/3;
                wpt.pos.x = [0 individual(1:numPoints)]';
                wpt.pos.y = [0 individual((numPoints+1):(numPoints*2))]';
                wpt.pos.z = [0 individual((numPoints*2+1):end)]';
                pointMatrix = [wpt.pos.x wpt.pos.y wpt.pos.z];
                [simdata , ALOSdata, state] = remus100path(wpt, R_switch);      
                eta_mutated = simdata(:,18:23);
                x_mutated = eta_mutated(:,1);
                y_mutated = eta_mutated(:,2);
                z_mutated = eta_mutated(:,3);
                path = [x_mutated y_mutated z_mutated];

                performance = evaluatePath(pointMatrix, R_switch, path);
                [withinEachWayPoint, missingWaypoints] = findMissingWaypoints(pointMatrix, R_switch, path);
                if size(missingWaypoints,1) ~= 0
                    obj.validPath(individualIndex) = 0;
                else
                    obj.validPath(individualIndex) = 1;
                end
                PopObj(individualIndex,:) = performance;

                %PopObj(individualIndex,1) = average_distance; % Objective 1
                %PopObj(individualIndex,2) = max_distance;
                %PopObj(individualIndex,3) = num_timesteps;
                %PopObj(individualIndex,4) = length(pointsOutsidePath);
                %PopObj(individualIndex,5) = num_missing_waypoints;

            end 
        end

        function PopCon = CalCon(obj, PopDec)
            % Calculate the matrix of distances between selected points
            %selPoints = obj.points(selected, :);
            PopCon = ones(size(PopDec,1),1);
            for individualIndex = 1:size(PopDec,1)
                individual = PopDec(individualIndex,:);
                numPoints = length(individual)/3;
                x = individual(1:numPoints);
                y = individual((numPoints+1):(numPoints*2)); 
                z = individual((2*numPoints+1):end);
                selPoints = [x' y' z'];

                distMatrix = pdist2(selPoints, selPoints);
                diagInd = 1:size(distMatrix, 1);
                distMatrix(diagInd, diagInd) = inf;

                %PopCon(individualIndex) = obj.minDistanceBetweenPoints - min(distMatrix,[], "all");
                PopCon(individualIndex) = round(obj.minDistanceBetweenPoints/2) < min(sqrt( diff(selPoints(:,1)).^2 + diff(selPoints(:,2)).^2 + diff(selPoints(:,3)).^2));
                PopCon(individualIndex) = PopCon(individualIndex) && any(z < zeros(1,numPoints));

                PopCon(individualIndex) = PopCon(individualIndex) && (obj.validPath(individualIndex) == 1);
                   
            end



        end
        function PopDec = CalDec(obj, PopDec)
            % calDec - Repair multiple invalid solutions
            %pointDist = ones(size(PopDec,1),1);
            for individualIndex = 1:size(PopDec,1)
                individual = PopDec(individualIndex,:);
                numPoints = length(individual)/3;
                x = individual(1:numPoints);
                y = individual((numPoints+1):(numPoints*2)); 
                z = individual((2*numPoints+1):end);
                selPoints = [x' y' z'];


                while (pointsToClose(selPoints, obj.minDistanceBetweenPoints) == true ||  all(any(selPoints(1:end-1,:) == selPoints(2:end,:),2)) || any(all(selPoints== [0 0 0],2)) || all(selPoints(:,3) < zeros(numPoints,1)) && (obj.validPath(individualIndex) ~= 1))

                    %individual  = unifrnd(obj.lower,obj.upper,1,obj.D); % TODO maybe redfine when we have to find a new one
                    if individualIndex ~= 1 
                        individual = PopDec(individualIndex-1,:);
                    else
                        individual = obj.initialPoints
                    end
                    x = individual(1:numPoints);
                    y = individual((numPoints+1):(numPoints*2)); 
                    z = individual((2*numPoints+1):end);
                    selPoints = [x' y' z'];

                end
                PopDec(individualIndex,:) = individual;
                    

            end
        end
        
    end
end

function validation = pointsToClose(ListOfpoints, minDistance)
    numPoints = size(ListOfpoints,1);
    pointDistances = zeros(1, numPoints);
    pointDistances(1) = pdist2([0 0 0],ListOfpoints(1,:));
    for pointIdx = 2:numPoints
        pointDistances(pointIdx) = pdist2(ListOfpoints(pointIdx-1,:),ListOfpoints(pointIdx,:));
    end

    if (any(pointDistances < minDistance))
        validation =  true; 
    else
        validation =  false;
    end

end



function [pointMatrix, wpt] = createWaypointsFromList(pointsList)
        numPoints = length(pointsList)/3;
        x = [0 pointsList(1:numPoints)];
        y = [0 pointsList((numPoints+1):(numPoints*2))]; 
        z = [0 pointsList((2*numPoints+1):end)];
        pointMatrix = [x' y' z'];
        
        wpt.pos.x = x;
        wpt.pos.y = y;
        wpt.pos.z = z;
end

function performance = evaluatePath(waypointsMatrix, R_switch, path)

     [transitionIndices, pathSegments] = splitDataBetweenWaypoints(waypointsMatrix, R_switch,path);
     performanceMatrix = [];
     for segment = 1:length(pathSegments)
        startpoint = waypointsMatrix(segment,:);
        endPoint = waypointsMatrix(segment +1,:);
        %distanceBetweenPoints = sqrt(sum(startPoint - endPoint.^2))
        distanceBetweenPoints = pdist2(startpoint, endPoint, 'euclidean');
        currentPath = pathSegments{segment};
    
        x = currentPath(:,1);
        y = currentPath(:,2);
        z = currentPath(:,3);
        % Define your path
        
        % Calculate the path's derivative
        dx = gradient(x); % Changes in x
        dy = gradient(y); % Changes in y
        dz = gradient(z);
        
    
        % Calculate the second derivative
        d2x = gradient(dx); % Changes in dx
        d2y = gradient(dy); % Changes in dy
        d2z = gradient(dz);
    
        %std_dev_velocity = std(sqrt(dx.^2 + dy.^2));
        %std_dev_acceleration = std(sqrt(d2x.^2 + d2y.^2));
    
        angles = atan2(dy,dx);
        dAngles = diff(angles);
        dAngles = mod(dAngles +pi, 2*pi) - pi;

        polarAngles = atan2(sqrt(dx.^2 + dy.^2), dz); 
        dpolarAngles = diff(polarAngles);
        dpolarAngles = mod(dpolarAngles +pi, 2*pi) - pi;
     
    
        
        % Calculate the magnitude of the derivative
        %fluxness = sqrt(dx.^2 + dy.^2);
        curvature = sqrt(d2x.^2 + d2y.^2 + d2z.^2);
    
        %averagefluxness = mean(fluxness);
        %maxfluxness = max(fluxness);
        %total_variation = sum(sqrt(dx.^2 + dy.^2));
        averagecurvature = mean(curvature);
        %maxcurvature = max(curvature);
        %std_dev = std(curvature);
        %averageAngles = mean(dAngles);
        maxangles = max(dAngles);
        angles_dev = std(dAngles);
        %avg_polar = mean(dpolarAngles);
        maxpolar = max(dpolarAngles);
        polar_dev = std(dpolarAngles);
        
        distanceBetweenPoints = length(currentPath)/distanceBetweenPoints;
    
        %performanceList = [segment std_dev_velocity std_dev_acceleration averagefluxness maxfluxness averagecurvature maxcurvature std_dev averageAngles maxangles angles_dev distanceBetweenPoints];
        performanceList = [averagecurvature maxangles angles_dev maxpolar polar_dev distanceBetweenPoints];
        performanceMatrix = [performanceMatrix; performanceList];
     end
     
     performance = [sum(performanceMatrix,1) ];


end


function [withinEachWayPoint, missingWaypoints] = findMissingWaypoints(wayPoints, R_switch,path)
    missingWaypoints = [];
    for point_idx=1:size(wayPoints,1)
        point = wayPoints(point_idx,:);
        distances = pdist2(point, path, 'euclidean');
        if all(distances > R_switch)
            missingWaypoints = [missingWaypoints; point];
        end
    end

    if isempty(missingWaypoints)
        withinEachWayPoint = true;
    else
        withinEachWayPoint = false;
    end
end