function [status, entry] = analysisResultStatus(base, dataset)
% Check for saved dataset metadata; no automatic outdated checks.
    if nargin > 1
        status = isfile(fullfile(base,'results',analysisDatasetName(dataset),'metadata.mat'));
        if nargout > 1, entry = resultEntry(base,analysisDatasetName(dataset)); end
        return;
    end
    datasets = ["classification";"timing";"candidates";"timeLimited";"metrics";"reports"];
    exists = false(size(datasets));
    for k = 1:numel(datasets)
        exists(k) = analysisResultStatus(base,datasets(k));
    end
    status = table(datasets,exists,'VariableNames',{'Dataset','Exists'});
    if nargout == 0, disp(status); end
end

function entry = resultEntry(base,id)
    folder = fullfile(base,'results',id);
    saved = load(fullfile(folder,'metadata.mat'));
    entry = struct('id',char(id),'records',[]);
    if isfield(saved,'records')
        entry.records = saved.records;
        return;
    end
    % Older split results have no file list in metadata.mat.
    files = dir(fullfile(folder,'**','*.mat'));
    records = struct('path',{},'variable',{},'approach',{},'experiment',{},'waypoint',{},'part',{},'bytes',{},'modified',{});
    for k = 1:numel(files)
        relative = extractAfter(string(fullfile(files(k).folder,files(k).name)),strlength(string(folder))+1);
        pieces = split(relative,filesep);
        [~,stem] = fileparts(files(k).name);
        record = struct('path',char(fullfile('results',id,relative)), ...
            'variable','','approach','','experiment',0,'waypoint',0,'part',stem,'bytes',files(k).bytes,'modified',files(k).datenum);
        if relative == "metadata.mat"
            record.variable = 'metadata';
        elseif pieces(1) == "classification" || pieces(1) == "timing"
            record.approach = char(pieces(2));
            record.experiment = sscanf(stem,'experiment-%d');
            record.part = char(pieces(1));
            if pieces(1) == "classification", record.variable = 'selectionTypeClassification';
            else, record.variable = 'selectionTypeTimeStamps'; end
        elseif any(string(id)==["candidates","timeLimited"]) && numel(pieces)==3
            record.variable = 'approachSortedInfoMap';
            record.approach = char(pieces(1));
            record.experiment = sscanf(pieces(2),'experiment-%d');
            record.waypoint = sscanf(stem,'waypoint-%d');
            record.part = 'candidates';
        elseif string(id)=="metrics"
            record.variable = 'metrics';
            if pieces(1)=="comparisons"
                record.waypoint = sscanf(stem,'waypoint-%d');
                record.part = 'comparisons';
            else
                record.approach = char(pieces(1));
                record.waypoint = sscanf(pieces(2),'waypoint-%d');
            end
        elseif string(id)=="reports"
            record.variable = stem;
        else
            continue;
        end
        records(end+1) = record;
    end
    entry.records = records;
end
