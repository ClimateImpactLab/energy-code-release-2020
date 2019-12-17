# Climate Data Construction

As described in Appendix A.1.4, we link gridded historical climate data to country-level energy consumption data by aggregating grid cell information to the country level. Nonlinear transformations of temperature and rainfall are computed at the grid cell level before averaging values across space using population weights and finally summing over days within a year. This procedure recovers grid-by-day-level nonlinearities in the energy-temperature (and energy-precipitation) relationship, because energy consumption is additive across time and space.

As outlined [here](https://gitlab.com/ClimateImpactLab/Impacts/energy-code-release/blob/master/0_make_dataset/coded_issues/README.md), the IEA dataset documentation describes that some energy load observations are reported on non-gregorian calendars and for non-standard geographic regions. We account for these two types of energy load data features by constructing country x year climate data variables which align with the geographic and temporal definitions baked into each energy load observation. For example:
* We construct yearly Australian climate data with the following definition of year: July t to June t + 1.  
* We use a shapefile for Italy which includes San Marino and the Holy Sea.

We implement this nuanced climate data construction by:
1. creating shapefiles which correspond to the region definitions in the IEA dataset
2. producing monthly (instead of yearly) aggregated climate data for regions which report energy data using non-standard year definitions 
3. running shapefile specific stata programs which clean each 

A combination of complex

## File Structure

programs - stata programs for cleaning climate data
* there is a program for each shapefile we use to construct climate data

shapefiles - the shapefiles we use to construct country level climate data variables 

## How we account for Non-Standard Year and Geographic Boundary Definitions in Climate Data Construction
To account for non-standard geographic boundary definitions, we use shapefiles that correpond to the geographic boundaries associated with the energy load data. To account for non-standard temporal definitions, we generate monthly climate data for affected regions in order to build years that correspond with the energy load data reporting period. 

### Non-Standard Year Definitions



### Non-Standard Geographic Boundary Defitions
Below I provide


- France includes Monaco
- Prior to 2012, Curacao energy load pertains to the former Netherland Antilles.
    - [shapefile]()
    - [cleaning code](https://gitlab.com/ClimateImpactLab/Impacts/energy-code-release/blob/master/0_make_dataset/climate/programs/clean_CUW_BES_ABW.do)
