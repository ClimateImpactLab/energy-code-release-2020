# Dataset construction

We construct three datasets for analysis:
* data/IEA_merged_long.dta: This is an intermediary dataset including population, energy load, climate, and income data. We clean IEA_merged_long.dta in two different ways to produce regression ready datasets for our main specification and robustbess models.
* data/GMFD_TINV_clim_EX_regsort.dta
* data/GMFD_TINV_clim_regsort.dta

## Constructing IEA_merged_long.dta

[1_construct_dataset_from_raw_inputs.do](https://gitlab.com/ClimateImpactLab/Impacts/energy-code-release/blob/master/0_make_dataset/1_construct_dataset_from_raw_inputs.do) produces IEA_merged_long.dta throught the following steps:
1. Clean and construct population, income, climate and energy load datasets
2. Merge population, income, climate and energy data by country and year
Note: Currently the data to complete this step is not available to the public.

## Constructing GMFD_TINV_clim*_regsort.dta

[2_construct_regression_ready_data.do](https://gitlab.com/ClimateImpactLab/Impacts/energy-code-release/blob/master/0_make_dataset/2_construct_regression_ready_data.do) can produce both GMFD_TINV_clim_EX_regsort.dta and GMFD_TINV_clim_regsort.dta through the following steps:

