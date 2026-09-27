function analysisPath = runAnalysis(vesselName, dataPath, timeLimitPolicy, usedSave)
    % Example: runAnalysis("mariner")
    % vesselName: "mariner", "remus100" or "nspauv".
    % dataPath: experiment root folder; defaults to experimentsData.
    % timeLimitPolicy: "slowestIncremental" (default), "averageIncremental",
    % "perApproach" or "none". Use [] for dataPath to keep its default.
    % Select experiment numbers in loadExperimentsStatus.m for each vessel.
    % usedSave: true (default) reuses saved analysis results;
    % false recalculates all analysis results.
    % Returns the analysis output folder. Each call runs the steps below.

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
    analysisPath = buildAnalysisPath(projectRoot, dataPath);

    baseResultsPath = fullfile(analysisPath, vesselName, 'AnalysedResults');
    configureAnalysisResults(baseResultsPath, fullfile(dataPath, vesselName), timeLimitPolicy);

    FullpathResultsIntoIncremental(vesselName, false, dataPath, usedSave);
    calculatePathForEachApproach(vesselName, dataPath, analysisPath, usedSave);
    calculateTimeUsageForEachApproach(vesselName, dataPath, analysisPath, usedSave);
    extractRawMetrics(vesselName, dataPath, analysisPath, usedSave);

    if timeLimitPolicy ~= "none"
        addTimeLimitedFullWP(vesselName, dataPath, analysisPath, timeLimitPolicy, usedSave);
    end

    manifest = analysisResultManifest(baseResultsPath,'read');
    datasets = "candidates";
    if timeLimitPolicy ~= "none", datasets(end+1) = "timeLimited"; end
    resultRevisions = {manifest.datasets(ismember(string({manifest.datasets.id}),datasets)).revision};
    combinedFile = fullfile(baseResultsPath,'combinedResults.mat');
    savedRevisions = struct();
    if usedSave && isfile(combinedFile)
        fields = who('-file',combinedFile);
        if ismember('resultRevisions',fields)
            savedRevisions = load(combinedFile,'resultRevisions');
        end
    end
    if ~isfield(savedRevisions,'resultRevisions') || ~isequal(savedRevisions.resultRevisions,resultRevisions)
        combinedResults = loadAnalysisResults(baseResultsPath,'candidates');
        combinedResults.resultRevisions = resultRevisions;
        save(combinedFile,'-struct','combinedResults');
    end

    calculateMetrics(vesselName, dataPath, analysisPath, usedSave);
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
