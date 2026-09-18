classdef waypointsRemus100Problem < PROBLEM
    properties
        points
        minDistanceBetweenPoints
    end
    methods
        % Default settings of the problem
        function Setting(obj)

            obj.minDistanceBetweenPoints = 5*2+1;  
            obj.M = 5;                                     % Set number of objectives
            obj.D = 6*3;                                % Set number of decision variables
            obj.lower = ones(1,obj.D)*(-400); 
            obj.lower(13:end) = obj.lower(13:end)*0;
            obj.upper = ones(1,obj.D)*(2400);  
            obj.upper(13:end) = ones(1,6)*(150);
            obj.encoding = ones(obj.D,1); 

            
        end
        
        function Population = Initialization(obj,N)
            if nargin < 2
                N = obj.N;
            end
            PopDec = zeros(N, obj.D);
            xinitial = [0 -20 -100   0  200, 200  400];
            yinitial =  [0  200  600 950 1300 1800 2200];
            zinitial =  [0   10  100 100   50   50   50];
            InitalPoints = [xinitial(:,2:end) yinitial(:,2:end) zinitial(:,2:end)];

            obj.D = length(InitalPoints);
            PopDec =  InitalPoints.*ones(N,1);
            Population = obj.Evaluation(PopDec);

        end

        function PopObj = CalObj(obj, PopDec)
            R_switch = 5;

            PopObj = zeros(obj.N,obj.M);
            for individualIndex = 1:size(PopDec,1)
                individual = PopDec(individualIndex,:);
                numPoints = length(individual)/3
                wpt.pos.x = [0 individual(1:numPoints)]'
                wpt.pos.y = [0 individual((numPoints+1):(numPoints*2))]'
                wpt.pos.z = [0 individual((numPoints*2+1):end)]'
                waypoints = [wpt.pos.x wpt.pos.y wpt.pos.z];
                [simdata , ALOSdata, state] = remus100path(wpt, R_switch);

                time = simdata(:,1);        
                eta_mutated = simdata(:,18:23);
                x_mutated = eta_mutated(:,1);
                y_mutated = eta_mutated(:,2);
                z_mutated = eta_mutated(:,3);
                [average_distance, median_distance, max_distance, min_distance,withinEachWayPoint, missing_waypoints, validPoints, pointsOutsidePath] = evaluate(waypoints, R_switch, x_mutated, y_mutated, z_mutated);
                num_missing_waypoints = size(missing_waypoints,1);
                num_timesteps = size(simdata,1);
        
                %msi_max = max(msi(time,state))
                procetagePathDeviation = length(pointsOutsidePath)/num_timesteps;

                PopObj(individualIndex,1) = average_distance; % Objective 1
                PopObj(individualIndex,2) = max_distance;
                PopObj(individualIndex,3) = num_timesteps;
                PopObj(individualIndex,4) = length(pointsOutsidePath);
                PopObj(individualIndex,5) = num_missing_waypoints;

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

                PopCon(individualIndex) = obj.minDistanceBetweenPoints - min(distMatrix,[], "all");
                PopCon(individualIndex) = any(z < zeros(1,numPoints))
                    

                

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


                while (pointsToClose(selPoints, obj.minDistanceBetweenPoints) == true ||  all(any(selPoints(1:end-1,:) == selPoints(2:end,:),2)) || any(all(selPoints== [0 0 0],2)) || all(selPoints(:,3) < zeros(numPoints,1))  )

                    individual  = unifrnd(obj.lower,obj.upper,1,obj.D);
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

