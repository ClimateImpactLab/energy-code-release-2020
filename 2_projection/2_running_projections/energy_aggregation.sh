# Shell purpose: aggregate/value delta method and point estimate results

#!/bin/bash

uname="USER"
repo_root="/home/${uname}/repos"

config_path="${repo_root}/energy-code-release-2020/projection_inputs/configs/GMFD"

model="TINV_clim_income_spline"
aggregate_config_path="${config_path}/${model}/break2_Exclude/semi-parametric/Projection_Configs/sacagawea/aggregate/median/"

cd ${repo_root}/impact-calculations

# Main model - aggregates both point estimate and delta method projections for all price scenarios

for config in ${aggregate_config_path}/energy-aggregate-median-*.yml; do
	echo "aggregating ${config}..."
	./aggregate.sh ${config} 
done

# For lininter and lininter_double models, only run point estimate aggregations, for price014 scenario
# and non-price aggregations

# Lininter model

model="TINV_clim_income_spline_lininter"
aggregate_config_path="${config_path}/${model}/break2_Exclude/semi-parametric/Projection_Configs/sacagawea/aggregate/median/"

for config in ${aggregate_config_path}/energy-aggregate-median-*y.yml; do
	echo "aggregating ${config}..."
	./aggregate.sh ${config} 
done

# Lininter double model 

model="TINV_clim_income_spline_lininter_double"
aggregate_config_path="${config_path}/${model}/break2_Exclude/semi-parametric/Projection_Configs/sacagawea/aggregate/median/"

for config in ${aggregate_config_path}/energy-aggregate-median-*y.yml; do
	echo "aggregating ${config}..."
	./aggregate.sh ${config} 
done


