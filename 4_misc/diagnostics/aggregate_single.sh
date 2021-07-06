# Shell purpose: aggregate/value delta method and point estimate results

#!/bin/bash

uname="liruixue"
repo_root="/home/${uname}/repos"
projection_repo_root="/home/${uname}/projection_repos"

config_path="${repo_root}/energy-code-release-2020/projection_inputs/configs/GMFD"

model="TINV_clim"
aggregate_config_path="${config_path}/${model}/break2_Exclude/semi-parametric/Projection_Configs/sacagawea/aggregate/diagnostics/"

echo "$aggregate_config_path"

cd ${projection_repo_root}/impact-calculations

# Main model - aggregates both point estimate and delta method projections for all price scenarios

# for config in ${aggregate_config_path}/energy-aggregate-median-*.yml; do
# 	echo "aggregating ${config}..."
# 	./aggregate.sh ${config} 
# done


config="${aggregate_config_path}/energy-aggregate-diagnostics-hddcddspline_OTHERIND_electricity.yml"
echo "aggregating ${config}..."
./aggregate.sh ${config} 

config="${aggregate_config_path}/energy-aggregate-diagnostics-hddcddspline_OTHERIND_other_energy.yml"
echo "aggregating ${config}..."
./aggregate.sh ${config} 