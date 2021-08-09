#!/bin/bash

echo "STEP 1"
stata-mp -b do 1_construct_dataset_from_raw_inputs.do 
echo "STEP 2"
stata-mp -b  do 2_construct_regression_ready_data.do 
echo "STEP 3"
stata-mp  -b do 3_unit_root_test_and_plot.do 
echo "STEP 4"
Rscript 4_plot_ITA_other_energy_regimes_timeseries.R > $LOG/4_plot_ITA_other_energy_regimes_timeseries.log &

