function [fullTypes, incTypes, matches, classificationError] = comparePathTypes(fullAngles, incAngles, fullReached, incReached)
    numberOfSegments = numel(fullReached);
    fullTypes = repmat("not simulated",numberOfSegments,1);
    incTypes = repmat("not simulated",numberOfSegments,1);
    classificationError = "";
    peakAnalysis = [];
    for branch = 1:2
        if branch==1, signals = fullAngles; reached = fullReached;
        else, signals = incAngles; reached = incReached; end
        labels = repmat("not simulated",numberOfSegments,1);
        for k = 1:numberOfSegments
            if isnan(reached(k)), continue; end
            if ~reached(k), labels(k) = "missing"; continue; end
            labels(k) = "unavailable";
            try
                assert(~isempty(signals{k}) && all(isfinite(signals{k}(:))), ...
                    'Classification requires finite angle/state samples.');
                if isempty(peakAnalysis)
                    root = fileparts(fileparts(mfilename('fullpath')));
                    folder = fullfile(root,'analysis');
                    if count(py.sys.path,folder)==0
                        insert(py.sys.path,int32(0),folder);
                    end
                    peakAnalysis = py.importlib.import_module('calculate_number_of_peaks');
                    peakAnalysis = py.importlib.reload(peakAnalysis);
                end
                peaks = zeros(1,size(signals{k},2));
                for channel = 1:numel(peaks)
                    peaks(channel) = calculateNumberOfPeaks(signals{k}(:,channel),true,peakAnalysis);
                end
                labels(k) = "stable";
                if any(peaks>0), labels(k) = "unstable"; end
            catch exception
                classificationError = string(exception.message);
            end
        end
        if branch==1, fullTypes = labels; else, incTypes = labels; end
    end
    valid = ["stable","unstable","missing"];
    available = ismember(fullTypes,valid) & ismember(incTypes,valid);
    matches = NaN(numberOfSegments,1);
    matches(available) = fullTypes(available)==incTypes(available);
end
