# Run instructions

Please note, the raw data used here is not publically available. 
* Therefore, only the codes in this folder that use intermediate data as an input can be run by a user. 
* The intermediate dataset, `IEA_merged_long.dta`, is outputed by  [1_construct_dataset_from_raw_inputs.do](https://gitlab.com/ClimateImpactLab/Impacts/energy-code-release/blob/master/0_make_dataset/1_construct_dataset_from_raw_inputs.do), and used as an input to [2_construct_regression_ready_data.do](https://gitlab.com/ClimateImpactLab/Impacts/energy-code-release/blob/master/0_make_dataset/2_construct_regression_ready_data.do).  
* Please only try to run codes that occur downstream of the construction of `IEA_merged_long.dta`.

# Folder structure

`climate` - code and shapefiles for constructing, cleaning and assembling climate data

`coded_issues` - encoded issues and documentation used to construct reporting regimes, clean the energy load data, and construct the climate data

`energy_load` - code for cleaning raw energy load data

`pop_and_income` - code for cleaning population and income data

`merged` - code for cleaning the merged dataset

# Dataset construction

Codes in this folder construct three datasets for analysis:
* `data/IEA_merged_long.dta`: This is an intermediary dataset including population, energy load, climate, and income data. We clean IEA_merged_long.dta in two different ways to produce regression ready datasets for our main specification and robustness models;
* `data/GMFD_TINV_clim_EX_regsort.dta`: regression ready data for estimating the Exclusively Imputed robustness model
* `data/GMFD_TINV_clim_regsort.dta`: regression ready data for estimating the main model

## Constructing IEA_merged_long.dta

[1_construct_dataset_from_raw_inputs.do](https://gitlab.com/ClimateImpactLab/Impacts/energy-code-release/blob/master/0_make_dataset/1_construct_dataset_from_raw_inputs.do) produces IEA_merged_long.dta throught the following steps:
1. Clean and construct population, income, climate and energy load datasets
2. Merge population, income, climate and energy data by country and year

Note: Currently the data to complete this step is not available to the public.

## Constructing GMFD_TINV_clim*_regsort.dta

[2_construct_regression_ready_data.do](https://gitlab.com/ClimateImpactLab/Impacts/energy-code-release/blob/master/0_make_dataset/2_construct_regression_ready_data.do) can produce both GMFD_TINV_clim_EX_regsort.dta and GMFD_TINV_clim_regsort.dta through the following steps:
1. Construct reporting regimes and drop data according to encoded data issues
2. Match product specific climate data with product -- climate is product specific due to the encoded data issues
3. Prepare data for Income Group Construction and Construct Large Income Groups 
    * this step is necessary to construct the income spline
4. Perform Final Cleaning Steps before first differenced interacted variable construction
	* Classify countries within 1 of 13 UN regions -- these UN regions are used to construct one of the fixed effects used in the analysis
	* Classify countries in income deciles and groups -- merge constructed income groups from (3) into main dataset
5. Construct First Differenced Interacted Variables used in the analysis section

***Note:*** at the top of `2_construct_regression_ready_data.do` set the global macro ***model*** to `TINV_clim` to produce regression ready data for the main model and to `TINV_clim_EX` to produce regression ready data for the Exclusively Imputed robustness model.
