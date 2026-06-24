classdef globalWaypointSearch < PROBLEM
    properties
        minDistanceBetweenPoints
        initialPoints
        initialPath
        R_switch
        generation
        pointDimension
        pathsMap
        shipName
        timestampList
        initialTimestamp
        searchType
        populationType
        pathMissingFlagsMatrix
        missingPathLabel
        subPathDistanceMatrix
        enviromentRandom
    end
    methods
        function Setting(obj)
            obj.M = 2;
            obj.generation = 1;
            obj.pathsMap = containers.Map();
        end

        function Population = Initialization(obj,N, parameters)
            % Store the static search configuration used by all individuals.
            obj.initialTimestamp = tic;
            obj.timestampList = [];

            obj.searchType = "fullPathSearch";
            obj.populationType = parameters.populationType;
            shipInformation = parameters.shipInformation;

            obj.shipName = shipInformation.shipName;
            obj.initialPoints = shipInformation.initialPoints;
            obj.pointDimension = shipInformation.pointDimension;
            obj.R_switch = shipInformation.R_switch;
            obj.minDistanceBetweenPoints = obj.R_switch * 2 + 1;
            obj.enviromentRandom = parameters.enviromentRandom;

            obj.D = length(obj.initialPoints);
            obj.encoding = ones(obj.D,1);

            [lower, upper, PopDec] = generateInitialPopulation(obj, obj.populationType);
            obj.lower = lower;
            obj.upper = upper;
            Population = obj.Evaluation(PopDec);
        end

        function PopObj = CalObj(obj, PopDec)
            % Simulate each full waypoint individual and collect path metrics.
            PopObj = zeros(obj.N,obj.M);
            obj.pathMissingFlagsMatrix = [];
            obj.subPathDistanceMatrix = [];
            obj.missingPathLabel = zeros(size(PopDec,1),1);
            for individualIndex = 1:size(PopDec,1)
                individual = PopDec(individualIndex, :);
                [fullpath, subPaths, transitionIndices, angles, numberOfPointsReached] = performSimulation(individual, obj);
                paths = containers.Map();
                paths("fullpath") = fullpath;
                paths("transitionIndices") = transitionIndices;
                paths("angles") = angles;
                obj.pathsMap(string(individualIndex)) = paths;

                [totalDistanceBetweenWaypoints, meanSubpathDistances, subPathDistances, pathMissingFlagsList] = evalauteWaypointsAndPath(obj.initialPoints, obj.initialPath, individual, fullpath, subPaths, transitionIndices, numberOfPointsReached);

                obj.pathMissingFlagsMatrix = [obj.pathMissingFlagsMatrix; pathMissingFlagsList];

                if sum(pathMissingFlagsList) > 0
                    obj.missingPathLabel(individualIndex) = 1;
                    meanSubpathDistances = 999999999;
                    subPathDistances = [subPathDistances; -meanSubpathDistances * ones(length(individual) / obj.pointDimension - length(subPathDistances), 1)];
                end

                obj.subPathDistanceMatrix = [obj.subPathDistanceMatrix subPathDistances];
                PopObj(individualIndex,:) = [-meanSubpathDistances totalDistanceBetweenWaypoints];
                obj.timestampList = [obj.timestampList; toc(obj.initialTimestamp)];
            end
        end

        function PopCon = CalCon(obj, PopDec)
            % Reject individuals with points too close together or invalid depth.
            PopCon = ones(size(PopDec,1),1);
            for individualIndex = 1:size(PopDec,1)
                individual = PopDec(individualIndex,:);

                numPoints = length(individual)/obj.pointDimension;
                pointsMatrix  =  reshape(individual, [obj.pointDimension, numPoints])';
       
                if obj.pointDimension == 2
                    PopCon(individualIndex) = round(obj.minDistanceBetweenPoints/2) > min(sqrt( diff(pointsMatrix(:,1)).^2 + diff(pointsMatrix(:,2)).^2));
                elseif obj.pointDimension == 3
                    PopCon(individualIndex) = round(obj.minDistanceBetweenPoints/2) > min(sqrt( diff(pointsMatrix(:,1)).^2 + diff(pointsMatrix(:,2)).^2 + diff(pointsMatrix(:,3)).^2));

                    z = pointsMatrix(:,3)';
                    PopCon(individualIndex) = PopCon(individualIndex) || any(z < zeros(1,numPoints));
                end

                if obj.missingPathLabel(individualIndex) == true % true = bad, false = good
                    PopCon(individualIndex) = obj.missingPathLabel(individualIndex)*1;
                end
            end
        end

        function PopDec = CalDec(obj, PopDec)
            % Repair invalid full-path individuals by resampling them.
            for individualIndex = 1:size(PopDec,1)
                individual = PopDec(individualIndex,:);
                numPoints = length(individual)/obj.pointDimension;

                pointsMatrix  =  reshape(individual, [obj.pointDimension, numPoints])';
                
                conditions = pointsToClose(pointsMatrix, obj.minDistanceBetweenPoints/2) == true ||  all(any(pointsMatrix(1:end-1,:) == pointsMatrix(2:end,:),2));
                if obj.pointDimension == 2
                    conditions = conditions || any(all(pointsMatrix== [0 0],2));

                elseif obj.pointDimension == 3
                    conditions =  conditions || any(all(pointsMatrix== [0 0 0],2)) || all(pointsMatrix(:,3) < zeros(numPoints,1));
                end

                while (conditions)
                    
                    individual = obj.lower + (obj.upper - obj.lower).*rand(1,obj.D);
                    pointsMatrix  =  reshape(individual, [obj.pointDimension, numPoints])';

                    conditions = pointsToClose(pointsMatrix, obj.minDistanceBetweenPoints/2) == true ||  all(any(pointsMatrix(1:end-1,:) == pointsMatrix(2:end,:),2));
                    if obj.pointDimension == 2
                        conditions = conditions || any(all(pointsMatrix== [0 0],2));
    
                    elseif obj.pointDimension == 3
                        conditions =  conditions || any(all(pointsMatrix== [0 0 0],2)) || all(pointsMatrix(:,3) < zeros(numPoints,1));
                    end
                end
                PopDec(individualIndex,:) = individual;
            end
        end
    end
end
