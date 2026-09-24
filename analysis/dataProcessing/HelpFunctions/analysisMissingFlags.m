function flags = analysisMissingFlags(raw, numIndividuals, numWaypoints)
% Native FullWP saves stacked per-individual columns; accept matrix archives too.
    if isequal(size(raw),[numIndividuals,numWaypoints])
        flags = raw;
    elseif isvector(raw) && numel(raw)==numIndividuals*numWaypoints
        flags = reshape(raw,numWaypoints,numIndividuals)';
    elseif isequal(size(raw),[numWaypoints,numIndividuals])
        flags = raw';
    else
        error('Analysis:ReachabilitySize','FullWP reachability flags do not match population/waypoint counts.');
    end
    assert(all(ismember(flags(:),[0,1])),'Analysis:InvalidReachability','Invalid FullWP reachability flags.');
    flags = logical(flags);
end
