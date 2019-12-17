# Dropping Data and Creating Fixed Effect Regimes

Using the IEA World Energy Balances 2017 Edition Database Documentation, we clean the IEA World Energy Balances Dataset to account for the following types of data issues:
* changes in sector and fuel definitions 
* changes in data quality, availability, or reporting
* documented changes in energy supply or demand
* country geographic changes

To accomplish this task, we first read the documentation and encoded the relevant issues into this [dataset](). Then, we created a procedure for dropping data or constructing fixed effect regimes based off the coded issues. Below, I will outline both of these steps. 

## Encoding IEA World Balance Documentation

### Step 1: Through multiple readings of the database documentation a team of RA's assembled a country x sector x fuel x issue dataset with the following metadata variables:
* `issue_code`: what type of data quality issue is this? options include:
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
* `issue`: why is there an issue with the data? 
* `description`: what caused the issue with the data?
* `year_start`: what year did the data quality issue begin in?
* `year_end`: what year did the data quality issue end in?

### Step 2: Based off this metadata and cross referencing each issue with the database documentation we constructed the following 5 dummy variables for use in dataset cleaning and construction as well as in fixed effect regime assignment. 

* `flag_drop`: = 1 if the issue is classified as “redefine sectors”, “combine sectors”, “redefine fuels”, or “combine fuels.” 
* `grey`: If issues are classified as “data availability” or “ex-post revision” grey will be assigned a value based on the following procedure: 
    * = 1 if the period recorded has strictly better data quality than the period not recorded
        * implication: drop observations outside the recorded range
        * occurrences: 85
    * = 9 if the period recorded has strictly worse data quality than the period not recorded
        * implication: drop observations inside the recorded range
        * occurrences: 8
    * = 0 if there is no clear change in data quality pre/post change
        * Implication: keep both and use issue fixing FE to denote the two periods
        * occurrences: 165

* `geo_change`: = 1 if the issue indicates a geographic definition change
* `fiscal_year`: = 1 if the issue indicates data is recordered not on the Gregorian calendar
* `ex_ex`: = 1 if the issue is classified as “extrapolation” and the issue description indicates that the data was exclusively estimated. In other words, the only data source is estimation. 

## Addressing Encoded Issues in Data Cleaning and Analysis

Using the 5 dummy variables assigned in `Step 2` above we accomplish the following tasks:
1. construct country x year climate data which accurately reflect the calendar year and geographic regions associated with each energy load observation
2. create reporting regimes as described in section A.5.1
3. drop observations





