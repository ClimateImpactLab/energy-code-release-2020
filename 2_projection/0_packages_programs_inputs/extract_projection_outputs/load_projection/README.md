# Query Projection Data 
Extract and load data using quantiles.py or load already extracted data from csvs. Currently the system is only set up to query median and delta method output... more functionality to come. 

## Necessary steps for using this system: 
1. Create a bash script similar to `example.sh`, which extracts a specific file specified by a set of parameters. Please reference `bash-extraction-script.md` for documentation on necessary syntax for creating a bash script which will integrate with the data querying code. 
2. Write necessary configs for all desired extraction calls from `quantiles.py` (a code in an external repo used for extracting quantiles across projection system outputs).
3. Add a get.*.code.paths() function to tell the querying system where your extraction bash script created in step 1 lives.
4. Source all functions in this directory.
5. Query Data - please reference `load-projection-parameters.md`. Also here's a code snippet for how to go about querying data:
```
projection.packages = {path_to_load_projection}

miceadds::source.all(paste0(projection.packages,"load_projection/"))
args <- list(
    conda_env = 'projection',
    proj_mode = '_dm', # '' and _dm are the two options
    region = "ARE.5", # needs to be specified for 
    rcp = NULL, 
    ssp = "SSP3", 
    price_scen = 'price014', # have this as NULL, "price014", "MERGEETL", ...
    unit =  "damage", # 'damagepc' ($ pc) 'impactpc' (kwh pc) 'damage' ($ pc)
    uncertainty = "values", # full, climate, values
    geo_level = "levels", # aggregated (ir agglomerations) or 'levels' (single irs)
    model = "TINV_clim_income_spline", # energy specific
    adapt_scen = "fulladapt", 
    clim_data = "GMFD", # energy specific
    iam = NULL,
    yearlist = as.character(seq(1980,2100,1)),  
    spec = "OTHERIND_total_energy",
    dollar_convert = "yes", 
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

### load_median.R - Query data from Medain Run

* *load.median.check.params()* - Check data query parameters are valid (always a work in progress :)
* *convert.to.2019* - changes means and variances from 2005 to 2019 dollars

### clean_data.R - Clean queried data

* *assign.names()* - based on data query and data frame add more variables to df to define what the contents of the data frame is
* *assign.names()* - based on data query and data frame add more variables to df to define what the contents of the data frame is

### get_paths.R - Functions for getting desired paths and file names from query}

* *get.energy.code.paths()* - get path to energy quantiles extraction shell
* *get.file.paths()* - Get relevant file paths for querying data
* *get.paths()* - Get relevant code and file paths 

### parse.R - Functions for parsing config and shell scripts to extract desired info about query

* *get.line.var()* - look through a specific string for a specific parameter's definition
* *get.file.var()* - Scroll through all lines of a file and get value of a specific variable defined at some point in the file
* *get.shell.file.parameters()* - Get list of parameters that need to be defined when calling extraction bash script as well as information about that parameter
    * this function relies on very specific syntax in the extraction bash script. I document the syntax specifics [here](https://gitlab.com/ClimateImpactLab/Impacts/gcp-energy/blob/simp_load_projection/rationalized/2_projection/2_processing/packages/load_projection/bash-extraction-script.md). 
* *parse.config.structure()* - Convert an extraction config's file-structure parameter to the file prefix outputted from the extraction config

### load_single.R - functions in this file are not ready from use... if you want to get it up and running [be my guest](https://www.youtube.com/watch?v=afzmwAKUppU)





