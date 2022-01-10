#!/bin/bash

echo "STEP 3 - Extraction projection outputs"
source activate energy_env_py3
cd ${REPO}/energy-code-release-2020/2_projection/3_extract_projection_outputs
Rscript 0_save_covariate_data.R
# Rscript 1_prepare_visualisation_data.R
# Rscript 2_prepare_damage_function_data.R

