% Restore missing files using the existing replication unzip helper.
% Edit these settings, then press Run. Existing files are kept.
% This script does not run validation or simulations.

vesselName = "remus100";
selectionType = "FullWP";
experimentNumber = 1;

repoRoot = fileparts(fileparts(mfilename('fullpath')));
dataRoot = fullfile(repoRoot, "experimentsData");
addpath(fullfile(repoRoot, "replication"));
imported = prepareReplicationDataFromZips(dataRoot, vesselName, selectionType, experimentNumber);
sourceFolder = fullfile(dataRoot, vesselName, selectionType + "-exNum" + experimentNumber);
files = dir(fullfile(sourceFolder, '*population-g*.mat'));
fprintf('%d population files available in %s\n', numel(files), sourceFolder);
