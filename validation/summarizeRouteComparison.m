function verdict = summarizeRouteComparison(route)
    segments = route.comparison;
    trajectory = checkStatus(double(segments.Same),segments.Compared);
    if any(xor(segments.FullSamples>0,segments.IncSamples>0))
        trajectory = "FAIL";
    end
    reachability = checkStatus(segments.ReachabilityMatch,isfinite(segments.ReachabilityMatch));
    inc = route.fitness(route.fitness.Formula=="IncWP",:);
    full = route.fitness(route.fitness.Formula=="FullWP",:);
    incFitness = checkStatus(inc.FitnessMatch,inc.Comparable);
    fullFitness = checkStatus(full.FitnessMatch,full.Comparable);
    pathType = checkStatus(segments.PathTypeMatch,isfinite(segments.PathTypeMatch));
    checks = [trajectory,reachability,incFitness,fullFitness,pathType];
    if strlength(route.incrementalError)>0 || strlength(route.classificationError)>0 || any(strlength(route.fitness.Error)>0)
        overall = "ERROR";
    elseif any(checks=="FAIL")
        overall = "FAIL";
    elseif any(checks=="INCOMPLETE")
        overall = "INCOMPLETE";
    else
        overall = "PASS";
    end
    verdict = table(trajectory,reachability,incFitness,fullFitness,pathType,overall, ...
        'VariableNames',{'Trajectory','Reachability','IncWPFitness','FullWPFitness','PathType','Verdict'});
end

function status = checkStatus(matches,available)
    if any(matches(available)==0)
        status = "FAIL";
    elseif isempty(matches) || ~all(available) || any(~isfinite(matches))
        status = "INCOMPLETE";
    else
        status = "PASS";
    end
end
