function info = analysisApproachInfo(name)
% Interpret families without renaming folders: IncWP-K2Means, FullWP_NP100, etc.
    name = string(name);
    info = struct('name',name,'isFullWP',~isempty(regexpi(char(name),'^Full(?:WP|[-_]?\d)','once')), ...
        'isIncremental',startsWith(lower(name),"incwp"),'isRandom',strcmpi(name,"RandomSearch"), ...
        'isKmeans',false,'branches',NaN,'populationSize',NaN);
    info.isKmeans = ~isempty(regexpi(char(name),'^(?:IncWP[-_])?K\d*[-_]?Means$','once'));
    if info.isKmeans
        info.isIncremental = true;
        info.branches = 3; % legacy IncWP_Kmeans
        token = regexpi(char(name),'^(?:IncWP[-_])?K(\d+)[-_]?Means$','tokens','once');
        if ~isempty(token), info.branches = str2double(token{1}); end
    end
    if info.isFullWP
        token = regexpi(char(name),'^Full(?:WP)?[-_]?(?:NP[-_]?)?(\d+)','tokens','once');
        if ~isempty(token), info.populationSize = str2double(token{1}); end
    end
end
