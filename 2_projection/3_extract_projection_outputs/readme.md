### Note for Rae and Ashwin: codes in this repo were used to extract results from the projection system. Since we ran everything in units of KWh, there are unit conversions going on where we convert impacts into GJ, as the inputs to the next stage of analysis assumes that all extracted csvs are in GJ. 
### These codes are meant to be a record of how we get the post-projection data from our servers into the the code release storage location. 
### Also note - we extract data from an allcalcs file in `0_save_covariate_data.R` for use in the blob plot. However, we do not include the single that was used to create this allcalcs file as one of the projections in the projection instructions, just because this is an extra projection and it seems confusing to include it.

# Overview
- Scripts in this repo extract projection system outputs, and save them as `.csv` files that are used in later analysis (i.e. in data visualisation, estimating damage functions, and calculating an SCC.)
- These codes also move data from our servers into the code release data storage location.
- Note: to run `0_save_covariate_data.R` you need to be in the [`risingverse`](https://github.com/ClimateImpactLab/risingverse) python 3 conda environment, whilst to run the other two codes in this directory, you need to be in the [risinsgverse-py27](https://github.com/ClimateImpactLab/risingverse-py27) conda environment. See those links for install instructions. 
- Codes in this repo depend on the projection system repos, including `prospectus-tools`, `impact-common` and `impactlab_tools`. Make sure you have all of these downloaded, and in the same directory as this `energy-code-release-2020` repo.
- These codes are only relevant to you if you have run your own version of the projection. Otherwise, they are provided just for reference.

# Code contents and run instructions

## `0_save_covariate_data.R`
- This code saves covariate data from our projection system onto the code release storage location (currently `/{synology}/CIL_energy/code_release_data_pixel_interaction/`).
  - The covariates that we extract and save include information on GDP and population projections taken from the SSPs. We also extract some projected climate data that is used to plot Figure C.3 in the appendix.  
- It also moves some data from our servers that is used for plotting aesthetics. 
- To run this code - make sure you are in the [`risingverse`](https://github.com/ClimateImpactLab/risingverse) python 3 conda environment. Also make sure that you have downloaded all projection system repos and followed their install intructions.
- Note: this code sources `energy-code-release-2020/2_projection/0_packages_programs_inputs/extract_projection_outputs/future_gdp_pop_data.py`

- ***Code inputs***:
  - Projection system git repos, projection system input income, population and climate data.
- ***Code outputs***: 
  - Miscellaneous plotting csvs. 
  - Population and gdp data needed for post projection analysis and plotting.

## `1_prepare_visualisation_data.R`
- This code extracts all projection system outputs that are needed for projection related plots and data visualisations.
- Note, to run this code you need to be in the [risinsgverse-py27](https://github.com/ClimateImpactLab/risingverse-py27) conda environment.
- This code relies on the extraction configs that were created using `1_prepare_projection_files/2_generate_projection_configs.do`.
  - In order to run these codes in a location other than the Climate Impact Lab servers, you will need to update the paths fed into the `write_extraction_config()` function in that config writer to reflect the location of your projection system outputs. 
- ***Code inputs***
  - Projection system output netcdf files, both raw and aggregated (note, this is a huge amount of raw data). Projection system repos.
  - Climate model weights csv (See Appendix Table A.1)
- ***Code outputs***
  - `.csv` files containing all data needed to plot projection system visualisations of impacts. 

## `2_prepare_damage_function_data.R`
- This code extracts projection system outputs needed to run damage functions and calculate an SCC.
- Note, to run this code you need to be in the [risinsgverse-py27](https://github.com/ClimateImpactLab/risingverse-py27) conda environment.
- This code relies on the extraction configs that were created using `1_prepare_projection_files/2_generate_projection_configs.do`.
  - In order to run these codes in a location other than the Climate Impact Lab servers, you will need to update the paths fed into the `write_extraction_config()` function in that config writer to reflect the location of your projection system outputs. 
- ***Code inputs***
  - Projection system output netcdf files, aggregated to the global level. Projection system repos.
- ***Code outputs***
  - Impacts projections csvs under each of the 33 climate projections, for each SSP/Price Scenario that we present in the paper. These are aggregated to the global level. 
  - A csv containing the global mean surface temperature anomolies associated with each year in each of the 33 climate projections, that is used for estimating damage functions. This csv was generated by our cliamte team - here we are just moving it from our servers into the code release data storage location. 
