#!/bin/bash
# Job name:
#SBATCH --job-name=other_energy
# Partition:
#SBATCH --partition=savio2_bigmem
# Account:
#SBATCH --account=co_laika
# QoS:
#SBATCH --qos=laika_bigmem2_normal
# Wall clock limit:
#SBATCH --time=98:00:00

## Command(s) to run:

export SINGULARITY_BINDPATH=/global/scratch/groups/co_laika/

/global/scratch/groups/co_laika/gcp-generate.img /global/scratch/tbearpark/repos/energy-code-release-2020/projection_inputs/configs/GMFD/TINV_clim_income_spline/break2_Exclude/semi-parametric/Projection_Configs/run/median/energy-median-hddcddspline_OTHERIND_other_energy.yml 24