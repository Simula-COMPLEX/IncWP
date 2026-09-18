%% Run experiments

projectRoot = fileparts(which("setupProject.m"));
resultsPath = fullfile(projectRoot, "experimentsData");

%approachType = "IncWP_KP";
%approachType = "IncWP_Rnd";
%approachType = "IncWP_Unst";
%approachType = "IncWP_Prox";
%approachType = "IncWP_Kmeans";
%approachType = "K2-Means";
%approachType = "K3-Means";
%approachType = "K5-Means";
%approachType = "RandomSearch";
approachType = "FullWP";

experimentNumber = 1;

vesselName = "mariner";
%vesselName = "nspauv";
%vesselName = "remus100";

populationSize = 10;
numGenerations = 1000;

if any(approachType == ["K2-Means", "K3-Means", "K5-Means"])
    numberOfClusters = str2double(extractBetween(approachType, "K", "-Means"));
    runIncWPKmeans(vesselName, resultsPath, experimentNumber, numGenerations, populationSize, numberOfClusters);
elseif approachType == "IncWP_Kmeans"
    runIncWPKmeans(vesselName, resultsPath, experimentNumber, numGenerations, populationSize);
elseif approachType == "RandomSearch"
    runRandomSearch(vesselName, resultsPath, experimentNumber, numGenerations, populationSize);
elseif approachType == "FullWP"
    runFullWP(vesselName, resultsPath, experimentNumber, numGenerations, populationSize);
else
    runIncWP(vesselName, approachType, resultsPath, experimentNumber, numGenerations, populationSize);
end
