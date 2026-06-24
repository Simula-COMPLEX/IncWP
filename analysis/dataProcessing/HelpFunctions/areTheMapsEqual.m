function mapsEqual= areTheMapsEqual(prevExperimentInfoMap, experimentInfoMap)
        mapsEqual = true;
        prevSelectionNames = prevExperimentInfoMap.keys;
        selectionNames= experimentInfoMap.keys;
    
        if length(prevSelectionNames) ~= length(selectionNames)
            mapsEqual = false;
            return
        
        end

        if mapsEqual
            selectionIndex = 1;
            while selectionIndex < length(selectionNames) && mapsEqual == true


                if ~isequal(selectionNames(selectionIndex),prevSelectionNames(selectionIndex))
                    mapsEqual = false;
                    return
                end

                type = selectionNames(selectionIndex);
                type = type{1};
                prevExperimentsNum = prevExperimentInfoMap(type);
                experimentNums = experimentInfoMap(type);
                if ~isequal(prevExperimentsNum,experimentNums)
                    mapsEqual = false;
                    return
                end
                selectionIndex = selectionIndex + 1;
            end
        end
    end