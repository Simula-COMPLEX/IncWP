function experimentInfoMap = loadExperimentsStatus(vesselName)
    experimentInfoMap = containers.Map();
    
    if vesselName == "remus100" || vesselName == "nspauv" || vesselName == "mariner"
        experimentInfoMap("IncWP_Kmeans") = 1:30;
        experimentInfoMap("IncWP_KP") = 1:30;
        experimentInfoMap("IncWP_Rnd") = 1:30;
        experimentInfoMap("RandomSearch") = 1:30;
        experimentInfoMap("FullWP") = 1:30;
        experimentInfoMap("IncWP_Unst") = 1:30;
        experimentInfoMap("IncWP_Prox") = 1:30;
    end
end
