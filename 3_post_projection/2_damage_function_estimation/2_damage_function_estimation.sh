#!/bin/bash

Rscript 1_take_draws.R
stata-se -b plot_city_responses.do
Rscript plot_damages_by_2012_income_decile.R
Rscript plot_kernel_density_function.R
Rscript plot_maps.R
Rscript plot_time_series.R