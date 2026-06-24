classdef incrementalWaypointProblem < PROBLEM
    properties
        minDistanceBetweenPoints
        initialPoints
        R_switch
        generation
        pointDimension
        pathsMap 
        vesselName
        startWpt
        startWptIndex
        endWpt
        endWptIndex
        enviromentRandom
        prevWptObjectiveScores
        iterationIndex
        vesselResultsPath
        missingPathLabel
        searchType
        timestampList
        initialTimestamp
        objectivesWithoutPrevList
    end
    methods
        function Setting(obj)
            obj.M = 2;
            obj.pathsMap = containers.Map();
        end

        function Population = Initialization(obj,N, parameters)
            % Store the waypoint transition that this incremental search solves.
            obj.initialTimestamp = tic;
            obj.timestampList = [];
            obj.objectivesWithoutPrevList = [];

            vesselInformation = parameters.vesselInformation;
            obj.vesselName = vesselInformation.shipName;
            obj.pointDimension = vesselInformation.pointDimension;
            obj.R_switch = vesselInformation.R_switch;
            obj.minDistanceBetweenPoints = obj.R_switch * 2 + 1;
            obj.startWpt = parameters.startWpt;
            obj.startWptIndex = parameters.startWptIndex;
            obj.endWpt = parameters.endWpt;
            obj.enviromentRandom = parameters.enviromentRandom;
            obj.endWptIndex = parameters.endWptIndex;
            obj.prevWptObjectiveScores = parameters.prevWptObjectiveScores;
            obj.vesselResultsPath = parameters.vesselResultsPath;
            obj.iterationIndex = parameters.iterationIndex;
            obj.searchType = "incrementalSearch";
            obj.generation = parameters.generation;

            obj.D = obj.pointDimension;
            obj.encoding = ones(obj.D,1);
            obj.missingPathLabel = zeros(1,obj.N);

            [lower, upper, PopDec] = generateWaypoint(obj);
            obj.lower = lower;
            obj.upper = upper;
            Population = obj.Evaluation(PopDec);
        end

        function PopObj = CalObj(obj, PopDec)
            % Simulate each candidate waypoint and evaluate the resulting segment.
            PopObj = zeros(obj.N,obj.M);
            tempTimestampList = [];
            obj.objectivesWithoutPrevList = zeros(obj.N,obj.M);
            for individualIndex = 1:size(PopDec,1)
                individual = PopDec(individualIndex,:);
                wpt.pos.x = [obj.startWpt(1); individual(1)];
                wpt.pos.y = [obj.startWpt(2); individual(2)];
                if obj.pointDimension == 3
                    wpt.pos.z = [obj.startWpt(3); individual(3)];
                end
                obj.iterationIndex = obj.iterationIndex + 1;

                [~, reachedWaypoint, ~, ~, subpath, angles] = runVesselSimulation(obj, wpt);
                paths = containers.Map();
                paths("angles") = angles;
                obj.pathsMap(string(obj.iterationIndex)) = paths;

                totalPathLength = 0;
                for i = 1:(size(subpath,1)-1)
                    totalPathLength = totalPathLength + pdist2(subpath(i,:),subpath(i+1,:),'euclidean');
                end
                totalPathLengthPenalized = totalPathLength/pdist2(obj.endWpt,obj.startWpt);
                distanceFromInitialWpt  = pdist2(obj.endWpt,individual,'euclidean');

                if reachedWaypoint == false
                    obj.missingPathLabel(individualIndex) = 1;
                    totalPathLengthPenalized = 999999999;
                end

                objectivesWithoutPrev = [-totalPathLengthPenalized distanceFromInitialWpt];
                obj.objectivesWithoutPrevList(individualIndex,:) = objectivesWithoutPrev;
                objectivesWithPrev = [obj.prevWptObjectiveScores; objectivesWithoutPrev];
                individualObjectives = [mean(objectivesWithPrev(:,1)) sum(objectivesWithPrev(:,2))];

                PopObj(individualIndex,:) = individualObjectives;
                tempTimestampList = [tempTimestampList; toc(obj.initialTimestamp)];
            end
            obj.timestampList = [obj.timestampList tempTimestampList];
        end

        function PopCon = CalCon(obj, PopDec)
            % Reject candidates that are too close to the previous waypoint.
            PopCon = ones(size(PopDec,1),1);
            for individualIndex = 1:size(PopDec,1)
                individual = PopDec(individualIndex,:);

                distanceFromLastPoint = pdist2(individual, obj.startWpt);
                validPoint = distanceFromLastPoint < obj.minDistanceBetweenPoints/2;
                PopCon(individualIndex) = validPoint;

                if obj.missingPathLabel(individualIndex) == true % true = bad, false = good
                    PopCon(individualIndex) = obj.missingPathLabel(individualIndex)*1;
                end
            end
        end

        function PopDec = CalDec(obj, PopDec)
            % Repair invalid candidates by resampling until they satisfy the distance constraint.
            for individualIndex = 1:size(PopDec,1)
                individual = PopDec(individualIndex,:);
                distanceFromLastPoint = pdist2(individual, obj.startWpt);
                validPoint = distanceFromLastPoint > obj.minDistanceBetweenPoints/2;
                while (validPoint == false)
                    individual = obj.lower + (obj.upper - obj.lower) .* rand(1, obj.D);
                    PopDec(individualIndex,:) = individual;
                end
            end
        end
    end
end
