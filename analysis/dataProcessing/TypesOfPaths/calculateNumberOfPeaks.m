function [numPeaks, validPeaks] = calculateNumberOfPeaks(measurement, usePython, peak_analysis)
    if usePython == true

        %if usePython == true
            measurement_py = py.list(measurement);
            %measurement_py = cell2mat(measurement_py);


            result = peak_analysis.calculate_number_of_peaks(measurement_py);

            numPeaks = double(result{1});
            validPeaks = double(result{2})';
        %end
    else 

        neighborhoodSize = floor(length(measurement)/100);
        threshold = 0.01;

        [autocorrelation, ~] = xcorr(measurement, 'coeff');
        [peaks,~] = findpeaks(autocorrelation, 'MinPeakDistance',neighborhoodSize);

        validPeaks = peaks(peaks > threshold);
        numPeaks = length(validPeaks) - 1 ;
        if numPeaks < 0
           numPeaks = 0;
        end
    end
    if  any(validPeaks == 1)
        %numPeaks = numPeaks -1;
        validPeaks = validPeaks(validPeaks ~= 1);
    end





    % if usePython == true
    %     measurement_py = py.list(measurement);
    % 
    % 
    %     result = peak_analysis.calculate_number_of_peaks(measurement_py);
    % 
    %     numPeaksPy = double(result{1});
    %     validPeaksPy = double(result{2})';
    % end
    % 
    % 
    % neighborhoodSize = floor(length(measurement)/100);
    % threshold = 0.01;
    % 
    % [autocorrelation, ~] = xcorr(measurement, 'coeff');
    % [peaks,~] = findpeaks(autocorrelation, 'MinPeakDistance',neighborhoodSize);
    % 
    % validPeaks = peaks(peaks > threshold);
    % numPeaks = length(validPeaks) - 1 ;
    % if numPeaks < 0
    %    numPeaks = 0;
    % end
    % 
    % if numPeaksPy < 10 || numPeaks < 10
    %     if numPeaksPy - numPeaks ~= 0
    %         if numPeaksPy == 0 
    %             numPeaksPy
    %             numPeaks
    %             plot3(path(:,2), path(:,1), path(:,3))
    %             grid
    %             numPeaksPy - numPeaks
    %         elseif numPeaks == 0 
    %             numPeaksPy
    %             numPeaks
    %             plot3(path(:,2), path(:,1), path(:,3))
    %             grid
    %             numPeaksPy - numPeaks
    %         end
    % 
    % 
    % 
    %     elseif length(validPeaksPy) ~= length(validPeaks)
    %         validPeaksPy
    %         validPeaks
    %         length(validPeaksPy)
    %     elseif sum(validPeaksPy - validPeaks) > 1e-5
    %         validPeaksPy
    %         validPeaks
    %         validPeaksPy - validPeaks
    %     end
    % end



   
end