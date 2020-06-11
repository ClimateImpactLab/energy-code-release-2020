## Folder Structure

`0_utils` contains R functions that are sourced by other codes in this folder. 

`1_visualise_impacts` contains codes used to plot the projection system outputs that are displayed in the paper. 

`2_damage_function_estimation` contains codes used to prepare, run and plot empirical damage functions. See Appendix E for the theoretical details underpinning this process. The outputs of this code are damage function and quantile regression coefficients which are inputs to the SCC code. 

`3_SCC` calculates our partial social cost of carbon for energy consumption. See Appendix F for details on this calculation. 

## Run instructions: 
* Codes in `0_utils` are not run directly, rather they are sourced by codes in the other folders. 
* For run instructions on the other codes in the other folders, see the readmes in those folders. 
