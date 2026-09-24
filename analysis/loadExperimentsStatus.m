function experimentInfoMap = loadExperimentsStatus(vesselName)
% Explicit analysis selection. Use [] to ignore an approach, or list selected run numbers.
    experimentInfoMap = containers.Map('KeyType','char','ValueType','any');
    switch string(vesselName)
        case "remus100"
            experimentInfoMap("IncWP_KP") = 1:30;
            experimentInfoMap("IncWP_Rnd") = 1:30;
            experimentInfoMap("RandomSearch") = 1:30;
            experimentInfoMap("IncWP_Unst") = 1:30;
            experimentInfoMap("IncWP_Prox") = 1:30;
            experimentInfoMap("IncWP_K2Means") = [];
            experimentInfoMap("IncWP_K3Means") = 1:30;
            experimentInfoMap("IncWP_K5Means") = [];
            experimentInfoMap("FullWP10") = 1:5;
            experimentInfoMap("FullWP50") = 1:5;
            %experimentInfoMap("FullWP100") = [];
            experimentInfoMap("FullWP10_TimeCutoff") = experimentInfoMap("FullWP10");
            experimentInfoMap("FullWP50_TimeCutoff") = experimentInfoMap("FullWP50");

        case "nspauv"
            experimentInfoMap("IncWP_KP") = 1:30;
            experimentInfoMap("IncWP_Rnd") = 1:30;
            experimentInfoMap("RandomSearch") = 1:30;
            experimentInfoMap("IncWP_Unst") = 1:30;
            experimentInfoMap("IncWP_Prox") = 1:30;
            experimentInfoMap("IncWP_K2Means") = [];
            experimentInfoMap("IncWP_K3Means") = 1:30;
            experimentInfoMap("IncWP_K5Means") = [];
            experimentInfoMap("FullWP10") = 1:5;
            experimentInfoMap("FullWP50") = 1:4;
            experimentInfoMap("FullWP10_TimeCutoff") = experimentInfoMap("FullWP10");
            experimentInfoMap("FullWP50_TimeCutoff") = experimentInfoMap("FullWP50");

            %experimentInfoMap("FullWP100") = [];

        case "mariner"
            experimentInfoMap("IncWP_KP") = 1:30;
            experimentInfoMap("IncWP_Rnd") = 1:30;
            experimentInfoMap("RandomSearch") = 1:30;
            experimentInfoMap("IncWP_Unst") = 1:30;
            experimentInfoMap("IncWP_Prox") = 1:30;
            experimentInfoMap("IncWP_K2Means") = [];
            experimentInfoMap("IncWP_K3Means") = 1:30;
            experimentInfoMap("IncWP_K5Means") = [];
            experimentInfoMap("FullWP10") = 1:5;
            experimentInfoMap("FullWP50") = 1:1;
            experimentInfoMap("FullWP10_TimeCutoff") = experimentInfoMap("FullWP10");
            experimentInfoMap("FullWP50_TimeCutoff") = experimentInfoMap("FullWP50");
            %experimentInfoMap("FullWP100") = [];

    end

    names = experimentInfoMap.keys();
    for k = 1:numel(names)
        if isempty(experimentInfoMap(names{k}))
            remove(experimentInfoMap, names{k});
        end
    end
end
