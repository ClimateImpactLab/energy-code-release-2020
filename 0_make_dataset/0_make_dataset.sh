#!/bin/bash
# This script run all data construction steps.
# You can also run individual scripts using commands in this script.

mkdir ${LOG}/0_make_dataset

echo "STEP 1: skipping because raw data is not publically available"
# stata-se -b do 1_construct_dataset_from_raw_inputs.do 
echo "STEP 2"
stata-se -b  do 2_construct_regression_ready_data.do 
echo "STEP 3"
stata-se -b do 3_unit_root_test_and_plot.do 
echo "STEP 4"
Rscript 4_plot_ITA_other_energy_regimes_timeseries.R

