
CP() {
    mkdir -p $(dirname "$2") && cp -rf "$1" "$2"
}


CP /shares/gcp/climate/_spatial_data/ /home/liruixue/energy_data_release/climate/_spatial_data/ 
CP /shares/gcp/climate/_spatial_data/WORLD/pre1991/weather_data/ /home/liruixue/energy_data_release/climate/_spatial_data/WORLD/pre1991/weather_data/ 
CP /shares/gcp/climate/BCSD/SMME/SMME-weights /home/liruixue/energy_data_release/climate/BCSD/SMME/SMME-weights
CP /shares/gcp/climate/BCSD/hierid/popwt/daily /home/liruixue/energy_data_release/climate/BCSD/hierid/popwt/daily

CP /shares/gcp/social/parameters/energy/incspline0719/GMFD/TINV_clim_income_spline /home/liruixue/energy_data_release/social/parameters/energy/incspline0719/GMFD/TINV_clim_income_spline
CP /shares/gcp/social/parameters/energy/extraction/median_delta_method_test/ /home/liruixue/energy_data_release/social/parameters/energy/extraction/median_delta_method_test/
CP /shares/gcp/social/parameters/energy_pixel_interaction/extraction/ /home/liruixue/energy_data_release/social/parameters/energy_pixel_interaction/extraction/
CP /shares/gcp/social/baselines/nightlights_downscale/NL/nightlights_1992_test2.csv /home/liruixue/energy_data_release/social/baselines/nightlights_downscale/NL/nightlights_1992_test2.csv
CP /shares/gcp/social/baselines/population/merged/population-merged.SSP3.csv /home/liruixue/energy_data_release/social/baselines/population/merged/population-merged.SSP3.csv

CP /shares/gcp/regions/hierarchy.csv /home/liruixue/energy_data_release/regions/hierarchy.csv
CP /shares/gcp/regions/continents2.csv /home/liruixue/energy_data_release/regions/continents2.csv
CP /shares/gcp/regions/macro-regions.csv /home/liruixue/energy_data_release/regions/macro-regions.csv

CP /shares/gcp/outputs/energy/scc_uncertainty/ /home/liruixue/energy_data_release/outputs/energy/scc_uncertainty/
# CP /shares/gcp/outputs/energy/impacts-blueghost
# CP /shares/gcp/outputs/energy_pixel_interaction/
# CP /shares/gcp/outputs/energy_pixel_interaction/impacts-blueghost

CP /shares/gcp/estimation/energy/IEA /home/liruixue/energy_data_release/estimation/energy/IEA
CP /shares/gcp/estimation/mortality/release_2020/data/3_valuation/inputs/adjustments/fed_income_inflation.csv  /home/liruixue/energy_data_release/estimation/mortality/release_2020/data/3_valuation/inputs/adjustments/fed_income_inflation.csv

CP /mnt/CIL_energy/code_release_data_pixel_interaction/ /home/liruixue/energy_data_release/CIL_energy/code_release_data_pixel_interaction/
CP /mnt/CIL_energy/IEA_Replication /home/liruixue/energy_data_release/CIL_energy/IEA_Replication
CP /mnt/CIL_energy/outreach/ipcc /home/liruixue/energy_data_release/CIL_energy/outreach/ipcc
CP /mnt/CIL_labor/outreach/ipcc /home/liruixue/energy_data_release/CIL_labor/outreach/ipcc

CP /mnt/Global_ACP/MORTALITY/Replication_2018/3_Output/7_valuation/1_values/adjustments/vsl_adjustments.dta /home/liruixue/energy_data_release/MORTALITY/Replication_2018/3_Output/7_valuation/1_values/adjustments/vsl_adjustments.dta
CP /mnt/Global_ACP/damage_function/GMST_anomaly/gcm_weights.csv /home/liruixue/energy_data_release/damage_function/GMST_anomaly/gcm_weights.csv
CP /mnt/Global_ACP/damage_function/GMST_anomaly /home/liruixue/energy_data_release/damage_function/GMST_anomaly
CP /mnt/Global_ACP/damage_function/GMST_anomaly/GMTanom_all_temp_2001_2010_smooth.csv /home/liruixue/energy_data_release/damage_function/GMST_anomaly/GMTanom_all_temp_2001_2010_smooth.csv


CP /mnt/CIL_labor/outreach/ipcc /home/liruixue/energy_data_release/CIL_labor/outreach/ipcc
CP /mnt/GCP_Reanalysis/cross_sector/hierarchy.csv /home/liruixue/energy_data_release/GCP_Reanalysis/cross_sector/hierarchy.csv







