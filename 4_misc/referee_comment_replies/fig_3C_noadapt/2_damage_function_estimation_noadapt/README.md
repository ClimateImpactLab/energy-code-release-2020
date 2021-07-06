## Post projection analysis

### Overview
- Codes in this folder estimate and plot damage functions from our projection system outputs. 
- To run codes in this directory:
  - change the `DB_data` variable at the top of each code to point to the location of the external data repository that contains our projection system outputs
  - change the `root` variable to point to the location of the `energy-code-release-2020` repo on your machine.  
- The purpose of the codes in this folder is to convert our impacts projections into empirical damage functions, and to estimate quantile regressions that will allow us to calculate uncertainty ranges for the partial SCC.

### Guide to data used in this process
- The input data to damage function estimation is housed in an external directory, under `code_release_data_pixel_interaction/projection_system_outputs/damage_function_estimation/`. 
- Raw projection system outputs are contained in `code_release_data_pixel_interaction/projection_system_outputs/damage_function_estimation/impact_values/`
- These files contain data on global projected impacts due to climate change under each of the 33 climate projections in the SMME, for each RCP, population/GDP scenario, and price scenario in every year. Data are arranged in a "long" format.
- The naming scheme for files in `impact_values` is as follows: 
  - `gcm_{damages_or_impacts}_OTHERIND_{fuel}_{price_scenario}_{ssp}{model_tag}.csv`, where: 
    - `damages_or_impacts` is damages if the units are dollars, and impacts if the units are GJ.
    - `fuel` is either electricity, other_energy, or total_energy.
    - `price_scenario` is one of the pricing scenarios we apply to our projected impacts to convert them into dollars. See Appendix Section D for more information. 
    - `ssp` is the Shared Socioeconomic Pathway scenario used in the projection to define our income and population covariates. We include some projection results for SSP2, SSP3, and SSP4 in this code release. 
    - `model_tag` refers to the econometric specification. If this is blank, then we are refering to the main model described in the main text of the paper. Other options are `lininter` (which includes a linear time interaction, as detailed in Appendix Section I.3) and `lininter_double`, `lininter_half` (which deterministically doubles or halves the time trend estimated in the `lininter` model as detailed in Appendix Section I.3).
- We also use Global Mean Surface Temperature (GMST) anomaly data that contains warming relative to the average GMST over 2001-2010 under each of the 33 climate projections in the SMME. These data are contained in: 
  - `code_release_data_pixel_interaction/projection_system_outputs/damage_function_estimation/GMTanom_all_temp_2001_2010_smooth.csv`

## Contents

### `1_take_draws.R`
- This code takes in means and variances in projected impacts under each of the 33 climate projections in the SMME, for a given RCP-population/GDP scenario-year-price_scenario combination, and takes random draws from these Gaussian distributions. We use these random draws for plotting purposes, and for running quantile regressions of damages on GMST anomaly. (See Methods and Appendix Section E.) 
- Note, since we only run uncertainty calculations on our main-model, and for SSP3, we only take draws for this projection type and socioeconomic scenario. 
- Code inputs:
  - `code_release_data_pixel_interaction/projection_system_outputs/damage_function_estimation/impact_values/*`
- Code outputs:
  - `code_release_data_pixel_interaction/projection_system_outputs/damage_function_estimation/resampled_data/*`

### `2_plot_damage_function_fig_3.do`
- This code plots a visualisation of our empirical damage functions in the year 2099 as seen in Figure 3C.
- It also plots density functions of the GMST anomolies at end of century.
- Code inputs:
  - `code_release_data_pixel_interaction/projection_system_outputs/damage_function_estimation/impact_values/*`
- Code outputs:
  - `fig_3/fig_3C_damage_function_*_2099_SSP3.pdf`
 
### `3_run_damage_functions.do`
- This code estimates damage functions for each price scenario x model x SSP combination for which we present an SCC in the paper. 
- To choose which scenarios to run, you can change the `ssp` and `model` locals at the top of the code. Note, only the main model can be run for scenarios other than SSP3.
- The damage function is estimated for all eight of our price scenarios for the main model under SSP3. For other scenarios, we estimate a damage function only for the `price014` scenario (1.4% annual price growth, See Appendix Section D.1).
- Details of this damage function estimation can be found in Step 4 of the Methods section of the paper. 
- Code inputs:
  - `code_release_data_pixel_interaction/projection_system_outputs/damage_function_estimation/impact_values/*`
- Code outputs:
  -  `code_release_data_pixel_interaction/projection_system_outputs/damage_function_estimation/coefficients/df_mean_output_*.csv`

### `4_run_quantile_regressions.do`
- This code estimates quantiles of the damage functions for our main model, SSP3 scenario. The coefficients from these quantile regressions are used in subsequent calculations related to SCC uncertainty.
- ***Note, this code is very computationally intensive, and will take many hours to run, even on a powerful server.***
- We estimate 19 quantile regressions (for every fifth percentile from the 5th to 95th percentiles) to capture the full distribution of damages conditional on GMST anomaly (See Step 4 of Methods and Appendix Section F.4).
- Code inputs:
  - `code_release_data_pixel_interaction/projection_system_outputs/damage_function_estimation/impact_values/*`
- Code outputs:
  -  `code_release_data_pixel_interaction/projection_system_outputs/damage_function_estimation/coefficients/df_qreg_output_SSP3.csv`

### `5_plot_damage_function_over_time.do`
- This code plots damage functions for a selection of years, showing how our empirically derived damage functions evolve over time, for our main model, price014 SSP3 scenario. The resulting plot is included as Figure 3C in the Appendix.
- Code inputs:
  - `code_release_data_pixel_interaction/projection_system_outputs/damage_function_estimation/GMTanom_all_temp_2001_2010_smooth.csv`
  - `code_release_data_pixel_interaction/projection_system_outputs/damage_function_estimation/coefficients/df_mean_output_SSP3.csv`
- Code outputs:
  - `fig_3C_total_energy_damage_function_evolution_SSP3-price014.pdf`

### `6_get_end_of_century_df_slopes_p_vals.do`
- This code computes the slope and the p values, confidence intervals, of end of century damage function.
- Code inputs:
  - `code_release_data_pixel_interaction/projection_system_outputs/damage_function_estimation/GMTanom_all_temp_2001_2010_smooth.csv`
  - `code_release_data_pixel_interaction/projection_system_outputs/damage_function_estimation/coefficients/df_mean_output_SSP3.csv`
- Code outputs:
  - console output






