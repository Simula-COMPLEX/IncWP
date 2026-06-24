projectRoot = fileparts(mfilename('fullpath'));
ensureFrameworkLayout(projectRoot);
ensureProjectDataLayout(projectRoot);

addpath(genpath(fullfile(projectRoot, "analysis")));
addpath(genpath(fullfile(projectRoot, "scripts")));
addpath(genpath(fullfile(projectRoot, "frameworks")));
addpath(genpath(fullfile(projectRoot, "replication")));

savepath;
fprintf('MATLAB path updated, framework folders checked, and data folders prepared.\n');


function ensureFrameworkLayout(projectRoot)
    frameworksRoot = fullfile(projectRoot, "frameworks");
    if ~isfolder(frameworksRoot)
        mkdir(frameworksRoot);
    end

    moveFrameworkFolder(projectRoot, fullfile(projectRoot, "MSS"), fullfile(frameworksRoot, "MSS"));

    evolutionaryRoot = fullfile(frameworksRoot, "evolutionaryPlatform");
    if ~isfolder(evolutionaryRoot)
        mkdir(evolutionaryRoot);
    end

    moveFrameworkFolder(projectRoot, ...
        fullfile(projectRoot, "BIMK-PlatEMO-4.7.0.0"), ...
        fullfile(evolutionaryRoot, "BIMK-PlatEMO-4.7.0.0"));
    moveFrameworkFolder(projectRoot, ...
        fullfile(projectRoot, "NSGA-II-Adapted"), ...
        fullfile(evolutionaryRoot, "NSGA-II-Adapted"));
end


function moveFrameworkFolder(projectRoot, sourcePath, targetPath)
    if ~isfolder(sourcePath) || isfolder(targetPath)
        return;
    end

    [targetParent, ~, ~] = fileparts(targetPath);
    if ~isfolder(targetParent)
        mkdir(targetParent);
    end

    movefile(sourcePath, targetPath);
    fprintf('Moved framework folder to %s\n', strrep(targetPath, [projectRoot filesep], ''));
end

function ensureProjectDataLayout(projectRoot)
    vesselNames = ["mariner", "nspauv", "remus100"];
    selectionTypes = ["RandomSearch", "IncWP_KP", "IncWP_Rnd", "IncWP_Prox", "IncWP_Unst", "IncWP_Kmeans", "FullWP"];
    experimentNumbers = 1:30;

    ensureExperimentRoot(fullfile(projectRoot, "experimentsData"), vesselNames, selectionTypes, experimentNumbers);
    ensureExperimentRoot(fullfile(projectRoot, "replicationRuns", "experiments"), vesselNames, selectionTypes, experimentNumbers);
    ensureFolder(fullfile(projectRoot, "replicationData", "zippedExperiments"));
    ensureFolder(fullfile(projectRoot, "replicationData", "zippedAnalysis"));
end

function ensureExperimentRoot(rootPath, vesselNames, selectionTypes, experimentNumbers)
    ensureFolder(rootPath);

    for vesselName = vesselNames
        vesselRoot = fullfile(rootPath, vesselName);
        ensureFolder(vesselRoot);

        for selectionType = selectionTypes
            for experimentNumber = experimentNumbers
                experimentRoot = fullfile(vesselRoot, selectionType + "-exNum" + string(experimentNumber));
                ensureFolder(experimentRoot);
            end
        end

        ensureFolder(fullfile(vesselRoot, "AnalysedResults"));
    end
end

function ensureFolder(folderPath)
    if ~isfolder(folderPath)
        mkdir(folderPath);
    end
end
