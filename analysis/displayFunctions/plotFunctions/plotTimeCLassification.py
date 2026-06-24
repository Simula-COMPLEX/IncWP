
from scipy.io import loadmat
import os
import numpy as np
import scipy.io
import matplotlib.pyplot as plt
import seaborn as sns
import pandas as pd 


results_path_info = os.path.abspath("ExperimentsResults")
results_path = str(results_path_info)
vesselName = "remus100"  # Replace with actual vessel name
#vesselName = "mariner"
base_results_path = os.path.join(results_path, vesselName, "AnalysedResults")

wpt_index = "2"  # Must match keys used in MATLAB (likely strings)

# Load the file
classification_file = os.path.join(base_results_path, "classesAndTimestamps.mat")
mat_data = scipy.io.loadmat(classification_file, squeeze_me=True)

#print(mat_data)

selectionTimeStampAndClassStruct = mat_data["selectionTimeStampAndClassStruct"]
#dataInfo = mat_data["dataInfo"]

#print(dataInfo)

print(selectionTimeStampAndClassStruct)

#(classesAndTimeFileLocation, "selectionTimeStampAndClassMap", "selectionTimeStampAndClassStruct","selectionTypeTimeStamps","experimentInfoMap", "selectionTypeClassification", "dataInfo");

#classesAndTimeFileLocation, "selectionTimeStampAndClassMap", "selectionTimeStampAndClassStruct","selectionTypeTimeStamps","experimentInfoMap", "selectionTypeClassification");



