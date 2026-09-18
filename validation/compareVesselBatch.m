function results = compareVesselBatch(vessel, generations, individuals)
    arguments
        vessel (1,1) string
        generations (1,:) double = 1
        individuals (1,:) double = 1:10
    end
    assert(~isempty(generations) && ~isempty(individuals),'Select at least one generation and individual.');
    results.vessel = vessel;
    results.generations = generations;
    results.individuals = individuals;
    results.routes = table();
    results.segments = table();
    results.fitness = table();
    results.note = "Runtime includes incremental state-file IO and is not a pure dynamics-speed comparison. " + ...
        "Metrics are computed after simulation. Trajectories are not retained in batch results. " + ...
        "Means of segment RMSEs weight segments equally. Errors and unavailable segments are reported separately.";
    total = numel(generations)*numel(individuals);
    index = 0;
    for generation = generations
        for individual = individuals
            index = index+1;
            fprintf('%s: route %d/%d (generation %d, individual %d) ... ', ...
                vessel,index,total,generation,individual);
            row = table(generation,individual,false,0,0,0,NaN,NaN,NaN,NaN,NaN,NaN,NaN,"", ...
                'VariableNames',{'Generation','Individual','AllSame','TotalSegments', ...
                'ComparedSegments','MatchingSegments','ReachabilityAgreementPercent', ...
                'MeanPositionRMSE_m','MaxPositionDifference','MaxEndpointDifference_m', ...
                'TotalPathLengthDifference_m','FullSeconds','IncrementalSeconds','Error'});
            row.Trajectory = "INCOMPLETE";
            row.Reachability = "INCOMPLETE";
            row.IncWPFitness = "INCOMPLETE";
            row.FullWPFitness = "INCOMPLETE";
            row.PathType = "INCOMPLETE";
            row.Verdict = "ERROR";
            try
                route = compareVesselRoute(vessel,[],generation,individual,false);
                segments = route.comparison;
                segments.Generation = repmat(generation,height(segments),1);
                segments.Individual = repmat(individual,height(segments),1);
                if isempty(results.segments), results.segments = segments;
                else, results.segments = [results.segments; segments]; end
                fitness = route.fitness;
                fitness.Generation = repmat(generation,height(fitness),1);
                fitness.Individual = repmat(individual,height(fitness),1);
                if isempty(results.fitness), results.fitness = fitness;
                else, results.fitness = [results.fitness; fitness]; end
                verdict = route.verdict;
                for field = string(verdict.Properties.VariableNames)
                    row.(field) = verdict.(field);
                end
                row.AllSame = route.allSame;
                row.TotalSegments = height(segments);
                row.ComparedSegments = sum(segments.Compared);
                row.MatchingSegments = sum(segments.Same);
                row.ReachabilityAgreementPercent = 100*mean(segments.ReachabilityMatch,'omitnan');
                row.MeanPositionRMSE_m = mean(segments.PositionRMSE_m(segments.Compared),'omitnan');
                row.MaxPositionDifference = max(segments.MaxPositionDifference,[],'omitnan');
                row.MaxEndpointDifference_m = max(segments.EndpointDifference_m,[],'omitnan');
                if all(isfinite(segments.FullPathLength_m)) && all(isfinite(segments.IncPathLength_m))
                    row.TotalPathLengthDifference_m = abs(sum(segments.FullPathLength_m)-sum(segments.IncPathLength_m));
                end
                row.FullSeconds = route.fullSeconds;
                row.IncrementalSeconds = route.incrementalSeconds;
                row.Error = route.incrementalError;
                if strlength(route.classificationError)>0
                    row.Error = row.Error+" Classification: "+route.classificationError;
                end
                fitnessErrors = route.fitness.Error(strlength(route.fitness.Error)>0);
                if ~isempty(fitnessErrors)
                    row.Error = strjoin([row.Error;fitnessErrors]," ");
                end
                clear route segments
            catch exception
                row.Error = string(exception.identifier)+": "+string(exception.message);
            end
            if isempty(results.routes), results.routes = row;
            else, results.routes = [results.routes; row]; end
            fprintf('%s\n',row.Verdict);
        end
    end
    routes = results.routes;
    results.summary = table(height(routes),sum(routes.Verdict=="PASS"), ...
        sum(routes.Verdict=="FAIL"),sum(routes.Verdict=="INCOMPLETE"),sum(routes.Verdict=="ERROR"), ...
        'VariableNames',{'Tested','Passed','Failed','Incomplete','Errors'});
    fitnessStatus = repmat("SAME",height(routes),1);
    fitnessStatus(routes.IncWPFitness=="INCOMPLETE" | routes.FullWPFitness=="INCOMPLETE") = "UNAVAILABLE";
    fitnessStatus(routes.IncWPFitness=="FAIL" | routes.FullWPFitness=="FAIL") = "DIFFERENT";
    results.overview = table(routes.Generation,routes.Individual,readable(routes.PathType), ...
        fitnessStatus,readable(routes.Trajectory),readable(routes.Reachability), ...
        readable(routes.Verdict),'VariableNames', ...
        {'Generation','Individual','PathType','Fitness','Trajectory','ReachedWaypoints','Overall'});
    if isempty(routes)
        results.verdict = "INCOMPLETE";
    elseif any(routes.Verdict=="ERROR")
        results.verdict = "ERROR";
    elseif any(routes.Verdict=="FAIL")
        results.verdict = "FAIL";
    elseif any(routes.Verdict=="INCOMPLETE")
        results.verdict = "INCOMPLETE";
    else
        results.verdict = "PASS";
    end
    displayVesselComparison(results);
end

function text = readable(status)
    text = status;
    text(status=="PASS") = "SAME";
    text(status=="FAIL") = "DIFFERENT";
    text(status=="INCOMPLETE") = "UNAVAILABLE";
end
