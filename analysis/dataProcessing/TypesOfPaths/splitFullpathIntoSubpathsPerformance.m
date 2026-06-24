function splitFullpathIntoSubpathsPerformance(vesselName, usePython)
    %pyversion('/opt/anaconda3/bin/python')
    maxValueCONST = 999999999;
    populationSize = 10;
    NumGenerations = 1000;

    if nargin == 0
        vesselName = "nspauv";
        usePython = true;
    end
    experimentInfoMap = loadExperimentsStatus(vesselName);
    experimentNumList = experimentInfoMap('FullWP');
    

    cutFullwptsetsearchatTimestamp(vesselName)

    if vesselName == "mariner"
        hours = 3;
    elseif vesselName == "nspauv"
        hours = 5;
    elseif vesselName == "remus100"
        hours = 3.5;
    end
    timestampthreshold = hours*60*60; 

    
    

    resultsPathInfo = what("ExperimentsResults");
    resultsPath = char(resultsPathInfo.path);
    if usePython == true
        
        %path_to_module = '/Users/karolinen/Documents/MATLAB/WPgen-extended/AnalyseResults';
        path_to_module = '/home/karolinen/vesselProject/WPgen-extended/AnalyseResults'

        pythonScriptPathInfo = what("AnalyseResults");
        pythonScriptPathInfo = char(pythonScriptPathInfo.path);
        if count(py.sys.path, pythonScriptPathInfo) == 0
            insert(py.sys.path, int32(0), path_to_module);
        end
        peak_analysis = py.importlib.import_module('calculate_number_of_peaks');
        py.importlib.reload(peak_analysis);  % force reload

    else
        peak_analysis = false;
    end

    
    initialPopulation = "Comb";
    

    vesselInformation = loadShipSearchParameters(vesselName);
    for experimentNum = experimentNumList
        
        subPathDistanceMatrixTemp = [];
        distances = [];
        numPeaksMatrix = [];
        individualClassMatrix = [];
        initialWpts = reshape(vesselInformation.initialPoints, [vesselInformation.pointDimension, vesselInformation.numWaypoints]);
        consMatrix = [];
        decsMatrix = [];
        timeUsage = 0;

        for gen = 1:NumGenerations
            filelocation = append(resultsPath, "/", vesselName, "/FullWP-exNum", string(experimentNum),"/",initialPopulation,"-paths-g",string(gen));
            load(filelocation, "missingPathLabel", "subPathDistanceMatrix", "timestamps","paths");
            filelocation = append(resultsPath, "/", vesselName, "/FullWP-exNum", string(experimentNum),"/",initialPopulation,"-population-g",string(gen));
            load(filelocation, "Population");
            startIndex = 1;
            individualsubPathDistanceMatrix = [];
            consMatrix = [consMatrix; Population.cons];
            decsMatrix = [decsMatrix; Population.decs];

            timeUsage  = timeUsage + timestamps(end);
            
            
    
            
            
            for individual = 1:length(missingPathLabel)
                individualClassList = [];
                numPeaksList = [];
                
                pathInfo = paths(string(individual));
                transitionIndices = [1; pathInfo('transitionIndices')];
                fullpathAngles = pathInfo('angles');
                %fullpath = pathInfo('fullpath');
                for wptIndex = 1:length(pathInfo('transitionIndices'))
                    %startIdx = transitionIndices(wptIndex,:);
                    angles = fullpathAngles(transitionIndices(wptIndex,:):transitionIndices(wptIndex+1,:),:);
                    %path = fullpath(transitionIndices(wptIndex,:):transitionIndices(wptIndex+1,:),:);
                    individualNumAngles = [];
                    for angIdx = 1:vesselInformation.pointDimension
                        %subAngles = angles(angIdx,:);
                        subAngles = angles(:,angIdx);


                        individualNumAngles = [individualNumAngles;  calculateNumberOfPeaks(angles(:,angIdx), usePython,peak_analysis)];
                        
                    end
    
                    if all(individualNumAngles == 0)
                    individualClass = "stable";
                    else
                        individualClass = "unstable";
                    end
                    individualClassList = [individualClassList individualClass];
                    numPeaksList = [numPeaksList individualNumAngles];

                    
    
                end
                if length(pathInfo('transitionIndices')) < vesselInformation.numWaypoints
                    if isscalar(pathInfo('transitionIndices'))
                        numPeaksList = -1*ones(vesselInformation.pointDimension, vesselInformation.numWaypoints);
                        individualClassList = repmat("missing", 1, vesselInformation.numWaypoints);
                        
                    else
                        individualNumAnglesList = -1*ones(vesselInformation.pointDimension, vesselInformation.numWaypoints-length(pathInfo('transitionIndices')));
                        numPeaksList = [numPeaksList individualNumAnglesList];
                        individualClass = repmat("missing", 1, vesselInformation.numWaypoints - length(pathInfo('transitionIndices')), 1);
                        individualClassList = [individualClassList individualClass];
    
                    end
                    
                end
                
                numPeaksMatrix = [numPeaksMatrix; numPeaksList];
                individualClassMatrix = [individualClassMatrix; individualClassList];

                %distancesFromInitialWaypointsList = [distancesFromInitialWaypointsList; distanceFromInitialWpt];
                
            end
            
            
    
    
    
        end
        
        filepathBase = append(resultsPath,  "/", vesselName, "/", "FullWP", "-exNum", string(experimentNum), "/WptIdx-resultsWpt-")
        decsIndex = 1;
        for wptIndex = 1:size(individualClassMatrix,2)

            individualClassMatrixWpt = individualClassMatrix(:,wptIndex);
            numPeaksMatrixWpt = numPeaksMatrix(:,wptIndex);

            %objs = [subPathDistanceMatrixWpt; distancesWpt']';
            %decs = decsMatrix(:,decsIndex:(decsIndex+vesselInformation.pointDimension-1));
            filepath = append(filepathBase,string(wptIndex+1),"-population");
            load(filepath, "finalPopulation","distancesWpt","subPathDistanceMatrixWpt", "prevObjectives")
       
            
            filepath = append(filepathBase,string(wptIndex+1));
            
            decsIndex = decsIndex+ vesselInformation.pointDimension;
            save(filepath, "finalPopulation","distancesWpt","subPathDistanceMatrixWpt","individualClassMatrixWpt","numPeaksMatrixWpt", "timestamps")
    
        end
    end
           
end
