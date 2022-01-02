#!/bin/bash

mkdir ${LOG}/2_projection

echo "STEP 1 - Prepare projection configs"
cd 1_prepare_projection_files
./1_prepare_projection_files.sh
cd ..

echo "STEP 2 - Running a single projection"
cd 2_running_projections
./2_running_projections.sh
cd ..

echo "STEP 3 - Extract the result of the projection (under construction)"
# TO-DO: this part is under construction, but it doesn't affect your ability
# to run the next section of the repo
# ./3_extract_projection_outputs.sh
