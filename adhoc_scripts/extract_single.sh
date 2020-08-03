
# adapted from https://gitlab.com/ClimateImpactLab/Impacts/gcp-energy/-/blob/master/rationalized/2_projection/1_setup_generation_aggregation_extraction/shells/extract_single.sh

#Activate env and ensure in correct repo
# conda activate risingverse-py27
cd /home/liruixue/repos/prospectus-tools/gcp/extract

#load parameters passed through command
climate_data="GMFD"
model="TINV_clim"
zero_case=Exclude
flow_break=break2
grouping_test="semi-parametric"
val="rebased"
SSP="SSP3"
proj_type=""
price=$7
date=719

#Check git branch if extracting delta method
BRANCH=$(git branch | sed -nr 's/\*\s(.*)/\1/p')

if (("${proj_type}" == "_deltamethod" | "${proj_type}" == "_dm")) && (("${BRANCH}" != "vcvinfo")); then
  echo "Wrong branch for extracting delta method output."
  exit 1
fi

if [[ ${price} ]]; then
  type_na="-levels"
else
  type_na=""
fi

if [ -z "${val}" ]; then
  echo "Need to specify which column to extract in the fourth parameter slot."
  exit 1
fi

for product in "electricity" "other_energy"; do
  for flow in "OTHERIND"; do

    singles_folder=single-${flow}_${product}_FD_FGLS_${date}_${zero_case}_all-issues_${flow_break}_${grouping_test}_${model}_${climate_data}${proj_type}
    root=FD_FGLS_inter_${flow}_${product}_${model}
    #singles_folder=single-${flow}_${product}_FD_FGLS_${date}_${zero_case}_IssueFix_${flow_break}_${model}_${climate_data}${proj_type}
    #root=FD_FGLS_inter_clim${climate_data}_${zero_case}_IssueFix_${flow_break}_poly2_${flow}_${product}_${model}

    inputdir=/shares/gcp/outputs/energy_pixel_interaction/impacts-blueghost/

    outputdir=/shares/gcp/social/parameters/energy_pixel_interaction/extraction/${singles_folder}


    # Check directories exist
    if [ ! -d ${inputdir}/${singles_folder}/rcp85/CCSM4/high/ ]; then
      echo "could not find: ${inputdir}/${singles_folder}/rcp85/CCSM4/high/"
      exit 1
    fi

    if [ ! -d ${outputdir} ]; then
      echo "output directory not working!!!!"
      mkdir -p ${outputdir} 
    fi

    # If input file exists run singles.py

    for ssp in "${SSP}"; do
      for type in "${type_na}" -aggregated; do
        
        # extracting delta method
        if [ "${proj_type}" == "_dm" ]; then
          
          echo "extracting delta method"

          for adapt in "" -incadapt -noadapt; do 
            
            input_file=${inputdir}/${singles_folder}/rcp85/CCSM4/high/${ssp}/${root}${adapt}${price}${type}.nc4
            histclim_file=${inputdir}/${singles_folder}/rcp85/CCSM4/high/${ssp}/${root}-histclim${price}${type}.nc4
            output_file=${outputdir}/single${type}_energy_rcp85_ccsm4_high_${ssp}_${flow}_${product}_FD_FGLS${adapt}${price}_${val}.csv

            if [ ! -f ${input_file} ]; then
              echo "${input_file} not found!!!!!!!"
            else
              if [ "${adapt}" != "-noadapt" ]; then
                echo "python single.py --column=${val} ${input_file} -${histclim_file} > ${output_file}"
                python single.py --column=${val} ${input_file} -${histclim_file} > ${output_file}
                echo "extracted: ${input_file}"
              elif [ "${adapt}" == "-noadapt" ]; then
                echo "python single.py --column=${val} ${input_file} > ${output_file}"
                python single.py --column=${val} ${input_file} > ${output_file}
                echo "extracted: ${input_file}"
                echo "output: ${output_file}"
              fi
            fi
          done

        # extracting impacts
        else

          echo "extracting impacts"

          # TO-DO: ask maya what are -incadapt-histclim and -noadapt-histclim
          # for adapt in "" -histclim -incadapt -incadapt-histclim -noadapt -noadapt-histclim; do 
          for adapt in "" -histclim -incadapt -noadapt; do 
            input_file=${inputdir}/${singles_folder}/rcp85/CCSM4/high/${ssp}/${root}${adapt}${price}${type}.nc4
            output_file=${outputdir}/single${type}_energy_rcp85_ccsm4_high_${ssp}_${flow}_${product}_FD_FGLS${adapt}${price}_${val}.csv
            
            if [ ! -f ${input_file} ]; then
              echo "${input_file} not found!!!!!!!"
            else
              echo "python single.py --column=${val} ${input_file} > ${output_file}"
              python single.py --column=${val} ${input_file} > ${output_file}
              echo "extracted: ${input_file}"
              echo "output: ${output_file}"
            fi
          done
        fi
      done
    done
  done
done
