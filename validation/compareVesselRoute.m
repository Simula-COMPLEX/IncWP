function results = compareVesselRoute(vessel, waypoints, generation, individual, showResults)
    arguments
        vessel (1,1) string
        waypoints = []
        generation (1,1) double = 1
        individual (1,1) double = 1
        showResults (1,1) logical = true
    end
    root = fileparts(fileparts(mfilename('fullpath')));
    oldPath = path;
    restorePath = onCleanup(@() path(oldPath));
    addpath(genpath(fullfile(root,'frameworks','MSS')));
    addpath(fullfile(root,'frameworks','evolutionaryPlatform','BIMK-PlatEMO-4.7.0.0','PlatEMO','Problems'));
    addpath(fullfile(root,'scripts','vesselSearch','incrementalSearch','pathSimulation'));
    addpath(fullfile(root,'scripts','vesselSearch','globalSearch'));
    addpath(fullfile(root,'scripts','vesselSearch','helpers'));
    addpath(fullfile(root,'analysis','dataProcessing','TypesOfPaths'));
    addpath(fullfile(root,'scripts','vesselSearch','globalSearch','pathSimulation','withEarlyStopping'));
    switch vessel
        case "remus100"
            fullSimulator = @remus100pathWithEarlyStopping;
            subSimulator = @runSubPathRemus100;
            dimension = 3;
        case "nspauv"
            fullSimulator = @npsauvPathWithEarlyStopping;
            subSimulator = @runSubPathNspauv;
            dimension = 3;
        case "mariner"
            fullSimulator = @marinerPathWithEarlyStopping;
            subSimulator = @runSubPathMariner;
            dimension = 2;
        otherwise
            error('Unknown vessel: %s',vessel);
    end
    source = fullfile(root,'experimentsData',vessel,'FullWP-exNum1');
    if ~isfile(fullfile(source,'setupConfiguration.mat'))
        source = fullfile(root,'validation','comparisonInputs',vessel,'FullWP-exNum1');
    end
    setup = load(fullfile(source,'setupConfiguration.mat'),'parameter');
    environment = setup.parameter.enviromentRandom;
    radius = setup.parameter.shipInformation.R_switch;
    if isempty(waypoints)
        populationFile = string(setup.parameter.populationType)+"-population-g"+generation+".mat";
        saved = load(fullfile(source,populationFile),'Population');
        decisions = saved.Population.decs;
        waypoints = [zeros(1,dimension); reshape(decisions(individual,:),dimension,[])'];
    end
    assert(size(waypoints,2)==dimension && size(waypoints,1)>=2 && all(waypoints(1,:)==0), ...
        'Supply a route with %d columns including the origin as its first row.',dimension);
    wpt.pos.x = waypoints(:,1);
    wpt.pos.y = waypoints(:,2);
    if dimension==3, wpt.pos.z = waypoints(:,3); end
    if showResults
    fprintf('%s route comparison: generation %d, individual %d, %d segments.\n', ...
        vessel,generation,individual,size(waypoints,1)-1);
    fprintf('Full simulator: %s\n',which(func2str(fullSimulator)));
    fprintf('Subpath simulator: %s\n',which(func2str(subSimulator)));
    end
    tic;
    switches = [];
    if vessel == "mariner"
        [simdata, ~, switches] = fullSimulator(wpt,radius,environment);
        guidance = [];
    else
        [simdata, guidance] = fullSimulator(wpt,radius,environment);
    end
    fullSeconds = toc;
    [fullAngles, fullPath] = extractAnglesAndPath(simdata,guidance,vessel);
    clear simdata guidance
    count = size(waypoints,1)-1;
    [fullSegments, fullSegmentAngles, fullReached] = splitRecordedRoute(fullPath,fullAngles,waypoints,radius,vessel,environment,switches);
    incSegments = cell(count,1);
    incAngles = cell(count,1);
    incReached = NaN(count,1);
    incError = "";
    scratch = tempname;
    mkdir(scratch);
    cleanup = onCleanup(@() rmdir(scratch,'s'));
    prefix = string(fullfile(scratch,'WptIdx-'));
    tic;
    for k = 1:count
        pair.pos.x = waypoints(k:k+1,1);
        pair.pos.y = waypoints(k:k+1,2);
        if dimension==3, pair.pos.z = waypoints(k:k+1,3); end
        try
            [nextSample,reached,~,~,incSegments{k},incAngles{k}] = ...
                subSimulator(pair,k+1,radius,environment,1,1,prefix);
        catch exception
            incError = string(exception.identifier)+": "+string(exception.message);
            if showResults, fprintf('Incremental simulation error: %s\n',incError); end
            break;
        end
        incReached(k) = reached;
        if ~reached || nextSample > size(environment,2), break; end
    end
    incSeconds = toc;
    fullSamples = cellfun(@(x) size(x,1),fullSegments);
    incSamples = cellfun(@(x) size(x,1),incSegments);
    positionRMSE = NaN(count,1);
    signalRMSE = NaN(count,size(fullAngles,2));
    endpointDifference = NaN(count,1);
    fullPathLength = NaN(count,1);
    incPathLength = NaN(count,1);
    compared = false(count,1);
    reachabilityMatch = NaN(count,1);
    maxPositionError = NaN(count,1);
    maxAngleError = NaN(count,1);
    same = false(count,1);
    for k = 1:count
        if fullSamples(k)>0
            fullPathLength(k) = sum(sqrt(sum(diff(fullSegments{k},1,1).^2,2)));
        end
        if incSamples(k)>0
            incPathLength(k) = sum(sqrt(sum(diff(incSegments{k},1,1).^2,2)));
        end
        if isfinite(fullReached(k)) && isfinite(incReached(k))
            reachabilityMatch(k) = fullReached(k)==incReached(k);
        end
        rows = min(fullSamples(k),incSamples(k));
        if rows==0, continue; end
        delta = abs(fullSegments{k}(1:rows,:)-incSegments{k}(1:rows,:));
        maxPositionError(k) = max(delta(:));
        positionRMSE(k) = sqrt(mean(sum(delta.^2,2)));
        endpointDifference(k) = norm(fullSegments{k}(end,:)-incSegments{k}(end,:));
        deltaAngles = abs(fullSegmentAngles{k}(1:rows,:)-incAngles{k}(1:rows,:));
        maxAngleError(k) = max(deltaAngles(:));
        signalRMSE(k,:) = sqrt(mean(deltaAngles.^2,1));
        compared(k) = all(isfinite(delta(:))) && all(isfinite(deltaAngles(:)));
        reference = incSegments{k}(1:rows,:);
        angleReference = incAngles{k}(1:rows,:);
        same(k) = fullSamples(k)==incSamples(k) && fullReached(k)==incReached(k) && ...
            all(isfinite(delta(:))) && all(isfinite(deltaAngles(:))) && ...
            all(delta(:)<=1e-8+1e-8*abs(reference(:))) && ...
            all(deltaAngles(:)<=1e-8+1e-8*abs(angleReference(:)));
    end
    results.comparison = table((1:count)',fullReached,incReached,fullSamples,incSamples, ...
        maxPositionError,maxAngleError,same,'VariableNames', ...
        {'Segment','FullReached','IncReached','FullSamples','IncSamples', ...
        'MaxPositionDifference','MaxAngleDifference','Same'});
    results.comparison.Compared = compared;
    results.comparison.ReachabilityMatch = reachabilityMatch;
    results.comparison.PositionRMSE_m = positionRMSE;
    results.comparison.SignalRMSE = signalRMSE;
    results.comparison.EndpointDifference_m = endpointDifference;
    results.comparison.FullPathLength_m = fullPathLength;
    results.comparison.IncPathLength_m = incPathLength;
    results.comparison.PathLengthDifference_m = abs(fullPathLength-incPathLength);
    results.comparison.SampleCountDifference = fullSamples-incSamples;
    [results.fitness,segmentFitness] = calculateComparisonFitness( ...
        setup.parameter.shipInformation.initialPoints,waypoints,radius,fullPath, ...
        vertcat(incSegments{:}),fullSegments,incSegments,fullReached,incReached,incError);
    results.comparison = [results.comparison segmentFitness];
    [fullTypes,incTypes,typeMatches,classificationError] = comparePathTypes( ...
        fullSegmentAngles,incAngles,fullReached,incReached);
    results.comparison.FullPathType = fullTypes;
    results.comparison.IncPathType = incTypes;
    results.comparison.PathTypeMatch = typeMatches;
    results.classificationError = classificationError;
    results.vessel = vessel;
    results.waypoints = waypoints;
    results.generation = generation;
    results.individual = individual;
    results.source = source;
    results.incrementalError = incError;
    results.fullSeconds = fullSeconds;
    results.incrementalSeconds = incSeconds;
    results.allSame = all(same) && strlength(incError)==0;
    results.note = "Differences compare overlapping rows; equality also requires equal lengths and reachability. " + ...
        "Incremental timing includes state-file IO; full timing does not. Both stop after a failed segment. " + ...
        "This compares full-path output with early stopping against original subpath output, not archived trajectories.";
    results.note = results.note + " Position RMSE is RMS Euclidean separation over overlapping segment samples. " + ...
        "Signal RMSE is reported per channel: roll/pitch/yaw (rad) for AUVs; u/v (m/s), r (rad/s), psi/delta (rad) for Mariner. " + ...
        "Endpoint and path length differences use each entire segment. Unavailable comparisons have Compared=false.";
    results.verdict = summarizeRouteComparison(results);
    if ~showResults, return; end
    disp(results.verdict);
    if results.verdict.Verdict ~= "PASS"
        disp(results.comparison);
        disp(results.fitness);
        if strlength(incError)>0, fprintf('%s\n',incError); end
    end
    fprintf('PASS means agreement on this tested route within 1e-8 absolute + relative tolerance.\n');

end

function [segments, segmentAngles, reached] = splitRecordedRoute(path, angles, waypoints, radius, vessel, environment, switches)
    count = size(waypoints,1)-1;
    segments = cell(count,1);
    segmentAngles = cell(count,1);
    reached = NaN(count,1);
    first = 1;
    k = 1;
    history = [];
    switched = false(size(path,1),1);
    switched(switches) = true;
    for sample = 1:size(path,1)
        position = path(sample,:);
        if vessel == "mariner"
            position = position + 0.01*environment(2:3,sample)';
        end
        distance = norm(position-waypoints(k+1,:));
        if vessel == "mariner", arrived = distance < radius/2 || switched(sample);
        else, arrived = distance < radius; end
        diverged = false;
        if mod(sample,100)==0
            if numel(history)>10
                if vessel=="mariner", diverged = all(diff(history(end-10:end))>0);
                else, diverged = all(history(end-10:end)<distance); end
            end
            history(end+1,1) = distance;
        end
        if arrived || diverged || sample==size(path,1)
            reached(k) = arrived && ~diverged;
            segments{k} = path(first:sample,:);
            segmentAngles{k} = angles(first:sample,:);
            if ~reached(k) || k==count, break; end
            k = k+1;
            first = sample+1;
            history = [];
        end
    end
end
