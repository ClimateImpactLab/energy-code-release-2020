# Overview 
Codes in this repo perform two tasks: 
1. Converting the regression coefficients stored in ster files to the `csvv` format that our projection system understands. 
2. Creating the configuration files needed to run a projection. 

The configuration files that our projection system needs to run fall broadly into three categories: 
  - ***Projection***: 
    - Projection configuration files tell the projection system how to run a given projection specification. There are two config files needed to run a projection
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
- This code prepares a csvv file, which is an input to our projection system. 
- It uses programs from `2_projection/0_packages_programs_inputs/csvv_generation_stacked.do`, and requires an input `.csv` file containing information on the coefficients for a given model. This csv file is stored here `2_projection/0_packages_programs_inputs/projection_specifications.csv`. 
- ***ADD RUN INSTRUCTIONS***
- ***Code inputs***
  - Regression coefficients saved in `.ster` files produced in the analysis step in this repo. 
  - 
1. Prepare a csvv file, which is the file type that our projection system uses to read in regression coefficients. 
  - This is done in the code `1_generate_csvv.do`
  
