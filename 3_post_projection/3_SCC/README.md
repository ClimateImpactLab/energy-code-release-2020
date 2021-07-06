## SCC Calculation Notebook

#### Contents: 
- SCC code. This code takes in damage function coefficients estimated previously, and outputs SCC values. 
- `/functions/`: this folder contains parameters from the FAIR climate model (See Step 5 of Methods) and functions called by the SCC code.  

#### Run Instructions
This code requires a Python 2.7 environment, with certain packages installed. It can be run from inside a conda environment, after creating a conda environment using the following commands: 

```
conda create -n scc_env python=2.7 numpy pandas xarray matplotlib seaborn jupyter NetCDF4
conda activate scc_env
jupyter notebook {path_to_this_repo}/energy-scc-code-2020-release.ipynb
```

You will also need to change the `root` variable so that it points to the location of the energy-code-release-2020 repo on your machine, and the `DB` variable so that it points to the location of the data storage directory.

Details of the calculations done in this code can be found in Appendix Section F, and in comments inside the code itself. 

#### Code options
- This code can be run for any of the three econometric models for which we project impacts under all 33 climate projections in the SMME and for which we present SCC values in the paper. Please select the model you wish to run at the top of this code, by changing the `model` variable in the first cell of the code.
- These are defined as in the readme for `3_post_projection`: 
    * `main`, which can run for SSP2, SSP3, or SSP4. 
    * `lininter` and `lininter_double`,`lininter_half`, which are run only for SSP3. 
- The `main-SSP3` SCC is calculated for 8 different price scenarios (Appendix Section D). All other permutations are calculated only for the `price014` price scenario (i.e. 1.4% annual price growth). 
- To choose the SSP to run (for the `main` model), edit the `ssp` variable in the first cell. 
- Every model x scenario can be run with either `hold_2100_damages_fixed= FALSE` (the default and main option used in the paper), or `hold_2100_damages_fixed = TRUE`. Holding 2100 damages fixed means that we fix the post-2100 damage functions to be the same as the end-of-century damage function (See Appendix Section G.2), rather than allow them to evolve using our usual extrapolation approach (See Appendix Section E). You can change this option by editing the first cell of the code. 
- There is an option to generate plots that may help users visualise the calculation process. Set `generate_plots = True` in the first cell of the code to produce extra plots using this code (these are not directly used in the paper). 

#### Code inputs
- Damage function coefficients, which are stored in: `code_release_data_pixel_interaction/projection_system_outputs/damage_function_estimation/`.

#### Code outputs
- The output of this code are csv files containing SCC values for different scenarios. These csv files are manually processed into the latex tables shown in the paper. 
- The output csvs from this code allow users to look at values for other RCPs than are discussed in the paper, and for a broader range of discount rates. They also include a breakdown of the damages by whether they are incurred pre or post 2100. 
   - To see the values relevant to the paper, filter the output csv files such that `time_cut = all`, `discrate` is in the set (2.5,3,5), and only consider the columns `rcp45` and `rcp85`. 
- This code generates values used in:
   - ***Figure 4E***. These central estimates are outputted to `/figures/scc_values/main/scc_energy_SSP3_all_prices_2100-fixed-False.csv`.
   - ***Table Appendix F.2***. The central estimates in this table are taken from `/figures/scc_values/main/scc_energy_SSP3_all_prices_2100-fixed-False.csv`.
   - ***Table Appendix G.1***. The central estimates in this table are taken from `/figures/scc_values/main/scc_energy_SSP3_all_prices_2100-fixed-False.csv`.
   - ***Table Appendix G.2***. The values in this table are taken from `/figures/scc_values/main/scc_energy_SSP3_all_prices_2100-fixed-True.csv`.
   - ***Table Appendix G.3***. The values in this table are taken from the following three csvs: 
      - `/figures/scc_values/main/scc_energy_SSP2_all_prices_2100-fixed-False.csv`
      - `/figures/scc_values/main/scc_energy_SSP3_all_prices_2100-fixed-False.csv`
      - `/figures/scc_values/main/scc_energy_SSP4_all_prices_2100-fixed-False.csv`
   - ***Table Appendix I.1***. The values in this table are taken from the following three csvs. 
      - `/figures/scc_values/main/scc_energy_SSP3_all_prices_2100-fixed-False.csv`
      - `/figures/scc_values/lininter/scc_energy_SSP3_all_prices_2100-fixed-False.csv`
      - `/figures/scc_values/lininter_double/scc_energy_SSP3_all_prices_2100-fixed-False.csv`
      - `/figures/scc_values/lininter_half/scc_energy_SSP3_all_prices_2100-fixed-False.csv`
    
