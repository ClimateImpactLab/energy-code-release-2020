# Dropping Data and Creating Fixed Effect Regimes

Using the IEA World Energy Balances 2017 Edition Database Documentation, we clean the IEA World Energy Balances Dataset to account for the following types of data issues:
* changes in sector and fuel definitions 
* changes in data quality, availability, or reporting
* documented changes in energy supply or demand
* country geographic changes

To accomplish this task, we first read the documentation and encoded the relevant issues into this [dataset](). Then, we created a procedure for dropping data or constructing fixed effect regimes based off the coded issues. Below, I will outline both of these steps. 

## Encoding IEA World Balance Documentation

### Step 1: Through multiple readings of the database documentation a team of RA's assembled a country x sector x fuel x issue dataset with the following metadata variables:
* issue_code: what type of data quality issue is this? options include:
    * combined sectors
    * data availability
    * climate data
    * combined fuels
    * ex-post revision
    * extrapolation
    * real anomaly
    * data source change
    * redefine sectors
    * methodology change
* issue: why is there an issue with the data? 
* description: what caused the issue with the data?
* year_start: what year did the data quality issue begin in?
* year_end: what year did the data quality issue end in?

### Step 2: Based off this metadata and cross referencing each issue with the database documentation we constructed 7 dummy variables for use in data cleaning and construction as well as in fixed effect regime assignment


## Addressing Encoded Issues in Data Cleaning and Analysis


Criteria for Dropping:

    a. issue_code is combine/redefine sectors/fuels
    b. issue_code is data availability or ex-post revision and one data source is clearly superior to the other

Criteria for FE regimes:

    a. all issues that don’t lead to dropping observations are used to make FE regimes

In order to drop, the observations that need to be dropped given the above criteria and the encoded issues, we define categorical variables. 

Grey Indicator Variable: 

The grey indicator corresponds to issues classified as “data availability” and “ex-post revision.” The variable takes on values 0, 1, and 9. If an issue is not classified as “data availability” or “ex-post revision” then grey = 0. For issues that are classified as “data availability” and “ex-post revision” the three different values for 0, 1, and 9 take on the following meanings: 

    1. = 1 if the period recorded has strictly better data quality than the period not recorded
        1. implication: drop obs outside the recorded range
        2. example: ALB, residential, oil, data availability, 2011, 2012
        3. occurrences: 85
    2. = 9 if the period recorded has strictly worse data quality than the period not recorded
        1. implication: drop obs inside the recorded range
        2. example: CZE, industrial, coal, BKB, data availability, 1990, 2011 (Note: this issue
        3. occurrences: 8
    3. = 0 if there is no clear change in data quality pre/post change
        1. Implication: keep both and use issue fixing FE to denote the two periods
        2. example: ARE, coal, ex-post revision, 2009, 2012
        3. occurrences: 165
    4. Note: The grey dummy always applies to COMPILE total_energy as well as whichever flow product combo is specified in the 

Flag_drop Dummy Variable:

The flag_drop dummy variable = 1 if the issue is classified as “redefine sectors”, “combine sectors”, “redefine fuels”, or “combine fuels.” Variables tot_drop, fuel_keep, and other_keep stop observation dropping for specific flow and product specifications for which a given issue does not apply. Below I define the meanings of tot_drop, fuel_keep, and other_keep and provide examples. Note: other_keep does not exist yet. 


    1. Tot_drop: =1 if for COMPILE, the data should be dropped
        1. example (tot_drop = 1): AUS, industrial, energy industry, electricity, combined sectors, 1971, 2005
            1. occurrences: 29
        2. example (tot_drop = 0): DEU, industrial, oil, combined sectors, 1971, 1993
            1. occurrences: 22
    2. Fuel_keep: =1 if for total_energy the data can be kept
        1. example (fuel_keep = 1): RUS, coal, charcoal, redefine fuels, 2010, 2012
            1. occurrences: 7
        2. example (fuel_keep = 0): PAK, oil, bitmen and lubricant, redefine fuels, 1971, 2012
            1. occurrences: 44
        3. Note: The impact of Fuel_keep on the COMPILE flow category is conditional on tot_drop ie if tot_drop = 0 then the issue should not impact a COMPILE total_energy observation
    3. Other_keep: =1 if for other_energy the data can be kept 
        1. example  (other_keep = 1): RUS, coal, charcoal, redefine fuels, 2010, 2012
        2. example (other_keep = 0): PAK, oil, bitmen and lubricant, redefine fuels, 1971, 2012

The last indicator variable is ex_est. Ex_est = 1 if the issue is classified as “extrapolation” and the issue description indicates that the data was exclusively estimated. In other words, the only data source is estimation. Under the dropped exclusively estimated data robustness check, all data should be dropped if Ex_est = 1 conditional on tot_drop, fuel_keep, and other_keep. 

Note: if grey = 9 or = 1, then Tot_drop, Other_keep , Flag_drop, and Fuel_keep all equal zero. Similarly, if Flag_drop = 1 or Ex_est = 1, then grey = 0, and Tot_drop, Extra_drop, and Fuel_keep can equal 0 or 1. 