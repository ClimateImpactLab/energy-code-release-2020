# Incorporating Dataset Documentation into Analysis and Data Cleaning/Construction

Using the IEA World Energy Balances 2017 Edition Database Documentation, we clean the IEA World Energy Balances Dataset to account for the following types of data issues:
* changes in sector and fuel definitions 
* changes in data quality, availability, or reporting
* documented changes in energy supply or demand
* country geographic definitions
* non-standard definitions of a year

To accomplish this task, we first read the documentation and encoded the relevant issues into this [dataset](https://github.com/ClimateImpactLab/energy-code-release-2020/blob/master/0_make_dataset/coded_issues/cleaned_coded_issues.csv). Then, using these coded issues, we cleaned the dataset and constructed reporting regimes. Below, I will outline both of these steps. 

## Encoding IEA World Balance Documentation

### Step 1: Through multiple readings of the database documentation a team of research assistants assembled a country x sector x fuel x issue dataset with the following metadata variables:
* `issue_code`: what type of data quality issue is this? options include:
    * combined sectors - two or more sectors are combined
    * data availability - changes in the availability of data
    * climate data - cannot construct climate data for energy consumption data
    * combined fuels - two or more fuels are combined
    * ex-post revision - data was changed after it was originally reported
    * extrapolation - data was estimated in some way
    * real anomaly - an event occured which presumably causing an energy supply or demand shock
    * data source change - there was a change in reporting source
    * redefine sectors - the definition of the sectoral breakdown changed
    * methodology change - how data got collected changed
* `issue`: why is there an issue with the data? 
* `description`: what caused the issue with the data?
* `year_start`: what year did the data quality issue begin in?
* `year_end`: what year did the data quality issue end in?

### Step 2: Based off this metadata and cross referencing each issue with the database documentation we constructed the following 5 dummy variables for use in dataset cleaning and construction as well as in fixed effect regime assignment. 
* `flag_drop`: = 1 if the issue is classified as “redefine sectors”, “combine sectors”, “redefine fuels”, or “combine fuels.” 
* `grey`: If issues are classified as “data availability”, “ex-post revision” or "climate data" grey will be assigned a value based on the following procedure: 
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
* `fiscal_year`: = 1 if the issue indicates data is not recordered on a Jan.-Dec. calendar year
* `ex_ex`: = 1 if the issue is classified as “extrapolation” and the issue description indicates that the data was exclusively estimated. In other words, the only data source is imputation. (*Appendix* I.2) 

Please note, there are some instances where `flag_drop` and `grey` are used to drop data with issues classified outside of the definitions specified above. Please reference [cleaned_coded_issues.csv](https://github.com/ClimateImpactLab/energy-code-release-2020/blob/master/0_make_dataset/coded_issues/cleaned_coded_issues.csv) for examples of these exceptions.

## Addressing Encoded Issues in Data Cleaning and Analysis

Using the 5 dummy variables assigned in `Step 2` above we accomplish the following tasks:
1. construct country x year climate data which accurately reflect the calendar year and geographic regions associated with each energy consumption observation
    * please reference this [readme](https://github.com/ClimateImpactLab/energy-code-release-2020/blob/master/0_make_dataset/climate/README.md) for more information about how climate data gets constructed with these issues in mind
2. drop untrustworthy observations
    * Using the `flag_drop` and `grey` indicator variables defined above, we drop observations. If an energy consumption observation corresponds to non-zero values of either indicator variable, we will drop that observation.
3. create reporting regimes as described in Appendix Section A.1
    * we use all encoded issues that don't lead to data dropping to classify energy consumption observations into reporting regimes.


