#!/bin/bash

output_root="/shares/gcp/outputs/energy_pixel_interaction/impacts-blueghost"
single_dir="median_OTHERIND_electricity_TINV_clim_GMFD" 


cd "${output_root}/${single_dir}"

filename_root="FD_FGLS_inter_OTHERIND_electricity_TINV_clim"
find . -name "status-generate.txt" | wc -l
find . -name "status-global.txt" | wc -l
find . -name "status-aggregate.txt" | wc -l

find . -name "${filename_root}.nc4" | wc -l




find . -name "FD_FGLS_inter_OTHERIND_other_energy_TINV_clim-histclim-aggregated.nc4" | wc -l
find . -name "FD_FGLS_inter_OTHERIND_other_energy_TINV_clim-levels.nc4" | wc -l
find . -name "FD_FGLS_inter_OTHERIND_other_energy_TINV_clim-histclim-levels.nc4" | wc -l
find . -name "status-aggregate.txt" | wc -l
find . -type d -mindepth 4  '!' -exec test -e "{}/FD_FGLS_inter_OTHERIND_other_energy_TINV_clim-histclim-levels.nc4" ';' -print




find . -name "FD_FGLS_inter_OTHERIND_electricity_TINV_clim-aggregated.nc4"  -size +2M| wc -l
find . -name "FD_FGLS_inter_OTHERIND_electricity_TINV_clim-histclim-aggregated.nc4" -size +2M | wc -l
find . -name "FD_FGLS_inter_OTHERIND_electricity_TINV_clim-noadapt-aggregated.nc4"  -size +2M| wc -l
find . -name "FD_FGLS_inter_OTHERIND_electricity_TINV_clim-incadapt-aggregated.nc4"  -size +2M| wc -l

find . -name "FD_FGLS_inter_OTHERIND_electricity_TINV_clim-levels.nc4"  -size +10M| wc -l
find . -name "FD_FGLS_inter_OTHERIND_electricity_TINV_clim-histclim-levels.nc4" -size +10M| wc -l
find . -name "FD_FGLS_inter_OTHERIND_electricity_TINV_clim-noadapt-levels.nc4" -size +10M| wc -l
find . -name "FD_FGLS_inter_OTHERIND_electricity_TINV_clim-incadapt-levels.nc4" -size +10M| wc -l


find . -name "FD_FGLS_inter_OTHERIND_electricity_TINV_clim.nc4" -size +5M | wc -l
find . -name "FD_FGLS_inter_OTHERIND_electricity_TINV_clim-noadapt.nc4" -size +5M | wc -l
find . -name "FD_FGLS_inter_OTHERIND_electricity_TINV_clim-incadapt.nc4" -size +5M | wc -l
find . -name "FD_FGLS_inter_OTHERIND_electricity_TINV_clim-histclim.nc4" -size +5M | wc -l




find . -name "FD_FGLS_inter_OTHERIND_other_energy_TINV_clim.nc4" -size +5M | wc -l
find . -name "FD_FGLS_inter_OTHERIND_other_energy_TINV_clim-noadapt.nc4" -size +5M | wc -l
find . -name "FD_FGLS_inter_OTHERIND_other_energy_TINV_clim-incadapt.nc4" -size +5M | wc -l
find . -name "FD_FGLS_inter_OTHERIND_other_energy_TINV_clim-histclim.nc4" -size +5M | wc -l

find . -name "FD_FGLS_inter_OTHERIND_other_energy_TINV_clim-aggregated.nc4"  -size +2M| wc -l
find . -name "FD_FGLS_inter_OTHERIND_other_energy_TINV_clim-histclim-aggregated.nc4"  -size +2M| wc -l
find . -name "FD_FGLS_inter_OTHERIND_other_energy_TINV_clim-noadapt-aggregated.nc4" | wc -l
find . -name "FD_FGLS_inter_OTHERIND_other_energy_TINV_clim-incadapt-aggregated.nc4" | wc -l

find . -name "FD_FGLS_inter_OTHERIND_other_energy_TINV_clim-levels.nc4" -size +10M | wc -l
find . -name "FD_FGLS_inter_OTHERIND_other_energy_TINV_clim-histclim-levels.nc4"  -size +10M| wc -l
find . -name "FD_FGLS_inter_OTHERIND_other_energy_TINV_clim-noadapt-levels.nc4"  -size +10M| wc -l
find . -name "FD_FGLS_inter_OTHERIND_other_energy_TINV_clim-incadapt-levels.nc4"  -size +10M| wc -l

