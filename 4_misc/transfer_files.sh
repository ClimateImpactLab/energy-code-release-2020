
CP() {
    mkdir -p $(dirname "$2") && cp -rf "$1" "$2"
}

DATA="/home/liruixue/energy_data_release"

for shp in WORLD WORLDpre SRB_MNE_XKO SRB_MNE MDA_other ITA_SMR_VAT ISR_PSE CUW_BES_ABW FRA_MCO
do
    CP "/shares/gcp/climate/_spatial_data/${shp}/weather_data/"  "${DATA}/DATA/climate/_spatial_data/${shp}/weather_data/"
    echo "/home/liruixue/energy_data_release/DATA/climate/_spatial_data/${shp}/weather_data/"
done

CP /shares/gcp/estimation/energy/IEA ${DATA}/DATA/energy/IEA

CP /mnt/CIL_energy/code_release_data_pixel_interaction/projection_system_outputs ${DATA}/OUTPUT/projection_system_outputs

CP /mnt/CIL_energy/code_release_data_pixel_interaction/intermediate_data  ${DATA}/DATA/

CP /mnt/CIL_energy/code_release_data_pixel_interaction/miscellaneous  ${DATA}/DATA/
CP /mnt/CIL_energy/code_release_data_pixel_interaction/price_scenarios  ${DATA}/DATA/
CP /mnt/CIL_energy/code_release_data_pixel_interaction/shapefiles  ${DATA}/DATA/
CP /mnt/CIL_energy/code_release_data_pixel_interaction/referee_comments  ${DATA}/OUTPUT/

CP "/home/liruixue/repos/energy-code-release-2020/figures" ${DATA}/OUTPUT/
CP "/home/liruixue/repos/energy-code-release-2020/sters" ${DATA}/OUTPUT/
