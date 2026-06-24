function [missingPathsFlag, nonMissingPathsFlag] = getIndexesOfMissingPaths(currentObjectives)
    %maxValueCONST = 999999999;
    %nonMissingPathsFlag =  abs(prevObjectives(:,1)) ~= maxValueCONST; 
    %missingPathsFlag =  abs(prevObjectives(:,1)) == maxValueCONST; 

    %missingPathsFlag = abs(prevObjectives(:,1)) > 1.0e+08;
    missingPathsFlag = abs(currentObjectives(:,1)) > 1.0e+08;
    %missingPathsFlag = missingPathsFlag || abs(currentObjectives(:,1)) > 1.0e+08;
    nonMissingPathsFlag = ~missingPathsFlag;
end