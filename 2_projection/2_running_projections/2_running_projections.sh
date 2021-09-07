#!/bin/bash

echo "STEP 1 - Running a single projection"
source activate energy_env_py3
cd ${REPO}/impact-calculations
./generate.sh ../energy-code-release-2020/projection_inputs/configs/GMFD/TINV_clim/break2_Exclude/semi-parametric/Projection_Configs/run/diagnostics/energy-diagnostics-hddcddspline_OTHERIND_electricity.yml
