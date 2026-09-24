function status = analysisResultStatus(base)
% Inspect sources, code, shards and dependency revisions; persist stale flags.
    manifest = analysisResultManifest(base,'refresh');
    stages = ["classification","timing","candidates","timeLimited","metrics","reports"];
    state = strings(6,1); reason = strings(6,1); updated = strings(6,1);
    for k = 1:numel(stages)
        index = find(strcmp({manifest.datasets.id},stages(k)),1);
        state(k) = "missing"; reason(k) = "Not calculated.";
        if ~isempty(index)
            state(k) = string(manifest.datasets(index).status);
            reason(k) = string(manifest.datasets(index).reason);
            updated(k) = string(manifest.datasets(index).updatedAt);
        end
        if stages(k)=="timeLimited" && string(manifest.configuration.timeLimitPolicy)=="none"
            state(k) = "disabled"; reason(k) = "Time-limit policy is none.";
        end
    end
    status = table(stages(:),state,reason,updated,'VariableNames',{'Dataset','Status','Reason','UpdatedAt'});
    if nargout==0, disp(status); end
end
