function runAnalysis(vesselName, dataPath)

    projectRoot = fileparts(which("setupProject.m"));
    if nargin < 2 || isempty(dataPath)
        dataPath = fullfile(projectRoot, "experimentsData");
    else
        dataPath = char(dataPath);
    end

    analysisPath = buildAnalysisPath(projectRoot, dataPath);

    calculatePathForEachApproach(vesselName, dataPath, analysisPath);
    calculateTimeUsageForEachApproach(vesselName, dataPath, analysisPath);
    extractRawMetrics(vesselName, dataPath, analysisPath);
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
