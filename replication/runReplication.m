function info = runReplication()
% runReplication Rerun simulations and analysis from packaged replication data.

    resumeFromLastIteration = true;
    runSimulationFlag = true;
    runAnalysisFlag = true;

    scriptRoot = fileparts(mfilename('fullpath'));
    repoRoot = fileparts(scriptRoot);
    dataRoot = fullfile(repoRoot, 'replicationRuns', 'experiments');
    zipRoot = fullfile(repoRoot, 'replicationData', 'zippedExperiments');

    if isfolder(zipRoot)
        prepareReplicationDataFromZips();
    end

    if ~isfolder(dataRoot)
        error('replicationRuns/experiments folder not found in %s', repoRoot);
    end

    addpath(genpath(fullfile(repoRoot, 'scripts')));
    addpath(genpath(fullfile(repoRoot, 'frameworks')));
    addpath(genpath(scriptRoot));
    analysisRoot = fullfile(repoRoot, 'analysis');
    if isfolder(analysisRoot) && isempty(which('loadExperimentsStatus'))
        addpath(genpath(analysisRoot));
    end

    vesselNames = {'remus100', 'nspauv', 'mariner'};
    selectedVessels = {};
    simulationSummary = struct('experimentsRun', 0, 'experimentsSkipped', 0);

    for v = 1:numel(vesselNames)
        vesselName = vesselNames{v};
        vesselFolder = fullfile(dataRoot, vesselName);
        if ~isfolder(vesselFolder)
            continue;
        end

        experimentInfoMap = loadExperimentsStatus(string(vesselName));
        selectionTypes = keys(experimentInfoMap);
        if ~isempty(selectionTypes)
            selectedVessels{end + 1} = vesselName;
        end

        for i = 1:numel(selectionTypes)
            selectionType = selectionTypes{i};
            experimentNumbers = experimentInfoMap(selectionType);

            for exNum = experimentNumbers
                resultFolder = fullfile(dataRoot, vesselName, sprintf('%s-exNum%d', selectionType, exNum));
                if ~isfolder(resultFolder)
                    simulationSummary.experimentsSkipped = simulationSummary.experimentsSkipped + 1;
                    continue;
                end

                if runSimulationFlag
                    simulateForSelectionType(vesselName, selectionType, exNum, resumeFromLastIteration, dataRoot);
                    simulationSummary.experimentsRun = simulationSummary.experimentsRun + 1;
                else
                    simulationSummary.experimentsSkipped = simulationSummary.experimentsSkipped + 1;
                end
            end
        end
    end

    fprintf('\nSimulation summary:\n');
    fprintf('  simulation enabled: %d\n', runSimulationFlag);
    fprintf('  experiments run: %d\n', simulationSummary.experimentsRun);
    fprintf('  experiments skipped: %d\n', simulationSummary.experimentsSkipped);

    analysisInfo = struct('vesselsRun', 0);
    if runAnalysisFlag
        vesselNamesToRun = unique(selectedVessels, 'stable');
        for i = 1:numel(vesselNamesToRun)
            vesselName = vesselNamesToRun{i};
            runAnalysis(vesselName, dataRoot);
            analysisInfo.vesselsRun = analysisInfo.vesselsRun + 1;
        end

        fprintf('\nAnalysis summary:\n');
        fprintf('  vessels analysed: %d\n', analysisInfo.vesselsRun);
    end

    info = struct('simulation', simulationSummary, 'analysis', analysisInfo);
end

function simulateForSelectionType(vesselName, selectionType, experimentNumber, resumeFromLastIteration, dataRoot)
    if strcmpi(selectionType, 'FullWP')
        simulateVesselFullWP(vesselName, selectionType, experimentNumber, resumeFromLastIteration, dataRoot);
    elseif strcmpi(selectionType, 'IncWP_Kmeans')
        simulateVesselIncWPKmeans(vesselName, selectionType, experimentNumber, resumeFromLastIteration, dataRoot);
    else
        simulateVessel(vesselName, selectionType, experimentNumber, resumeFromLastIteration, dataRoot);
    end
end
