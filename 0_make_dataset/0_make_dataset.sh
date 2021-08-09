#!/bin/bash

echo "STEP 1"
stata-mp  < 1_construct_dataset_from_raw_inputs.do > $LOG/1_construct_dataset_from_raw_inputs.log &
echo "STEP 2"
stata-mp  < 2_construct_regression_ready_data.do > $LOG/2_construct_regression_ready_data.log &
echo "STEP 3"
stata-mp  < 3_unit_root_test_and_plot.do > $LOG/3_unit_root_test_and_plot.log &
echo "STEP 4"
Rscript 4_plot_ITA_other_energy_regimes_timeseries.R 2 > $LOG/4_plot_ITA_other_energy_regimes_timeseries.log &

