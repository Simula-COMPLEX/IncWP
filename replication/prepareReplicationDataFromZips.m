function imported = prepareReplicationDataFromZips()
% prepareReplicationDataFromZips Unzip packaged experiments into replicationRuns/experiments without overwriting.

    repoRoot = fileparts(which('setupProject.m'));
    zipRoot = fullfile(repoRoot, 'replicationData', 'zippedExperiments');
    targetRoot = fullfile(repoRoot, 'replicationRuns', 'experiments');

    imported = struct('zipFile', {}, 'targetFolder', {}, 'imported', {});

    if ~isfolder(zipRoot)
        error('Zip folder not found: %s', zipRoot);
    end

    vesselDirs = dir(zipRoot);
    for vesselIndex = 1:numel(vesselDirs)
        vesselName = vesselDirs(vesselIndex).name;
        if ~vesselDirs(vesselIndex).isdir || ismember(vesselName, {'.', '..'})
            continue;
        end

        vesselZipRoot = fullfile(zipRoot, vesselName);
        zipFiles = dir(fullfile(vesselZipRoot, '*.zip'));

        for zipIndex = 1:numel(zipFiles)
            zipFile = fullfile(vesselZipRoot, zipFiles(zipIndex).name);
            [~, folderName] = fileparts(zipFiles(zipIndex).name);
            targetFolder = fullfile(targetRoot, vesselName, folderName);

            if isfolder(targetFolder)
                imported(end + 1, 1) = struct( ...
                    'zipFile', zipFile, ...
                    'targetFolder', targetFolder, ...
                    'imported', false);
                continue;
            end

            targetVesselRoot = fullfile(targetRoot, vesselName);
            if ~isfolder(targetVesselRoot)
                mkdir(targetVesselRoot);
            end

            unzip(zipFile, targetVesselRoot);

            imported(end + 1, 1) = struct( ...
                'zipFile', zipFile, ...
                'targetFolder', targetFolder, ...
                'imported', true);
        end
    end
end
