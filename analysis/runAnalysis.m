function analysisPath = runAnalysis(vesselName, dataPath, timeLimitPolicy, usedSave, makePlots)
    % Example: runAnalysis("mariner")
    % vesselName: "mariner", "remus100" or "nspauv".
    % dataPath: experiment root folder; defaults to experimentsData.
    % timeLimitPolicy: "slowestIncremental" (default), "averageIncremental",
    % "perApproach" or "none". Use [] for dataPath to keep its default.
    % Select experiment numbers in loadExperimentsStatus.m for each vessel.
    % usedSave: true (default) reuses saved analysis results;
    % false recalculates all analysis results; use after changing calculation code.
    % makePlots: false (default) skips plotting; true generates the enabled plots.
    % Returns the analysis output folder. Each call runs the steps below.

    if nargin < 5
        makePlots = false;
    end
    if nargin < 4
        usedSave = true;
    end
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
    analysisPath = fullfile(projectRoot, "analysisResults");

    baseResultsPath = fullfile(analysisPath, vesselName, 'AnalysedResults');

    FullpathResultsIntoIncremental(vesselName, false, dataPath, usedSave);
    calculatePathForEachApproach(vesselName, dataPath, analysisPath, usedSave);
    calculateTimeUsageForEachApproach(vesselName, dataPath, analysisPath, usedSave);
    extractRawMetrics(vesselName, dataPath, analysisPath, usedSave);

    if timeLimitPolicy ~= "none"
        addTimeLimitedFullWP(vesselName, dataPath, analysisPath, timeLimitPolicy, usedSave);
    end

    combinedFile = fullfile(baseResultsPath,'combinedResults.mat');
    if ~usedSave || ~isfile(combinedFile)
        combinedResults = loadAnalysisResults(baseResultsPath,'candidates', ...
            'IncludeTimeLimited',timeLimitPolicy ~= "none");
        save(combinedFile,'-struct','combinedResults');
    end

    calculateMetrics(vesselName, dataPath, analysisPath, usedSave);
    if makePlots
        displayCalculatedMetricsRelevant(vesselName, analysisPath);
    end
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
