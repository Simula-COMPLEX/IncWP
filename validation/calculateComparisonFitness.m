function [fitness, segmentFitness] = calculateComparisonFitness(initialPoints, waypoints, radius, fullPath, incPath, fullSegments, incSegments, fullReached, incReached, incError)
    dimension = size(waypoints,2);
    nominal = reshape(initialPoints,dimension,[])';
    count = size(waypoints,1)-1;
    assert(size(nominal,1)==count,'Fitness:RouteSize', ...
        'Fitness requires the same number of targets as the saved nominal route.');
    fullScores = segmentScores(fullSegments,fullReached,waypoints,nominal);
    incScores = segmentScores(incSegments,incReached,waypoints,nominal);
    segmentFitness = table(fullScores(:,1),incScores(:,1),abs(fullScores(:,1)-incScores(:,1)), ...
        fullScores(:,2),incScores(:,2),abs(fullScores(:,2)-incScores(:,2)), ...
        'VariableNames',{'FullInstabilityFitness','IncInstabilityFitness','InstabilityFitnessDifference', ...
        'FullProximityFitness','IncProximityFitness','ProximityFitnessDifference'});
    full = NaN(2,2);
    inc = NaN(2,2);
    full(1,:) = [mean(fullScores(:,1)),sum(fullScores(:,2))];
    inc(1,:) = [mean(incScores(:,1)),sum(incScores(:,2))];
    errors = strings(2,1);
    try
        full(2,:) = fullFitness(initialPoints,waypoints,radius,fullPath);
    catch exception
        errors(2) = "Full simulation: "+string(exception.message);
    end
    if strlength(incError)==0
        try
            inc(2,:) = fullFitness(initialPoints,waypoints,radius,incPath);
        catch exception
            errors(2) = errors(2)+" Incremental simulation: "+string(exception.message);
        end
    else
        inc(:,:) = NaN;
        errors(:) = errors(:)+" Incremental simulation incomplete: "+incError;
    end
    comparable = all(isfinite(full),2) & all(isfinite(inc),2);
    matches = NaN(2,1);
    matches(comparable) = all(abs(full(comparable,:)-inc(comparable,:)) <= ...
        1e-8+1e-8*abs(inc(comparable,:)),2);
    fitness = table(["IncWP";"FullWP"],full(:,1),inc(:,1),abs(full(:,1)-inc(:,1)), ...
        full(:,2),inc(:,2),abs(full(:,2)-inc(:,2)),comparable,matches,errors, ...
        'VariableNames',{'Formula','FullInstabilityFitness','IncInstabilityFitness', ...
        'InstabilityFitnessDifference','FullProximityFitness','IncProximityFitness', ...
        'ProximityFitnessDifference','Comparable','FitnessMatch','Error'});
end

function scores = segmentScores(segments,reached,waypoints,nominal)
    scores = NaN(numel(segments),2);
    for k = 1:numel(segments)
        if isnan(reached(k)) || isempty(segments{k}), continue; end
        lengthOfPath = 0;
        for j = 1:size(segments{k},1)-1
            lengthOfPath = lengthOfPath+pdist2(segments{k}(j,:),segments{k}(j+1,:),'euclidean');
        end
        instability = lengthOfPath/pdist2(nominal(k,:),waypoints(k,:),'euclidean');
        if ~reached(k), instability = 999999999; end
        scores(k,:) = [-instability,pdist2(nominal(k,:),waypoints(k+1,:),'euclidean')];
    end
end

function objectives = fullFitness(initialPoints,waypoints,radius,path)
    if isempty(path), objectives = [NaN NaN]; return; end
    decisions = reshape(waypoints(2:end,:)',1,[]);
    [transitions,subpaths,reached] = splitDataBetweenWaypoints(waypoints(2:end,:),radius,path);
    [proximity,instability,~,missing] = evalauteWaypointsAndPath( ...
        initialPoints,[],decisions,path,subpaths,transitions,reached);
    if any(missing), instability = 999999999; end
    objectives = [-instability,proximity];
end
