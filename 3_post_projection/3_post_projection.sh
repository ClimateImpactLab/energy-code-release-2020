#!/bin/bash
mkdir ${LOG}/3_post_projections

echo "STEP 1 - Plot figures in the paper"
mkdir ${LOG}/3_post_projection/1_visualise_impacts
cd 1_visualise_impacts
./1_visualise_impacts.sh
cd ..

echo "STEP 2 - Running damage functions"
mkdir ${LOG}/3_post_projection/2_damage_function_estimation
cd 2_damage_function_estimation
./2_damage_function_estimation.sh
cd ..

echo "STEP 3 - Calculate the SCCs"
echo "Please follow instructions in the README in 3_SCC folder to run this step."