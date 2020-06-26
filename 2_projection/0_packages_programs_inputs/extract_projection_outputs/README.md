### Packages for processing projection output

##### `load_projection/.`
- This directory contains functions to query projection data from median projection output. Documentation for how to use these functions is within the subdirectory `load_projection`. 
- Please note that this depends on projection system codes that are currently unreleased (specifically, `quantiles.py` from the `open-estimate` repo). 
- To run this code, you should be inside the `risingverse-py27` conda environment. See the readme in `2_projection/2_running_projections/` for more details. 

##### `future_gdp_pop_data.py`
- To run this code, you will need to be inside the `risingverse` conda environment. Please see the readme in `2_projection/2_running_projections/` for more details. 
- Functions retrieve the following outputs from the projection system: 
  - future population data for each impact region for all years 
  - global gdp time series into the future
  - future income per capita data for each impact region for all years

