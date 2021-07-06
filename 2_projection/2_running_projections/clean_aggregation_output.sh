#!/bin/bash
# this is a piece of code that helps us clean the incomplete aggregation output
# can be run from anywhere, just set the correct paths

# set some paths and parameters
energy="other_energy"
# energy="electricity"
output_root="/shares/gcp/outputs/energy_pixel_interaction/impacts-blueghost"
output_dir="median_OTHERIND_${energy}_TINV_clim_GMFD_dm" 

# the size of files above which we consider complete
# look at the completed output files to determine this size
levels_file_size_above=10
aggregated_file_size_above=2
# 130 for one SSP
n_folders_total=520

aggregation_scenario=price0082
filename_stem="FD_FGLS_inter_OTHERIND_${energy}_TINV_clim"

cd "${output_root}/${output_dir}"

# choose to delete or print. recommended: print once first,
# if everything looks ok, then delete
action=print
# action=delete

# if the projection is still running, set to the second
# so that the folders that are currently working on will not be affected
# if no process is running, set time_limit to empty string
# so that all incomplete files can be deleted
time_limit=""
# time_limit=" -mtime +1 "

# clean status-aggregate.txt files
files=$(find . -name "status-aggregate.txt" ${time_limit} -${action})
printf "\n===================================\n"
echo "${action}ing status-aggregate.txt "
echo "${files}"



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
		incomplete=$(find . -name "${filename_stem}${filename_suffix}-${aggregation_scenario}${file_type_suffix}.nc4" -size -${output_file_size_above}M ${time_limit} -${action})
		printf "\n===================================\n"
		printf "${scenario}: \n"
		echo "${action}ing incomplete ${filename_stem}${filename_suffix}-${aggregation_scenario}${file_type_suffix}.nc4"
		echo ""
		echo "${incomplete}"
	done
done


# uncomment to look for files with HDF error
# printf "\nFiles with HDF errors:"
# HDF_errors=$(find . -name "*.nc4" -exec ncdump -h {} \; -print |& grep HDF)
# echo "${HDF_errors}"
