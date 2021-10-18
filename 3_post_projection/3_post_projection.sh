#!/bin/bash

echo "STEP 1 - Prepare projection configs"
./1_prepare_projection_files/1_prepare_projection_files.sh

echo "STEP 2 - Running a single projection"
./2_running_projection.sh

echo "STEP 2 - Extract the result of the projection"
./3_extract_projection_outputs.sh
# TO-DO: this part is being updated