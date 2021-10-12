# Note to ashwin and rae - change out the configs here to whatever are used in the final version. 

# Overview

- In this folder, we briefly describe how we run projections. 
- Please note, running a projection is ***highly computationally intensive***. This is probably not suitable for most users. 
- By "running a projection" we mean running codes that convert our econometric response estimates into projections of the impact of climate change on energy consumption. 

# Prerequisites
- In order to run and process projections, you will need to have access to four additional git repos; `impact-calculations`, `open-estimate`, `impact-common`, and `prospectus-tools`. Please see documentationn in those repos for instructions for loading and using those codes. 
- To run projections, you will also need access to two conda environments: 
  - `risingverse`: a python 3 conda environment used for running and aggregating projections (where aggregation refers to conversion of impacts into units of dollars rather than energy consumption per capita, for a range of pricing scenarios, and aggregating across space to get global time series of impacts). See [here](https://github.com/ClimateImpactLab/risingverse) for install instructions
  - `risingverse-py27`: a python 2 conda environment used for extracting projection system outputs. See [here](https://github.com/ClimateImpactLab/risingverse-py27) for install instructions. 
    - By "extraction", we mean converting our climate model specific projection `.ncdf` outputs into `.csv` files containing means and quantiles of the impacts across these climate model specific projections. 
- You will also need access to the climate and socioeconomic data used by the projection system. 
- Finally, you will need to have used the config writer `2_projection/1_prepare_projection_files/2_generate_projection_configs.do`, and made sure that the configs produced reflect the set up on your server. 

# Run instructions

## Running a projection
To run a projection (after following set up instructions in the `impact-calculations` repo) run this bash command from within the `impact-calculations` repo: 
```
./generate.sh {path_to_config}/{run_config_name} {number of threads}
```
This will then begin running a projection for the specification determined by the run config, and the associated module config. The `{number of threads}` variable should be replaced by a scalar (e.g. 20) which determines how many processes will be run in parallel. Note, each process takes around 4GB of memory for a point estimate run (i.e. for calculating central estimates of impacts), and around 8GB of memory for a delta method run (i.e. for calculating variances of impacts). This might limit the amount of processes you are able to run in parallel. Each process works on a directory, one at a time, where a directory is defined by an `SSP-rcp-iam-gcm` combination (i.e. combination of Shared Socioeconomic Pathway (ssp), emissions trajectory (rcp), population/income scenario (iam), and one of 33 climate projections (gcm)). 

For example, to run a projection for SSP3, for a point estimate for our main econometric specification, with 40 processes running in parallel at the same time, the command to run would be (if you are running it on the CIL "sacagawea" server: 

```
./generate.sh {your path}/energy-code-release-2020/projection_inputs/configs/GMFD/TINV_clim/break2_Exclude/semi-parametric/Projection_Configs/sacagawea/run/median/energy-median-hddcddspline_OTHERIND_electricity.yml  40
```

## Running the projections presented in the paper

In the paper, we include the following set of projections, all of which require running projections separately for electricity consumption and other fuels consumption impacts. In this section we present the commands needed to run these projections, assuming that you are running them with access to our CIL "sacagawea' servers and are running 30 processes at a time. All commands are bash commands used in a linux command line. 

### Main econometric specification (Appendix Section C.3)
In the paper, we include projection results for: 
  - SSP3 Point estimate and Delta Method. 
  - SSP2 and SSP4 Point estimates

To run these projecitons, run: 

```
# SSP3 point estimates
./generate.sh {your path}/energy-code-release-2020/projection_inputs/configs/GMFD/TINV_clim/break2_Exclude/semi-parametric/Projection_Configs/sacagawea/run/median/energy-median-hddcddspline_OTHERIND_other_energy.yml  30
./generate.sh {your path}/energy-code-release-2020/projection_inputs/configs/GMFD/TINV_clim/break2_Exclude/semi-parametric/Projection_Configs/sacagawea/run/median/energy-median-hddcddspline_OTHERIND_electricity.yml  30

# SSP3 uncertainty projections 
./generate.sh {your path}/energy-code-release-2020/projection_inputs/configs/GMFD/TINV_clim/break2_Exclude/semi-parametric/Projection_Configs/sacagawea/run/median/energy-median-hddcddspline_OTHERIND_other_energy_dm.yml  30
./generate.sh {your path}/energy-code-release-2020/projection_inputs/configs/GMFD/TINV_clim/break2_Exclude/semi-parametric/Projection_Configs/sacagawea/run/median/energy-median-hddcddspline_OTHERIND_electricity_dm.yml  30
```
Then, update the config writer such that it replaces the configs with the SSP2 configs, (or equivalently just manually edit the configs to change the `only-ssp` argument to `SSP2` and run: 
```
./generate.sh {your path}/energy-code-release-2020/projection_inputs/configs/GMFD/TINV_clim/break2_Exclude/semi-parametric/Projection_Configs/sacagawea/run/median/energy-median-hddcddspline_OTHERIND_other_energy.yml  30
./generate.sh {your path}/energy-code-release-2020/projection_inputs/configs/GMFD/TINV_clim/break2_Exclude/semi-parametric/Projection_Configs/sacagawea/run/median/energy-median-hddcddspline_OTHERIND_electricity.yml  30
```
The update the configs so they are ready to run SSP4, and once again run:
```
./generate.sh {your path}/energy-code-release-2020/projection_inputs/configs/GMFD/TINV_clim/break2_Exclude/semi-parametric/Projection_Configs/sacagawea/run/median/energy-median-hddcddspline_OTHERIND_other_energy.yml  30
./generate.sh {your path}/energy-code-release-2020/projection_inputs/configs/GMFD/TINV_clim/break2_Exclude/semi-parametric/Projection_Configs/sacagawea/run/median/energy-median-hddcddspline_OTHERIND_electricity.yml  30
```


### Econometric specification with linear time interaction (`lininter`) (Appendix Section I.3)
In the paper, we include projection results for: 
  - SSP3 point estimate 
  
Command needed to run this projection: 

```
./generate.sh {your path}/energy-code-release-2020/projection_inputs/configs/GMFD/TINV_clim_lininter/break2_Exclude/semi-parametric/Projection_Configs/sacagawea/run/median/energy-median-hddcddspline_OTHERIND_other_energy.yml  30
./generate.sh {your path}/energy-code-release-2020/projection_inputs/configs/GMFD/TINV_clim_lininter/break2_Exclude/semi-parametric/Projection_Configs/sacagawea/run/median/energy-median-hddcddspline_OTHERIND_electricity.yml  30
```

### Econometric specification with linear time trend, deterministically doubled (`lininter_double`) (Appendix Section I.3)
In the paper, we include projection results for: 
  - SSP3 point estimate 
```
./generate.sh {your path}/energy-code-release-2020/projection_inputs/configs/GMFD/TINV_clim_lininter_double/break2_Exclude/semi-parametric/Projection_Configs/sacagawea/run/median/energy-median-hddcddspline_OTHERIND_other_energy.yml  30
./generate.sh {your path}/energy-code-release-2020/projection_inputs/configs/GMFD/TINV_clim_lininter_double/break2_Exclude/semi-parametric/Projection_Configs/sacagawea/run/median/energy-median-hddcddspline_OTHERIND_electricity.yml  30
```


### Econometric specification with linear time trend, deterministically doubled (`lininter_half`) (Appendix Section I.3)
In the paper, we include projection results for: 
  - SSP3 point estimate 
```
./generate.sh {your path}/energy-code-release-2020/projection_inputs/configs/GMFD/TINV_clim_lininter_half/break2_Exclude/semi-parametric/Projection_Configs/sacagawea/run/median/energy-median-hddcddspline_OTHERIND_other_energy.yml  30
./generate.sh {your path}/energy-code-release-2020/projection_inputs/configs/GMFD/TINV_clim_lininter_half/break2_Exclude/semi-parametric/Projection_Configs/sacagawea/run/median/energy-median-hddcddspline_OTHERIND_electricity.yml  30
```


### Slow adaptation model (Appendix Section I.1)
In the paper, we include projection results for: 
- SSP3, climate projections from the CCSM4 climate model

Please note - the config files for this model were generated by hand, rather than by using code (it is the same as the one for the main model, just with an extra option specifying that we halve the rate of adaptation).

The command used to run this projection is: 
```
./generate.sh {your path}/energy-code-release-2020/projection_inputs/configs/GMFD/TINV_clim/break2_Exclude/semi-parametric/Projection_Configs/sacagawea/run/diagnostics/energy-diagnostics-hddcddspline_OTHERIND_other_energy_slow_adapt.yml 
./generate.sh {your path}/energy-code-release-2020/projection_inputs/configs/GMFD/TINV_clim/break2_Exclude/semi-parametric/Projection_Configs/sacagawea/run/diagnostics/energy-diagnostics-hddcddspline_OTHERIND_electricity_slow_adapt.yml 
```

### Note for Ashwin and Rae: these configs are `diagnostic` configs, meaning that they will only run for a single climate model and set of RCP-SSP-IAM scenarios. By default, this will be RCP8.5, for our high IAM and SSP3. In the paper (Figure I.1), we also present results from this model for RCP4.5. To run this projection, we have to change a hard coded value in [this script](https://gitlab.com/ClimateImpactLab/Impacts/impact-calculations/-/blob/master/generate/loadmodels.py) and then re-run the above commands, (`single_clim_scenario ` = 'rcp45'). Hopefully when we are ready to release impact-calculations, this is a bit more streamlined or at least documented in James' repo.



## Running an aggregation

### Note for Ashwin and Rae - when running these aggregations, added something to the projection code to prevent the code from aggregating the incadapt and noadapt scenarios (this is just to save disk space). Since then, James has implemented an option to specify this in the config instead. See [this issue](https://gitlab.com/ClimateImpactLab/Impacts/impact-calculations/-/issues/31) for details. If we want to implement this option in the aggregation configs for future aggregations, just add the line `only-farmers: ['', 'histclim']` to the aggregation configs by editing the config writer.

- After running projections, the next step is to aggregate them. This means converting impacts into units of dollars rather than energy consumption per capita, for a range of pricing scenarios, and aggregating across space to get global time series of impacts. 
- To run an aggregation, you need to be in the `risingverse` conda environment, and have the projection repos set up. 

The generic syntax for running an aggregation is to run (from inside the impact-calculations projection repo): 
```
./aggregate.sh {path to aggregation config}/{aggregation config name} {number of processes}
```

Please note - running aggregation generates large data files! 

To run aggregations for all permutations of scenarios in the paper, run `energy_aggregation.sh`, after editing the `uname` variable such that the `repo_root` variable points to the location of the energy code release repo on your machine.

## Extracting results
- See the readme in `2_projection/3_extract_projection_outputs/`.
- Note - it is at this point in the process that we combine projections across our two fuel types.
