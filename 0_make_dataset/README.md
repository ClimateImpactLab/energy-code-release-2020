# Dataset construction

We construct three datasets for analysis:
* data/IEA_merged_long.dta: This is an intermediary dataset including population, energy load, climate, and income data. We clean IEA_merged_long.dta in two different ways to produce regression ready datasets for our main specification and robustbess models.
* data/GMFD_TINV_clim_EX_regsort.dta
* data/GMFD_TINV_clim_regsort.dta

## Folder structure

climate - code and shapefiles for constructing, cleaning and assembling climate data

coded_issues - encoded issues and documentation used to construct reporting regimes, clean the energy load data, and construct the climate data

energy_load - code for cleaning raw energy load data

pop_and_income - code for cleaning population and income data

merged - code for cleaning the merged dataset

## Constructing IEA_merged_long.dta

[1_construct_dataset_from_raw_inputs.do](https://gitlab.com/ClimateImpactLab/Impacts/energy-code-release/blob/master/0_make_dataset/1_construct_dataset_from_raw_inputs.do) produces IEA_merged_long.dta throught the following steps:
1. Clean and construct population, income, climate and energy load datasets
2. Merge population, income, climate and energy data by country and year
Note: Currently the data to complete this step is not available to the public.

## Constructing GMFD_TINV_clim*_regsort.dta

[2_construct_regression_ready_data.do](https://gitlab.com/ClimateImpactLab/Impacts/energy-code-release/blob/master/0_make_dataset/2_construct_regression_ready_data.do) can produce both GMFD_TINV_clim_EX_regsort.dta and GMFD_TINV_clim_regsort.dta through the following steps:

