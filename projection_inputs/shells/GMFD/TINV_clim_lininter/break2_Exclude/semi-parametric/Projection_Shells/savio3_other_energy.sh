#!/bin/bash
# Job name:
#SBATCH --job-name=other_energy
# Partition:
#SBATCH --partition=savio3
# Account:
#SBATCH --account=co_laika
# QoS:
#SBATCH --qos=laika_savio3_normal
# Wall clock limit:
#SBATCH --time=98:00:00

## Command(s) to run:

export SINGULARITY_BINDPATH=/global/scratch2/groups/co_laika/

/global/scratch2/groups/co_laika/gcp-generate.img /global/scratch/liruixue/repos/energy-code-release-2020/projection_inputs/configs/GMFD/TINV_clim_lininter/break2_Exclude/semi-parametric/Projection_Configs/laika/run/median/energy-median-hddcddspline_OTHERIND_other_energy.yml 24