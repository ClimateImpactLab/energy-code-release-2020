#!/bin/bash

extract=true # default extract file ... unless set as false in parameters passed in

eval "$1" # fetch parameters from the command line

# Bash script purpose: Extract values from netcdfs using quantiles.py
# Example commands:

## extract full uncertainty impactspc for the global region --
#### bash extraction_quantiles.sh "conda_env=projection;proj_type=median;
#### clim_data=GMFD;model=TINV_clim;grouping_test=semi-parametric;
#### unit=impactpc;adapt_scen=fulladapt;geo_level=aggregated;spec=OTHERIND_other_energy;region=global;uncertainty=full"

## extract a variance value csv impactspc for the global region --
#### bash extraction_quantiles.sh "conda_env=projection;proj_type=median;
#### clim_data=GMFD;model=TINV_clim;grouping_test=semi-parametric;
#### unit=impactpc;adapt_scen=fulladapt;geo_level=aggregated;spec=OTHERIND_other_energy;
#### region=global;uncertainty=values;proj_mode=_dm"

# Parameters:
## note -- parameters are written with a very specific syntax so they can be read into R please stick to the syntax below if you are adding or changing parameters
## spaces, /, and : need to be copied to a T... really what it comes down to is my parsing functions aren't that smart
## / parameter:grouping_test / options:semi-parametric, visual / required:yes /
## / parameter:model / options:TINV_clim, TINV_clim_lininter, TINV_clim_lininter_double, TINV_clim_lininter_half, TINV_clim_mixed / required:yes /
### or etc. (look to other scripts for info on other models... you should just be able to plop whatever model name in here)
## / parameter:clim_data / options:GMFD, BEST / required:yes /
## / parameter:conda_env / options:UNDEFINED / required:yes /
### name of conda environment you run quantiles.py in
## / parameter:adapt_scen / options:fulladapt, incadapt, noadapt / required:yes /
### adaptation scenario you want to extract
## / parameter:geo_level / options:aggregated, levels / required:yes /
### aggregated - ir agglomerations or levels - single irs
## / parameter:unit / options:damagepc, impactpc, damage / required:yes /
### 'damagepc' ($ pc) 'impactpc' (kwh pc) 'damage' ($ pc)
## / parameter:spec / options:OTHERIND_electricity, OTHERIND_other_energy, OTHERIND_total_energy / required:yes /
## / parameter:region / options:UNDEFINED / required:no /
### specify region if extracting full uncertainty or if extracting values for an aggregated region
## / parameter:uncertainty / options:full, climate, values / required:yes /
## / parameter:iam / options:high, low / required:no /
## / parameter:rcp / options:rcp85, rcp45 / required:no /
## / parameter:proj_mode / options:_dm / required:no /
### options really are '' and _dm but i'm not sure yet how to pass that into R through my funciton
## / parameter:price_scen / options:price014, price0, price03, WITCHGLOBIOM42_rcp45, WITCHGLOBIOM42_rcp85, REMINDMAgPIE1730_rcp85, REMINDMAgPIE1730_rcp45, REMIND17CEMICS_rcp85, REMIND17CEMICS_rcp45, REMIND17_rcp85, REMIND17_rcp45, MERGEETL60_rcp85, MERGEETL60_rcp45 / required:no /
## / parameter:extract / options:true, false / required:no /
### only sort of required... for R script calling required though
### default is TRUE... if you want to get names but not extract extract should equal FALSE

############################################################################################################
# Part 0 -- Locals Necessary for running script
############################################################################################################

repo_root=/home/$USER/repos
extraction_config_path=gcp-energy/rationalized/2_projection/1_setup_generation_aggregation_extraction/configs/${clim_data}/${model}/break2_Exclude/${grouping_test}/Extraction_Configs/sacagawea
log_file_path=/home/${USER}/extraction_shell_logs

############################################################################################################
# Part 1 -- Define Helper Functions for working part of bash script
############################################################################################################

# fxn which prepares log file for header pre nohup output
setup_log_file() {
	excp=$1
	lf=$2
	cmnd=$3
	
	echo "config: ${excp}" > ${lf}
	echo "command: ${cmnd}" >> ${lf}
}

get_input_file() {
	eval "$1"
        as=$2
        product=$3
	if [[ "${as}" == "fulladapt" ]]; then
		as_tag=""
	else
		as_tag=-${as}
	fi

	stem=FD_FGLS_inter_clim${clim_data}_Exclude_all-issues_break2_${grouping_test}_poly2_${product}_${model}
	input_file=${stem}${as_tag}${price_scen_tag}${geo_level_tag}
}


############################################################################################################
# Part 1.5 -- Making sure dont try to extract something you shouldn't 
# ( a little variable assignment happens here as well but minimal)
############################################################################################################

if [[ "${unit}" != *"impact"* ]]; then 
	
    price_scen_tag=-${price_scen}
    
    # abort if unit is a damage but price scneario has not been defined
    if [[ -z ${price_scen} ]]; then
        echo "Aborting because for unit == ${unit} price_scen must be defined"
        exit 1
    fi

fi

if [[ "${spec}" == "OTHERIND_total_energy" && "{$uncertainty}" == "full" ]]; then   
    # need to understand if this is true for all extractions for this spec or just full uncertainty total_energy extractions
    if [[ -z ${rcp} ]]; then
            echo "Aborting because rcp must be restricted if extracting total_energy due to memory constraints."
            exit 1
    fi
    
    rcp_restriction=--rcp=${rcp}

 fi


############################################################################################################
# Part 2 -- Define tags for properly calling netcdfs, naming csvs, and calling configs
############################################################################################################

geo_level_tag=-${geo_level}

# impactspc levels doesn't have a geo_level_tag

if [[ "${unit}" == "impactpc" && "${geo_level}" != "aggregated" ]]; then
    geo_level_tag=""
fi

# full uncertainty can only extract one region at a time, so make sure that happens or an error is thrown

if [[ "${uncertainty}" == "full" ]]; then
	uncertainty_tag=_fulluncertainty
	region_restriction=--region=${region}
	region_tag=${region}_
fi

# netcdfs don't have a tag for fulladapt

if [[ "${adapt_scen}" == "fulladapt" ]]; then
	adapt_scen_tag=""
else
	adapt_scen_tag=-${adapt_scen}
fi

# restrict to one iam if desired

if [[ ( "${iam}" ) ]]; then
	iam_tag=_${iam}
	iam_restriction=--only-iam=${iam}
else
	iam_tag=''
	iam_restriction=''
fi

# restrict to one region if extracting aggregated values (standard)

if [[ ( "${geo_level}" == "aggregated" ) && ( "${uncertainty}" == "values" ) ]]; then

	region_restriction=--region=${region}

fi

# restrict to one region if a region is specified for values -- this allows for unenforced flexibility 
# (this is different from above because I want an error to get thrown if you try to extract aggregated values without specifying a region)

if [[ ( ${region} ) &&  ( "${uncertainty}" == "values" ) ]]; then
    region_restriction=--region=${region}
    region_log_tag=${region}_
fi

############################################################################################################
# Part 3 -- Get parameters for calling quantiles.py ready go go
############################################################################################################

# set up environment, working directory and location for log files

cd ${repo_root}/prospectus-tools/gcp/extract
source activate ${conda_env}

if [ ! -d ${log_file_path} ]; then
  mkdir -p ${log_file_path}
fi

# set up some variables to make the calling line not a gazillion characters --
ecp=${repo_root}/${extraction_config_path}/${unit}/${price_scen}/${uncertainty}/${geo_level}/median/energy-extract-${unit}${geo_level_tag}${price_scen_tag}-median_${spec}${proj_mode}.yml 
suffix=_${region_tag}${unit}${price_scen_tag}_median${uncertainty_tag}${iam_tag}${rcp_tag}_${adapt_scen}${geo_level_tag}${proj_mode}
log_file=${log_file_path}/${region_log_tag}log${suffix}_${spec}.txt

# print out information about call
# for parsing copy : and space usage to a T... again my parsing functions aren't that smart

echo "extraction.config:${ecp}"
echo "iam.restriction:${iam_restriction}"
echo "region.restriction:${region_restriction}"
echo "suffix:${suffix}"
echo "log.file:${log_file}"

#######################################################################################
# Part 4 -- Specify quantiles.py command
#######################################################################################

# for calling get_input_file specify parameters
parameters=$(echo "clim_data=${clim_data};grouping_test=${grouping_test};model=${model};price_scen_tag=${price_scen_tag};geo_level_tag=${geo_level_tag}") 

if [[ "${spec}" != "OTHERIND_total_energy" ]]; then 

        # define input files 
	get_input_file ${parameters} ${adapt_scen} ${spec}
	input_file_adapt=${input_file}
	get_input_file ${parameters} histclim ${spec}
        input_file_histclim=${input_file}

	if [[ "${adapt_scen}" == "noadapt" ]]; then
	    command=$(echo "nohup python -u quantiles.py ${ecp} ${iam_restriction} ${region_restriction} --suffix=${suffix} ${input_file_adapt} >> ${log_file} 2>&1 &")
	else
	    command=$(echo "nohup python -u quantiles.py ${ecp} ${iam_restriction} ${region_restriction} --suffix=${suffix} ${input_file_adapt} -${input_file_histclim} >> ${log_file} 2>&1 &")
	fi
else
        # get electricity input files
        get_input_file ${parameters} ${adapt_scen} OTHERIND_electricity
        input_file_adapt_e=${input_file}
        get_input_file ${parameters} histclim OTHERIND_electricity
        input_file_histclim_e=${input_file}

        # get other energy input files
        get_input_file ${parameters} ${adapt_scen} OTHERIND_other_energy
        input_file_adapt_oe=${input_file}
        get_input_file ${parameters} histclim OTHERIND_other_energy
        input_file_histclim_oe=${input_file}

	if [[ "${adapt_scen}" == "noadapt" ]]; then

	    command=$(echo "nohup python -u quantiles.py ${ecp} ${iam_restriction} ${rcp_restriction} ${region_restriction} --suffix=${suffix} ${input_file_adapt_e} ${input_file_adapt_oe} >> ${log_file} 2>&1 &")

	else
	    command=$(echo "nohup python -u quantiles.py ${ecp} ${iam_restriction} ${rcp_restriction} ${region_restriction} --suffix=${suffix} ${input_file_adapt_e} -${input_file_histclim_e} ${input_file_adapt_oe} -${input_file_histclim_oe} >> ${log_file} 2>&1 &")
	fi

fi

########################################################
# Part 5 -- call quantiles.py
#########################################################

# set up log file
setup_log_file ${ecp} ${log_file} "${command}"

if ${extract}; then
	# execute command
	eval ${command}
	echo "pid:$!"
fi






