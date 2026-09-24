function analysisPath = runAnalysis(vesselName, dataPath, timeLimitPolicy)
    % Example: runAnalysis("mariner")
    % vesselName: "mariner", "remus100" or "nspauv".
    % dataPath: experiment root folder; defaults to experimentsData.
    % timeLimitPolicy: "slowestIncremental" (default), "averageIncremental",
    % "perApproach" or "none". Use [] for dataPath to keep its default.
    % Select experiment numbers in loadExperimentsStatus.m for each vessel.
    % Returns the analysis output folder. Each call runs the steps below.

    if nargin < 3
        timeLimitPolicy = "slowestIncremental";
    end
    timeLimitPolicy = string(validatestring(timeLimitPolicy, ...
        {'perApproach', 'slowestIncremental', 'averageIncremental', 'none'}));

    projectRoot = fileparts(fileparts(mfilename('fullpath')));
    if nargin < 2 || isempty(dataPath)
        dataPath = fullfile(projectRoot, "experimentsData");
    else
        dataPath = char(dataPath);
    end
    analysisPath = buildAnalysisPath(projectRoot, dataPath);

    baseResultsPath = fullfile(analysisPath, vesselName, 'AnalysedResults');
    configureAnalysisResults(baseResultsPath, fullfile(dataPath, vesselName), timeLimitPolicy);

    FullpathResultsIntoIncremental(vesselName, false, dataPath);
    calculatePathForEachApproach(vesselName, dataPath, analysisPath);
    calculateTimeUsageForEachApproach(vesselName, dataPath, analysisPath);
    extractRawMetrics(vesselName, dataPath, analysisPath);

    if timeLimitPolicy ~= "none"
        addTimeLimitedFullWP(vesselName, dataPath, analysisPath, timeLimitPolicy);
    end

    combinedResults = loadAnalysisResults(baseResultsPath,'candidates');
    save(fullfile(baseResultsPath,'combinedResults.mat'),'-struct','combinedResults');

    calculateMetrics(vesselName, dataPath, analysisPath);
    displayCalculatedMetricsRelevant(vesselName, analysisPath);
end

function analysisPath = buildAnalysisPath(projectRoot, dataPath)
    dataPath = char(dataPath);
    projectRoot = char(projectRoot);

    projectPrefix = [projectRoot filesep];
    if startsWith(dataPath, projectPrefix)
        relativeDataPath = extractAfter(string(dataPath), strlength(projectPrefix));
        analysisPath = fullfile(projectRoot, "analysisResults", char(relativeDataPath));
    else
        [~, dataFolderName] = fileparts(dataPath);
        analysisPath = fullfile(projectRoot, "analysisResults", dataFolderName);
    end
end
