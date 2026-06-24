

import os
import numpy as np
import scipy.io
import matplotlib.pyplot as plt
import seaborn as sns
import pandas as pd 


# Use a stable backend for compatibility with MATLAB
matplotlib.use("TkAgg")

def get_module_path():
    """Prints the absolute path of this Python file."""
    # os.path.abspath(__file__) gets the full path of the current script
    print("The Python script being executed is located at:", os.path.abspath(__file__))
    return os.path.abspath(__file__)



def createBoxplots(input_matrix, selectionNames):
    # Convert the memoryview object to a NumPy array
    np_matrix = np.array(input_matrix, copy=False)
    #selectionNamesPY = np.array(input_matrix, copy=False)
    
    print("Type of the received matrix:", type(np_matrix))
    sys.stdout.flush() # Force flush the output
    
    print("Shape of the matrix:", np_matrix.shape)
    sys.stdout.flush() # Force flush again
    
    #print(np_matrix)
    #sys.stdout.flush()

    print("999")
    sys.stdout.flush()

    print("selectionNames")
    print(selectionNames)
    sys.stdout.flush()

    matrix_array = np.array([
    [10, 12, 11, 15, 9, 13, 14, 12, 10, 11],  # Results for Approach 1
    [15, 17, 16, 19, 18, 20, 15, 16, 17, 18],  # Results for Approach 2
    [5, 6, 4, 7, 8, 5, 6, 7, 5, 6],           # Results for Approach 3
    ])

    

    df = pd.DataFrame(matrix_array.T, columns=['Approach 1', 'Approach 2', 'Approach 3'])

    plt.figure(figsize=(10, 6))
    sns.boxplot(data=df)
    # Add titles and labels for clarity
    plt.title('Performance of Different Approaches', fontsize=16)
    plt.xlabel('Approach', fontsize=12)
    plt.ylabel('Results', fontsize=12)

    # Display the plot
    plt.show()



    # ... your code for plotting
    
    return  "Function executed successfully"

simulated_matrix = np.array([[1, 2, 3], [4, 5, 6], [7, 8, 9]], dtype=np.float64)

#createBoxplotsFunc(simulated_matrix)