# PLEASE READ - note for ashwin / rae - to be updated, and this header and it's below bullet points to be deleted eventually
- Currently, the csvv writer will write a csvv using the ster files generated in this repo. 
  - This means that the units of the csvv are in GJ - which is the units of the plots and analysis in the paper. 
  - However, the units we actually ran all our projections in is KWh. To convert between them, multiply KWh impacts by 0.0036.
  - Also, the name of the csvvs that this writer produces are not the same as the name of the csvvs we actually used to run our projections. 
    - This means that the names of the output files that would be produced if you ran a projection using this csvv are different from the names of the projection files that we actually produced
    
- All other codes in this directory, on the other hand, ***do*** reflect the way we actually ran projections. 
  - So, for example, the config writer produces the actual configs we used to run projections (but it outputs them to this repo, rather than to the gcp-energy repo). 
  - This means that those configs point to paths on our own servers - not to the eventual paths that a user would want to . 
  - It also means that they point the csvvs (held on sac) that we actually used to run projections, which have units in Kwh rather than GJ.
  - Similarly, the extraction codes in this repo, and the `load_projection` package will extract from files that are on our servers. 
  - If we move these files to a public repository, we should redirect these codes to point to this public repository eventually. 
  - This will also require updates to the config writer - and the codes used for post-projection extraction  so that the paths in those configs and codes point to wherever the output is stored. 

## User suitability 

- ***Please note - the code in `2_projection` does not need to be run in order for a user to work with codes later in the process.
We have included the outputs of this projection step as csv files in the data repository associated with this repo***
- Running projection codes is highly computationally intensive - and should only be done on a server (it would probably take months on a laptop - it takes weeks on out powerful Climate Impact Lab servers)
- If attempting to run a projection - you will need to follow some extensive set up instructions, and have access to all projection system data (this isn't currently saved in the
code release data repository). You will also need to modify the codes in this folder to reflect the paths and set up on your server.

## Overview

Codes in this repo show users how we complete three types of projection related tasks: 

### 1. Prepare projection system input files.
- We convert regression coeffiecients saved in stata .ster files into `csvv` files which are the input to our projection system. 
- We generate and save the configuration files that are used to run projections.
- We provide some example commands for how a projection is run. Note - these commands require access to three external repos, which are not currently public. 
  - ***This should be updated in the future when James has moved all code to github***

### 2. Run projections
- We provide examples of how to run a projection. This requires some extensive set up and computational resources, and is probably not suitable for most users. 

### 3. Extract projection  outputs
- We provide code that converts the projection system outputs from it's native format (netcdf files) into the csv files that are used in later analysis. 

