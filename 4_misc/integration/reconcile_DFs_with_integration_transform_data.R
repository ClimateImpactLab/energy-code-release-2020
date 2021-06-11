# This script loads in GCM level mean and standard deviations, and outputs random draws from 
# the uncertainty space 

rm(list = ls())
library(vroom)
library(glue)
library(parallel)

cilpath.r:::cilpath()

# Load in the required packages, installing them if necessary 
if(!require("pacman")){install.packages(("pacman"))}
pacman::p_load(dplyr,
               readr, tidyr)

source(glue("~/repos/mortality/utils/wrap_mapply.R"))

projection.packages <- paste0(REPO,"/energy-code-release-2020/2_projection/0_packages_programs_inputs/extract_projection_outputs/")
setwd(paste0(REPO))

# Source codes that help us load projection system outputs
miceadds::source.all(paste0(projection.packages,"load_projection/"))

input_dir = "/shares/gcp/social/parameters/energy_pixel_interaction/extraction/multi-models/rationalized_code/break2_Exclude_all-issues_semi-parametric/TINV_clim_GMFD/total_energy/price014/"
output_dir = "/shares/gcp/outputs/energy_pixel_interaction/impacts-blueghost/integration_resampled/"
projection_path = "/shares/gcp/outputs/energy_pixel_interaction/impacts-blueghost/median_OTHERIND_electricity_TINV_clim_GMFD/median/"

points = read_csv("/home/liruixue/repos/labor-code-release-2020//data/misc/energy_damage_function_points_integration.csv")
conversion_value = 1.273526
points = points %>% mutate(
  global_damages_constant_model_collapsed = global_damages_constant_model_collapsed * conversion_value / 1000000000)
write_csv(points, "/home/liruixue/repos/labor-code-release-2020//data/misc/energy_damage_function_points_integration_transformed.csv")
