function displayVesselComparison(results, generation, individual)
    if nargin == 1
        displayOverview(results);
        return;
    end
    assert(nargin==3,'Use displayVesselComparison(results, generation, individual).');
    selected = results.routes.Generation==generation & results.routes.Individual==individual;
    assert(any(selected),'No results for this generation and individual.');
    results.routes = results.routes(selected,:);
    fprintf('\n%s: full-path versus incremental simulation\n',upper(results.vessel));
    fprintf('Waypoint 1 is the origin. Numerical equality uses 1e-8 absolute + relative tolerance.\n');
    for r = 1:height(results.routes)
        route = results.routes(r,:);
        fprintf('\nGeneration %d, individual %d\n',route.Generation,route.Individual);
        if strlength(route.Error)>0, fprintf('  Error: %s\n',route.Error); end
        if isempty(results.segments)
            fprintf('  No segment comparisons available.\n');
            continue;
        end
        selected = results.segments.Generation==route.Generation & ...
            results.segments.Individual==route.Individual;
        segments = results.segments(selected,:);
        if isempty(segments)
            fprintf('  No segment comparisons available.\n');
            continue;
        end
        available = isfinite(segments.PathTypeMatch);
        fprintf('  Path type: %d/%d match; %d unavailable.\n', ...
            sum(segments.PathTypeMatch==1),sum(available),sum(~available));
        first = find(~segments.Same & (segments.FullSamples>0 | segments.IncSamples>0),1);
        if ~isempty(first)
            fprintf('  First nonmatching or unavailable trajectory: segment %d (waypoint %d -> %d).\n', ...
                segments.Segment(first),segments.Segment(first),segments.Segment(first)+1);
        end
        fprintf('  %-10s %-15s %-15s %-12s %-12s\n','Waypoints','Full type','Inc type','Type match','Trajectory');
        for k = 1:height(segments)
            typeMatch = matchText(segments.PathTypeMatch(k));
            trajectory = "unavailable";
            if segments.Compared(k), trajectory = matchText(double(segments.Same(k))); end
            if xor(segments.FullSamples(k)>0,segments.IncSamples(k)>0), trajectory = "different"; end
            fprintf('  %-10s %-15s %-15s %-12s %-12s\n', ...
                string(segments.Segment(k))+" -> "+string(segments.Segment(k)+1), ...
                segments.FullPathType(k),segments.IncPathType(k),typeMatch,trajectory);
        end
        fprintf('  Reached targets: full %d, incremental %d (of %d).\n', ...
            sum(segments.FullReached==1),sum(segments.IncReached==1),height(segments));
        if ~isempty(results.fitness)
            selected = results.fitness.Generation==route.Generation & results.fitness.Individual==route.Individual;
            fitness = results.fitness(selected,:);
            for k = 1:height(fitness)
                fprintf('  Fitness using %s formula: %s\n',fitness.Formula(k),matchText(fitness.FitnessMatch(k)));
                fprintf('    Full: instability %.8g, proximity %.8g\n', ...
                    fitness.FullInstabilityFitness(k),fitness.FullProximityFitness(k));
                fprintf('    Inc:  instability %.8g, proximity %.8g\n', ...
                    fitness.IncInstabilityFitness(k),fitness.IncProximityFitness(k));
                if strlength(fitness.Error(k))>0, fprintf('    %s\n',fitness.Error(k)); end
            end
        end
    end
    routes = results.routes;
    fprintf('\nSummary: %d tested; %d fully matching; %d different; %d incomplete; %d errors.\n', ...
        height(routes),sum(routes.Verdict=="PASS"),sum(routes.Verdict=="FAIL"), ...
        sum(routes.Verdict=="INCOMPLETE"),sum(routes.Verdict=="ERROR"));
    fprintf('missing = target not reached; not simulated = segment not attempted.\n');
    fprintf('NaN fitness = unavailable, not a matching value. No simulations were run by this display function.\n');
end

function displayOverview(results)
    routes = results.routes;
    fprintf('\n%s: %d/%d individuals fully match\n',upper(results.vessel), ...
        sum(routes.Verdict=="PASS"),height(routes));
    fprintf('%-4s %-4s %-11s %-10s %-12s %-12s %s\n', ...
        'Gen','Ind','Result','Types same','Fitness','Reached F/I','First diff');
    for r = 1:height(routes)
        route = routes(r,:);
        types = "n/a";
        reached = "n/a";
        first = "n/a";
        if ~isempty(results.segments)
            selected = results.segments.Generation==route.Generation & ...
                results.segments.Individual==route.Individual;
            segments = results.segments(selected,:);
            if ~isempty(segments)
                types = string(sum(segments.PathTypeMatch==1))+"/"+string(height(segments));
                reached = string(sum(segments.FullReached==1))+"/"+string(sum(segments.IncReached==1));
                mismatch = find(~segments.Same & (segments.FullSamples>0 | segments.IncSamples>0),1);
                if ~isempty(mismatch)
                    first = "segment "+string(segments.Segment(mismatch));
                elseif all(segments.Same)
                    first = "none";
                end
            end
        end
        fitness = "unavailable";
        if route.IncWPFitness=="FAIL" || route.FullWPFitness=="FAIL"
            fitness = "different";
        elseif route.IncWPFitness=="PASS" && route.FullWPFitness=="PASS"
            fitness = "same";
        end
        fprintf('%-4d %-4d %-11s %-10s %-12s %-12s %s\n', ...
            route.Generation,route.Individual,route.Verdict,types,fitness,reached,first);
    end
    fprintf('Types same = matching segments / total. Reached F/I = full / incremental counts.\n');
    fprintf('First diff = first differing or unavailable trajectory segment.\n');
    fprintf('Details for one individual (no rerun): displayVesselComparison(results, generation, individual)\n');
end

function text = matchText(value)
    text = "unavailable";
    if value==1, text = "same";
    elseif value==0, text = "different"; end
end
