## SCC Calculation Notebook

#### Contents: 
- SCC code. This code takes in damage function coefficients estmiated previously, and outputs SCC values. 
- `/Functions/`: this folder contains some FAIR parameters and functions called by the SCC code.  

#### Run Instructions
This code requires a Python 2.7 environment, with certain packages installed. It can be run from inside a conda environment, after creating a conda environment using the following command: 

```
conda create -n scc_env python=2.7 numpy pandas xarray matplotlib seaborn jupyter NetCDF4
conda activate scc_env
jupyter notebook {path_to_this_repo}/energy-scc-code-2020-release.ipynb
```

Then run the jupyter notebook from inside this conda environment. 

You will also need to change the `root` variable so that it points to the location of the energy-code-release-2020 repo on your machine, and the `DB` variable so that it points to the location of the data storage directory.

There are details of the calculations done in this code in Appendix F of the paper, and in comments inside the code itself. 

#### Code options
- This code can be run for any of the three models that we project across all GCMs, and present SCC values for in the paper. Please select the model you wish to run at the tom of this code, by changing the `model`
- These are: 
    * `main`, which can run for SSP2, SSP3, or SSP4. 
    * `lininter` and `lininter_double`, which are run only for SSP3. 
- The `main-SSP3` scenario SCC is calculated for 8 different price scenarios. All other permutations are calculated only for the `price014` price scenario. 
- To chose the SSP to run (for the `main` scenario), edit the `ssp` variable in the first cell. 
- Every scenario can be run with either `hold_2100_damages_fixed= FALSE` (the default and main option used in the paper), or `hold_2100_damages_fixed = TRUE`. Holding 2100 damages fixed means that we fix the shape of the damage function at it's 2100 shape, rather than allow it to evolve using our usual extrapolation approach. See appendix G.2 for more details of this. You can change this option by editing the first cell of the code. 
- There is an option to generate plots that may help users visualise the calculation process. Set `generate_plots = True` in the first cell of the code to produce extra plots using this code (these are not directly used in the paper). 

#### Code inputs
- 


    
