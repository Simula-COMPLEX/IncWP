function files = analysisGenerationFiles(folder, waypoint)
% Read actual saved generations; do not infer evaluation budgets from names.
    if nargin < 2 || isempty(waypoint)
        files = dir(fullfile(folder,'*-population-g*.mat'));
        files = files(~startsWith(string({files.name}),"WptIdx-"));
    else
        files = dir(fullfile(folder,"WptIdx-"+string(waypoint)+"-population-g*.mat"));
    end
    generations = zeros(numel(files),1);
    for k = 1:numel(files)
        token = regexp(files(k).name,'-population-g(\d+)\.mat$','tokens','once');
        assert(~isempty(token),'Analysis:GenerationName','Invalid generation file: %s',files(k).name);
        generations(k) = str2double(token{1});
    end
    [generations, order] = sort(generations);
    files = files(order);
    assert(numel(unique(generations)) == numel(generations), ...
        'Analysis:DuplicateGeneration','Multiple population prefixes in %s.',folder);
    assert(isempty(generations) || isequal(generations(:)',1:max(generations)), ...
        'Analysis:MissingGeneration','Missing saved generations in %s.',folder);
end
