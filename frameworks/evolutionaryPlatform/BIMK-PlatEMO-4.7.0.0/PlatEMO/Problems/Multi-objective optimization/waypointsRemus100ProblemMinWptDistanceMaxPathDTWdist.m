classdef waypointsRemus100ProblemMinWptDistanceMaxPathDTWdist < PROBLEM
    properties
        points
        minDistanceBetweenPoints
        %startPoint
        %endPoint
        validPath
        initialPoints 
        intialSegementDistnace
        initialPath
    end
    methods
        % Default settings of the problem
        function Setting(obj)

            obj.minDistanceBetweenPoints = 5*2+1;  
            obj.M = 3;                                     % Set number of objectives
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
            initialWaypointsMatrix = [xinitial' yinitial' zinitial']
            InitalPoints = [xinitial(:,2:end) yinitial(:,2:end) zinitial(:,2:end)];
            wpt.pos.x = xinitial';
            wpt.pos.y = yinitial';
            wpt.pos.z = zinitial';
            R_switch = 5;
            [simdata , ALOSdata, state] = remus100path(wpt, R_switch); 
            eta_mutated = simdata(:,18:23);
            x_mutated = eta_mutated(:,1);
            y_mutated = eta_mutated(:,2);
            z_mutated = eta_mutated(:,3);
            path = [x_mutated y_mutated z_mutated];

            obj.initialPoints = InitalPoints;
            obj.intialSegementDistnace = calculateSegmentLengths(initialWaypointsMatrix, R_switch,path);
            obj.initialPath = path;

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

                distanceBetweenPoints = diff(individual-obj.initialPoints);
                distanceBetweenPoints = sum(abs(distanceBetweenPoints));

                %segementDistance = calculateSegmentLengths(pointMatrix, R_switch,path);
                %segmenetDistanceDiff = segementDistance - obj.intialSegementDistnace;
                dtwDistance = calculateDTWdistance(obj.initialPath, path)


                %performance = waypointsRemus100ProblemMinWptDistanceMaxPathDist
                [withinEachWayPoint, missingWaypoints] = findMissingWaypoints(pointMatrix, R_switch, path);

                performance  = [-distanceBetweenPoints*0.1 dtwDistance -size(missingWaypoints,1)*10000]
                if size(missingWaypoints,1) ~= 0
                    obj.validPath(individualIndex) = 0;
                else
                    obj.validPath(individualIndex) = 1;
                end
                PopObj(individualIndex,:) = performance;

   

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


 function segementDistance = calculateSegmentLengths(waypointsMatrix, R_switch,path)
    [transitionIndices, pathSegments] = splitDataBetweenWaypoints(waypointsMatrix, R_switch,path);
     segementDistance = 0; 
     for segment = 1:length(pathSegments)
        startpoint = waypointsMatrix(segment,:);
        endPoint = waypointsMatrix(segment +1,:);
        %distanceBetweenPoints = sqrt(sum(startPoint - endPoint.^2))
        distanceBetweenPoints = pdist2(startpoint, endPoint, 'euclidean');
        
        currentPath = pathSegments{segment};
        distanceBetweenPointsPerLength = length(currentPath)/distanceBetweenPoints;
        
        segementDistance = segementDistance + distanceBetweenPointsPerLength;
     end

    
 end

 function totalPathDistanceDTW = calculateDTWdistance(intialPath, generatedPath)
    axisDistances = zeros(size(intialPath,2),1);
     for axis = 1:size(intialPath,2)
        axisDistances(axis) = dtw(intialPath(:,axis), generatedPath(:,axis));
     end
     totalPathDistanceDTW = sum(axisDistances);
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