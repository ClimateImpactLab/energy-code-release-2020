#!/bin/bash
# this is a piece of code that helps us check the completeness of aggregation output
# can be run from anywhere, just set the correct paths

# set some paths and parameters
energy_type="electricity"
# energy_type="other_energy"
dm=""
dm="_dm"
# suffix=""
# aggregation_scenario=""
# aggregation_scenario="-MERGEETL60_rcp45"
# aggregation_scenario="-MERGEETL60_rcp85"
aggregation_scenario="-price014" 
# aggregation_scenario="-price03"
# aggregation_scenario="-price0"
# aggregation_scenario="-REMIND17_rcp45"
# aggregation_scenario="-REMIND17_rcp85" 
# aggregation_scenario="-REMIND17CEMICS_rcp45"
# aggregation_scenario="-REMIND17CEMICS_rcp85" 
# aggregation_scenario="-REMINDMAgPIE1730_rcp45" 
# aggregation_scenario="-REMINDMAgPIE1730_rcp85"
# aggregation_scenario="-WITCHGLOBIOM42_rcp45"
# aggregation_scenario="-WITCHGLOBIOM42_rcp85"



output_root="/shares/gcp/outputs/energy_pixel_interaction/impacts-blueghost"
output_dir="median_OTHERIND_${energy_type}_TINV_clim${suffix}_GMFD${dm}" 

# the size of files above which we consider complete
# look at the completed output files to determine this size
levels_file_size_above=10
aggregated_file_size_above=2
# 130 for one SSP
n_folders_total=520
# time_constraint=" -mtime -1 "
time_constraint=" "

filename_stem="FD_FGLS_inter_OTHERIND_${energy_type}_TINV_clim${suffix}"

cd "${output_root}/${output_dir}"

# check number of status-aggregate.txt files
n=$(find . -name "status-aggregate.txt" | wc -l)
echo "Number of status-aggregate.txt files: ${n}"


# check the files for each adaptation scenario
# if the file size is large enough, consider it complete
# otherwise consider it incomplete
for file_type in aggregated levels; 
do 
	# choose file size criteria based on 
	# if we're looking at aggregated or levels files
	if [ ${file_type} = "aggregated" ];
	then 
		output_file_size_above=${aggregated_file_size_above}
		file_type_suffix="-aggregated"
	else
		output_file_size_above=${levels_file_size_above}
		file_type_suffix="-levels"
	fi

	printf "=============================================\n"
	printf "Checking ${file_type} files: \n"

	for scenario in fulladapt incadapt noadapt histclim; 
	do 
		if [ ${scenario} = "fulladapt" ];
		then 
			filename_suffix=""
		else
			filename_suffix="-${scenario}"
		fi
		# echo "${filename_stem}${filename_suffix}-${aggregation_scenario}${file_type_suffix}"
		n_complete=$(find . -name "${filename_stem}${filename_suffix}${aggregation_scenario}${file_type_suffix}.nc4" -size +${output_file_size_above}M ${time_constraint}| wc -l)
		n_incomplete=$(find . -name "${filename_stem}${filename_suffix}${aggregation_scenario}${file_type_suffix}.nc4" -size -${output_file_size_above}M ${time_constraint} | wc -l)
		n_total=$(find . -name "${filename_stem}${filename_suffix}${aggregation_scenario}${file_type_suffix}.nc4" ${time_constraint}| wc -l)
		
		printf "${scenario}: \n"
		echo "${filename_stem}${filename_suffix}${aggregation_scenario}${file_type_suffix}.nc4"
		echo "${n_complete} complete, ${n_incomplete} incomplete, total ${n_total}/${n_folders_total} files"
	done
done

# uncomment to look for files with HDF error
# printf "\nFiles with HDF errors:"
# HDF_errors=$(find . -name "*.nc4" -exec ncdump -h {} \; -print |& grep HDF)
# echo "${HDF_errors}"
# missing_file="FD_FGLS_inter_OTHERIND_other_energy_TINV_clim-histclim-price014-levels.nc4"
# if needed, modify the following command to find folders that doesn't contain a certain file
# find . -type d -mindepth 4  '!' -exec test -e "{}/${missing_file}.nc4" ';' -print

