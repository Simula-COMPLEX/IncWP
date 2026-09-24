function FullpathResultsIntoIncremental(vesselName, onServer, resultsPath)

    if nargin < 3 || strlength(string(resultsPath)) == 0
        error("FullpathResultsIntoIncremental needs a resultsPath so it does not accidentally overwrite ExperimentsResults.")
    end

    resultsPath = char(resultsPath);
    experimentInfoMap = loadExperimentsStatus(vesselName);
    vesselInformation = loadShipSearchParameters(vesselName);
    for selectionType = string(experimentInfoMap.keys())
        if isempty(regexp(char(selectionType),'^FullWP[0-9]+$','once'))
            continue;
        end
        for experimentNum = experimentInfoMap(selectionType)
            folder = fullfile(resultsPath,vesselName,selectionType+"-exNum"+string(experimentNum));
            missingFiles = false;
            for waypoint = 2:vesselInformation.numWaypoints+1
                filename = fullfile(folder,"WptIdx-resultsWpt-"+string(waypoint));
                missingFiles = missingFiles || ~isfile(filename+".mat") || ~isfile(filename+"-population.mat");
            end
            if ~missingFiles
                continue;
            end
            fprintf('Preparing waypoint files for %s experiment %d.\n',selectionType,experimentNum);
            if ~isfile(fullfile(folder,'ObjectivesUnsplit.mat'))
                splitOjectivesPerExperiment(vesselName,experimentNum,resultsPath,selectionType);
            end
            if ~isfile(fullfile(folder,'ResultsPathTypeUnSplit.mat'))
                calculateClassPerExperiment(vesselName,experimentNum,resultsPath,selectionType);
            end
            splitPerWaypoint(vesselName,experimentNum,"none",resultsPath,selectionType);
        end
    end

end


function splitOjectivesPerExperiment(vesselName, experimentNum, resultsPath, selectionType)
    folder = fullfile(resultsPath,vesselName,selectionType+"-exNum"+string(experimentNum));
    generationFiles = analysisGenerationFiles(folder);
    numGenerations = numel(generationFiles);
    if numGenerations == 0
        error('No FullWP population generations found in %s.',folder);
    end
    maxValueCONST = 999999999;

    initialPopulation = "Comb";
    consMatrix = [];
    decsMatrix = [];
        

    vesselInformation = loadShipSearchParameters(vesselName);
    initialWpts = reshape(vesselInformation.initialPoints, [vesselInformation.pointDimension, vesselInformation.numWaypoints]);

    % start my making a matrix that splits each waypoint
    distancesFromInitialAllIndividuals = []; 
    subPathDistanceMatrixAllIndividuals = [];
    for gen = 1:numGenerations
        filelocation = fullfile(folder,strrep(generationFiles(gen).name,'-population-','-paths-'));
        load(filelocation, "missingPathLabel", "subPathDistanceMatrix", "timestamps","paths");
        filelocation = fullfile(folder,generationFiles(gen).name);
        load(filelocation, "Population");
        decs = Population.decs;
        consMatrix = [consMatrix; Population.cons];
        decsMatrix = [decsMatrix; Population.decs];
        

        individualsubPathDistanceMatrix = subPathDistanceMatrix;

        for individual = 1:size(Population.decs,1)
            %subPath = paths(string(individual));
            

            individualDistance = [];
            individualWpts = reshape(decs(individual,:), [vesselInformation.pointDimension, vesselInformation.numWaypoints]);
            for wptIndex = 1:vesselInformation.numWaypoints
                individualDistance = [individualDistance pdist2(individualWpts(:,wptIndex)',initialWpts(:,wptIndex)','euclidean')];

            end
            
            distancesFromInitialAllIndividuals = [distancesFromInitialAllIndividuals; individualDistance];
        
        end
        subPathDistanceMatrixAllIndividuals = [subPathDistanceMatrixAllIndividuals individualsubPathDistanceMatrix];

    end
    size(subPathDistanceMatrixAllIndividuals)
    filepath = append(resultsPath,  "/", vesselName, "/", selectionType, "-exNum", string(experimentNum), "/ObjectivesUnsplit")
    if ~exist(fileparts(char(filepath)), 'dir')
        mkdir(fileparts(char(filepath)));
    end
    save(filepath, "subPathDistanceMatrixAllIndividuals", "distancesFromInitialAllIndividuals", "decsMatrix","consMatrix")

    

end

function calculateClassPerExperiment(vesselName, experimentNum, resultsPath, selectionType)
    if vesselName == "mariner"
        hours = 3;
        indivdualLimit = 2000;
    elseif vesselName == "nspauv"
        hours = 5;
        indivdualLimit = 1670;
    elseif vesselName == "remus100"
        hours = 3.5;
        indivdualLimit = 1670;
    end

    
    timestampthreshold = hours*60*60; 
    usePython = true;
    onServer = true;
    folder = fullfile(resultsPath,vesselName,selectionType+"-exNum"+string(experimentNum));
    generationFiles = analysisGenerationFiles(folder);
    numGenerations = numel(generationFiles);
    if numGenerations == 0
        error('No FullWP population generations found in %s.',folder);
    end
    approachInfo = analysisApproachInfo(selectionType);
    populationSize = approachInfo.populationSize;
    vesselInformation = loadShipSearchParameters(vesselName);
    initialPopulation = "Comb";
    

    if usePython == true
        
        projectRoot = fileparts(which('setupProject.m'));
        pythonScriptPath = fullfile(projectRoot,'analysis');
        if count(py.sys.path,pythonScriptPath) == 0
            insert(py.sys.path,int32(0),pythonScriptPath);
        end
        peak_analysis = py.importlib.import_module('calculate_number_of_peaks');
        py.importlib.reload(peak_analysis);  % force reload

    else
        peak_analysis = false;
    end

    numPeaksMatrix = [];
    individualClassMatrix = [];
    numPeaksMatrixTimeLimited = [];
    individualClassMatrixTimeLimited = [];
    numPeaksMatrixIndividualLimited = [];
    individualClassMatrixIndividualLimited = [];
    genAndIndivudalForTimeLimit = [];
    genAndIndivudalForIndividualLimited = [];

    consMatrix = [];
    decsMatrix = [];
    timeUsage = 0;
    
    for gen = 1:numGenerations
        filelocation = fullfile(folder,strrep(generationFiles(gen).name,'-population-','-paths-'));
        load(filelocation, "missingPathLabel", "subPathDistanceMatrix", "timestamps","paths");
        filelocation = fullfile(folder,generationFiles(gen).name);
        load(filelocation, "Population");

        startIndex = 1;
        individualsubPathDistanceMatrix = [];
        consMatrix = [consMatrix; Population.cons];
        decsMatrix = [decsMatrix; Population.decs];

        timeUsage  = timeUsage + timestamps(end);
            
            

        for individual = 1:size(Population.decs,1)
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

            if timeUsage < timestampthreshold
                numPeaksMatrixTimeLimited = [numPeaksMatrixTimeLimited; numPeaksList];
                individualClassMatrixTimeLimited = [individualClassMatrixTimeLimited; individualClassList];
                genAndIndivudalForTimeLimit = [gen individual];
                
            end

            if gen < (indivdualLimit/populationSize)
                numPeaksMatrixIndividualLimited = [numPeaksMatrixIndividualLimited; numPeaksList];
                individualClassMatrixIndividualLimited = [individualClassMatrixIndividualLimited; individualClassList];
                genAndIndivudalForIndividualLimited = [gen individual];
            end
        end

           
    end
    
    filepathBase = append(resultsPath,  "/", vesselName, "/", selectionType, "-exNum", string(experimentNum), "/ResultsPathTypeUnSplit")
    if ~exist(fileparts(char(filepathBase)), 'dir')
        mkdir(fileparts(char(filepathBase)));
    end
    save(filepathBase,"individualClassMatrix", "numPeaksMatrix", "individualClassMatrixTimeLimited", "numPeaksMatrixTimeLimited", "genAndIndivudalForTimeLimit", "timestamps", "numPeaksMatrixIndividualLimited", "individualClassMatrixIndividualLimited", "genAndIndivudalForIndividualLimited")

    
end

function splitPerWaypoint(vesselName,experimentNum, limit, resultsPath, selectionType)
    maxValueCONST = 999999999;
    vesselInformation = loadShipSearchParameters(vesselName);
    approachInfo = analysisApproachInfo(selectionType);
    populationSize = approachInfo.populationSize;

    filepath = append(resultsPath,  "/", vesselName, "/", selectionType, "-exNum", string(experimentNum), "/ResultsPathTypeUnSplit")
    %filepath = append(resultsPath,  "/", vesselName, "/", selectionType, "-exNum", string(experimentNum), "/ResultsPathTypeUnSplit")
    load(filepath,"individualClassMatrix", "numPeaksMatrix", "individualClassMatrixTimeLimited", "numPeaksMatrixTimeLimited", "genAndIndivudalForTimeLimit", "timestamps","numPeaksMatrixIndividualLimited", "individualClassMatrixIndividualLimited", "genAndIndivudalForIndividualLimited")
    filepath = append(resultsPath,  "/", vesselName, "/", selectionType, "-exNum", string(experimentNum), "/ObjectivesUnsplit");
    load(filepath, "subPathDistanceMatrixAllIndividuals", "distancesFromInitialAllIndividuals",  "decsMatrix","consMatrix")

    prevObjectives = [];
    decsIndex = 1;
    numGenerations = 1000;

    if limit == "none"
        filepathBase = append(resultsPath,  "/", vesselName, "/", selectionType, "-exNum", string(experimentNum), "/WptIdx-resultsWpt-");

    elseif limit == "time"
        individualClassMatrix = individualClassMatrixTimeLimited
        numPeaksMatrix = numPeaksMatrixTimeLimited;
        genForTimeLimit = genAndIndivudalForTimeLimit(1);
        individualForTimeLimit = genAndIndivudalForTimeLimit(2);
        cutForTimeLimit = (genForTimeLimit-1)*populationSize + individualForTimeLimit;

        subPathDistanceMatrixAllIndividuals = subPathDistanceMatrixAllIndividuals(:,1:cutForTimeLimit);
        distancesFromInitialAllIndividuals = distancesFromInitialAllIndividuals(1:cutForTimeLimit,:);
        decsMatrix = decsMatrix(1:cutForTimeLimit,:);
        consMatrix = consMatrix(1:cutForTimeLimit,:);


        filepathBase = append(resultsPath,  "/", vesselName, "/", "FullWP_Timelimited", "-exNum", string(experimentNum), "/WptIdx-resultsWpt-timedLimited-");
    elseif limit == "individual"
        individualClassMatrix = individualClassMatrixIndividualLimited
        numPeaksMatrix = numPeaksMatrixIndividualLimited;
        genForIndividualLimit = genAndIndivudalForIndividualLimited(1);
        individualForIndivdualLimit = genAndIndivudalForIndividualLimited(2);
        cutForIndivudalLimit = (genForIndividualLimit-1)*populationSize + individualForIndivdualLimit;

        subPathDistanceMatrixAllIndividuals = subPathDistanceMatrixAllIndividuals(:,1:cutForIndivudalLimit);
        distancesFromInitialAllIndividuals = distancesFromInitialAllIndividuals(1:cutForIndivudalLimit,:);
        decsMatrix = decsMatrix(1:cutForIndivudalLimit,:);
        consMatrix = consMatrix(1:cutForIndivudalLimit,:);


        filepathBase = append(resultsPath,  "/", vesselName, "/", "FullWP-individualLimited", "-exNum", string(experimentNum), "/WptIdx-resultsWpt-individualLimited-");
    end

   
    %for wptIndex = 1:size(individualClassMatrix,2)-1
    for wptIndex = 1:size(individualClassMatrix,2)
        individualClassMatrixWpt = individualClassMatrix(:,wptIndex);
        numPeaksMatrixWpt = reshape(numPeaksMatrix(:,wptIndex),vesselInformation.pointDimension,[]);

        missingFlagCategory = individualClassMatrixWpt == "missing";

        distancesWpt = sum(distancesFromInitialAllIndividuals(:,1:wptIndex),2)/wptIndex;
          

        subPathDistanceMatrixWpt = subPathDistanceMatrixAllIndividuals(1:wptIndex,:);
        subPathDistanceMatrixObjectives = zeros(size(subPathDistanceMatrixAllIndividuals(wptIndex,:)));
        [missingPathsFlag, nonMissingPathsFlag] = getIndexesOfMissingPaths(subPathDistanceMatrixAllIndividuals(wptIndex,:)');
        missingPathsFlag = missingPathsFlag | missingFlagCategory;
        nonMissingPathsFlag = ~missingPathsFlag;


        %missingPathsFlagsMatrix = [missingPathsFlagsMatrix missingPathsFlag]
        %if sum(missingPathsFlag>0)
            %wptIndex:
            %missingPathsFlag

        %end
        indexOfMissingPaths = find(missingPathsFlag);
        indexesOfNonMissingPaths = find(nonMissingPathsFlag);
        
        if isempty(prevObjectives)
            prevObjectives = zeros(size(subPathDistanceMatrixWpt));
        end
        
        if ~isempty(indexesOfNonMissingPaths)
            if wptIndex == 1
                subPathDistanceMatrixObjectives(indexesOfNonMissingPaths) =  subPathDistanceMatrixWpt(:,indexesOfNonMissingPaths);

            else
                subPathDistanceMatrixObjectives(indexesOfNonMissingPaths) =  mean(subPathDistanceMatrixWpt(:,indexesOfNonMissingPaths))';
            end
        end
        if ~isempty(indexOfMissingPaths)            
            subPathDistanceMatrixObjectives(indexOfMissingPaths) = -maxValueCONST*ones(size(indexOfMissingPaths));
        end
        subPathDistanceMatrixWpt = -subPathDistanceMatrixObjectives;
        objs = [subPathDistanceMatrixWpt; distancesWpt']';
        prevObjectives = objs;
        
        decs = decsMatrix(:,decsIndex:(decsIndex+vesselInformation.pointDimension-1));
        finalPopulation = SOLUTION(decs,objs, consMatrix);
        decsIndex = decsIndex+ vesselInformation.pointDimension;

        filepath = append(filepathBase,string(wptIndex+1),"-population");
        if ~exist(fileparts(char(filepath)), 'dir')
            mkdir(fileparts(char(filepath)));
        end
        if ~isfile(filepath+".mat")
            save(filepath, "finalPopulation","distancesWpt","subPathDistanceMatrixWpt", "prevObjectives", "missingPathsFlag")
        end

        
        filepath = append(filepathBase,string(wptIndex+1));
        if ~exist(fileparts(char(filepath)), 'dir')
            mkdir(fileparts(char(filepath)));
        end
        if ~isfile(filepath+".mat")
            save(filepath, "finalPopulation","distancesWpt","subPathDistanceMatrixWpt","individualClassMatrixWpt","numPeaksMatrixWpt", "timestamps")
        end

        
    end

    
end
