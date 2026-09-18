generations = 100;
individuals = 1:10;

addpath(fileparts(mfilename('fullpath')));
results = compareVesselBatch("remus100", generations, individuals);
