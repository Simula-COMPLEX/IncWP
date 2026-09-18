classdef waypointMarinerProblem < PROBLEM
    properties
        points
        minDist = 1001 
    end
    methods
        function obj = waypointMarinerProblem()
            x = [0 2000 5000 3000 6000 10000]';
            y = [0 0 5000  8000 12000 12000]';
            
            obj = [x y]; 
            obj.Global.M = 5;                                     % Set number of objectives
            obj.Global.D = length(obj.points);                    % Set number of decision variables
            obj.Global.lower = ones(length(obj.point),1)*(-120000); % [0,0,0,0,0,0,0,0,0,0]; % Lower bound of the decision variables
            obj.Global.upper = ones(length(obj.point),1)*(120000);  %[1,1,1,1,1,1,1,1,1,1]; % Upper bound of the decision variables
            obj.Global.encoding = 'real'; % Encoding method
        end
        function PopObj = CalObj(obj, PopDec)

            R_switch = 500;
            Delta_h = 500;
            [simdata, state] = marinerPath(PopDec, Delta_h, R_switch);


            wayPointsMatrix = [wayPoints.pos.x wayPoints.pos.y];
            time = simdata(:,1);        
            x_mutated = simdata(:,5);
            y_mutated = simdata(:,6);
            [average_distance, median_distance, max_distance, min_distance,withinEachWayPoint, missing_waypoints, validPoints, pointsOutsidePath] = evaluate(wayPointsMatrix, R_switch, x_mutated, y_mutated);
            num_missing_waypoints = size(missing_waypoints,1);
            num_timesteps = size(simdata,1);
            % procetagePathDeviation = length(pointsOutsidePath)/num_timesteps;


            % This function calculates the objective values
            % You can define your own multi-objective function here
            PopObj(:,1) = average_distance; % Objective 1
            PopObj(:,2) = max_distance;
            PopObj(:,3) = num_missing_waypoints;
            PopObj(:,4) = num_timesteps;
            PopObj(:,5) = pointsOutsidePath;
        end
        function PopCon = CalCon(obj, PopDec)
            % Calculate the matrix of distances between selected points
            %selPoints = obj.points(selected, :);
            selPoints = PopDec;
            distMatrix = pdist2(selPoints, selPoints);

            % The constraint is violated if any distance is less than the minimum
            % We set the diagonal to infinity to ignore the zero distances of points to themselves
            diagInd = 1:size(distMatrix, 1);
            distMatrix(diagInd, diagInd) = inf;
            
            % Calculate constraint violations
            PopCon = obj.minDist - min(distMatrix);
        end

    end
    end

