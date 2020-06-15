## Folder Structure

`0_utils` contains R functions that are sourced by other codes in this folder. 

`1_visualise_impacts` contains codes used to plot the projection system outputs that are displayed in the paper. 

`2_damage_function_estimation` contains codes used to prepare, run and plot empirical damage functions. See Appendix E for the theoretical details underpinning this process. The outputs of this code are damage function and quantile regression coefficients which are inputs to the SCC code. 

`3_SCC` calculates our partial social cost of carbon for energy consumption. See Appendix F for details on this calculation. 

More details of each sections inputs and outputs can be found in each of these subfolders. 

## Run instructions: 
* Codes in `0_utils` are not run directly, rather they are sourced by codes in the other folders. 
* For run instructions on the other codes in the other folders, see the readmes in those folders. 

## Naming conventions
- Three projection models were taken through the process of running projections, calculating damage functions, and calculating an SCC. We also ran a `single` projection for a further model. These models are: 
  - `main`. This refers to the main model present in our paper. See details of htis model in Appendix Section C.4. If a particular file or plot does not explicitly reference a model, or includes the string `"main"`, then that file refers to this model. 
  - `lininter`. This model is an extension of our main model to include a linear inteaction with time. More details of this model can be found in Appendix Section I.3. 
  - `lininter_double`. This model deterministically doubles the time trend present estimated in the `lininter` model. More details can be found in Appendix Section I.3.  
  - `SA` refers to a slow-adaptation scenario, in which we halve the rate of income and climate adaptation. More details can be found in Appendix section 

## Guide to data used in this process

Data used in code housed in `/3_post_projection/` is stored in an external location (currently `/{synology}/GCP_Reanalysis/ENERGY/code_release_data/projection_system_outputs`). This is intermediate data, that was produced and extracted using the projection system.

The data in this location includes: 
- ***Time series data***, 
  - These data are contained in `/projection_system_outputs/time_series_data/`
  - These csv files contain globally aggrgeated time series of our projected impacts due to climate change. Unless otherwise stated, these time series reflect the (weighted) mean values of impacts across the 33 GCMs for which we project temperatures. 
  - Files under the `/CCSM4/` folder are time series for a single run, in which the temperature data reflects only the CCSM4 climate data model, rather than taking a mean across all 33 climate models. We did this due to computational constraints. 
  - Naming convention for these files: 
    - `{model}-{fuel}-{ssp}-{rcp}-{iam}-{adapt_scenario}-{price_scenario}`. When impacts are in Gigajoules rather than in dollars, we name the price scenario as `impact_pc`. Otherwise, the units are billions of 2019 USD, and are not per capita. 
    - `model` refers to the type of model we project (ie main, lininter, or lininter_double). 
    - `fuel` is either electricity, other_energy, or total_energy. 
    - `ssp` is the Shared Socioeconomic Pathway scenario, and can be either SSP2, SSP3 or SSP4. 
    - `rcp` is the representative concentration pathway, and can be rcp45 or rcp85.
    - `iam` refers to the gdp and population growth scenarios, and can either be high or low. 
    - `adapt_scenario` refers to the extent to which we allow response functions to change over time in response to changes in income and climate. In the "full_adapt" adaptation scenario, we allow agent's sensitivity to weather to change flexibly over time as their income and climate changes. In the "no_adapt" scenario, we fix agents' sensitivity to income and climate at their 2015 levels. 
    - price_scenario refers to the pricing we apply to convert impacts into dollars. See Appendix G.1 for more details. 
- ***Mapping data***
  - These data are contained in  `/projection_system_outputs/mapping_data/`
  - All files in this folder are from the main model, and reflect the mean impact across all climate models.
  - The values in these csvs are impact region level impacts.
  - Naming convention for these files: 
    - {model}-{fuel}-{ssp}-{rcp}-{iam}-{adapt_scenario}-{price_scen}-{year}-map
    - Variables in the names of the map data are defined as above, except that we include a `year`, since the map data is only for a given year. 
- ***GCM level impacts data***
  - These data are contained in  `/projection_system_outputs/IR_GCM_level_impacts/`
  - Data in this file reflects the damages projected for each of our GCMs for selected impact regions. The file has the same naming convention as above.
- ***Covariates data***
  - These data are contained in  `/projection_system_outputs/covariates/`
  - `SSP3-global-gdp-time_series.csv` contains a time series of global projected gdp values under the SSP3 scenario. 
  - `SSP3-high-IR_level-gdppc_pop-2099.csv` contains impact region level gdp, population and gdp per capita data for the year 2099, under the SSP3 scenario. 
  - `SSP3-high-IR_level-gdppc-pop-2012.csv` contains impact region level gdp, population and gdp per capita data for the year 2012, under the SSP3 scenario. 
  - `SSP3_IR_level_population.csv` contains impact region level population values for all years, under the SSP3 scenario.
  - `covariates-SSP3-rcp85-high-2010_2090-CCSM4.csv` contains HDD, CDD, log-gdppc and population values under the SSP3-rcp85-high scenario, where the HDD and CDD values are calculated from only the CCSM4 climate model. 
- ***Damage function estimation data***
  - For more details on data stored in `/projection_system_outputs/damage_function_estimation/`, please see the documentation in  `/2_damage_function_estimation/`. 


    
