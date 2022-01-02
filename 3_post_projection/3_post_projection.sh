#!/bin/bash

echo "STEP 1 - Plot figures in the paper"
cd 1_visualise_impacts
./1_visualise_impacts.sh
cd ..

echo "STEP 2 - Running damage functions"
cd 2_damage_function_estimation
./2_damage_function_estimation.sh
cd ..

# echo "STEP 2 - Calculate the SCCs"
# # TO-DO: this part is being updated