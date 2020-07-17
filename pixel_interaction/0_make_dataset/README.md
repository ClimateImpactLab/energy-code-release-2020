# Run instructions

In order to run codes, please change the macro `$root` at the top of the codes to the location of this repo on your computer. 

Please note, the raw data used here is not publicly available. 
* Therefore, only [2_construct_regression_ready_data.do](https://github.com/ClimateImpactLab/energy-code-release-2020/blob/master/0_make_dataset/2_construct_regression_ready_data.do), 
[3_unit_root_test_and_plot.do](https://github.com/ClimateImpactLab/energy-code-release-2020/blob/master/0_make_dataset/3_unit_root_test_and_plot.do), and
[4_plot_ITA_other_energy_regimes_timeseries.R](https://github.com/ClimateImpactLab/energy-code-release-2020/blob/master/0_make_dataset/4_plot_ITA_other_energy_regimes_timeseries.R)
in this folder (the codes that use intermediate data as an input) can be run by a user outside of the Climate Impact Lab. 
* The intermediate dataset, `IEA_merged_long.dta`, is outputed by  [1_construct_dataset_from_raw_inputs.do](https://github.com/ClimateImpactLab/energy-code-release-2020/blob/master/0_make_dataset/1_construct_dataset_from_raw_inputs.do), and cannot be run.

# Folder structure

`climate` - code and shapefiles for constructing, cleaning and assembling climate data 

`coded_issues` - encoded issues and documentation used to construct reporting regimes, clean the energy consumption data, and construct the climate data

`energy_load` - code for cleaning raw energy consumption data

`pop_and_income` - code for cleaning population and income data

`merged` - code for cleaning the merged dataset

**Because the raw data is currently unavailable, code in `climate`, `energy_load`, and `pop_and_income` cannot be run and is only present for reference.**

# Directory Master Scripts

Codes in this folder accomplish the following tasks:
* Construct an intermediate dataset including population, energy consumption, climate, and income data. 
    * `data/IEA_merged_long.dta`: 
    *  We clean IEA_merged_long.dta in two different ways to produce regression ready datasets for our main specification (*Methods* Equation 2; *Appendix* Equation C.4) and robustness models;
* Construct regression ready data:
    * `data/GMFD_TINV_clim_EX_regsort.dta`: used for estimating the excluding imputed data model (*Appendix* I.2)
    * `data/GMFD_TINV_clim_regsort.dta`: used for estimating the main model
* Save information on each country-year's income and climate covariates, which is used as an input to plotting code
    * `data/break_data_TINV_clim_EX.dta`: used for plotting output for the excluding imputed data model
    * `data/break_data_TINV_clim.dta`: used for plotting output for the main model
* Testing for the existence of unit roots in our outcome variable, motivating the need to use first differenced variables in our empirical analysis

## Constructing Intermediate Dataset (IEA_merged_long.dta)

[1_construct_dataset_from_raw_inputs.do](https://github.com/ClimateImpactLab/energy-code-release-2020/blob/master/0_make_dataset/1_construct_dataset_from_raw_inputs.do) produces IEA_merged_long.dta throught the following steps:
1. Clean and construct population, income, climate and energy consumption datasets
2. Merge population, income, climate and energy data by country and year

### Code Inputs:
* unavailable raw data

### Code Outputs:
* `energy-code-release-2020/data/IEA_merged_long.dta`

## Constructing Regression Ready Dataset (GMFD_TINV_clim*_regsort.dta)

[2_construct_regression_ready_data.do](https://github.com/ClimateImpactLab/energy-code-release-2020/blob/master/0_make_dataset/2_construct_regression_ready_data.do) can produce both `GMFD_TINV_clim_EX_regsort.dta` and `GMFD_TINV_clim_regsort.dta` through the following steps:
1. Construct reporting regimes and drop data according to encoded data issues
2. Match product specific climate data with product
    * climate is product specific due to the encoded data issues. Please reference this [climate/README.md](https://github.com/ClimateImpactLab/energy-code-release-2020/tree/master/0_make_dataset/climate) for more information on the topic.
3. Find income spline knot location to model a nonlinear effect of income on energy temperature sensitivity
4. Perform Final Cleaning Steps before first differenced interacted variable construction
	* Classify countries within 1 of 13 UN regions -- these UN regions are used to construct one of the fixed effects used in the analysis
	* Classify countries in income deciles and groups -- merge constructed income groups from (3) into main dataset
5. Construct First Differenced Interacted Variables used in the analysis section

***Note:*** at the top of `2_construct_regression_ready_data.do` set the global macro ***model*** to `TINV_clim` to produce regression ready data for the main model and to `TINV_clim_EX` to produce regression ready data for the excluding imputed data model.

### Code Inputs:
* `energy-code-release-2020/data/IEA_merged_long.dta`

### Code Outputs:
* `energy-code-release-2020/data/GMFD_TINV_clim*_regsort.dta`

## Constructing Covariate Intermediate Datasets (break_data_TINV_clim*.dta)

As well as producing the regression ready datasets, [2_construct_regression_ready_data.do](https://github.com/ClimateImpactLab/energy-code-release-2020/blob/master/0_make_dataset/2_construct_regression_ready_data.do) 
can produce both `break_data_TINV_clim.dta` and `break_data_TINV_clim_EX.dta`. These are intermediate 
datasets, that are outputted for 3x3 array plotting. These datasests contain covariate information for each 
country-year, including:
* Income: 
    * Decile of overall income distribution of our observations (`gpid`)
    * Tercile of overall income distribution of our observations (`tpid`)
    * Income groupings based on location of knot (`largegpid_*`), note, these vary by product. 
        * See the Paper Appendix Section C.3 for discussion of what these knots are.  
    * Average values of the long run income covariate, within each CDD tercile (`avgInc_tgpid`)
    * Maximum values of the long run income covariate within each income group (`maxInc_largegpid_other_energy` and `maxInc_largegpid_electricity`)

* Climate
    * Tercile of the distribution of long run CDDs (`tpid`)
    * Average value of the long run HDD covariate, within each income tercile (`avgHDD_tpid`)
    * Average value of the long run CDD covariate, within each income tercile (`avgCDD_tpid`)

***Note:*** at the top of `2_construct_regression_ready_data.do` set the global macro ***model*** to `TINV_clim` to produce regression ready data for the main model and to `TINV_clim_EX` to produce this covariate information for the excluding imputed data model.

### Code Inputs:
* `energy-code-release-2020/data/IEA_merged_long.dta`

### Code Outputs:
* `energy-code-release-2020/data/break_data_TINV_clim.dta`
* `energy-code-release-2020/data/break_data_TINV_clim_EX.dta`

## Testing for the existence of unit roots in our outcome variable
Through this data testing we motivate the first differencing completed in `Step 5` of **Constructing Regression Ready Dataset**

[`3_unit_root_test_and_plot.do`](https://github.com/ClimateImpactLab/energy-code-release-2020/blob/master/0_make_dataset/3_unit_root_test_and_plot.do) takes the regression ready dataset created in [2_construct_regression_ready_data.do](https://github.com/ClimateImpactLab/energy-code-release-2020/blob/master/0_make_dataset/2_construct_regression_ready_data.do), and tests for the existence of unit roots in the load_pc variable.
* The code implements the tests described in Section Appendix A.1 of the paper. 
* The figures outputted are those in the paper as Appendix Figure A.2

[`4_plot_ITA_other_energy_regimes_timeseries.R`](https://github.com/ClimateImpactLab/energy-code-release-2020/blob/master/0_make_dataset/4_plot_ITA_other_energy_regimes_timeseries.R) takes the regression ready dataset created in [2_construct_regression_ready_data.do](https://github.com/ClimateImpactLab/energy-code-release-2020/blob/master/0_make_dataset/2_construct_regression_ready_data.do), and plots a simple visualisation of the time series for ITALY Other fuels.
* The figure outputted is in the paper as Appendix Figure A.1


### Code Inputs:
* `energy-code-release-2020/data/GMFD_TINV_clim_regsort.dta`

### Code Outputs:
* `energy-code-release-2020/figures/fig_Appendix-A1_ITA_other_fuels_time_series_regimes.pdf`
* `energy-code-release-2020/figures/fig_Appendix-A2_Unit_Root_Tests_p_val_hists_electricity.pdf`
