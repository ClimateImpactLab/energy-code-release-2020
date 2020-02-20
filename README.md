# The Social Cost of Global Energy Consumption Due to Climate Change

The analysis in the paper proceeds in **five steps**. 

1. Historical data on energy consumption and climate are cleaned and merged, along with other covariates needed in our analysis (population and income). 
2. Econometric analysis is conducted to establish the energy-temperature empirical relationship. 
3. This relationship is used to project future impacts of climate change using an ensemble of climate models 
    * Note: this step is exceptionally computationally intensive, and sharable code for steps after step 2 are a work in progress.
4. These impacts are translated into empirical “damage functions” relating monetized damages to warming 
5. Damage functions are used to compute an energy-only partial social cost of carbon. 

This master readme outlines the process for each step, and each analysis step has it’s own readme and set of scripts in a subdirectory.

*Note, the code currently in this repo performs the first two steps outlined above. We will update with more replication code in the future*

## Description of folders

`0_make_dataset` - Code for constructing the dataset used to estimate all models described and displayed in the paper

`1_analysis` - Code for estimating and plotting all models present in the paper

`data` - Repository for storing data

`figures` - Contains figures produced by codes in this analysis

`sters` - Contains regression output, saved as .ster files 

## Step 1 - Historical Energy Consumption and Climate Dataset Construction

Data construction is a multi-faceted process. We clean and merge data on energy consumption from the International Energy Agency's (IEA) World Energy Balances dataset, 
historical climate data from the Global Meterological Forcing Dataset (GMFD), and income and population data from the IEA.

In Part A, we construct data on final consumption of electricity and other fuels, covering 146 countries annually over the period 1971 to 2010.  
In Part B, we construct data on historical climate to align with the geographic and temporal definitions used in the energy final consumption dataset. 
In Part C, we clean data on population and income of each country-year in our data. 
In Part D, we clean and merge together data produced in each of the previous parts, and output an intermediate merged dataset.

#### Part 1.A - Final Consumption Energy Data

* Data on energy consumption were obtained from the International Energy Agency's (IEA) World Energy Balances dataset. 
* This dataset is not public, and not provided in this repository. 
* From this raw data, we construct a country-year-product level panel dataset (where product is either electricity or other_energy). 
* Due to data quality concerns, we incorporate information on data consistency and quality from the IEAs documentation into this dataset. 
    * Details of this can be found in Appendix Section A.1, and in the [0_make_dataset/coded_issues](https://gitlab.com/ClimateImpactLab/Impacts/energy-code-release/tree/master/0_make_dataset/coded_issues) folder of this repo.
    * This allows us to determine which data should be dropped, to contruct a set of fixed effects and FGLS weights to help deal with data quality concerns, and assemble climate data that reflects the geographic and temporal definitions used to report energy consumption data.

#### Part 1.B - Historical Climate Data

* We take Historical Climata Data on daily average temperature and precip-
itation from the Global Meteorological Forcing Dataset (GMFD) dataset.
* The raw GMFD data is at the 0.25 x 0.25 degree gridded resolution. We link climate and energy con-
sumption data by aggregating gridded daily temperature data to the country-year level
using a procedure detailed in Appendix A.2.4 that preserves nonlinearity in the energy
consumption-temperature relationship.
    * This step is highly computationally intensive, and the code for this step is not currently provided in this repo.
* In addition to temperature and precipitation measures, we also calculate other climate measures, such as cooling and heating degree days.
* We then clean these data, so that they match the observations present in our energy load data. 
    * More documentation of the cleaning process can be found in [0_make_dataset/climate](https://gitlab.com/ClimateImpactLab/Impacts/energy-code-release/tree/master/0_make_dataset/climate)

#### Part 1.C - Population and income data

* We obtain historical values of country-level annual income per capita from within
the International Energy Agencys World Energy Balances dataset, which in turn sources
these data from the World Bank. 
* Cleaning steps undertaken on these variables can be found in [0_make_dataset/pop_and_income](https://gitlab.com/ClimateImpactLab/Impacts/energy-code-release/tree/master/0_make_dataset/pop_and_income)

#### Part 1.D - Merge energy final consumption, historical climate, population and income data

* As the final part of our dataset construction, we merge all of the data together. 
* Codes used in this step can be found in [0_make_dataset/merged](https://gitlab.com/ClimateImpactLab/Impacts/energy-code-release/tree/master/0_make_dataset/merged)

#### Part 1.E - Clean merged data for econometric analysis 

* Motivated by [tests](https://gitlab.com/ClimateImpactLab/Impacts/energy-code-release/blob/master/0_make_dataset/3_unit_root_test_and_plot.do) 
that showed that our outcome variable has a unit root, we construct first differenced versions of our 
variables for use in later econometric analysis. 
* To nonlinearly model income heterogeneity in the energy-temperature response, we construct an income spline variable. We decide on knot location based on in sample income deciles.
* Lastly to plot 3 x 3 arrays displaying the interacted model, we save a dataset with information on average income and climate in different terciles of the in sample data.

### Outputs of Step 1 

* Step 1 produces datasets ready to run regressions on, and datasets used in later plotting analysis. These can be found in [/data](https://gitlab.com/ClimateImpactLab/Impacts/energy-code-release/tree/master/data). Specifically,
    * Part 1.D produces `/data/IEA_Merged_long_GMFD.do` -- an intermediate dataset used to construct the final analysis dataset
    * Part 1.E produces: 
        * `/data/GMFD_*_regsort.data` -- the analysis dataset used in `Step 2`
        * `/data/break_data_*.dta` -- a dataset used for plotting 3 x 3 arrays
* Within Step 1, we produce two figures that are used in the paper:
    * ***Figure Appendix A.1***: `fig_Appendix-A1_ITA_other_fuels_time_series_regimes.pdf`
        * This figure is used to visualise the persistent shocks present in energy consumption. 
    * ***Figure Appendix A.2***: `fig_Appendix-A2_Unit_Root_Tests_p_val_hists_*.pdf`
        * These figures are used to visualise the distribution of p-values for unit root tests for within regime energy consumption.

## Step 2 - Econometric Analysis to Establish Energy-Temperature Empirical Relationship

This step implements analysis to recover the emprical relationship between temperature and energy consumption.
In this step, we take the cleaned data produced in step 1, run regressions and then plot the resulting outputs. 

We run three kinds of regressions in this section: 
1. Uninteracted global regressions
    * These regressions recover the global population weighted average response of energy consumption to temperature variation. 
    * Code for these regressions can be found in [1_analysis/uninteracted_regression](https://gitlab.com/ClimateImpactLab/Impacts/energy-code-release/tree/master/1_analysis/uninteracted_regression)
    * This code outputs: 
        * ster files for both the first stage and the FGLS regression: `FD_global_TINV_clim.ster` and `FD_FGLS_global_TINV_clim.ster`, respectively  
        * ***Appendix Figure C1***: `fig_Appendix-C1_product_overlay_TINV_clim_global.pdf`
2. Decile regressions
    * These regressions are run in order to understand how the sensitivity of energy consumption to climate change modulates with incomoe levels. 
    * Code for these regressions can be found in [1_analysis/decile_regression](https://gitlab.com/ClimateImpactLab/Impacts/energy-code-release/tree/master/1_analysis/decile_regression)
    * This code outputs:
        * ster files for both the first stage and the FGLS regression: `FD_FGLS_income_decile_TINV_clim.ster` and `FD_FGLS_income_decile_TINV_clim.ster`, respectively
        * ***Figure 1A***: `fig_1A_product_overlay_income_decile_TINV_clim.pdf` 
3. Interacted regressions
    * In these regressions, we model heterogeneity in the energy-climate relationship, by interacting our models with income and climate covariates.
    * Code for these regressions can be found in [1_analysis/interacted_regression](https://gitlab.com/ClimateImpactLab/Impacts/energy-code-release/tree/master/1_analysis/interacted_regression)
    * This code outputs: 
        * Ster files for the first stage and the FGLS regression for the main (***TINV_clim***), the excluding imputed data (***TINV_clim_EX***), tech trend (***TINV_clim_lininter***), and most recent decade (***TINV_clim_decinter***) models:
            * `FD_inter_*.ster` and `FD_FGLS_inter_*.ster`
        * The following paper and appendix figures:
            * ***Figures 1C***: `fig_1C_*_interacted_TINV_clim*.pdf`
            * ***Appendix Figures I2***: `fig_Appendix-I2_*_interacted_main_model_TINV_clim_overlay_model_EX*.pdf`
            * ***Appendix Figures I3A***: `fig_Appendix-I3A_ME_time_TINV_clim_lininter_*.pdf`
            * ***Appendix Figures I3B***: `fig_Appendix-I3B_*_interacted_main_model_TINV_clim_overlay_model_lininter.pdf`

## Step 3 - Project Future Impacts of Climate Change 

In this stage of our analysis, we take the coefficients identified in Step 2, 
and use them to project future impacts on energy consumption due to climate change 

Code for this step is not currently in this repo.

## Step 4 - Estimate Empirical Damage Function

In this stage, we take the projected future impacts found in step 3, and use them to construct and emprical damage function. 

Code for this step is not currently in this repo.

## Step 5 - Compute Energy-Only Partial Social Cost of Carbon

In the final step of the analysis, we use the empirically derived damage function to calculate an energy-only partial social cost of carbon.

Code for this step is not currently in this repo.