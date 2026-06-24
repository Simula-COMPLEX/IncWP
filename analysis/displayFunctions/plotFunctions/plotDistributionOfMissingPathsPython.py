import os
import numpy as np
import matplotlib.pyplot as plt
from scipy.io import loadmat, savemat

from oct2py import Oct2Py

oc  = Oct2Py()

def plot_distribution_of_missing_paths(vessel_name, on_server):
    experiment_info_map = oc.loadExperimentsStatus(vessel_name)

    # Paths
    results_path_info = os.path.join("ExperimentsResults")  # You may need to replace this with `what()` equivalent
    results_path = os.path.abspath(results_path_info)
    base_results_path = os.path.join(results_path, vessel_name, "AnalysedResults")
    vessel_results_base = os.path.join(results_path, vessel_name)

    print("Currently looking at missing distribution")

    # Constants
    population_size = 10
    num_generations = 1000
    use_time_restricted = True
    colors = ['g', 'b', 'r', 'k', 'y', 'm']

    # Load vessel info
    vessel_info = oc.loadShipSearchParameters(vessel_name)
    selection_names = list(experiment_info_map.keys())

    # Determine whether to plot
    plot_figure = not on_server
    plot_figure = True  # Force True, as in MATLAB code

    for wpt_index in range(2, vessel_info['numWaypoints'] + 2):  # MATLAB 1-based to Python 0-based
        for selection_index, selection_type in enumerate(selection_names):
            filename_data = os.path.join(
                base_results_path,
                f"missingVSnotMissingPoint-approach-{selection_type}-WPindex-{wpt_index}matrix.mat"
            )

            if plot_figure:
                # Load existing .mat data
                data = loadmat(filename_data, squeeze_me=True)
                ex_decs_missing = data['exDecsMissing']
                ex_decs_non_missing = data['exDecsNonMissing']

                fig = plt.figure(figsize=(15, 10))
                if vessel_info['pointDimension'] == 2:
                    plt.plot(ex_decs_missing[:, 0], ex_decs_missing[:, 1], colors[selection_index] + 'o')
                    plt.plot(ex_decs_non_missing[:, 0], ex_decs_non_missing[:, 1], colors[selection_index] + 'x')
                else:
                    ax = fig.add_subplot(111, projection='3d')
                    ax.scatter(ex_decs_missing[:, 2], ex_decs_missing[:, 0], ex_decs_missing[:, 1], c='r', marker='o')
                    ax.scatter(ex_decs_non_missing[:, 2], ex_decs_non_missing[:, 0], ex_decs_non_missing[:, 1], c='g', marker='x')

                plt.title(f"Missing points for approach {selection_type} at WP {wpt_index} "
                          f"({ex_decs_missing.shape[0]} missing, {ex_decs_non_missing.shape[0]} not missing)")
                output_fig = os.path.join(
                    base_results_path,
                    f"missingVSnotMissingPoint-approach-{selection_type}-WPindex-{wpt_index}.png"
                )
                plt.savefig(output_fig, dpi=300, bbox_inches='tight')
                plt.close()
            else:
                # Recreate data by loading population from experiments
                experiment_list = experiment_info_map[selection_type]
                ex_decs_missing = []
                ex_decs_non_missing = []

                for experiment_num in experiment_list:
                    population = oc.get_population(
                        vessel_info, vessel_results_base,
                        population_size, num_generations,
                        selection_type, experiment_num,
                        wpt_index, use_time_restricted
                    )
                    ex_decs = population["decs"]
                    ex_objs = population["objs"]

                    missing_flags, non_missing_flags = get_indexes_of_missing_paths(ex_objs)

                    ex_decs_missing.append(ex_decs[missing_flags])
                    ex_decs_non_missing.append(ex_decs[non_missing_flags])

                ex_decs_missing = np.vstack(ex_decs_missing)
                ex_decs_non_missing = np.vstack(ex_decs_non_missing)

                savemat(filename_data, {
                    "exDecsMissing": ex_decs_missing,
                    "exDecsNonMissing": ex_decs_non_missing
                })
