# Climate Data Construction

[//]: # (Github doesn't support inline maths, so i used this website to generate links that render as maths: https://www.codecogs.com/latex/eqneditor.php)

As described in Appendix A.2.4, we link GMFD gridded daily historical climate data to country-year-level energy consumption data by aggregating daily grid cell 
information to the country year level. Nonlinear transformations of temperature and rainfall are computed at the grid cell level before averaging values 
across space using population weights and finally summing over days within a year. 
This procedure recovers grid-by-day-level nonlinearities in the energy-temperature (and energy-precipitation) 
relationship, because energy consumption is additive across time and space.

The IEA dataset documentation describes that some energy consumption observations are reported on non-standard year definitions and for non-standard geographic regions. 
We account for these two types of energy consumption data features by constructing country x year climate data variables which align with the geographic and temporal 
definitions baked into each energy consumption observation. For example:
* We construct yearly Australian climate data with the following definition of year: July t to June t + 1.  
* We use a shapefile for Italy which includes San Marino and the Holy See.
Please reference this [readme](https://github.com/ClimateImpactLab/energy-code-release-2020/tree/master/0_make_dataset/coded_issues) 
for more information about the IEA dataset documentation and how we incorporated it into our analysis.

The code and shapefiles in this directory demonstrate how we construct our climated data, accounting for non-standard definitions of country boundaries and years
when aggregating and compiling aggregated daily gridded climate data.

## Directory Contents

`programs` - stata programs for cleaning shapefile specific aggregated climate data
* contribution: complete shapefile specific aggregated climate data cleaning, accounting for non-standard year definitions in particular regions for specific periods

`shapefiles` - the shapefiles we use to construct country level climate data from gridded climate data 
* contribution: aggregate climate data into regions which correspond to the regions in the IEA energy consumption dataset

`1_clean_climate_data.do` - the master program
* contribution: assemble a country x year panel dataset with temporally and spatially aggregated climate data that corresponds 
* to definitions of space and time in each energy consumption observation.

## Definitions of the Climate Variables we use in our analysis: 

Below we describe the climate variable transformations we perform at the grid cell level and each transformations variable name in the country x year climate dataset. 

* temp1_GMFD, temp2_GMFD, temp3_GMFD, and temp4_GMFD
    * These variables are polynomials of the daily average temperature. For example, temp2_GMFD is a pop-weighted average 
    of a second order polynomial of pixel level daily average temperature for a given country summed to the year.
    * These variables constitute the elements of the vector <a href="https://www.codecogs.com/eqnedit.php?latex=\boldsymbol{T}_{jt}" target="_blank"><img src="https://latex.codecogs.com/gif.latex?\boldsymbol{T}_{jt}" title="\boldsymbol{T}_{jt}" /></a>  for country <a href="https://www.codecogs.com/eqnedit.php?latex=j" target="_blank"><img src="https://latex.codecogs.com/gif.latex?j" title="j" /></a>, year <a href="https://www.codecogs.com/eqnedit.php?latex=t" target="_blank"><img src="https://latex.codecogs.com/gif.latex?t" title="t" /></a> (*Appendix* A.2.4; C.1).
* precip1_GMFD, precip2_GMFD
    * Similarly, these terms are polynomials of precipitation. They constitute the elements of the vector <a href="https://www.codecogs.com/eqnedit.php?latex=\boldsymbol{P}_{jt}" target="_blank"><img src="https://latex.codecogs.com/gif.latex?\boldsymbol{P}_{jt}" title="\boldsymbol{P}_{jt}" /></a>(*Appendix* A.2.4; C.1).
* polyAbove1_GMFD, polyAbove2_GMFD
    *  These terms are respectively <a href="https://www.codecogs.com/eqnedit.php?latex=\sum_{d&space;\in&space;t}(T_{jd}-20)\mathbf{I}_{T_{jd}\geq20}" target="_blank"><img src="https://latex.codecogs.com/gif.latex?\sum_{d&space;\in&space;t}(T_{jd}-20)\mathbf{I}_{T_{jd}\geq20}" title="\sum_{d \in t}(T_{jd}-20)\mathbf{I}_{T_{jd}\geq20}" /></a> and <a href="https://www.codecogs.com/eqnedit.php?latex=\sum_{d&space;\in&space;t}(T^{2}_{jd}-20^{2})\mathbf{I}_{T_{jd}\geq20}" target="_blank"><img src="https://latex.codecogs.com/gif.latex?\sum_{d&space;\in&space;t}(T^{2}_{jd}-20^{2})\mathbf{I}_{T_{jd}\geq20}" title="\sum_{d \in t}(T^{2}_{jd}-20^{2})\mathbf{I}_{T_{jd}\geq20}" /></a> from Appendix Equation C.4.
* polyBelow1_GMFD, polyBelow2_GMFD
    *  These terms are respectively <a href="https://www.codecogs.com/eqnedit.php?latex=\sum_{d&space;\in&space;t}(20-T_{jd})\mathbf{I}_{T_{jd}<20}" target="_blank"><img src="https://latex.codecogs.com/gif.latex?\sum_{d&space;\in&space;t}(20-T_{jd})\mathbf{I}_{T_{jd}<20}" title="\sum_{d \in t}(20-T_{jd})\mathbf{I}_{T_{jd}<20}" /></a> and <a href="https://www.codecogs.com/eqnedit.php?latex=\sum_{d&space;\in&space;t}(20^{2}-T^{2}_{jd})\mathbf{I}_{T_{jd}<20}" target="_blank"><img src="https://latex.codecogs.com/gif.latex?\sum_{d&space;\in&space;t}(20^{2}-T^{2}_{jd})\mathbf{I}_{T_{jd}<20}" title="\sum_{d \in t}(20^{2}-T^{2}_{jd})\mathbf{I}_{T_{jd}<20}" /></a> from Appendix Equation C.4
* cdd20_GMFD
    * cooling degree days (*Appendix* C.3)
* hdd20_GMFD
    * heating degree days (*Appendix* C.3)

Note: the `*_other*` tag in climate data variable names denotes climate data that will be assigned to other fuel final energy consumption. 
Some encoded issues differ by product for a specific temporal or spatial definition, thus we need to differentiate climate data by product. 
The Moldova case outlined below is an example of where climate data differs by fuel.

## How we account for Non-Standard Year and Geographic Boundary Definitions in Climate Data Construction
To account for non-standard geographic boundary definitions, we use shapefiles that correpond to the geographic boundaries associated with the energy consumption data. 
To account for non-standard temporal definitions, we generate monthly climate data for affected regions in order to build years that correspond with the energy 
consumption data reporting period. Below, we outline the non-standard spatial and temporal definitions we account for in our analysis. 
Additionally, we describe which shape files and pieces of code account for these non-standard definitions.

### Non-Standard Year Definitions

The shapefile specific programs below construct yearly climate data for specific countries and time periods based on the following year definitions: 

* [programs/clean_WORLD.do](https://github.com/ClimateImpactLab/energy-code-release-2020/blob/master/0_make_dataset/climate/programs/clean_WORLD.do)
    * JPN: From 1990, data are reported on a fiscal year basis (e.g. April 2015 to March 2016 for 2015).
    * AUS: All data refer to the fiscal year (e.g. July 2014 to June 2015 for 2015)
    * BGD: Data are reported on a fiscal year basis, beginning on 1 July and ending on 30 June of the subsequent year.
    * EGY: Data are reported on a fiscal year basis. Data for 2015 correspond to 1 July 2015-30 June 2016
    * ETH: Data are reported according to the Ethiopian financial year, which runs from 1 July to 30 June of the next year
    * IND: Data are reported on a fiscal year basis. Data for 2015 correspond to 1 April 2015 – 30 March 2016
    * IRN: Data for 2015 correspond to 20 March 2015 19 March 2016, which is Iranian year 1394
    * NPL: Data are reported on a fiscal year basis, beginning on 1 July and ending on 30 June of the subsequent year 2015/16 is treated as 2015
    * NZL: Prior to 1994, data refer to fiscal year (April 1993 to March 1994 for 1993). From 1994, data refer to calendar year.
    * KEN: As of 2001, electricity data are reported on a fiscal year basis, beginning on 1 July and ending on 30 June of the subsequent year.
    * MMR: Some data are reported on a fiscal year basis. Since we do not know which years, we cannot match climate data to MMR, and therefore do not include it in our analysis.

* [programs/clean_WORLDpre.do](https://github.com/ClimateImpactLab/energy-code-release-2020/blob/master/0_make_dataset/climate/programs/clean_WORLDpre.do)
    * ETH: Data are reported according to the Ethiopian financial year, which runs from 1 July to 30 June of the next year.

### Non-Standard Geographic Boundary Definitions

The shapefile specific programs below clean yearly climate data for specific countries and time periods based on the following country definitions. Shapefiles used in the analysis are stored in the external data repository, under `/code_release_data_pixel_interaction/shapefiles`

* [programs/clean_CUW_BES_ABW.do](https://github.com/ClimateImpactLab/energy-code-release-2020/blob/master/0_make_dataset/climate/programs/clean_CUW_BES_ABW.do):
    * Prior to 2012, Curaçao data cover the entire territory of the former Netherland Antilles
    * `shapefiles/CUW_BES_ABW`
* [programs/clean_FRA_MCO.do](https://github.com/ClimateImpactLab/energy-code-release-2020/blob/master/0_make_dataset/climate/programs/clean_FRA_MCO.do):
    * France data includes Monaco
    * `shapefiles/FRA_MCO`
* [programs/clean_ISR_PSE.do](https://github.com/ClimateImpactLab/energy-code-release-2020/blob/master/0_make_dataset/climate/programs/clean_ISR_PSE.do):
    * Israel data includes Palestine 
    * `shapefiles/ISR_PSE`
    * Note from documentation: The statistical data for Israel are supplied by and under the responsibility of the relevant Israeli authorities. The use of such data by the OECD is without prejudice to the status of the Golan Heights, East Jerusalem and Israeli settlements in the West Bank under the terms of international law
* [programs/clean_ITA_SMR_VAT.do](https://github.com/ClimateImpactLab/energy-code-release-2020/blob/master/0_make_dataset/climate/programs/clean_ITA_SMR_VAT.do):
    * Italy data includes San Marino and the Holy See
    * `shapefiles/ITA_SMR_VAT`
* [programs/clean_MDA_other.do](https://github.com/ClimateImpactLab/energy-code-release-2020/blob/master/0_make_dataset/climate/programs/clean_MDA_other.do):
    * For Moldova, official figures on natural gas imports, natural gas inputs to power plants, electricity production and consumption are modified by the IEA Secretariat to include estimates for supply and demand for the autonomous region of Stînga Nistrului (also known as the Pridnestrovian Moldavian Republic or Transnistria). 
    * Other energy production or consumption from this region is not included in the Moldovan data.
    * `shapefiles/MDA_other`
* [programs/clean_SRB_MNE.do](https://github.com/ClimateImpactLab/energy-code-release-2020/blob/master/0_make_dataset/climate/programs/clean_SRB_MNE.do):
    * Serbia data includes Montenegro and only Montenegro from 1999 to 2004
    * `shapefiles/SRB_MNE`
* [programs/clean_SRB_MNE_XKO.do](https://github.com/ClimateImpactLab/energy-code-release-2020/blob/master/0_make_dataset/climate/programs/clean_SRB_MNE_XKO.do):
    * Serbia data includes Montenegro and Kossovo from 1990 to 1999
    * `shapefiles/SRB_MNE_XKO`
* [programs/clean_WORLDpre.do](https://github.com/ClimateImpactLab/energy-code-release-2020/blob/master/0_make_dataset/climate/programs/clean_WORLDpre.do):
    * Data for South Sudan are available from 2012. Prior to 2012, they are included in Sudan
    * Prior to 1992, ERI included in Ethiopia
    * Countries in former soviet union pre 1990: AZE, BLR, KAZ, KGZ, LVA, LTU, MDA, RUS, TJK, TKM, UKR, UZB, ARM, EST, GEO
    * Countries in former Yugoslavia pre 1990: HRV, MKD, MNE, SRB, SVN, BIH, XKO
    * `shapefiles/WORLDpre`

## Standard Country Boundary Definitions

We rely on `shapefiles/WORLD` for country boundary definitions and clean the aggregated climate data with [programs/clean_WORLD.do](https://github.com/ClimateImpactLab/energy-code-release-2020/blob/master/0_make_dataset/climate/programs/clean_WORLD.do).
