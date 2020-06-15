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
- Time series data. 
  - These csv files contain globally aggrgeated time series of our projected impacts due to climate change. Unless otherwise stated, these time series reflect the (weighted) mean values of impacts across the 33 GCMs for which we project temperatures. 
  - Files under the `CCSM4
