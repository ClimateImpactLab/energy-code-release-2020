# Dropping Data and Creating Fixed Effect Regimes

Using the IEA World Energy Balances 2017 Edition Database Documentation, we clean the IEA World Energy Balances Dataset to account for the following types of data issues:
* changes in sector and fuel definitions 
* changes in data quality, availability, or reporting
* documented changes in energy supply or demand
* country geographic definitions
* non-gregorian definitions of a year

To accomplish this task, we first read the documentation and encoded the relevant issues into this [dataset](https://gitlab.com/ClimateImpactLab/Impacts/energy-code-release/blob/master/0_make_dataset/coded_issues/cleaned_coded_issues.csv). Then, we created a procedure for dropping data or constructing fixed effect regimes based off the coded issues. Below, I will outline both of these steps. 

## Encoding IEA World Balance Documentation

### Step 1: Through multiple readings of the database documentation a team of research assistants assembled a country x sector x fuel x issue dataset with the following metadata variables:
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
2. drop untrustworthy observations
3. create reporting regimes as described in section A.5.1

### Constructing climate data which aligns with the regions and time spans reflected in the energy load data

We use the issues outlined below to construct climate data for impacted country boundary and year definitions:

Fiscal year fixing: 

- AUS - “All data refer to the fiscal year (e.g. July 2014 to June 2015 for 2015).”
- JPN [1990,] - “From 1990, data are reported on a fiscal year basis (e.g. April 2015 to March 2016 for 2015).”
- NZL [,1994) - “Prior to 1994, data refer to fiscal year (April 1993 to March 1994 for 1993). From 1994, data refer to calendar year.”
- BGD - “Data are reported on a fiscal year basis, beginning on 1 July and ending on 30 June of the subsequent year.”
- EGY - “Data are reported on a fiscal year basis. Data for 2015 correspond to 1 July 2015-30 June 2016.”
- IND - “Data are reported on a fiscal year basis. Data for 2015 correspond to 1 April 2015 – 30 March 2016.”
- KEN - “As of 2001, electricity data are reported on a fiscal year basis, beginning on 1 July and ending on 30 June of the subsequent year.”
- MMR - “Some data are reported on a fiscal year basis, beginning on 1 April and ending on 31 March of the subsequent year.”
- NPL - “Data are reported on a fiscal year basis, beginning on 1 July and ending on 30 June of the subsequent year 2015/16 is treated as 2015.”
- TZA - “Some of oil data (EWURA) are reported on a fiscal year basis. Data for 2015 correspond to 1 July 2015 30 June 2016.”
- IRN - “Data for 2015 correspond to 20 March 2015 19 March 2016, which is Iranian year 1394.”
- ETH - “Data are reported according to the Ethiopian financial year, which runs from 1 July to 30 June of the next year.”

Geographic Changes:

- Countries in former soviet union pre 1990: AZE, BLR, KAZ, KGZ, LVA, LTU, MDA, RUS, TJK, TKM, UKR, UZB, ARM, EST, GEO
- Countries in former Yugoslavia pre 1990: HRV, MKD, MNE, SRB, SVN, BIH, XKO
- CUW - “From 2012 onwards, data now account for the energy statistics of Curaçao Island only. Prior to 2012, data remain unchanged and still cover the entire territory of the former Netherland Antilles.”
- ETH - Prior to 1992, ERI included in Ethiopia
- SRB - XKO included in Serbia until 1999
- SRB - MNE included in Serbia between 1990 and 2004
- MDA- include the autonomous region of Stînga Nistrului (also known as the Pridnestrovian Moldavian Republic or Transnistria)
- SSD/SDN - “Data for South Sudan are available from 2012. Prior to 2012, they are included in Sudan.”
- SVK- “The Slovak Republic became a separate state in 1993 and harmonised its statistics to EU standards in 2000. These two facts lead to several breaks in time series between 1992 and 1993, and between 2000 and 2001.”
- DNK- “Excludes Greenland and the Faroe Islands, except prior to 1990, where data on oil for Greenland were included with the Danish statistics. The Administration is planning to revise the series back to 1974 to exclude these amounts.”
- CYP- 
    - Note by Turkey: The information in this document with reference to “Cyprus” relates to the southern part of the Island. There is no single authority representing both Turkish and Greek Cypriot people on the Island. Turkey recognizes the Turkish Republic of Northern Cyprus (TRNC). Until a lasting and equitable solution is found within the context of the United Nations, Turkey shall preserve its position concerning the “Cyprus” issue.
    - Note by all the European Union Member States of the OECD and the European Union: The Republic of Cyprus is recognised by all members of the United Nations with the exception of Turkey. The information in this report relates to the area under the effective control of the Government of the Republic of Cyprus.”
- FRA- “Includes Monaco and excludes the following overseas departments: Guadeloupe; French Guiana; Martinique; Mayotte; and Réunion; and collectivities: New Caledonia; French Polynesia; Saint Barthélemy; Saint Martin; Saint Pierre and Miquelon; and Wallis and Futuna.”
- ISR- “The statistical data for Israel are supplied by and under the responsibility of the relevant Israeli authorities. The use of such data by the OECD is without prejudice to the status of the Golan Heights, East Jerusalem and Israeli settlements in the West Bank under the terms of international law.”
- ITA- “Includes San Marino and the Holy See.”
- JPN- “Includes Okinawa”
- NDL- “Excludes Suriname, Aruba and the other former Netherland Antilles (Bonaire, Curaçao, Saba, Saint Eustatius and Sint Maarten).”
- PRT- “Includes the Azores and Madeira.” 
- ESP- “Includes the Canary Islands.”
- CHE- “Includes Liechtenstein for the oil data. Data for other fuels do not include Liechtenstein.”
- USA- “Includes the 50 states and the District of Columbia but generally excludes all territories, and all trade between the U.S. and its territories. Oil statistics include Guam, Puerto Rico 9 and the United States Virgin Islands; trade statistics for coal include international trade to and from Puerto Rico and the United States Virgin Islands.”

[1_clean_climate_data.do](https://gitlab.com/ClimateImpactLab/Impacts/energy-code-release/blob/master/0_make_dataset/climate/1_clean_climate_data.do) cleans and constructs our climate data to reflect all of these nuances.

### Dropping Untrustworthy Observations and Constructing Reporting Regimes

Using the `flag_drop` and `grey` indicator variables defined above, we drop observations. If an energy load observation corresponds to non-zero values of either indicator variable, we will drop that observation. Using the remaining issues we classify energy load observations into reporting regimes.

This data cleaning and reporting regime construction takes place in [1_issue_fix_v2.do](https://gitlab.com/ClimateImpactLab/Impacts/energy-code-release/blob/master/0_make_dataset/merged/1_issue_fix_v2.do)



