# Climate Data Construction

As described in Appendix A.1.4, we link gridded daily historical climate data to country-year-level energy consumption data by aggregating daily grid cell information to the country year level. Nonlinear transformations of temperature and rainfall are computed at the grid cell level before averaging values across space using population weights and finally summing over days within a year. This procedure recovers grid-by-day-level nonlinearities in the energy-temperature (and energy-precipitation) relationship, because energy consumption is additive across time and space.

As outlined [here](https://gitlab.com/ClimateImpactLab/Impacts/energy-code-release/blob/master/0_make_dataset/coded_issues/README.md), the IEA dataset documentation describes that some energy load observations are reported on non-gregorian calendars and for non-standard geographic regions. We account for these two types of energy load data features by constructing country x year climate data variables which align with the geographic and temporal definitions baked into each energy load observation. For example:
* We construct yearly Australian climate data with the following definition of year: July t to June t + 1.  
* We use a shapefile for Italy which includes San Marino and the Holy Sea.

The code and shapefiles in this directory demonstrate how we address non-standard definitions of country boundaries and years when aggregating and compiling aggregated daily gridded climate data.

## Directory File Structure

`programs` - stata programs for cleaning shapefile specific aggregated climate data
* contribution: complete shapefile specific aggregated climate data cleaning, accounting for non-standard year definitions in particular regions for specific periods

`shapefiles` - the shapefiles we use to construct country level climate data variables 
* contribution: aggregate climate data into regions which correspond to the regions in the IEA energy load dataset

`1_clean_climate_data.do` - the master program
* contribution:

## How we account for Non-Standard Year and Geographic Boundary Definitions in Climate Data Construction
To account for non-standard geographic boundary definitions, we use shapefiles that correpond to the geographic boundaries associated with the energy load data. To account for non-standard temporal definitions, we generate monthly climate data for affected regions in order to build years that correspond with the energy load data reporting period. 

### Non-Standard Year Definitions



### Non-Standard Geographic Boundary Defitions
Below I provide


- France includes Monaco
- Prior to 2012, Curacao energy load pertains to the former Netherland Antilles.
    - [shapefile]()
    - [cleaning code](https://gitlab.com/ClimateImpactLab/Impacts/energy-code-release/blob/master/0_make_dataset/climate/programs/clean_CUW_BES_ABW.do)
