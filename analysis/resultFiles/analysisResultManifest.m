function manifest = analysisResultManifest(base, action, varargin)
% Internal manifest management. Public entry points are load/save/status helpers.
    base = char(base);
    filename = fullfile(base,'analysis-manifest.json');
    manifest = readManifest(filename);
    switch string(action)
        case "read"
            return;
        case "configure"
            manifest.configuration.sourceFolder = char(varargin{1});
            manifest.configuration.timeLimitPolicy = char(varargin{2});
            manifest = refresh(manifest,base);
        case "refresh"
            manifest = refresh(manifest,base);
        case "begin"
            id = char(varargin{1});
            index = findEntry(manifest,id);
            if isempty(index)
                entry = emptyEntry(); entry.id = id;
                manifest.datasets(end+1) = entry;
                index = numel(manifest.datasets);
            end
            manifest.datasets(index).status = 'building';
            manifest.datasets(index).reason = 'Update in progress or interrupted; rebuild this dataset.';
            manifest = invalidateDependents(manifest,id);
        case "finish"
            id = char(varargin{1}); records = varargin{2};
            index = findEntry(manifest,id);
            assert(~isempty(index),'Analysis:ManifestState','Dataset must begin before it can finish.');
            entry = manifest.datasets(index);
            entry.records = records;
            entry.revision = char(java.util.UUID.randomUUID());
            entry.updatedAt = char(datetime('now','TimeZone','UTC','Format',"yyyy-MM-dd'T'HH:mm:ss'Z'"));
            entry.sourceStamp = sourceStamp(manifest.configuration.sourceFolder);
            entry.codeStamp = codeStamp();
            entry.policy = policyFor(id,manifest.configuration.timeLimitPolicy);
            dependencies = dependencyNames(id,manifest.configuration.timeLimitPolicy);
            entry.dependencies = struct('id',{},'revision',{});
            for dependency = dependencies
                parent = findEntry(manifest,dependency);
                assert(~isempty(parent) && strcmp(manifest.datasets(parent).status,'current'), ...
                    'Analysis:OutdatedDependency','Build current %s results before saving %s.',dependency,id);
                entry.dependencies(end+1) = struct('id',char(dependency),'revision',manifest.datasets(parent).revision);
            end
            entry.status = 'current'; entry.reason = '';
            manifest.datasets(index) = entry;
        case "invalidate"
            id = char(varargin{1}); reason = char(varargin{2});
            index = findEntry(manifest,id);
            assert(~isempty(index),'Analysis:MissingResults','No dataset %s has been saved.',id);
            manifest.datasets(index).status = 'outdated';
            manifest.datasets(index).reason = reason;
            manifest = invalidateDependents(manifest,id);
        otherwise
            error('Analysis:ManifestAction','Unknown manifest action: %s',action);
    end
    if ~isfolder(base), mkdir(base); end
    pending = [tempname(base),'.json'];
    fid = fopen(pending,'w');
    assert(fid>=0,'Analysis:ManifestWrite','Cannot write manifest in %s.',base);
    cleanup = onCleanup(@() fclose(fid));
    fprintf(fid,'%s\n',jsonencode(manifest,'PrettyPrint',true));
    clear cleanup
    [ok,message] = movefile(pending,filename,'f');
    assert(ok,'Analysis:ManifestWrite','%s',message);
end

function manifest = readManifest(filename)
    manifest = struct('schemaVersion',1,'configuration',struct('sourceFolder','','timeLimitPolicy','none'), ...
        'datasets',repmat(emptyEntry(),0,1));
    if ~isfile(filename), return; end
    manifest = jsondecode(fileread(filename));
    assert(manifest.schemaVersion==1,'Analysis:ManifestVersion','Unsupported analysis manifest version.');
    if isempty(manifest.datasets), manifest.datasets = repmat(emptyEntry(),0,1); end
    for k = 1:numel(manifest.datasets)
        if isempty(manifest.datasets(k).dependencies)
            manifest.datasets(k).dependencies = struct('id',{},'revision',{});
        end
        if isempty(manifest.datasets(k).records)
            manifest.datasets(k).records = emptyRecords();
        end
    end
end

function entry = emptyEntry()
    entry = struct('id','','status','outdated','reason','Not calculated.','revision','', ...
        'updatedAt','','sourceStamp','','codeStamp','','policy','', ...
        'dependencies',struct('id',{},'revision',{}),'records',emptyRecords());
end

function records = emptyRecords()
    records = struct('path',{},'variable',{},'approach',{},'experiment',{},'waypoint',{}, ...
        'part',{},'bytes',{},'modified',{});
end

function index = findEntry(manifest,id)
    index = find(strcmp({manifest.datasets.id},char(id)),1);
end

function manifest = refresh(manifest,base)
    if isempty(manifest.datasets), return; end
    source = sourceStamp(manifest.configuration.sourceFolder);
    code = codeStamp();
    for k = 1:numel(manifest.datasets)
        entry = manifest.datasets(k);
        if ~strcmp(entry.status,'current'), continue; end
        reason = '';
        if ~strcmp(entry.sourceStamp,source)
            reason = 'Experiment input files were added, removed or changed.';
        elseif ~strcmp(entry.codeStamp,code)
            reason = 'Analysis code changed.';
        elseif ~strcmp(entry.policy,policyFor(entry.id,manifest.configuration.timeLimitPolicy))
            reason = 'Time-limit policy changed.';
        else
            for r = 1:numel(entry.records)
                record = entry.records(r); file = dir(fullfile(base,record.path));
                if isempty(file) || file.bytes~=record.bytes || file.datenum~=record.modified
                    reason = ['Result file missing or changed: ',record.path];
                    break;
                end
            end
        end
        if ~isempty(reason)
            manifest.datasets(k).status = 'outdated'; manifest.datasets(k).reason = reason;
        end
    end
    % Iterate to propagate changes through the complete dependency graph.
    for pass = 1:numel(manifest.datasets)
        for k = 1:numel(manifest.datasets)
            if ~strcmp(manifest.datasets(k).status,'current'), continue; end
            for dependency = reshape(manifest.datasets(k).dependencies,1,[])
                parent = findEntry(manifest,dependency.id);
                if isempty(parent) || ~strcmp(manifest.datasets(parent).status,'current') || ...
                        ~strcmp(dependency.revision,manifest.datasets(parent).revision)
                    manifest.datasets(k).status = 'outdated';
                    manifest.datasets(k).reason = ['Dependency outdated or replaced: ',dependency.id];
                    break;
                end
            end
        end
    end
end

function manifest = invalidateDependents(manifest,id)
    pending = string(id);
    while ~isempty(pending)
        parent = pending(1); pending(1) = [];
        for k = 1:numel(manifest.datasets)
            if any(strcmp({manifest.datasets(k).dependencies.id},parent)) && strcmp(manifest.datasets(k).status,'current')
                manifest.datasets(k).status = 'outdated';
                manifest.datasets(k).reason = ['Dependency updated: ',char(parent)];
                pending(end+1) = string(manifest.datasets(k).id);
            end
        end
    end
end

function names = dependencyNames(id,policy)
    switch string(id)
        case {"classification","timing"}, names = strings(1,0);
        case "candidates", names = ["classification","timing"];
        case "timeLimited", names = ["classification","timing","candidates"];
        case "metrics"
            names = "candidates";
            if string(policy)~="none", names(end+1) = "timeLimited"; end
        case "reports", names = "metrics";
        otherwise, error('Analysis:Dataset','Unknown dataset: %s',id);
    end
end

function policy = policyFor(id,configured)
    policy = '';
    if any(string(id)==["timeLimited","metrics","reports"]), policy = char(configured); end
end

function stamp = sourceStamp(folder)
    if isempty(folder), stamp = 'unconfigured'; return; end
    if ~isfolder(folder), stamp = 'missing-source-folder'; return; end
    % Hash file inventory metadata, not gigabytes of simulation contents.
    % Include classification caches: changing a supplied classification is an input change.
    files = dir(fullfile(folder,'**','*.mat'));
    lines = strings(0,1);
    for k = 1:numel(files)
        full = fullfile(files(k).folder,files(k).name);
        relative = extractAfter(string(full),strlength(string(folder))+1);
        if contains(lower(relative),'validation') || startsWith(files(k).name,'.'), continue; end
        lines(end+1,1) = string(sprintf('%s|%d|%.17g',relative,files(k).bytes,files(k).datenum));
    end
    stamp = hashText(strjoin(sort(lines),newline));
end

function stamp = codeStamp()
    root = fileparts(fileparts(fileparts(mfilename('fullpath'))));
    files = [dir(fullfile(root,'analysis','**','*.m')); dir(fullfile(root,'analysis','*.py')); ...
        dir(fullfile(root,'scripts','**','*.m'))];
    [~,order] = sort(string(fullfile({files.folder},{files.name}))); files = files(order);
    text = strings(0,1);
    for k = 1:numel(files)
        filename = fullfile(files(k).folder,files(k).name);
        if contains(filename,[filesep,'tests',filesep]), continue; end
        text(end+1,1) = string(filename)+newline+string(fileread(filename));
    end
    stamp = hashText(strjoin(text,newline));
end

function result = hashText(text)
    digest = java.security.MessageDigest.getInstance('SHA-256');
    digest.update(typecast(unicode2native(char(text),'UTF-8'),'int8'));
    result = lower(reshape(dec2hex(typecast(digest.digest(),'uint8'),2)',1,[]));
end
