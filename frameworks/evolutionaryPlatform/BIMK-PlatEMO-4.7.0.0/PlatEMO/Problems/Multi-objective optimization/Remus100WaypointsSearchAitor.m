classdef Remus100WaypointsSearch < PROBLEM
    properties
        minDistanceBetweenPoints
        validPath
        initialPoints 
        intialSegementDistance
        initialPath
        R_switch = 5
        generation
        path
        pointDimension
        pathsMap
    end
    methods
        % Default settings of the problem
        function Setting(obj)

            obj.minDistanceBetweenPoints = obj.R_switch*2+1;  
            obj.M = 2;                                     % Set number of objectives
            obj.D = 6*3;                                   % Set number of decision variables

            obj.encoding = ones(obj.D,1);
            obj.generation = 1;
            obj.pointDimension = 3;
            obj.pathsMap = containers.Map(); % container to save all the paths for one generation 

        end
        
        function Population = Initialization(obj,N)
            if nargin < 2
                N = obj.N;
            else
                obj.N = N;
            end
            
            [obj, PopDec] =  generateInitialPopulation(obj);
            Population = obj.Evaluation(PopDec);
            
        end

        function PopObj = CalObj(obj, PopDec)
            PopObj = zeros(obj.N,obj.M);
            for individualIndex = 1:size(PopDec,1)
                
                individual = PopDec(individualIndex,:);
                [fullpath, subPaths, transitionIndices] = performSimulation(individual, obj);
                obj.pathsMap(string(individualIndex)) = fullpath;
                [totalDistanceBetweenWaypoints, subPathLength] = evalauteWaypointsAndPath(obj.initialPoints, obj.initialPath, individual, fullpath, subPaths, transitionIndices);
                PopObj(individualIndex,:) = [-subPathLength totalDistanceBetweenWaypoints];
 
            end 
        end

        function PopCon = CalCon(obj, PopDec)
            PopCon = ones(size(PopDec,1),1);
            for individualIndex = 1:size(PopDec,1)
                individual = PopDec(individualIndex,:);
                numPoints = length(individual)/3;
                x = individual(1:numPoints);
                y = individual((numPoints+1):(numPoints*2)); 
                z = individual((2*numPoints+1):end);
                selPoints = [x' y' z'];

                PopCon(individualIndex) = round(obj.minDistanceBetweenPoints/2) < min(sqrt( diff(selPoints(:,1)).^2 + diff(selPoints(:,2)).^2 + diff(selPoints(:,3)).^2));
                PopCon(individualIndex) = PopCon(individualIndex) && any(z < zeros(1,numPoints));

                   
            end



        end
        function PopDec = CalDec(obj, PopDec)
            % calDec - Repair multiple invalid solutions
            for individualIndex = 1:size(PopDec,1)
                individual = PopDec(individualIndex,:);
                numPoints = length(individual)/3;
                x = individual(1:numPoints);
                y = individual((numPoints+1):(numPoints*2)); 
                z = individual((2*numPoints+1):end);
                selPoints = [x' y' z'];


                while (pointsToClose(selPoints, obj.minDistanceBetweenPoints) == true ||  all(any(selPoints(1:end-1,:) == selPoints(2:end,:),2)) || any(all(selPoints== [0 0 0],2)) || all(selPoints(:,3) < zeros(numPoints,1))) % && (obj.validPath(individualIndex) ~= 1))
                    individual = obj.lower + (obj.upper - obj.lower).*rand(1,obj.D);
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



  function totalSubpathDistances  = calculateSegmentLengths(transitionIndices, fullpath)
    
    transitionIndices = [1; transitionIndices]; %% at 1 size the inital point = [0 0 0]
    subPathDistances = zeros(length(transitionIndices)-1,1);
    for pointIndex = 1:length(transitionIndices)-1
        startPoint = fullpath(transitionIndices(pointIndex),:);
        endPoint = fullpath(transitionIndices(pointIndex+1),:);
        subpathLength = transitionIndices(pointIndex+1) - transitionIndices(pointIndex);
        pointDistance = pdist2(startPoint,endPoint);

        subPathDistances(pointIndex) = subpathLength/pointDistance;
    end
    totalSubpathDistances = sum(subPathDistances);

 end

function [totalDistanceBetweenWaypoints, totalSubpathDistances] = evalauteWaypointsAndPath(initialPoints, intialPath, newPoints, fullpath, subPaths, transitionIndices)
    
    numPoints = length(initialPoints)/3; 
    xInitial = [0 initialPoints(1:numPoints)]';
    yInitial = [0 initialPoints((numPoints+1):(numPoints*2))]'; 
    zInitial = [0 initialPoints((numPoints*2+1):end)]'; 
    xNew = [0 newPoints(1:numPoints)]';
    yNew = [0 newPoints((numPoints+1):(numPoints*2))]'; 
    zNew = [0 newPoints((numPoints*2+1):end)]'; 
    initialPointsMatrix = [xInitial yInitial zInitial];
    newPointsMatrix = [xNew yNew zNew];


    distanceBetweenWaypoints  = zeros(size(newPointsMatrix,1),1);
    for pointIndex = 1:size(newPointsMatrix,1)
        distanceBetweenWaypoints(pointIndex) = pdist2(initialPointsMatrix(pointIndex,:), newPointsMatrix(pointIndex,:),'euclidean');
    end
    totalDistanceBetweenWaypoints = abs(sum(distanceBetweenWaypoints));
    
    transitionIndices = [1; transitionIndices]; 
    subPathDistances = zeros(length(transitionIndices)-1,1);
    for pointIndex = 1:length(transitionIndices)-1
        startPoint = fullpath(transitionIndices(pointIndex),:);
        endPoint = fullpath(transitionIndices(pointIndex+1),:);
        
        subpathLength = transitionIndices(pointIndex+1) - transitionIndices(pointIndex);
        pointDistance = pdist2(startPoint,endPoint);

        subPathDistances(pointIndex) = subpathLength/pointDistance;
    end
    totalSubpathDistances = sum(subPathDistances);

    
end


function [fullpath, subPaths, transitionIndices] = performSimulation(listOfPoints, obj)

     numPoints = length(listOfPoints)/3;
     wpt.pos.x = [0 listOfPoints(1:numPoints)]';
     wpt.pos.y = [0 listOfPoints((numPoints+1):(numPoints*2))]';
     wpt.pos.z = [0 listOfPoints((numPoints*2+1):end)]';
     pointMatrix = [wpt.pos.x wpt.pos.y wpt.pos.z];
     [simdata , ~, ~] = remus100path(wpt, obj.R_switch);      
     eta_mutated = simdata(:,18:23);
     x_mutated = eta_mutated(:,1);
     y_mutated = eta_mutated(:,2);
     z_mutated = eta_mutated(:,3);
     fullpath = [x_mutated y_mutated z_mutated];


     [transitionIndices, subPaths] = splitDataBetweenWaypoints(pointMatrix, obj.R_switch,fullpath);
end


function [obj, PopDec] =  generateInitialPopulation(obj)
    xinitial =  [0  -20 -100   0  200, 200  400];
    yinitial =  [0  200  600 950 1300 1800 2200];
    zinitial =  [0   10  100 100   50   50   50];
    InitalPoints = [xinitial(:,2:end) yinitial(:,2:end) zinitial(:,2:end)];

    [fullpath, subPaths, transitionIndices] = performSimulation(InitalPoints, obj);
    obj.pathsMap('0') = fullpath;

    obj.initialPoints = InitalPoints;
    obj.initialPath = fullpath; 
    obj.intialSegementDistance =calculateSegmentLengths(transitionIndices, fullpath);
    obj.lower = InitalPoints - ones(size(InitalPoints))*150;
    obj.lower(13:end) = obj.lower(13:end)*0;
    obj.upper = InitalPoints + ones(size(InitalPoints))*150;
    obj.D = length(InitalPoints);
    obj.validPath = ones(obj.N, 1);

    
    randomPopulation = randomizePopulation(obj.N-1,obj.D, obj.minDistanceBetweenPoints, obj.lower, obj.upper, 3);
    strategyAitor = true;
    if strategyAitor 
        randomPopulation = seedPopulation(obj.N-1,obj.D, obj.minDistanceBetweenPoints, obj.lower, obj.upper, 3, InitalPoints);
    end
    PopDec = [obj.initialPoints; randomPopulation];
    
end

