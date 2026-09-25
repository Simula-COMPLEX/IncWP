function experimentInfoMap = loadExperimentsStatusOriginal(vesselName, onServer)
    experimentInfoMap = containers.Map();
    if ~onServer
        if vesselName == "remus100"
            experimentInfoMap("IncWP_KP") = 1;
        elseif vesselName == "nspauv"
        elseif vesselName == "mariner"
        end
        return;
    end

    if vesselName == "remus100"
        IncWP_Kmeans = 1:32;
        IncWP_Kmeans(ismember(IncWP_Kmeans, [10, 31])) = [];
        experimentInfoMap("IncWP_Kmeans") = IncWP_Kmeans;

        IncWP_KP = 1:31;
        IncWP_KP(ismember(IncWP_KP, [13])) = [];
        experimentInfoMap("IncWP_KP") = IncWP_KP;

        IncWP_Rnd = 1:34;
        IncWP_Rnd(ismember(IncWP_Rnd, [28, 29, 30, 4])) = [];
        experimentInfoMap("IncWP_Rnd") = IncWP_Rnd;

        experimentInfoMap("RandomSearch") = 1:30;
        experimentInfoMap("FullWP") = 1:30;

        IncWP_Unst = 1:42;
        IncWP_Unst(ismember(IncWP_Unst, [11, 18, 22, 3, 8, 9])) = [];
        IncWP_Unst(ismember(IncWP_Unst, [7, 10, 23, 26, 28, 35])) = [];
        experimentInfoMap("IncWP_Unst") = IncWP_Unst;

        IncWP_Prox = 1:37;
        IncWP_Prox(ismember(IncWP_Prox, [1, 16, 17, 19, 2, 20, 22])) = [];
        experimentInfoMap("IncWP_Prox") = IncWP_Prox;

    elseif vesselName == "nspauv"
        experimentInfoMap("IncWP_Kmeans") = 1:30;

        IncWP_KP = 1:31;
        IncWP_KP(ismember(IncWP_KP, [6])) = [];
        experimentInfoMap("IncWP_KP") = IncWP_KP;

        IncWP_Rnd = 1:43;
        IncWP_Rnd(ismember(IncWP_Rnd, [28, 29, 30])) = [];
        IncWP_Rnd(ismember(IncWP_Rnd, [1, 4, 15, 24, 25, 28, 31])) = [];
        IncWP_Rnd(ismember(IncWP_Rnd, [34, 35, 39, 40])) = [];
        experimentInfoMap("IncWP_Rnd") = IncWP_Rnd;

        experimentInfoMap("RandomSearch") = 1:30;
        experimentInfoMap("FullWP") = 1:30;
        experimentInfoMap("IncWP_Prox") = 1:30;

        IncWP_Unst = 1:40;
        IncWP_Unst(ismember(IncWP_Unst, [23])) = [];
        IncWP_Unst(ismember(IncWP_Unst, [5, 6, 8, 13, 17, 30])) = [];
        IncWP_Unst(ismember(IncWP_Unst, [34, 36, 37])) = [];
        experimentInfoMap("IncWP_Unst") = IncWP_Unst;

        IncWP_Prox = 1:36;
        IncWP_Prox(ismember(IncWP_Prox, [1, 15, 17, 19, 20, 21])) = [];
        experimentInfoMap("IncWP_Prox") = IncWP_Prox;

    elseif vesselName == "mariner"
        experimentInfoMap("IncWP_Kmeans") = 1:30;
        experimentInfoMap("IncWP_KP") = 1:30;
        experimentInfoMap("IncWP_Rnd") = 1:30;
        experimentInfoMap("RandomSearch") = 1:30;
        experimentInfoMap("FullWP") = 1:30;
        experimentInfoMap("IncWP_Unst") = 1:30;
        experimentInfoMap("IncWP_Prox") = 1:30;
    end
end
