# The Social Cost of Global Energy Consumption Due to Climate Change

The analysis in the paper proceeds in **five steps**. 

1. Historical data on energy consumption and climate are cleaned and merged, along with other covariates needed in our analysis (population and income). 
2. Econometric analysis is conducted to establish the energy-temperature empirical relationship. 
3. This relationship is used to project future impacts of climate change using an ensemble of climate models 
    * Note: this step is exceptionally computationally intensive, and sharable code that is helpful for an average user for steps after step 2 are a work in progress.
4. These impacts are translated into empirical “damage functions” relating monetized damages to warming 
5. Damage functions are used to compute an energy-only partial social cost of carbon. 

This master readme outlines the process for each step, and each analysis step has it’s own readme and set of scripts and subdirectories.

*Note, the code currently in this repo performs the first two steps outlined above. We will update with more replication code in the future*

## Description of folders

`0_make_dataset` - Code for constructing the dataset used to estimate all models described and displayed in the paper

`1_analysis` - Code for estimating and plotting all models present in the paper

`data` - Repository for storing data

`figures` - Contains figures produced by codes in this analysis

`sters` - Contains regression output, saved as .ster files 

## Step 1 - Historical Energy Consumption and Climate Dataset Construction

Data construction is a multi-faceted process. We clean and merge data on energy consumption from the International Energy Agency's (IEA) World Energy Balances dataset, 
historical climate data from the Global Meterological Forcing Dataset (GMFD), and income and population data from IEA.

Part A, we construct data on final consumption of electricity and other fuels, covering 146 countries annually over the period 1971 to 2010.  
Part B, we construct data on historical climate to align with the geographic and temporal definitions used in the energy final consumption dataset. 
Part C, we clean data on population and income of each country-year in our data. 
Part D, we clean and merge together data produced in each of the previous parts, and output an intermediate merged dataset.

#### Part 1.A - Final Consumption Energy Data

* Data on energy consumption were obtained from the International Energy Agency's (IEA) World Energy Balances dataset. 
* This dataset is not public, and not provided in this repository. 
* From this raw data, we construct a country-year-product level panel dataset (where product is either electricity or other_energy). 
* Due to data quality concerns, we incorporate information on data consistency and quality from the IEAs documentation into this dataset. 
    * Details of this can be found in Appendix Section A.5, and in the [0_make_dataset/coded_issues](https://gitlab.com/ClimateImpactLab/Impacts/energy-code-release/tree/master/0_make_dataset/coded_issues) folder of this repo.
    * This allows us to determine which data should be dropped, and to contruct a set of fixed effects, and FGLS weights to help deal with data quality concerns.

#### Part 1.B - Historical Climate Data

* We take Historical Climata Data on daily average temperature and precip-
itation from the Global Meteorological Forcing Dataset (GMFD) dataset.
* The raw GMFD data is at the 0.25 x 0.25 degree gridded resolution. We link climate and energy con-
sumption data by aggregating gridded daily temperature data to the country-year level
using a procedure detailed in Appendix A.1.4 that preserves nonlinearity in the energy
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


#### Part 1.D - Population and income data

* As the final part of our dataset construction, we merge all of the data together. 
* Codes used in this step can be found in [0_make_dataset/merged](https://gitlab.com/ClimateImpactLab/Impacts/energy-code-release/tree/master/0_make_dataset/merged)
* Motivated by [tests](https://gitlab.com/ClimateImpactLab/Impacts/energy-code-release/blob/master/0_make_dataset/3_unit_root_test_and_plot.do) 
that showed that our outcome variable has a unit root, we also construct first differenced versions of our 
variables for use in later econometric analysis. 


### Outputs of Step 1 

* Step 1 produces datasets ready to run regressions on, and datasets used in later plotting analysis. 
    * These can be found in [/data](https://gitlab.com/ClimateImpactLab/Impacts/energy-code-release/tree/master/data)



## Step 2 - Econometric Analysis to Establish Energy-Temperature Empirical Relationship

This step implements analysis to recover the emprical relationship between temperature and energy consumption.
In this step, we take the cleaned data produced in step 1, run regression



## Step 3 - Project Future Impacts of Climate Change 

In this stage of our analysis, we take the coefficients identified in Step 2, 
and use them to project future impacts on energy consumption due to climate change 

Code for this step is not currently in this repo.

## Step 4 - Estimate Empirical Damage Function

In this stage, we take the projected future impacts found in step 3, and use them to construct and emprical damage function. 

Code for this step is not currently in this repo.

## Step 5 - Compute Energy-Only Partial Social Cost of Carbon

In the final step of the analysis, we use the empirically derived damage function to calculate an energy-only partial social cost of carbon.






--------------------------- to delete at the bottom--------------------------- 
















Electricity con-
sumption is taken from the ELECTR variable code, and consumption of other fuels is ob-
tained by aggregating over the following variable codes: COAL (Coal and coal products);
PEAT (Peat and peat products); OILSHALE (Oil shale and oil sands); TOTPRODS
(Oil products); NATGAS (Natural gas); SOLWIND (Solar/wind/other); GEOTHERM
(Geothermal); COMRENEW (Biofuels and waste); HEAT (Heat), and HEATNS (Heat
production from non-specified combustible fuels). For both electricity and other fuels, we
aggregate over the following sectoral codes: TOTIND, which encompasses consumption in
the industrial sector, and TOTOTHER, which encompasses consumption in the commer-
cial/public services, residential, agricultural, forestry, fishing, and non-specified sectors.
The non-specified sector includes consumption in the other sectors within TOTOTHER
if disaggregated fgures are not provided for those sectors.
	The IEA's data on energy consumption are extensively documented with regard to
data inconsistencies and quality issues across countries and years,30 including lack of
data, partial revisions to data, imputed data, and changes in reporting practices over
time. We employ a series of data preparation and econometric techniques to address such
record-keeping idiosyncrasies (Appendix, A.5).
	Historical Climata Data on daily average temperature and precip-
itation are obtained from the Global Meteorological Forcing Dataset (GMFD) dataset.31
This data product relies on a climate model in combination with observational data to
create globally-comprehensive data on daily mean, maximum, and minimum temperature
and precipitation at 0.25 x 0.25 degree gridded resolution. We link climate and energy con-
sumption data by aggregating gridded daily temperature data to the country-year level
using a procedure detailed in Appendix A.1.4 that preserves nonlinearity in the energy



consumption-temperature relationship.





1. Run [0_construct_dataset_from_raw_inputs.do]() to construct a country x year x fuel panel dataset with climate, energy load, population and income data. SEE pg. 14
2. Run [1_construct_regression_ready_data.do]() to construct a dataset ready for regressions. This script completes the following tasks:
	1. Construct fixed effect regimes and drop data based off coded issues (fill out based on paper) SEE pg. 36 of paper
	2. Pair climate data
	3. Income group construction SEE pg. 10 for deciles, pg. 40 for large income groups
	4. Final cleaning steps SEE pg. 16 for UN region FEs
	5. Construct FD variables SEE pg. 36

