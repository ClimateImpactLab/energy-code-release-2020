#!/bin/bash
# this is a piece of code that helps us check the completeness of projection output

# set some paths and parameters
output_root="/shares/gcp/outputs/energy_pixel_interaction/impacts-blueghost"
output_dir="median_OTHERIND_electricity_TINV_clim_GMFD" 

# the size of files above which we consider complete
# look at the completed output files to determine this size
output_file_size_above=10

# 130 for one SSP
n_folders_total=130

cd "${output_root}/${output_dir}"

filename_stem="FD_FGLS_inter_OTHERIND_electricity_TINV_clim"

# check number of status-*.txt files
for type in global generate; 
do
	n=$(find . -name "status-${type}.txt" | wc -l)
	echo "Number of status-${type}.txt files: ${n}"
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
	n_complete=$(find . -name "${filename_stem}${filename_suffix}.nc4" -size +${output_file_size_above}M| wc -l)
	n_incomplete=$(find . -name "${filename_stem}${filename_suffix}.nc4" -size -${output_file_size_above}M | wc -l)
	printf "${scenario}: \n"
	echo "${n_complete}/${n_folders_total} completed, ${n_incomplete} incomplete"
done

# look for files with HDF error
printf "\nFiles with HDF errors:"
HDF_errors=$(find . -name "*.nc4" -exec ncdump -h {} \; -print |& grep HDF)
echo "${HDF_errors}"

# if needed, modify the following command to find folders that doesn't contain a certain file
# find . -type d -mindepth 4  '!' -exec test -e "{}/${filename_stem}.nc4" ';' -print


