import numpy as np
from scipy.signal import correlate, find_peaks


def calculate_number_of_peaks(measurement):
    measurement = np.array(measurement, dtype="float").flatten()
    #print("Updated version called! 2" )
    #neighborhood_size = len(measurement) // 100
    neighborhood_size = int(np.ceil(len(measurement) / 100)) + 1 
    neighborhood_size = neighborhood_size
    #print(neighborhood_size)
    threshold = 0.01

    # Calculate autocorrelation
    #autocorrelation = np.correlate(measurement, measurement, mode='full')
    #autocorrelation = autocorrelation / np.max(autocorrelation)  # Normalize
    autocorrelation = correlate(measurement, measurement, mode='full')
    autocorrelation /= np.max(np.abs(autocorrelation))  # normalize like 'coeff' in MATLAB
    #print(len(autocorrelation))

    # Find peaks with minimum distance
    peaks, _ = find_peaks(autocorrelation,distance=neighborhood_size)

    # Filter peaks above the threshold
    valid_peaks = autocorrelation[peaks][autocorrelation[peaks] > threshold]
    num_peaks = len(valid_peaks) - 1
    num_peaks = max(num_peaks, 0)

    return num_peaks, valid_peaks