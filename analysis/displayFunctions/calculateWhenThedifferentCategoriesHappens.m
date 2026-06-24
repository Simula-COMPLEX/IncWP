function calculateWhenThedifferentCategoriesHappens(vesselName)

    vesselInformation = loadShipSearchParameters(vesselName);

    resultsPathInfo = what("ExperimentsResults");
    resultsPath = char(resultsPathInfo.path);
    baseResultsPath = append(resultsPath,"/", vesselName, "/AnalysedResults/");
    % Time usage
    display("Currently looking at time usage")

    timeUsageResultsPath =  append(baseResultsPath,"TimeusageResults");
    load(timeUsageResultsPath, "selectionTypeTimeStamps","experimentInfoMap");
    
    ClassresultsPath = append(baseResultsPath,"ClassificationResults");
    load(ClassresultsPath, "distancesRanges", "selectionTypeClassification", "selectionTypeClassificationWithBrackets", "experimentInfoMap", "selectionResultsDistributionMap", "resultsMatrix", "precentageResultsMap");
    selectionTimeStampAndClassMap = containers.Map();

    dataInfo = struct();
    

    for selectionType = selectionTypeTimeStamps.keys()
        selectionType = selectionType{1};
        selectionTimestamps = selectionTypeTimeStamps(selectionType);
        selectionClassification = selectionTypeClassification(selectionType);
        experimentTimestampAndClassMap = containers.Map();
        dataInfo.(selectionType) = string(selectionTimestamps.keys());
        
        for experimentNumber = selectionTimestamps.keys()
            experimentNumber = experimentNumber{1};
            experimentTimestamp = selectionTimestamps(experimentNumber);
            experimentClassification = selectionClassification(experimentNumber);
            classesMap = experimentClassification('classes');
             

            wayPointTimestampAndClassMap = containers.Map;
            if selectionType == "FullWP"
                experimentTimestamp = experimentTimestamp;
                wayPointIdx = classesMap.keys()
                wayPointIdx = wayPointIdx(end);
                %for wayPointIdx = classesMap.keys()
                wayPointIdx = wayPointIdx{1}
                wayPointClassifcation = classesMap(wayPointIdx);
                %waypointTimestamps = experimentTimestamp(wayPointIdx);
                wayppointTimestampList = experimentTimestamp %waypointTimestamps(:);
                % we need the categorize 
                wayPointTimestampAndClassMap(wayPointIdx) = containers.Map({'classification' 'timestamp'},{wayPointClassifcation, wayppointTimestampList})
   
                %end
            else 
             
                for wayPointIdx = experimentTimestamp.keys()
                    wayPointIdx = wayPointIdx{1}

                    waypointTimestamps = experimentTimestamp(wayPointIdx);
                    wayppointTimestampList = waypointTimestamps(:);
                    wayPointClassifcation = classesMap(wayPointIdx);
                    % we need the categorize 
                    wayPointTimestampAndClassMap(wayPointIdx) = containers.Map({'classification' 'timestamp'},{wayPointClassifcation, wayppointTimestampList})
                end
            end
            experimentTimestampAndClassMap(experimentNumber) = wayPointTimestampAndClassMap;

        end
        selectionTimeStampAndClassMap(selectionType) = experimentTimestampAndClassMap;
    end
    selectionTimeStampAndClassStruct = convert_matlab_to_python_format(selectionTimeStampAndClassMap)
    dataInfo.("numberOfWayponts") = wayPointIdx;
    

    classesAndTimeFileLocation = append(baseResultsPath, "/classesAndTimestamps.mat")
    save(classesAndTimeFileLocation, "selectionTimeStampAndClassMap", "selectionTimeStampAndClassStruct","selectionTypeTimeStamps","experimentInfoMap", "selectionTypeClassification", "dataInfo");
end

function flattened_data = convert_matlab_to_python_format(selectionTimeStampAndClassMap)
    % CONVERT_MATLAB_TO_PYTHON_FORMAT Flattens a nested containers.Map and saves it.
    %
    %   This function takes a 3-level nested containers.Map and flattens it 
    %   into a single-level struct suitable for loading in Python.
    %
    %   Args:
    %       nested_data (containers.Map): The nested MATLAB map to process.
    %       output_filename (char): The name of the .mat file to save (e.g., 'data.mat').
    %
    %   Returns:
    %       flattened_data (struct): The new, single-level struct.

    fprintf('Flattening the data structure...\n');
    flattened_data = struct();
    % Get top-level keys (your 'selectionNames') using keys() instead of fieldnames()

    for selectionType = selectionTimeStampAndClassMap.keys()
        selectionType = selectionType{1};
        
        % Access map data using parentheses: map(key)
        selectiontMap = selectionTimeStampAndClassMap(selectionType);
        
        

        for experimentNumber = selectiontMap.keys()
            experimentNumber = experimentNumber{1};

            experimentMap = selectiontMap(experimentNumber);

            

            for wayPointIdx = experimentMap.keys()
                wayPointIdx = wayPointIdx{1};
                waypointMap = experimentMap(wayPointIdx);
                
                
                

                % --- Construct the new, flattened field names ---
                % Convert numeric keys to strings for creating the field name
                expNum_str = append(experimentNumber);
                wpIndex_str = append(wayPointIdx);

                newName_classification = append(selectionType, '_', expNum_str, '_', wpIndex_str, '_classification');
                newName_timestamps = append(selectionType, '_', expNum_str, '_', wpIndex_str, '_timestamp');
                
                flattened_data.(newName_classification) = waypointMap('classification');
                flattened_data.(newName_timestamps) = waypointMap('timestamp');
                
            end
        end
    end
end
