# Overview 
Codes in this repo perform two tasks: 
1. Converting the regression coefficients stored in ster files to the `csvv` format that our projection system understands. 
2. Creating the configuration files needed to run a projection. 

Please note - codes in this repo prepare the necessary projection inputs. For details on running projections, please see the readme in `2_projection/2_running_projections`. 

The configuration files that our projection system needs to run fall broadly into three categories: 
  - ***Projection***: 
    - Projection configuration files tell the projection system how to run a given projection specification. 
    - There are two config files needed to run a projection:
        1. A `run` config. This contains information on where the output of the projection will be stored. It also contains information on the type of projection that will be run (ie the socioeconomic scenario), and the adaptation scenarios. It also determines whether a given projection outputs impact projections or projections of the variance of these impacts (derived from the variance of the estimated regression coefficients).
        2. A `model` config. This contains information on the projection model. It tells the projection system where to find the csvv, and provides information on how the projected model is constructed. 
  - ***Aggregation***:
    - Aggregation configs are inputs to the aggregation of projection system results. Aggregation performs two functions; spatial aggregation, and unit conversion. 
      - Spatial aggregation converts our impacts from being at the Impact Region level higher administrative units (eg country level or global level).
      - Unit conversion aggregation converts projections from being in units of energy use per capita to dollars, or to dollars per person.
  - ***Extraction***:
    - Extraction configs are used to extract results from the netcdf outputs of the projection system into user friendly `.csv` files for post-projection analysis. 
    - As part of this process, we combine results across multiple climate models, by taking quantiles of their projected impacts. 

Please see documentation in the `impacts-calculation` projection system repo for more details on the contents of these configuration files.  

# Code contents and run instructions

### `1_generate_csvv.do`
- This code prepares a csvv file, which is an input to our projection system. The csvv files is a file containing regression coefficients, and their variance matrices.
- It uses programs from `2_projection/0_packages_programs_inputs/csvv_generation_stacked.do`.

#### Run instructions
- Change the macro "root" to the location of the code release repo on your machine.
- Note - the program in this code has more functionality than is needed to create the specific csvv files that were used. The options that are not needed are hard coded into the functions arguments in this version of the code for code-release. 

#### Code inputs 
  - Regression coefficients saved in `.ster` files produced in the analysis step in this repo. 
  - Specifications csv (saved here: `/2_projection/0_packages_programs_inputs/projection_set_up/projection_specifications.csv`).
    - This `.csv` file contains information on which variables are in each model. 
#### Code outputs
- CSVV files for three models: 
  - The four models are `TINV_clim`, `TINV_clim_lininter`,  `TINV_clim_lininter_double`, and , `TINV_clim_lininter_half`. 
  - Please note - the csvvs for the `TINV_clim_lininter` and `TINV_clim_lininter_double` and `TINV_clim_lininter_half` models are identical, as both pull in the same regression coefficients, and have the same model specifications. They have different config files, however. 
  - Note also, the `slow_adapt` scenario projection presented in Appendix I.1 uses the same csvv as main model (`TINV_clim`). Similarly, this is because this model uses the same coefficients as the main model - we just limit the adaptation in the configuration file when running the projection.
- For each model, we generate three `csvv` files. 
  1. A `csvv` for the `electricity` projection.
  1. A `csvv` for the `other_energy` projection.
  1. A `csvv` for the variance covariance matrix from the stacked regression of both products. 
- These csvv files are outputted to this git repo, and are stored in `energy-code-release-2020/projection_inputs/csvv`

### `2_generate_projection_configs.do`
- This code generates config files that are used to run projections. 
- It uses programs from `/2_projection/0_packages_programs_inputs/projection_set_up/write_projection_file.do`. 
- ***Please note - this code is set up to run the projections that we actually ran. Therefore it points to the CSVVs generated in from the gcp-energy repo. The names of these csvvs are slightly different! Also, they are in KWh rather than GJ. To run this using the csvv files made in this repo, you will need to edit the config writer***. 
- ***Please also note that the configs are set up to point to code and data that is saved on our CIL servers. To run this on an external server, you will need to edit this code to make it point to paths and data on your server.***

#### Run instructions 
- Change the macro `root` at the top of the code to point to the location of the code release repo on your machine. 
- Also, change the macro `user` to your username on your server. 
- Choose the SSP you want to generate configs for by editing the local `ssp_list`. The projection writer is set up to run "SSP3" as the default. 
- Note - the code assumes that your projection repos, and this repo, are located on our CIL servers at `/home/{uname}/repos/` or on BRC at `/global/scratch/{uname}/repos/`. If this isn't the case, you will need to edit `/2_projection/0_packages_programs_inputs/projection_set_up/write_projection_file.do`.

#### Code inputs
- `csvv` file name and location

#### Code outputs
- The four types of configuration files that are needed to run and extract projection results (Projection Run configs and Model configs, Aggregation configs, and Extraction configs). See above for details.
- We also create Slurm scripts that are used for running projections on [BRC](https://research-it.berkeley.edu/programs/berkeley-research-computing) (note, BRC is also known as `laika`). 
- Outputs are stored in this git repo in `energy-code-release-2020/projection_inputs/configs/GMFD`.
- For the Projection and Aggregation configs, we create two versions - one which would allow a user to run the projection on on our CIL server, and one that would allow a user to run it on BRC. 
- Also, for each projection type, we create both `median` and `diagnostic` configs. Median configs allow a user to run the projection for all 33 of our GCMs, for both RCPs and both IAMSs. A diagnostic config, on the other hand, runs the projection for a single climate model and scenario. The default is using the `CCSM4` climate model, RCP8.5, and the "high" IAM scenario. 
