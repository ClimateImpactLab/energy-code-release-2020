## User suitability 

- ***Please note - the code in `2_projection` does not need to be run in order for a user to work with codes later in the process.
We have included the outputs of this projection step as csv files in the data repository associated with this repo***
- Running a full projection over all climate model, gdp growth model, all SSPs, all fuels is highly computationally intensive - and should only be done on a server (it would probably take months on a laptop - it takes weeks on out powerful Climate Impact Lab servers). It also generates many TB of data.
- So instead, we've provided a limited dataset that allows you to run a single projection without uncertainties that projects future electricity usage for CCSM4 climate model, SSP3, OECD gdp growth model.

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
- We provide code that converts the projection system outputs from their native format (netcdf files) into the csv files that are used in later analysis. 



