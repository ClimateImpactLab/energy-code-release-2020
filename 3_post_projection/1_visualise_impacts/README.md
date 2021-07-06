# Impacts visualisation

## Overview 
- Codes in this repo reproduce figures in the paper that are visualisations of projected impacts, in order to show their distribution across space and time. 

## Run instructions
- To run stata codes in this directory, change the macro `DB_data` such that it points to the location of the `code_release_data_pixel_interaction` folder, that contains .csv files of our projected impacts due to climate change. Change the macro `root` such that it points to the location of this git repo. 
- To run R codes in this directory, change the `DB_data` variable such that it points to the location of the `code_release_data_pixel_interaction` folder, and change the `root` variable  such that it points to the location of this git repo. 

## Code specific notes

Note: data listed as being in `/data/` is stored in this git repo in the `/data` folder. Data listed as being stored in `/code_release_data_pixel_interaction/` is stored in an external location. 

### `bar_chart_fig_2B/`
- Run `1_prepare_bar_chart_data.do` to clean data from the projection system outputs and prepare it for plotting. 
- `2_plot_bar_chart.R` takes in the data prepared in `1_prepare_bar_chart_data.do`, and outputs paper Figure 2B. 
- Code inputs:
	- `/code_release_data_pixel_interaction/projection_system_outputs/covariates/SSP3_IR_level_population.csv`: projected population data
	- `data/IEA_Merged_long_GMFD.dta`: historical consumption data from our estimation dataset
	- `/code_release_data_pixel_interaction/projection_system_outputs/mapping_data/main_model-*-SSP3-rcp85-high-fulladapt-impact_pc-2099-map.csv`: projected impacts per capita at the impact region level for the year 2099.
- Code outputs: 
	- `fig_2B_*_consumption_compared_to_2099_impact_bars.pdf`

### `plot_2010_and_2090_covariate_distributions.R`
- This code outputs the raw materials used to construct Appendix Figure C.3, which shows how the global income and climate covariate sample changes between 2010 and 2090.
- Note - construction of the final version of the figure used in the paper requires assembly using Adobe Illustrator.
- Code inputs:
	- `code_release_data_pixel_interaction/projection_system_outputs/covariates/covariates-SSP3-rcp85-high-2010_2090-CCSM4.csv`
- Code outputs: 
	- `/fig_Extended_Data_fig_3_sample_overlap_present_future/*`

### `plot_city_responses.do`
- This code plots response functions for the Guangzhou and Stockholm, at both their 2015 and 2099 covariate values. This aims to help readers understand how changing income and climate affect our projected response functions. These are presented in the paper as insets within Figure 2A. 
- Code inputs:
	- `code_release_data_pixel_interaction/miscellaneous/stockholm_guangzhou_covariates_2015_2099.csv`: projected covariates for the two impact regions  (Guangzhou and Stockholm) both in 2015 and in 2099. 
	- `code_release_data_pixel_interaction/miscellaneous/stockholm_guangzhou_2015_min_max.csv`: min and max values for the two impact regions, to allow us to subset the temperature range over which we show our response functions. 
	- `data/IEA_Merged_long_GMFD.dta`: historical consumption and income knot point (See Appendix Section C.3) data from our estimation dataset
	- `code_release_data_pixel_interaction/miscellaneous/stockholm_guangzhou_region_names_key.csv`: a cross walk between the names of our impact regions and strings that refer to Guangzhou and Stockholm
	- `sters/FD_FGLS_inter_TINV_clim.ster` coefficient values calculated from our regression (Appendix Equation C.4). 
- Code outputs: 
	- `fig_2A_city_response_functions_2015_and_2099.pdf`

### `plot_damages_by_2012_income_decile.R`
- This code shows how the end-of-century energy consumption impacts we project are distributed across present-day income deciles. The output is Figure H.1 in the Appendix. 
- Code inputs:
	- `/code_release_data_pixel_interaction/projection_system_outputs/mapping_data/main_model-*-SSP3-rcp85-high-fulladapt-impact_pc-2099-map.csv`: projected impacts per capita at the impact region level for the year 2099.
	- `/code_release_data_pixel_interaction/projection_system_outputs/covariates/SSP3-high-IR_level-gdppc-pop-2012.csv`: 2012 income and population data at the impact region level
	- `/code_release_data_pixel_interaction/projection_system_outputs/covariates/SSP3-high-IR_level-gdppc-pop-2099.csv`: 2099 income and population data at the impact region level
- Code outputs: 
	- `fig_Extended_Data_fig_4-H1-new_SSP3-high_rcp85-total-energy-price014-damages_by_country_inc_decile.pdf`

### `plot_kernel_density_functions.R`
- This code generates visualisations of the uncertainty around our projected impacts due to climate change for selected impact regions. We do this by taking draws from the distribution of impacts for these impact regions, by loading in the mean and variance of their impacts under each of the 33 climate projections in the SMME for the year 2099. By taking draws from each of these Gaussian distributions in proportion to each GCM's weight (see Appendix Section A.2.3 and Table 1 for more details), we can calculate the mixture distribution across the 33 climate projections for each impact region. See Appendix Section C.5.
- Note - this code sources functions from `0_utils/kernel_densities.R`. 
- The outputs of this code are used in Figure 3A of the paper.
- Code inputs:
	- `/code_release_data_pixel_interaction/projection_system_outputs/IR_GCM_level_impacts/gcm_damages-main_model-total_energy-SSP3-rcp85-high-fulladapt-price014-2099-select_IRs.csv`: Impacts for selected impact regions in the year 2099, under each of the 33 climate projections in the SMME. 
	- `/code_release_data_pixel_interaction/projection_system_outputs/covariates/SSP3-high-IR_level-gdppc_pop-2099.csv`: GDP values for the Impact Regions in the year 2099, in order to convert the units of the plots to percent of GDP. 
- Code outputs: 
	- `/fig_3/fig_3A_kd_plot_*.pdf`

### `plot_maps.R`
- This code plots all maps presented in the paper, including those present in Figures 2A and 3A. 
- This code sources mapping functions from `0_utils/mapping.R`. 
- Code inputs:
	- `/code_release_data_pixel_interaction/shapefiles/world-combo-new-nytimes/.`: shapefile for the world that we use in our global map plots. 
	- `/code_release_data_pixel_interaction/projection_system_outputs/mapping_data/main_model-*-SSP3-rcp85-high-fulladapt-impact_pc-2099-map.csv`: projected impacts data for electricity and other energy, used in plotting Figure 2A. 
	- `/code_release_data_pixel_interaction/projection_system_outputs/mapping_data/main_model-total_energy-SSP3-rcp85-high-fulladapt-price014-2099-map.csv`: projected impacts for total energy, in dollars, priced using the `price014` price scenario.
	- `/projection_system_outputs/covariates/SSP3_IR_level_gdppc_pop_2099.csv`: Impact region level GDP data for 2099, allowing us to plot impacts as a percent of each Impact Region's GDP.
- Code outputs: 
	- `fig_2A_electricity_impacts_map.png`
	- `fig_3/fig_3A_2099_damages_proportion_gdp_map.png`
	
### `plot_time_series.R`
- This code produces all time series plots shown in the paper. This includes plots presented in Figures 2C and 3B, and also Appendix Figures D1, I1, and I3. 
- This code sources plotting functions from `0_utils/time_series.R`. 
- Code inputs:
	- `code_release_data_pixel_interaction/projection_system_outputs/time_series_data/main_model-*-SSP3-*-high-*-impact_pc.csv` time series of impacts, with uncertainty, for our main model, electricity and other energy, rcp45 and rcp85, and our full adaptation and no-adaptation scenarios. These are used to plot our impacts per capita time series in Figure 2C.
	- `code_release_data_pixel_interaction/projection_system_outputs/time_series_data/main_model-total_energy-SSP3-*-high-fulladapt-price014.csv`: main model total energy impacts time series, for rcp45 and rcp85. 
	- `code_release_data_pixel_interaction/projection_system_outputs/covariates/SSP3-global-gdp-time_series.csv`: global gdp time series data to plot monetized impacts as a percent of global gdp. 
	- `code_release_data_pixel_interaction/projection_system_outputs/time_series_data/main_model-total_energy-SSP3-*-high-fulladapt-*.csv`: main model time series by each of our price scenarios. 
	- `code_release_data_pixel_interaction/projection_system_outputs/time_series_data/CCSM4_single/SA_single-*-SSP3-high-fulladapt-impact_pc.csv`: single climate model (CCSM4) time series of projected impacts for our Slow Adaptation model
	- `code_release_data_pixel_interaction/projection_system_outputs/time_series_data/CCSM4_single/main_model_single-*-SSP3-high-fulladapt-impact_pc.csv`: single climate model (CCSM4) time series of projected impacts for our main model. The main model impact time series under CCSM4 is included here to provide a direct comparison to Slow Adaptation impact time series, which was projected under the same climate model. 
	- `code_release_data_pixel_interaction/projection_system_outputs/time_series_data/lininter_model-*-SSP3-rcp85-high-fulladapt-impact_pc.csv`: global time series of impacts for the `lininter` model, by fuel type. 
- Code outputs: 
	- `fig_2C_*_time_series.pdf`
	- `fig_3/fig_3b_global_damage_time_series_percent_gdp_SSP3-high.pdf`
	- `fig_Extended_Data_fig_5_global_total_energy_timeseries_all-prices-*.pdf`
	- `fig_Appendix-G1_Slow_adapt-global_*_timeseries_impact-pc_CCSM4-SSP3-high.pdf`
	- `fig_Appendix-G3_lininter-global_*_timeseries_impact-pc_SSP3-high-rcp85.pdf`
	

