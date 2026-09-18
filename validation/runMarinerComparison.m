generations = 1;
individuals = 1:10;

addpath(fileparts(mfilename('fullpath')));
results = compareVesselBatch("mariner", generations, individuals);
