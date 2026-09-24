function name = analysisDatasetName(name)
% Accept public dataset names and old MAT filenames during migration.
    name = string(name);
    switch lower(erase(name,'.mat'))
        case {'classification','classificationresults'}, name = "classification";
        case {'timing','timeusageresults'}, name = "timing";
        case {'candidates','combined','combinedresults'}, name = "candidates";
        case {'metrics','finalresults'}, name = "metrics";
        case 'timelimited', name = "timeLimited";
        case 'reports', name = "reports";
        case 'all', name = "all";
        otherwise, error('Analysis:Dataset','Unknown dataset: %s',name);
    end
end
