function [Dec,Obj,Con] = runFullWP(vessel, resultsPath, experimentNumber, numGenerations, populationSize)
    % Run the full waypoint baseline and save the search setup.
    algorithm = @WPgen;
    parameter.populationType = "Comb";
    searchName = "FullWP";

    % Use the full evaluation budget in one global waypoint search.
    MaxEvaluation = populationSize * numGenerations;

    vesselResultsPath = append(resultsPath, "/", vessel, "/", searchName, "-exNum", string(experimentNumber), "/");
    parameter.shipResultsPath = vesselResultsPath;

    % The full-path baseline uses the global waypoint problem.
    problem = @globalWaypointSearch;
    parameter.shipInformation = loadShipSearchParameters(vessel);
    parameter.vesselResultsPath = vesselResultsPath;

    numberOfSamples = parameter.shipInformation.numberOfSamples;
    numberOfRandomEnviromentVariables = parameter.shipInformation.numberOfRandomEnviromentVariables;
    enviromentRandom = randn([numberOfRandomEnviromentVariables, numberOfSamples + 1]);
    parameter.enviromentRandom = enviromentRandom;

    % Run the search and store the setup used to reproduce it later.
    [Dec,Obj,Con] = platemo('algorithm', algorithm, 'problem', problem, 'N', populationSize, 'maxFE', MaxEvaluation, 'save', 0, 'run', 1, 'parameter', parameter);
    save(append(vesselResultsPath, "setupConfiguration"), "parameter");
end
