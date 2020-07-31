# Query Projection Output Data 

- The purpose of the codes in this directory is to extract and load projection system outputs. 
- The projection system outputs ncdf files, which are GCM specific. 
- In order to calculate quantiles and means of the impacts across these GCMs, we run a code called `quantiles.py` from the `open-estimate` repo (not currently released). This code outputs a csv of impacts, where the impacts are calculated as means or quantiles of the impacts from each of the GCMs.
- When running the `load.median()` function from this package, we: 
    - First check if the desired csv of quantiles of our impacts already exists.
    - If it does exist, we load it. 
    - If it doesn't exist, we run a wrapper for `quantiles.py` that extracts the desired output csv from the ncdf files, and the loads it.
- Please note, in order to extract the outputs, this package reads the necessary extraction configs in this repo, to work out which extraction command is needed for a given query. 
- Currently the system is only set up to query point estimate and delta method output (i.e. variance of projected impact estimates, see Appendix Section C.5). If you would like to query single run outputs, you will need to add more functionality.

## Necessary steps for using this system: 
1. Create a bash script similar to `example.sh`, which extracts a specific file specified by a set of parameters. Please reference `bash-extraction-script.md` for documentation on necessary syntax for creating a bash script which will integrate with the data querying code. Note - the bash script that is actually used in this code is in this folder and is called `extraction_quantiles.sh`.
2. Write necessary configs for all desired extraction calls from `quantiles.py` (a code in an external repo used for extracting quantiles across projection system outputs).
3. Add a get.*.code.paths() function to tell the querying system where your extraction bash script created in step 1 lives.
4. Source all functions in this directory.
5. Query Data - please reference `load-projection-parameters.md`. Also here's a code snippet for how to go about querying data:
```
projection.packages = {path_to_load_projection}

miceadds::source.all(paste0(projection.packages,"load_projection/"))
args <- list(
    conda_env = 'risingverse-py27', # your conda environment
    proj_mode = '_dm', # '' and _dm are the two options. Determines if we are extracting means(`''`) or variances (`'_dm'`)
    region = "ARE.5", # needs to be specified for delta method outputs. A region for which we have a projection result (can be an aggregated region)
    rcp = NULL, 
    ssp = "SSP3", 
    price_scen = 'price014', # have this as NULL, "price014", "MERGEETL", ...
    unit =  "damage", # 'damagepc' ($ pc) 'impactpc' (kwh pc) 'damage' ($ pc). Must be impactpc if price scenario is NULL
    uncertainty = "values", # full, climate, values
    geo_level = "levels", # aggregated (ir agglomerations such as countries or the "global" region) or 'levels' (single IRs)
    model = "TINV_clim", # energy specific
    adapt_scen = "fulladapt", # adaptation scenario - can be "fulladapt", "noadapt", or "incadapt"
    clim_data = "GMFD", # energy specific
    iam = "high",
    yearlist = as.character(seq(1980,2100,1)),  
    spec = "OTHERIND_total_energy",  # can be "OTHERIND_total_energy", "OTHERIND_electricity", or "OTHERIND_other_energy"
    dollar_convert = "yes", # determines whether to convert dollar outputs from 2005 USD to billions of 2019 USD.  
    grouping_test = "semi-parametric") # energy specific)

df = do.call(load.median, args)

```

For first time users, these are the functions I predict you will need to adapt to make sure they make sense for you sector as well as energy:
    * assign.names(), load.median.check.params() (this is not an all encompassing list... I'll add to it as I think of more things)

## Code Outline: 

### bash.R - Functions for interacting with extraction bash script from R

* *call.shell.script()* - Calls extraction shell script
* *check.memory()* - Kills process if there isn't enough available memory for the process to keep running
* *get.available.memory()* - Get available memory for use
* *get.process.memory.use()* - Get process memory use (in percent of total memory)
* *get.bash.parameters()* - Gets parameters ready for use in call.shell.script. Along the way, function checks to make sure parameter values are within the functionality of the extraction shell and required parameters have non-null non-blank values
* *extract()* - Perform extraction while monitoring memory use 
* *check.file.complete()* - Check to see if a file is complete based on time last touched

### load_median.R - Query data from Median Run

* *load.median.check.params()* - Check data query parameters are valid (always a work in progress :) - more should be added whenever anyone has time!)
* *load.median()* * - loads a csv of results if it exists, and if not, runs an extraction

### clean_data.R - Clean queried data

* *assign.names()* - based on data query and data frame add more variables to df to define what the contents of the data frame is
* *convert.to.2019* - changes means and variances from 2005 to 2019 dollars

### get_paths.R - Functions for getting desired paths and file names from query}

* *get.energy.code.paths()* - get path to energy quantiles extraction shell
* *get.file.paths()* - Get relevant file paths for querying data
* *get.paths()* - Get relevant code and file paths 

### parse.R - Functions for parsing config and shell scripts to extract desired info about query

* *get.line.var()* - look through a specific string for a specific parameter's definition
* *get.file.var()* - Scroll through all lines of a file and get value of a specific variable defined at some point in the file
* *get.shell.file.parameters()* - Get list of parameters that need to be defined when calling extraction bash script as well as information about that parameter
    * this function relies on very specific syntax in the extraction bash script. I document the syntax specifics [here](https://github.com/ClimateImpactLab/energy-code-release-2020/blob/projection/2_projection/0_packages_programs_inputs/extract_projection_outputs/load_projection/bash-extraction-script.md). 
* *parse.config.structure()* - Convert an extraction config's file-structure parameter to the file prefix outputted from the extraction config





