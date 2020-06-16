# Impacts visualisation

## Overview 
- Codes in this repo reproduce figures in the paper that are visualisation of projected impacts in order to show their distribution across space and time. 

## Run instructions
- To run stata codes in this directory, change the macro `DB_data` such that it points to the location of the `code_release_data` folder, that contains csvs of our projected impacts due to climate change. Change the macro `root` such that it points to the location of this git repo. 
- To run R codes in this directory, change the `DB_data` variable such that it points to the location of the `code_release_data` folder, and change the `root` variable  such that it points to the location of this git repo. 

## Code specific notes

### `bar_chart_fig_2B/`
- Run `1_prepare_bar_chart_data.do` to clean data from the projection system outputs and prepare it for plotting. 
- `2_plot_bar_chart.R` takes in the data prepared in `1_prepare_bar_chart_data.do`, and outputs paper Figure 2B. 
- Code inputs:
	- `/code_release_data/projection_system_outputs/covariates/SSP3_IR_level_population.csv`: projected population data
	- `data/IEA_Merged_long_GMFD.dta`: historical consumption data from our estimation dataset
	- `/code_release_data/projection_system_outputs/mapping_data/main_model-*-SSP3-rcp85-high-fulladapt-impact_pc-2099-map.csv`: projected impacts per capita at the impact region level for the year 2099.
- Code outputs: 
	- `fig_2B_*_consumption_compared_to_2099_impact_bars.pdf`

### `plot_2010_and_2090_covariate_distributions.R`
- This code outputs the raw materials used to construct Appendix Figure C.3, which shows how the global income and climate covariate sample changes between 2010 and 2090.
- Note - construction of the final version of the figure used in the paper requires assembly using illustrator.
- Code inputs:
	- `code_release_data/projection_system_outputs/covariates/covariates-SSP3-rcp85-high-2010_2090-CCSM4.csv`
- Code outputs: 
	- `/fig_Appendix-C3_sample_overlap_present_future/*`

### `plot_city_responses.do`
- This code plots response functions for the Ghangzhou and Stockholm, at both their 2015 and 2099 covariate values. This aims to help readers understand how changing income and climate affects our projected response functions. These are presented in the paper in Figure 2A. 
- Code inputs:
	- `code_release_data/miscellaneous/stockholm_guangzhou_covariates_2015_2099.csv`: projected covariates for the two Impact Regions both in 2015 and in 2099. 
	- `code_release_data/miscellaneous/stockholm_guangzhou_2015_min_max.csv`: min and max values for the two impact regions, to allow us to subset the temperature range over which we show our response functions. 
	- `data/IEA_Merged_long_GMFD.dta`: historical consumption and income group cut off data from our estimation dataset
	- `code_release_data/miscellaneous/stockholm_guangzhou_region_names_key.csv`: a cross walk between the names of our impact regions and strings that refer to Ghangzhou and Stockholm
	- `sters/FD_FGLS_inter_TINV_clim.ster` coefficient values calculated from our regressions. 
- Code outputs: 
	- `fig_2A_city_response_functions_2015_and_2099.pdf`

### `plot_damages_by_2012_income_decile.R`
-
- Code inputs:
	- 
- Code outputs: 
	- 
	
### `plot_kernel_density_functions.R`
-
- Code inputs:
	- 
- Code outputs: 
	- 
	
### `plot_maps.R`
-
- Code inputs:
	- 
- Code outputs: 
	- 
	
### `plot_time_series.R`
-
- Code inputs:
	- 
- Code outputs: 
	- 
	

