#!/bin/bash
# this is a piece of code that helps us delete incomplete projection output
# so that the new processes can fill them in
# can be run from anywhere, just set the correct paths

# set some paths and parameters
output_root="/shares/gcp/outputs/energy_pixel_interaction/impacts-blueghost"
output_dir="median_OTHERIND_electricity_TINV_clim_GMFD_dm" 

# the size of files above which we consider complete
# look at the completed output files to determine this size
output_file_size_above=10

# 130 for one SSP
n_folders_total=130

cd "${output_root}/${output_dir}"

filename_stem="FD_FGLS_inter_OTHERIND_electricity_TINV_clim"

# choose to delete or print. recommended: print once first,
# if everything looks ok, then delete
# action=delete
action=print

# if the projection is still running, set to the second
# so that the folders that are currently working on will not be affected
# if no process is running, set time_limit to empty string
# so that all incomplete files can be deleted
# time_limit=""
time_limit=" -mtime +1 "

# check number of status-*.txt files
for type in global generate; 
do
	files=$(find . -name "status-${type}.txt" ${time_limit} -${action})
	printf "\n===================================\n"
	echo "${action}ing status-${type}.txt "
	echo "${files}"
done

# check the files for each adaptation scenario
# if the file size is large enough, consider it complete
# otherwise consider it incomplete
for scenario in fulladapt incadapt noadapt histclim; 
do 
	if [ ${scenario} = "fulladapt" ];
	then 
		filename_suffix=""
	else
		filename_suffix="-${scenario}"
	fi
	complete=$(find . -name "${filename_stem}${filename_suffix}.nc4" -size +${output_file_size_above}M ${time_limit} -${action})
	incomplete=$(find . -name "${filename_stem}${filename_suffix}.nc4" -size -${output_file_size_above}M ${time_limit} -${action})
	printf "\n===================================\n"
	printf "${scenario}: \n"
	echo "${action}ing incomplete ${filename_stem}${filename_suffix}.nc4"
	echo ""
	echo "${incomplete}"
done

# look for files with HDF error
# printf "\nFiles with HDF errors:"
# HDF_errors=$(find . -name "*.nc4" -exec ncdump -h {} \; -print |& grep HDF)
# echo "${HDF_errors}"

# if needed, modify the following command to find folders that doesn't contain a certain file
# find . -type d -mindepth 4  '!' -exec test -e "{}/${filename_stem}.nc4" ';' -print


