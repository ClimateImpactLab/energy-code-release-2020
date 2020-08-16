# Shell purpose: aggregate/value delta method and point estimate results

#!/bin/bash

uname="$USER"
repo_root="/home/${uname}/repos"

config_path="${repo_root}/energy-code-release-2020/projection_inputs/configs/GMFD"

model="TINV_clim"
aggregate_config_path="${config_path}/${model}/break2_Exclude/semi-parametric/Projection_Configs/sacagawea/aggregate/median/"

cd ${repo_root}/impact-calculations

# Main model - aggregates both point estimate and delta method projections for all price scenarios

for config in ${aggregate_config_path}/energy-aggregate-median-*electricity_dm.yml; do
	echo "aggregating ${config}..."
	./aggregate.sh ${config} 30
	./aggregate.sh ${config}
	sleep 1m
	
done


