python -u quantiles.py /home/liruixue/repos/energy-code-release-2020/projection_inputs/configs/GMFD/TINV_clim/break2_Exclude/semi-parametric/Extraction_Configs/sacagawea/impactpc//full/aggregated/median/energy-extract-impactpc-aggregated-median_OTHERIND_electricity.yml --only-iam=low --only-ssp="SSP3" --suffix=_impactpc_median_fulluncertainty_low_fulladapt-aggregated_press FD_FGLS_inter_OTHERIND_electricity_TINV_clim-aggregated -FD_FGLS_inter_OTHERIND_electricity_TINV_clim-histclim-aggregated
python -u quantiles.py /home/liruixue/repos/energy-code-release-2020/projection_inputs/configs/GMFD/TINV_clim/break2_Exclude/semi-parametric/Extraction_Configs/sacagawea/impactpc//full/aggregated/median/energy-extract-impactpc-aggregated-median_OTHERIND_other_energy.yml --only-iam=low --only-ssp="SSP3" --suffix=_impactpc_median_fulluncertainty_low_fulladapt-aggregated_press FD_FGLS_inter_OTHERIND_other_energy_TINV_clim-aggregated -FD_FGLS_inter_OTHERIND_other_energy_TINV_clim-histclim-aggregated

python -u quantiles.py /home/liruixue/repos/energy-code-release-2020/projection_inputs/configs/GMFD/TINV_clim/break2_Exclude/semi-parametric/Extraction_Configs/sacagawea/impactpc//full/levels/median/energy-extract-impactpc-median_OTHERIND_electricity.yml --only-iam=low --only-ssp="SSP3" --suffix=_impactpc_median_fulluncertainty_low_fulladapt-levels_press FD_FGLS_inter_OTHERIND_electricity_TINV_clim -FD_FGLS_inter_OTHERIND_electricity_TINV_clim-histclim
python -u quantiles.py /home/liruixue/repos/energy-code-release-2020/projection_inputs/configs/GMFD/TINV_clim/break2_Exclude/semi-parametric/Extraction_Configs/sacagawea/impactpc//full/levels/median/energy-extract-impactpc-median_OTHERIND_other_energy.yml --only-iam=low --only-ssp="SSP3" --suffix=_impactpc_median_fulluncertainty_low_fulladapt-levels_press FD_FGLS_inter_OTHERIND_other_energy_TINV_clim -FD_FGLS_inter_OTHERIND_other_energy_TINV_clim-histclim

python -u quantiles.py /home/liruixue/repos/energy-code-release-2020/projection_inputs/configs/GMFD/TINV_clim/break2_Exclude/semi-parametric/Extraction_Configs/sacagawea/damage/price014/full/aggregated/median/energy-extract-damage-median_OTHERIND_total_energy.yml --only-iam=low --only-ssp="SSP3" --suffix=_impactpc_median_fulluncertainty_low_fulladapt-levels_press FD_FGLS_inter_OTHERIND_electricity_TINV_clim -FD_FGLS_inter_OTHERIND_electricity_TINV_clim-histclim
