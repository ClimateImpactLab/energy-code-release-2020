# How to set up a bash extraction script that agrees with the data querying system

#### 0) Checkout [example.sh](https://github.com/ClimateImpactLab/energy-code-release-2020/blob/projection/2_projection/0_packages_programs_inputs/extract_projection_outputs/load_projection/example.sh)
This file extracts a specific file or set of files specified by a set of parameters. Some of the syntax used in this script is not arbitrary and essential to the functionality of the querying code. I try to flag the important syntax below and explain the reasoning behind it. Also to better understand how to set this script up and the configs that it references checkout [prospectus-tools](https://github.com/jrising/prospectus-tools/tree/master/gcp/extract).

#### 1) Essential syntax to note (obviously if you think of a more simplified way of doing this improve it!)

##### a) the extract boolean is an essential parameter and its functionality must be replicated
why you might ask: currently the code uses the bash script in two ways
* its used to get file path information (config path, log file, and the queried data's file suffix (present or future))
    * the config path is necessary to get the queried data's file prefix (present or future)
    * the log file is usefule in monitoring extraction progress if extraction is necessary
    * the file suffix is necessary for seeing if the file already exists, so the code can determine if extraction is necessary
    * checkout [get.file.paths()](https://github.com/ClimateImpactLab/energy-code-release-2020/blob/projection/2_projection/0_packages_programs_inputs/extract_projection_outputs/load_projection/get_paths.R) to better understand why this functionality is important
* its also used to extract files if necessary

##### b) parameters are defined in a very specific way... copy this syntax

For example, this line defines the model parameter. The slashes (`/`) indicate the start and stop of a definition. The colons (`:`) seperate the definition type from the definition value. 
```
## / parameter:model / options:TINV_clim, TINV_clim_lininter / required:yes /
```
Each parameter the bash extraction script has functionality for should be documented in the file in this way.
why you might ask (...inquisitive bunch): 
* to confirm the bash script is being fed the right parameters, the script checks to make sure you are feedint the script all the required parameters and that all of the parameters' values are supported by the script.
* checkout [get.shell.file.parameters()](https://github.com/ClimateImpactLab/energy-code-release-2020/blob/projection/2_projection/0_packages_programs_inputs/extract_projection_outputs/load_projection/parse.R) and [get.bash.parameters()](https://github.com/ClimateImpactLab/energy-code-release-2020/blob/projection/2_projection/0_packages_programs_inputs/extract_projection_outputs/load_projection/bash.R) to understand the ins and outs of why this specific syntax is necessary for the current code's status.

##### c) the following four lines of code are necessary

```
echo "extraction.config:${ecp}"
echo "suffix:${suffix}"
echo "log.file:${log_file}"
```
and, at the bottom of the script in the extraction conditional
```
echo "pid:$!"
```
why you might ask? ...this one i'll let you figure out. Here are two hints [get.file.paths()](https://github.com/ClimateImpactLab/energy-code-release-2020/blob/projection/2_projection/0_packages_programs_inputs/extract_projection_outputs/load_projection/get_paths.R) and [extract()](https://github.com/ClimateImpactLab/energy-code-release-2020/blob/projection/2_projection/0_packages_programs_inputs/extract_projection_outputs/load_projection/bash.R)


