function markAnalysisResultsOutdated(base,dataset,reason)
% Explicitly invalidate a dataset and its dependents after a manual change.
    if nargin<3, reason = 'Manually marked outdated.'; end
    analysisResultManifest(base,'invalidate',analysisDatasetName(dataset),reason);
end
