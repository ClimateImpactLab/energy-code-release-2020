### Packages for physically and emotionally processing projection output

##### [load_projection](https://gitlab.com/ClimateImpactLab/Impacts/gcp-energy/tree/master/rationalized/2_projection/2_processing/packages/load_projection)
this directory contains functions to query projection data from median projection output. documentation for how to use these functions is within the subdirectory `load_projection`

##### [future_gdp_pop_data.py](https://gitlab.com/ClimateImpactLab/Impacts/gcp-energy/blob/master/rationalized/2_projection/2_processing/packages/future_gdp_pop_data.py)
functions which query the following datasets: 
* future population data for each impact region for all years 
* future income per capita data for each impact region for all years
* global gdp time series into the future

##### [damage_timeseries.R](https://gitlab.com/ClimateImpactLab/Impacts/gcp-energy/blob/master/rationalized/2_projection/2_processing/packages/damage_timeseries.R) (possibly relevant in the future possibly not... for now we'll keep them around)
functions to construct lists useful for plotting a lot of different time series with specific colors. I originally wrote the functions for plotting damage time series for all pricing scenarios. Lines 188 and beyond in [make_timeseries.R](https://gitlab.com/ClimateImpactLab/Impacts/gcp-energy/blob/master/rationalized/2_projection/2_processing/plotting/make_timeseries.R) call these functions.

##### [response_function.R](https://gitlab.com/ClimateImpactLab/Impacts/gcp-energy/blob/master/rationalized/2_projection/2_processing/packages/response_function.R)
these functions are the energy specific functions meant to be used with the communal [yellow purple and delta beta code](https://gitlab.com/ClimateImpactLab/Impacts/post-projection-tools/tree/yellow_purple/response_function). Both the yp/db code and the energy specific response function code are called by [yp_plots.R](https://gitlab.com/ClimateImpactLab/Impacts/gcp-energy/blob/master/rationalized/2_projection/2_processing/diagnostics/yp_plots.R) to make delta betas and yellow purple plots.

