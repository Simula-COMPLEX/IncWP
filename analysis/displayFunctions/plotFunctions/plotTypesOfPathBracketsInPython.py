
from scipy.io import loadmat
import os
import numpy as np
import scipy.io
import matplotlib.pyplot as plt
import seaborn as sns
import pandas as pd 

results_path_info = os.path.abspath("ExperimentsResults")
results_path = str(results_path_info)
vesselName = "nspauv"  # Replace with actual vessel name
#vesselName = "mariner"
base_results_path = os.path.join(results_path, vesselName, "AnalysedResults")

wpt_index = "2"  # Must match keys used in MATLAB (likely strings)

# Load the file
classification_file = os.path.join(base_results_path, "ClassificationResults.mat")
mat_data = scipy.io.loadmat(classification_file, squeeze_me=True)

# Extract variables
#distances_ranges = mat_data["distancesRanges"]
#selection_type_classification = mat_data["selectionTypeClassification"]
#selection_type_classification_with_brackets = mat_data["selectionTypeClassificationWithBrackets"]
#experiment_info_map = mat_data["experimentInfoMap"]
#selection_results_distribution_map = mat_data["selectionResultsDistributionMap"]
#results_matrix = mat_data["resultsMatrix"]
#precentage_results_map = mat_data["precentageResultsMap"]
matSelectionNames = mat_data['pySelectionNames']
selectionNames = matSelectionNames
selectionNames = selectionNames[selectionNames != 'FullWP_Timelimited']
selectionNames = selectionNames[selectionNames != 'FullWP-individualLimited']
#selectionNames = [str(name[0]) for name in matSelectionNames[0]]


selectionResultsDistributionStruct = mat_data["selectionResultsDistributionStruct"]
precentageResultsStruct = mat_data["precentageResultsStruct"]

bracketsData = precentageResultsStruct.item()
selectionNamesWaypoints = precentageResultsStruct.dtype.names

bracketsDict = dict(zip(selectionNamesWaypoints, bracketsData))
print(bracketsDict)

if (vesselName == "remus100") or (vesselName == "nspauv"):
    numWaypoints = 7
else:
    numWaypoints = 6


cmap = 'YlGnBu' # 'viridis' plasma' 'inferno' 'magma' 'cividis' 'Blues' 'Greens' 'coolwarm' 'bwr' 'RdBu_r' 'seismic' 'GnBu' 'YlGnBu'

numPlots = len(selectionNames)
numColumns = 3
numRow = (numPlots + numColumns - 1) // numColumns


#axes = [axes] 
labelsClasses = ["% Missing", "% Unstable",  "% Stable"]
rangesClasses = ["Closest", "2nd closest", "3rd closest", "4th closest", "Furthes"]
for wptIndex in range(1, numWaypoints):
    fig, axes = plt.subplots(nrows=numRow, ncols=numColumns, figsize=(numColumns * 5, numRow * 4))
    title = "Waypoint " + str(wptIndex)
    fig.suptitle(title, fontsize=20, y=0.9) # y adjusts vertical position
    # In your plot_multiple_heatmaps function...

    if numPlots > 1:
        axes = axes.flatten()
    
    for selectionNum in range(0,len(selectionNames)):
        keyName = selectionNames[selectionNum] + "_" + str(wptIndex+1)
        selectionBracketsData = bracketsDict[keyName]
        print(selectionBracketsData)
        ax = axes[selectionNum]
        sns.heatmap(selectionBracketsData, ax=ax, cmap=cmap, annot=True, fmt=".3f", xticklabels=labelsClasses, yticklabels=rangesClasses)
        
        # Set the title for the current subplot
        ax.set_title( selectionNames[selectionNum], fontsize=14)

    for i in range(numPlots, len(axes)):
        axes[i].set_visible(False)

    # Adjust the layout to prevent titles and labels from overlapping
    # In your plot_multiple_heatmaps function...
    plt.tight_layout(pad=3.0, rect=[0, 0, 1, 0.96])

    # Display the final figure
    plt.show()

    plotFilename = os.path.join(base_results_path,f"plots/BracketsHeatmap-{wptIndex}")
    plt.savefig(plotFilename, dpi=300, bbox_inches='tight')


