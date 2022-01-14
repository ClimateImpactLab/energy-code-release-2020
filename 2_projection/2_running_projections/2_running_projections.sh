#!/bin/bash

echo "STEP 1 - Running a single projection"
# Note: the next line may fail for you, which is ok, just make sure that you're in the energy_env_py3 conda environment
source activate energy_env_py3
cd ${REPO}/impact-calculations
./generate.sh ../energy-code-release-2020/projection_inputs/configs/GMFD/TINV_clim/break2_Exclude/semi-parametric/Projection_Configs/run/diagnostics/energy-diagnostics-hddcddspline_OTHERIND_electricity.yml

echo "STEP 2 - Aggregating a single projection (as an example)"
./aggregate.sh ../energy-code-release-2020/projection_inputs/configs/GMFD/TINV_clim/break2_Exclude/semi-parametric/Projection_Configs/aggregate/diagnostics/energy-aggregate-diagnostics-hddcddspline_OTHERIND_electricity.yml

