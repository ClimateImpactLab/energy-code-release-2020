#!/bin/bash

Rscript 1_take_draws.R
stata-se -b do 2_plot_damage_function_fig_3.do
stata-se -b do 3_run_damage_functions.do 
stata-se -b do 4_run_quantile_regressions.do 
stata-se -b do 5_plot_damage_function_over_time.do 
stata-se -b do 6_get_end_of_century_df_slopes_p_vals.do 