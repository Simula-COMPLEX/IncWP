import os
import numpy as np
import scipy.io
import matplotlib.pyplot as plt
import seaborn as sns
import pandas as pd 

# Load paths
results_path_info = os.path.abspath("ExperimentsResults")
results_path = str(results_path_info)
vesselName = "mariner"  # Replace with actual vessel name
#vesselName = "mariner"
base_results_path = os.path.join(results_path, vesselName, "AnalysedResults")

resultsPath = os.path.join(os.getcwd(), "ExperimentsResults")
baseResultsPath = os.path.join(resultsPath, vesselName, "AnalysedResults")


if (vesselName == "remus100") or (vesselName == "nspauv"):
    numWaypoints = 7
else:
    numWaypoints = 6
    


for wptIndex in range(2, numWaypoints + 1):
    final_filename = f"HVresults-wpt{wptIndex}.mat"
    full_path_to_file = os.path.join(baseResultsPath, final_filename)
    print(f"Attempting to load file from: {full_path_to_file}")



    mat_data = scipy.io.loadmat(full_path_to_file)
    HVmatrix = mat_data['HVmatrix']
    matSelectionNames = mat_data['pySelectionNames']

    selectionNames = [str(name[0]) for name in matSelectionNames[0]]

    print(HVmatrix )
    print("\nSuccessfully loaded 'HVmatrix'.")
    print(np.shape(HVmatrix))
    print(selectionNames)
t
    #fig, ax = plt.subplots()
    sns.set_style("whitegrid") #darkgrid whitegrid
    #plt.figure(figsize=(14,10))
    fig, ax = plt.subplots(figsize=(14,10))
    dfHVmatrix = pd.DataFrame(data=HVmatrix.T, columns=selectionNames)
    pallet = "pastel" # pastel Set1 Set2 Set3 

    colors = sns.color_palette(pallet,n_colors=len(dfHVmatrix.columns))
    darker_colors = [sns.saturate(c) for c in colors]

    bplot = ax.boxplot(dfHVmatrix.values,patch_artist=True, labels=dfHVmatrix.columns)

    for i, color in enumerate(colors):
    # Box Style
        bplot['boxes'][i].set_facecolor((*color, 0.85)) # Less transparent (alpha=0.8)
        bplot['boxes'][i].set_edgecolor(darker_colors[i])
        bplot['boxes'][i].set_linewidth(1.5)
        
        # Median Line Style
        bplot['medians'][i].set_color(darker_colors[i])
        bplot['medians'][i].set_linewidth(2)
        
        # Whisker and Cap Style (the 25% and 75% markers)
        bplot['whiskers'][i*2].set_color(darker_colors[i])
        bplot['whiskers'][i*2 + 1].set_color(darker_colors[i])
        bplot['caps'][i*2].set_color(darker_colors[i])
        bplot['caps'][i*2 + 1].set_color(darker_colors[i])
        
        # Outlier Style
        bplot['fliers'][i].set_markerfacecolor(darker_colors[i])
        bplot['fliers'][i].set_markeredgecolor(darker_colors[i])
        bplot['fliers'][i].set_marker('D') # 'D' for diamond marker

    # --- 5. Optional: Style the median line for better visibility ---
    #for median in bplot['medians']:
    #    median.set(color='black', linewidth=2)

    for median, color in zip(bplot['medians'], colors):
    # Make the color more intense (darker/richer)
        darker_color = sns.saturate(color)
        median.set(color=darker_color, linewidth=2)

    #sns.boxplot(data=dfHVmatrix, palette="Set3", notch=True) # Set3 Pastel, "viridis" 
    #sns.boxplot(data=dfHVmatrix, palette="PRGn") #, hue="sex") # Set3 Pastel, "viridis" 
    #sns.swarmplot(data=dfHVmatrix, color=".25", size=4)

    
    #bp = ax.boxplot(HVmatrix.T)

    plt.title(f"Hypervolume for waypoint number {wptIndex}",fontsize=16)
    plt.xlabel("Approach", fontsize=16)
    plt.ylabel("Hypervolume score", fontsize=16)

    plt.xticks(rotation=45, ha='right') # if they overlap
    plt.tight_layout()

    plotFilename = os.path.join(baseResultsPath,f"plots/HVforWP-{wptIndex}")
    plt.savefig(plotFilename,dpi=300)

    # 4. Show the plot
    plt.show()



'''

# Load .mat file
# %hv_results_path = os.path.join(base_results_path, "HVresults.mat")
# mat_data = scipy.io.loadmat(hv_results_path)
#rint(mat_data)
#print(type(mat_data))
#HVresultsMap = mat_data["HVresultsMap"]
#referencePointMap = mat_data["referencePointMap"]
#combinedPopulation = mat_data["combinedPopulation"]
#comperisationResults = mat_data["comperisationResults"]
#experimentInfoMap = mat_data["experimentInfoMap"]

# Convert MATLAB struct to usable dict if needed
#selection_names = [str(k[0]) for k in experimentInfoMap.dtype.names]

# vesselInformation assumed to be from a function or struct — replace this
# vesselInformation = loadShipSearchParameters(vessel_name)
num_waypoints = 5  # Replace with vesselInformation.numWaypoints

for wpt_index in range(2, num_waypoints + 2):
    hv_results_path_wpt = base_results_path+ "/HVresults-wptIndex-" +str(wpt_index)
    mat_data = scipy.io.loadmat(hv_results_path_wpt)
    print(mat_data)
    HVmatrix = mat_data["HVmatrix"]
    print(HVmatrix)    
    selectionNames = mat_data["selectionNames"]
    selectionNames = [str(s[0]) for s in selectionNames.flatten()]

    print(selectionNames)
    #wp_key = str(wpt_index)
    #HVmatrix = HVresultsMap[wp_key] if isinstance(HVresultsMap, dict) else HVresultsMap[wp_key]  # Adjust access as needed

    plt.figure(figsize=(15, 10))
    plt.boxplot(HVmatrix.T, whis=1.5)
    plt.title(f"WPindex {wpt_index}")
    plt.xticks(ticks=range(1, len(selectionNames) + 1), labels=selectionNames, fontsize=18)

    
    

    plt.tick_params(axis='x', labelsize=18)
    plt.gca().tick_params(labelsize=18)
    
    # Save figure
    file_name = os.path.join(base_results_path, f"boxPlot-WPindex-{wpt_index}.png")
    plt.savefig(file_name, dpi=300, bbox_inches='tight')
    plt.close()

    '''