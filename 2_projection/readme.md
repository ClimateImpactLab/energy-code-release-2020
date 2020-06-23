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

