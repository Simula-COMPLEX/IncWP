classdef waypointMarinerProblem < PROBLEM
    properties
        points
        minDistanceBetweenPoints
    end
    methods
        % Default settings of the problem
        function Setting(obj)
            %obj.M = 2;
            %if isempty(obj.D); obj.D = 30; end
            %obj.lower    = zeros(1,obj.D);
            %obj.upper    = ones(1,obj.D);
            %obj.encoding = ones(1,obj.D);

            %x = [0 2000 5000 3000 6000 10000]';
            %y = [0 0 5000  8000 12000 12000]';
            %obj.points = [0 2000 5000 3000 6000 10000  0 0 5000  8000 12000 12000]; 
            obj.minDistanceBetweenPoints = 1001;  
            obj.M = 5;                                     % Set number of objectives
            obj.D = 10; %length(obj.points);                    % Set number of decision variables
            obj.lower = ones(1,obj.D)*(-12000); % [0,0,0,0,0,0,0,0,0,0]; % Lower bound of the decision variables
            obj.upper = ones(1,obj.D)*(12000);  %[1,1,1,1,1,1,1,1,1,1]; % Upper bound of the decision variables
            obj.encoding = ones(obj.D,1); %'real'; %ones(1,obj.D); %'real'; % Encoding method
            %Pop = obj.Initialization(1)
            
        end

        function Population = Initialization(obj,N)
        %    if nargin < 2
        %        N = obj.N;
        %    end
            %if ~isempty(obj.initFcn)
            %    Population = obj.Evaluation(CallFcn(obj.initFcn,N,obj.data,'initialization function',[N obj.D]));
            %else
            %    Population = Initialization@PROBLEM(obj,N);
            %end
            %pointList = [0 2000 5000 3000 6000 10000  0 0 5000  8000 12000 12000]
            %Population.objs = obj
            %Population.cons = 3

            %obj.optimum = max(Population.objs,[],1);
            if nargin < 2
                N = obj.N;
            end
            PopDec = zeros(N, obj.D);
            xinitial = [0 2000 5000 3000 6000 10000];
            yinitial = [0 0 5000  8000 12000 12000];
            %InitalPoints = [0 2000 5000 3000 6000 10000  0 0 5000  8000 12000 12000];
            InitalPoints = [xinitial(:,2:end) yinitial(:,2:end)];
            obj.D = length(InitalPoints);
            %PopDec(:) = [0 2000 5000 3000 6000 10000  0 0 5000  8000 12000 12000];
            PopDec =  InitalPoints.*ones(N,1);

            
            Population = obj.Evaluation(PopDec);

            % Dec, Obj, Con are matrices, where each row denotes a solution
            % and each column denotes a dimension of the variables,
            % objectives, constraints 


        end
        %function PopDec = 
        function PopObj = CalObj(obj, PopDec)
            R_switch = 500;
            Delta_h = 500;

            PopObj = zeros(obj.N,obj.M);
            for individualIndex = 1:size(PopDec,1)
                individual = PopDec(individualIndex,:);
                numPoints = length(individual)/2;
                wpt.pos.x = [0 individual(1:numPoints)]';
                wpt.pos.y = [0 individual((numPoints+1):end)]';
                waypoints = [wpt.pos.x wpt.pos.y];
                [simdata, state] = marinerPath(wpt, Delta_h, R_switch);
                if isempty(simdata)
                    wpt
                    waypoints
                    [simdata, state] = marinerPath(wpt, Delta_h, R_switch)
                    simdata
                end


                time = simdata(:,1);        
                x_mutated = simdata(:,5);
                y_mutated = simdata(:,6);
                [average_distance, median_distance, max_distance, min_distance,withinEachWayPoint, missing_waypoints, validPoints, pointsOutsidePath] = evaluate(waypoints, R_switch, x_mutated, y_mutated);
                num_missing_waypoints = size(missing_waypoints,1);
                num_timesteps = size(simdata,1);
                procetagePathDeviation = length(pointsOutsidePath)/num_timesteps;
                
                if validPoints == true
                    PopObj(individualIndex,1) = average_distance; % Objective 1
                    if isempty(max_distance)
                        %isequal(size(max_distance), [0 1])
                        max_distance
                    end
                    PopObj(individualIndex,2) = max_distance;
                    PopObj(individualIndex,3) = num_timesteps;
                    PopObj(individualIndex,4) = length(pointsOutsidePath);
                    PopObj(individualIndex,5) = num_missing_waypoints;
                else
                    validPoints
                end


            end 
        end

        function PopCon = CalCon(obj, PopDec)
            % Calculate the matrix of distances between selected points
            %selPoints = obj.points(selected, :);
            PopCon = ones(size(PopDec,1),1);
            for individualIndex = 1:size(PopDec,1)
                individual = PopDec(individualIndex,:);
                numPoints = length(individual)/2;
                x = individual(1:numPoints);
                y = individual((numPoints+1):end); 
                selPoints = [x' y'];

                distMatrix = pdist2(selPoints, selPoints);
                diagInd = 1:size(distMatrix, 1);
                distMatrix(diagInd, diagInd) = inf;

                PopCon(individualIndex) = obj.minDistanceBetweenPoints - min(distMatrix,[], "all");


            end


 
        end
        function PopDec = CalDec(obj, PopDec)
            % calDec - Repair multiple invalid solutions
            for individualIndex = 1:size(PopDec,1)
                individual = PopDec(individualIndex,:);
                numPoints = length(individual)/2;
                x = individual(1:numPoints);
                y = individual((numPoints+1):end); 
                selPoints = [x' y'];

                numel(unique(sort(selPoints),"rows")) < numel(selPoints);

                all(any(selPoints(1:end-1,:) == selPoints(2:end,:),2));
                numel(unique(sort(selPoints),"rows")) < numel(selPoints);
                any(all(selPoints== [0 0],2));
                while (pointsToClose(selPoints, obj.minDistanceBetweenPoints) == true ||  all(any(selPoints(1:end-1,:) == selPoints(2:end,:),2)) || any(all(selPoints== [0 0],2)) )
                    % if distance is less than R_switch, to points are
                    % equal to each other or zero 

                    individual  = unifrnd(obj.lower,obj.upper,1,obj.D);
                    x = individual(1:numPoints);
                    y = individual((numPoints+1):end); 
                    selPoints = [x' y'];
                    %PopDec(individualIndex,:) = obj.points

                end
                PopDec(individualIndex,:) = individual;

                %distMatrix = pdist2(selPoints, selPoints);
                %diagInd = 1:size(distMatrix, 1);
                %distMatrix(diagInd, diagInd) = inf;

                %PopCon(individualIndex) = obj.minDistanceBetweenPoints - min(distMatrix,[], "all");
                    

            end
            %PopDec = PopDec
        end
        
    end
end

function validation = pointsToClose(ListOfpoints, minDistance)
    numPoints = size(ListOfpoints,1);
    pointDistances = zeros(1, numPoints);
    pointDistances(1) = pdist2([0 0],ListOfpoints(1,:));
    for pointIdx = 2:numPoints
        pointDistances(pointIdx) = pdist2(ListOfpoints(pointIdx-1,:),ListOfpoints(pointIdx,:));
    end

    if (any(pointDistances < minDistance))
        validation =  true; 
    else
        validation =  false;
    end

end


