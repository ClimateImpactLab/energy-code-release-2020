## Folder Structure

`0_utils` contains R functions that are sourced by other codes in this folder. 

`1_visualise_impacts` contains codes used to plot the projection system outputs that are displayed in the paper. 

`2_damage_function_estimation` contains codes used to prepare, run and plot empirical damage functions. See Methods and Appendix E for the details underpinning this process. The outputs of this code are damage function and quantile regression coefficients which are inputs to the SCC and SCC uncertainty code. 

`3_SCC` calculates our partial social cost of carbon for energy consumption. See Methods and Appendix F for details on this calculation. 

More details of each sections inputs and outputs can be found in each of these subfolders. 

## Run instructions: 
* Codes in `0_utils` are not run directly, rather they are sourced by codes in the other folders. 
* For run instructions on the other codes in the other folders, see the readmes in those folders. 

## Naming conventions
- Three sets of empirical estimates were taken through the process of running projections, calculating damage functions, and calculating an SCC. These are: 
  - `main`. This refers to the main econometric model present in our paper. See details of this model in Appendix Section C.3. If a particular file or plot does not explicitly reference a model, or includes the string `"main"`, then that file refers to this model. 
  - `lininter`. This model is an extension of our main econometric model to include a linear inteaction with time. More details of this model can be found in Appendix Section I.3. 
  - `lininter_double`. This model deterministically doubles the time trend estimated in the `lininter` model. More details can be found in Appendix Section I.3.  
  - `lininter_half`. This model deterministically halves the time trend estimated in the `lininter` model.  
  We also took the following set of estimates through a `single` projection (i.e. one that relies on future climate projections from a single GCM): 
  - `SA`, which refers to a slow-adaptation scenario, where we deterministically halve the rates of income and climate adaptation estimated in the `main` model. More details can be found in Appendix Section I.1.

## Guide to data used in this process

Data used in code housed in `/3_post_projection/` are stored in an external location (currently `/{synology}/CIL_energy/code_release_data_pixel_interaction/projection_system_outputs`). This is intermediate data, that was produced and extracted using the projection system.

The data in this location include: 
- ***Time series data***, 
  - These data are contained in `/projection_system_outputs/time_series_data/`
  - These csv files contain globally aggrgeated time series of our projected impacts due to climate change. Unless otherwise stated, these time series reflect the (weighted) mean values of impacts across the 33 climate projections in the SMME (See Methods and Appendix Secton A.2).  
  - Files under the `/CCSM4/` folder contain time series of projected impacts using climate projections from a single climate model (CCSM4). 
  - Naming convention for these files: 
    - `{model}-{fuel}-{ssp}-{rcp}-{iam}-{adapt_scenario}-{price_scenario}`.
    - `model` refers to the type of model we project (ie main, lininter, lininter_double, or lininter_half). 
    - `fuel` is either electricity, other_energy, or total_energy. 
    - `ssp` is the Shared Socioeconomic Pathway scenario, and can be either SSP2, SSP3 or SSP4. (See Appendix Section A.3.2)
    - `rcp` is the representative concentration pathway, and can be rcp45 or rcp85.
    - `iam` refers to the gdp and population growth scenarios, and can either be high (referring to the scenario from the OECD Env-Growth model) or low (referring to the scenario from the IIASA). See Appendix Section A.3.2.
    - `adapt_scenario` refers to the extent to which we allow response functions to change over time in response to changes in income and climate. In the "full_adapt" adaptation scenario, we allow agent's sensitivity to weather to change flexibly over time as their income and climate changes. In the "no_adapt" scenario, we fix agents' sensitivity to income and climate at their 2015 levels. 
    - price_scenario refers to the pricing we apply to convert impacts into dollars. See Appendix D for more details. When impacts are in Gigajoules per capita, we name the price scenario as `impact_pc`. Otherwise, the units are billions of 2019 USD, and are not per capita. 
- ***Mapping data***
  - These data are contained in  `/projection_system_outputs/mapping_data/`
  - All files in this folder are from the main model, and reflect the mean impact across all 33 climate projections in the SMME.
  - The values in these csvs are impact region-level impacts.
  - Naming convention for these files: 
    - {model}-{fuel}-{ssp}-{rcp}-{iam}-{adapt_scenario}-{price_scenario}-{year}-map
    - Variables in the names of the map data are defined as above, except that we include a `year`, since the map data is only for a given year. 
- ***Impacts data (under individual climate projections)***
  - These data are contained in  `/projection_system_outputs/IR_GCM_level_impacts/`
  - Data in this file reflect the damages projected under each of the 33 climate projections in the SMME for selected impact regions. The file has the same naming convention as above.
- ***Covariates data***
  - These data are contained in  `/projection_system_outputs/covariates/`
  - `SSP3-global-gdp-time_series.csv` contains a time series of global projected gdp values under the SSP3 socioeconomic scenario. 
  - `SSP3-high-IR_level-gdppc_pop-2099.csv` contains impact region-level gdp, population and gdp per capita data for the year 2099, under the SSP3 scenario. 
  - `SSP3-high-IR_level-gdppc-pop-2012.csv` contains impact region-level gdp, population and gdp per capita data for the year 2012, under the SSP3 scenario. 
  - `SSP3_IR_level_population.csv` contains impact region level population values for all years, under the SSP3 scenario.
  - `covariates-SSP3-rcp85-high-2010_2090-CCSM4.csv` contains HDD, CDD, log-gdppc and population values under the SSP3-rcp85-high scenario, where the HDD and CDD values are calculated from only the CCSM4 climate model. 
- ***Damage function estimation data***
  - For more details on data stored in `/projection_system_outputs/damage_function_estimation/`, please see the documentation in  `/2_damage_function_estimation/`. 


    
