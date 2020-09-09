# Shell purpose: aggregate/value delta method and point estimate results

#!/bin/bash

uname="$USER"
repo_root="/home/${uname}/repos"

config_path="${repo_root}/energy-code-release-2020/projection_inputs/configs/GMFD"

model="TINV_clim"
aggregate_config_path="${config_path}/${model}/break2_Exclude/semi-parametric/Projection_Configs/sacagawea/aggregate/median/"

cd ${repo_root}/impact-calculations


n=0
for config in ${aggregate_config_path}/energy-aggregate-median*other_energy_dm.yml; do
	printf "\n"
	n=$[$n +1]
	echo "${n}-th process"
	echo "aggregating ${config}..."
	./aggregate.sh ${config} 1
	sleep 2s
done


