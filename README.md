# The Social Cost of Global Energy Consumption Due to Climate Change

The analysis in the paper proceeds in five steps. 

1. Historical data on energy consumption and climate are cleaned and merged, along with other covariates needed our analysis. 
2. Econometric analysis is conducted to establish the energy-temperature empirical relationship. 
3. This relationship is used to project future impacts of climate change using an ensemble of climate models 
    * Note: this step is exceptionally computationally intensive, and sharable code that is helpful for an average user for steps after step 2 are a work in progress.
4. These impacts are translated into empirical “damage functions” relating monetized damages to warming 
5. Damage functions are used to compute an energy-only partial social cost of carbon. 

This master readme outlines the process for each step, and each analysis step has it’s own readme and set of scripts and subdirectories.

## Description of folders

`0_make_dataset` - Code for constructing the dataset used to estimate all models described and displayed in the paper

`1_analysis` - Code for estimating and plotting all models present in the paper

`data` - 

`figures` - 

`sters` -

## Step 1 - Historical Energy Consumption and Climate Dataset Construction

Data construction is a multi-faceted process. We start with energy consumption data from the International Energy Agency's (IEA) World Energy Balances dataset, historical climate data from the Global Meterological Forcing Dataset (GMFD), and income and population data from IEA  



___________________ everything below this is scraps to build off of ___________________________



At the root dataset construction depends on extensive documentatoin Part A, we construct data on final consumption of electricity and other fuels, covering 146 countries annually over the period 1971 to 2010.  Part B, we construct data on historical climate to align with the geographic and temporal definitions used in the energy final consumption dataset. Part C, in our final merged dataset we also include population and income data. Part D, clean intermediate merged dataset based on the documented issues 

### Part A - Final Consumption Energy Data

were obtained from the International Energy Agency's (IEA) World Energy Balances dataset.

### Part B - Historical Climate Data


Historical Climata Data on daily average temperature and precip-
itation are obtained from the Global Meteorological Forcing Dataset (GMFD) dataset.31
This data product relies on a climate model in combination with observational data to
create globally-comprehensive data on daily mean, maximum, and minimum temperature
and precipitation at 0.25 x 0.25 degree gridded resolution. We link climate and energy con-
sumption data by aggregating gridded daily temperature data to the country-year level
using a procedure detailed in Appendix A.1.4 that preserves nonlinearity in the energy
consumption-temperature relationship.



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
	Covariate Data Our analysis allows for heterogeneity in the energy consumption-
temperature relationship as a function of two covariates: income per capita and long run
climate (measured by long-run average values of cooling degree days and heating degree
days). We obtain historical values of country-level annual income per capita from within
the International Energy Agencys World Energy Balances dataset, which in turn sources
these data from the World Bank. Cooling and heating degree days data are calculated
from GMFD.

## Step 2 - Econometric Analysis to Establish Energy-Temperature Empirical Relationship

## Step 3 - Project Future Impacts of Climate Change 
(coming soon to theaters near you)

## Step 4 - Estimate Empirical Damage Function
(coming soon to theaters near you)

## Step 5 - Compute Energy-Only Partial Social Cost of Carbon
(coming soon to theaters near you)

1. Run [0_construct_dataset_from_raw_inputs.do]() to construct a country x year x fuel panel dataset with climate, energy load, population and income data. SEE pg. 14
2. Run [1_construct_regression_ready_data.do]() to construct a dataset ready for regressions. This script completes the following tasks:
	1. Construct fixed effect regimes and drop data based off coded issues (fill out based on paper) SEE pg. 36 of paper
	2. Pair climate data
	3. Income group construction SEE pg. 10 for deciles, pg. 40 for large income groups
	4. Final cleaning steps SEE pg. 16 for UN region FEs
	5. Construct FD variables SEE pg. 36

## Instructions for Running Regressions
1. Run
    1. FGLS 
    2. Global regression SEE pg. 16, 38
	3. Income decile regression SEE pg. 16
	4. Income/Climate interacted regression SEE pg. 17, 41
	5. Robustness- Excl. imputed data SEE pg. 60
	6. Robustness- Last decade SEE pg. 61
	7. Tech trends SEE pg. 63-64

## Instructions for producing analysis related figures
1. Run
    1. Global regression SEE Figure A.5 on pg. 39
	2. Income decile regression SEE Figure 1A on pg. 10
	3. Income/Climate interacted regression SEE Figure 1B on pg. 10; description on pg. 5, 42
	4. Robustness- Excl. imputed data SEE Figure A.13 on pg. 61
	5. Robustness- Last decade SEE Figure A.14 on pg. 64
	6. Tech trends SEE Figure A.15 on pg. 65