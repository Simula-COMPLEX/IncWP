function population = getPopulation(vesselInformation, vesselResultsPathBase, populationSize, numGenerations, selectionName, experimentNumber, wptIndex)
% Read every saved candidate, independent of population size or branch count.
% populationSize/numGenerations remain accepted for existing callers.
    waypoint = str2double(string(wptIndex));
    folder = fullfile(vesselResultsPathBase,string(selectionName)+"-exNum"+string(experimentNumber));
    info = analysisApproachInfo(selectionName);
    if info.isFullWP
        archived = fullfile(folder,"WptIdx-resultsWpt-"+string(waypoint)+"-population.mat");
        if isfile(archived)
            saved = load(archived,'finalPopulation');
            population = saved.finalPopulation;
            return;
        end
        archived = fullfile(folder,"WptIdx-resultsWpt-"+string(waypoint)+".mat");
        if isfile(archived)
            saved = load(archived,'finalPopulation');
            if isfield(saved,'finalPopulation')
                population = saved.finalPopulation;
                return;
            end
        end
        files = analysisGenerationFiles(folder);
    else
        files = analysisGenerationFiles(folder,waypoint);
    end
    assert(~isempty(files),'Analysis:MissingPopulation','No population data in %s for waypoint %d.',folder,waypoint);
    objs = []; decs = []; cons = [];
    for k = 1:numel(files)
        if info.isFullWP
            saved = load(fullfile(folder,files(k).name),'Population');
        else
            saved = load(fullfile(folder,files(k).name),'Population','objectivesWithoutPrevList');
        end
        decisions = saved.Population.decs;
        scores = saved.Population.objs;
        if info.isFullWP
            pathFile = fullfile(folder,strrep(files(k).name,'-population-','-paths-'));
            data = load(pathFile,'subPathDistanceMatrix','pathMissingFlagsMatrix');
            prefix = waypoint-1;
            nominal = reshape(vesselInformation.initialPoints,vesselInformation.pointDimension,[])';
            proximity = zeros(size(decisions,1),1);
            for j = 1:prefix
                columns = (j-1)*vesselInformation.pointDimension+(1:vesselInformation.pointDimension);
                proximity = proximity + sqrt(sum((decisions(:,columns)-nominal(j,:)).^2,2));
            end
            scores = [-data.subPathDistanceMatrix(prefix,:)', proximity/prefix];
            flags = analysisMissingFlags(data.pathMissingFlagsMatrix,size(decisions,1),vesselInformation.numWaypoints);
            missing = any(flags(:,1:prefix),2);
            scores(missing,1) = -999999999;
            columns = (prefix-1)*vesselInformation.pointDimension+(1:vesselInformation.pointDimension);
            decisions = decisions(:,columns);
        else
            if isfield(saved,'objectivesWithoutPrevList')
                [missing,~] = getIndexesOfMissingPaths(saved.objectivesWithoutPrevList);
                scores(missing,1) = -999999999;
            end
            scores(:,2) = scores(:,2)/(waypoint-1);
        end
        decs = [decs; decisions];
        objs = [objs; scores];
        cons = [cons; saved.Population.cons];
    end
    population = SOLUTION(decs,objs,cons);
end
