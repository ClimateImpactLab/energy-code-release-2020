# Note to ashwin and rae - change out the configs here to whatever are used in the final version. 


# Overview

- In this folder, we briefly describe how we run projections. 
- Please note, running a projection is ***highly computationally intensive***. This is probably not suitable for most users. 
- By "running a projection" we mean running codes that convert our econometric response estimates into projections of the impact of climate change on energy consumption. 

# Prerequisites
- In order to run and process projections, you will need to have access to four additional git repos; `impact-calculations`, `open-estimate`, `impact-common`, and `prospectus-tools`. Please see documentationn in those repos for instructions for loading and using those codes. 
- To run projections, you will also need access to two conda environments: 
  - `risingverse`: a python 3 conda environment used for running and aggregating projections. See [here](https://github.com/ClimateImpactLab/risingverse) for install instructions
  - `risingverse-py27`: a python 2 conda environment used for extracting projection system outputs. See [here](https://github.com/ClimateImpactLab/risingverse-py27) for install instructions. 
- You will also need access to the climate and socioeconomic data used by the projection system. 
- Finally, you will need to have used the config writer `2_projection/1_prepare_projection_files/2_generate_projection_configs.do`, and made sure that the configs produced reflect the set up on your server. 

# Run instructions

## Running a projection
To run a projection (after following set up instructions in the `impact-calculations` repo) run this bash command from within the `impact-calculations` repo: 
```
./generate.sh {path_to_config}/{run_config_name} {number of threads}
```
This will then generate begin running a projection for the specification determined by the run config, and the associated module config. The `{number of threads}` variable should be replaced by a scalar (e.g. 20) which determines how many processes will be run in parallel. Note, each process takes around 4GB of memory for a point estimate run, and around 8GB of memory of a delta method run (i.e. for calculating variance projections). This might limit the amount of processes you are able to run in paralell. Each process works on a directory, one at a time, where a directory is defined by an `SSP-rcp-iam-gcm` combination. 

For example, to run a projection for SSP3, for a point estimate for our main model, with 40 processes running in parallel at the same time, the command to run would be (if you are running it on the CIL "sacagawea" server: 

```
./generate.sh {your path}/energy-code-release-2020/projection_inputs/configs/GMFD/TINV_clim_income_spline/break2_Exclude/semi-parametric/Projection_Configs/sacagawea/run/median/energy-median-hddcddspline_OTHERIND_electricity.yml  40
```

## Running the projections presented in the paper

In the paper, we include the following set of projections, all of which require running projections separately for electricity and other energy. In this section we present the commands needed to run these projections, assuming that you are running them will access to our CIL "sacagawea' servers and are running 30 processes at a time. All commands are bash commands used in a linux command line. 

## Main model. 
In the paper, we include projection results for: 
  - SSP3 Point estimate and Delta Method. 
  - SSP2 and SSP4 Point estimates

To run these projecitons, run: 

```
# SSP3 point estimates
./generate.sh {your path}/energy-code-release-2020/projection_inputs/configs/GMFD/TINV_clim_income_spline/break2_Exclude/semi-parametric/Projection_Configs/sacagawea/run/median/energy-median-hddcddspline_OTHERIND_other_energy.yml  30
./generate.sh {your path}/energy-code-release-2020/projection_inputs/configs/GMFD/TINV_clim_income_spline/break2_Exclude/semi-parametric/Projection_Configs/sacagawea/run/median/energy-median-hddcddspline_OTHERIND_electricity.yml  30

# SSP3 uncertainty projections 
./generate.sh {your path}/energy-code-release-2020/projection_inputs/configs/GMFD/TINV_clim_income_spline/break2_Exclude/semi-parametric/Projection_Configs/sacagawea/run/median/energy-median-hddcddspline_OTHERIND_other_energy_dm.yml  30
./generate.sh {your path}/energy-code-release-2020/projection_inputs/configs/GMFD/TINV_clim_income_spline/break2_Exclude/semi-parametric/Projection_Configs/sacagawea/run/median/energy-median-hddcddspline_OTHERIND_electricity_dm.yml  30
```
Then, update the config writer such that it replaces the configs with the SSP2 configs, (or equivalently just manually edit the configs to change the `only-ssp` argument to `SSP2` and run: 
```
./generate.sh {your path}/energy-code-release-2020/projection_inputs/configs/GMFD/TINV_clim_income_spline/break2_Exclude/semi-parametric/Projection_Configs/sacagawea/run/median/energy-median-hddcddspline_OTHERIND_other_energy.yml  30
./generate.sh {your path}/energy-code-release-2020/projection_inputs/configs/GMFD/TINV_clim_income_spline/break2_Exclude/semi-parametric/Projection_Configs/sacagawea/run/median/energy-median-hddcddspline_OTHERIND_electricity.yml  30
```
The update the configs so they are ready to run SSP4, and once again run:
```
./generate.sh {your path}/energy-code-release-2020/projection_inputs/configs/GMFD/TINV_clim_income_spline/break2_Exclude/semi-parametric/Projection_Configs/sacagawea/run/median/energy-median-hddcddspline_OTHERIND_other_energy.yml  30
./generate.sh {your path}/energy-code-release-2020/projection_inputs/configs/GMFD/TINV_clim_income_spline/break2_Exclude/semi-parametric/Projection_Configs/sacagawea/run/median/energy-median-hddcddspline_OTHERIND_electricity.yml  30
```


## Linear interaction model (`lininter`)
In the paper, we include projection results for: 
  - SSP3 point estimate 

## Linear interaction double model (`lininter_double`). 
In the paper, we include projection results for: 
  - SSP3 point estimate 

## Slow adaptation 
In the paper, we include projection results for: 
- SSP3 single run

## Running an aggregation

## Extracting results
