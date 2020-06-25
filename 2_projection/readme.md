# PLEASE READ - note for ashwin / rae - to be updated, and this header and it's below bullet points to be deleted eventually
- Currently, the csvv writer will write a csvv using the ster files generated in this repo. 
  - This means that the units of the csvv are in GJ - which is the units of the plots and analysis in the paper. 
  - However, the units we actually ran all our projections in is KWh. So the CSVV on the server are in that unit . 
  - The csvvs are outputted here in this repo:
    - `energy-code-release-2020/projection_inputs/csvv/`
  - And the versions on the server are here: 
    - `/shares/gcp/social/parameters/energy/incspline0719/GMFD/` 
  - To convert between them, multiply KWh coefficients by 0.0036 (or 0.0036^2 for values in the vcv).
  - Also, the name of the csvvs that this writer produces are not the same as the name of the csvvs we actually used to run our projections. 
    - This means that the names of the output files that would be produced if you ran a projection using this csvv are different from the names of the projection files that we actually produced (since the projection system outputs files with the same name as the csvv).
  - This is because the code release repos uses a simplified naming scheme. 
  - Ie - we refer to:
    - `TINV_clim_income_spline` as `TINV_clim`
    - `TINV_clim_income_spline_lininter` as `TINV_clim_lininter`
    - `TINV_clim_income_spline_lininter_double` as `TINV_clim_lininter_double`

- All other codes in this directory, on the other hand, ***do*** reflect the way we actually ran projections. 
  - So, for example, the config writer produces the actual configs we used to run projections (but it outputs them to this repo, rather than to the gcp-energy repo). 
  - This means that those configs point to paths on our own servers - not to the eventual paths that a user would want to . 
  - It also means that they point the csvvs (held on sac) that we actually used to run projections, which have units in Kwh rather than GJ.
  - Similarly, the extraction codes in this repo, and the `load_projection` package will extract from files that are on our servers. 
  - If we move these files to a public repository, we should redirect these codes to point to this public repository eventually (and to whatever our final projection results are). 
  - This will also require updates to the config writer - and the codes used for post-projection extraction so that the paths in those configs and codes point to wherever the output is stored. 
  - Since the `load_projection` depends on the configs (ie it reads the config files to work out where a given projection output lives), load_projection will also need tweaking
if we end up changing the configs.

- To use the config writer to point to csvs in this repo, you will need to:
  - Update it so that it pops out module configs that are pointing to the csvv you produced using this repo, rather than the one currently on the server. This should be easy - it's an option you pass into the code (csvv_location).
  - ***Update any logic in the `write_projection_file.do` config writer that depends on the name of the model or csvv***. This might take a bit of work - there is quite a bit of logic that depends on 
 the name of the model including the string "income_spline". So if the model name changes, then the logic will need to be changed. 
    - Since the name of the models we use in this repo don't include income_spline, even running a projection from this repo using a csvv
 generated in this repo (ie the main model, which has the name "TINV_clim" here rather than "TINV_clim_income_spline") will require some changs to that logic).
 
 - Note - if you change the existing configs (specifically the extraction configs), then `load_projection` won't work on the current set of projection results on sac. 

- Note for aggregation: price units are currently in $/Kwh. Change this (by either updating the price files, or by pointing the aggregation configs to new price files) if you run a projection 
in units of GJ rather than KWh. The files in the code release data (stored here `/mnt/norgay_synology_drive/GCP_Reanalysis/ENERGY/code_release_data/price_scenarios` are in $/GJ, so you could just update the configs to point to here. 

# End of stuff that's just a message for Ashwin / Rae
  
## User suitability 

- ***Please note - the code in `2_projection` does not need to be run in order for a user to work with codes later in the process.
We have included the outputs of this projection step as csv files in the data repository associated with this repo***
- Running projection codes is highly computationally intensive - and should only be done on a server (it would probably take months on a laptop - it takes weeks on out powerful Climate Impact Lab servers). It also generates many TB of data, so be prepared to have access to large amounts of storage. 
- If attempting to run a projection - you will need to follow some extensive set up instructions, and have access to all projection system data (this isn't currently saved in the
code release data repository). You will also need to modify the codes in this folder to reflect the paths and set up on your server.

## Overview

Codes in this repo show users how we complete three types of projection related tasks. See notes inside each subfolder for more details on each part of the process, and some run instructions. 

### 1. Prepare projection system input files.
- We convert regression coeffiecients saved in stata .ster files into `csvv` files which are the input to our projection system. 
- We generate and save the configuration files that are used to run projections.
- We provide some example commands for how a projection is run. Note - these commands require access to three external repos, which are not currently public. 
  - ***This should be updated in the future when James has moved all code to github***

### 2. Run projections
- We provide examples of how to run a projection. This requires some extensive set up and computational resources, and is probably not suitable for most users. 

### 3. Extract projection outputs
- We provide code that converts the projection system outputs from it's native format (netcdf files) into the csv files that are used in later analysis. 



