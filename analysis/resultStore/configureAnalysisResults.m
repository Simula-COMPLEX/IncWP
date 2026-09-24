function configureAnalysisResults(base, sourceFolder, timeLimitPolicy)
% Record the vessel input folder and policy; mark affected outputs outdated.
    timeLimitPolicy = validatestring(timeLimitPolicy,{'none','slowestIncremental','averageIncremental','perApproach'});
    sourceFolder = char(java.io.File(char(sourceFolder)).getCanonicalPath());
    analysisResultManifest(base,'configure',sourceFolder,timeLimitPolicy);
end
