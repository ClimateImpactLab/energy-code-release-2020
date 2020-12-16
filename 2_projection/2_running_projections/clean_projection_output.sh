#!/bin/bash
# this is a piece of code that helps us delete incomplete projection output
# so that the new processes can fill them in
# can be run from anywhere, just set the correct paths

# set some paths and parameters

# set some paths and parameters
# energy=electricity
energy=other_energy
dm=_dm
# dm=""
suffix=""

# suffix=_lininter
# suffix=_lininter_double
output_root="/shares/gcp/outputs/energy_pixel_interaction/impacts-blueghost"
output_dir="median_OTHERIND_${energy}_TINV_clim${suffix}_GMFD${dm}" 


# the size of files above which we consid complete
# look at the completed output files to determine this size
output_file_size_above=10

# 130 for one SSP
n_folders_total=520

cd "${output_root}/${output_dir}"
filename_stem="FD_FGLS_inter_OTHERIND_${energy}_TINV_clim${suffix}"

# choose to delete or print. recommended: print once first,
# if everything looks ok, then delete
# action=print
action=delete

# if the projection is still running, set to the second
# so that the folders that are currently working on will not be affected
 # so that all incomplete files can be deleted
time_limit=""
#time_limit=" -mtime +0 "

# clean status-*.txt files
for type in generate; 
do
	files=$(find . -name "status-${type}.txt" -${action})
	printf "\n===================================\n"
	echo "${action}ing status-${type}.txt "
	echo "${files}"
done

# check the files for each adaptation scenario
# if the file size is large enough, consider it complete
# otherwise consider it incomplete
# delete or print incomplete files
for scenario in fulladapt incadapt noadapt histclim; 
do 
	if [ ${scenario} = "fulladapt" ];
	then 
		filename_suffix=""
	else
		filename_suffix="-${scenario}"
	fi
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



