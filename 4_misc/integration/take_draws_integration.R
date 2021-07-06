# This script loads in GCM level mean and standard deviations, and outputs random draws from 
# the uncertainty space 

rm(list = ls())
library(vroom)
library(glue)
library(parallel)

# Load in the required packages, installing them if necessary 
if(!require("pacman")){install.packages(("pacman"))}
pacman::p_load(dplyr,
               readr, tidyr)

source(glue("~/repos/mortality/utils/wrap_mapply.R"))

input_dir = "/shares/gcp/social/parameters/energy_pixel_interaction/extraction/multi-models/rationalized_code/break2_Exclude_all-issues_semi-parametric/TINV_clim_GMFD/total_energy/integration/"
output_dir = "/shares/gcp/outputs/energy_pixel_interaction/impacts-blueghost/integration_resampled/"
projection_path = "/shares/gcp/outputs/energy_pixel_interaction/impacts-blueghost/median_OTHERIND_electricity_TINV_clim_GMFD/median/"


# get the list of gcms 
gcms = list()
gcms$"rcp45" = c(list.dirs(path = paste0(projection_path, "rcp45/"), 
  full.names = FALSE,
  recursive = FALSE))
gcms$"rcp85" = c(list.dirs(path = paste0(projection_path, "rcp85/"), 
  full.names = FALSE,
  recursive = FALSE))


# This function takes in a csv that contains means and variances of 
# each GCMs projected global impact for a given year. 
# Outputs a long dataframe for damage function estimation, plotting, and 
# uncertainty calculations

take_draws = function(df) {
  
  # Take draws
  l = length(df$mean)
  df["rebased"] = rnorm(l, mean = df$mean, sd = df$sd)
  df <- df %>% dplyr::select(-c(mean, sd))

}   

# reads extracted mean and sd of each ssp/rcp/iam/gcp combination, and take draws
process_results <- function(input_dir, output_dir, gcm, ssp, rcp, iam, num_iterations=15) {
  
  mean_path = glue("{input_dir}/{ssp}-{rcp}_{iam}_{gcm}_damage-integration_median_fulladapt-levels_integration.csv")
  sd_path = glue("{input_dir}/{ssp}-{rcp}_{iam}_{gcm}_damage-integration_median_fulladapt-levels_dm_integration.csv")
  # if (file.exists(mean_path) & file.exists(sd_path)) {
    mean = vroom(mean_path)
    sd = vroom(sd_path)

    mean = mean %>%
        rename(mean=value) %>% 
        dplyr::select(region, year, mean) %>%  
        mutate(mean = mean / 0.0036)

    sd = sd %>% 
          mutate(sd=sqrt(value))%>% 
          dplyr::select(region, year, sd) %>% 
          mutate(sd = sd / 0.0036)

    joined = left_join(mean, sd, by=c("region", "year"))
    # set seed for replicability:
    set.seed(123)

    for(i in 0:14) {
      df = take_draws(joined)
      output_folder = glue("{output_dir}/batch{i}/{rcp}/{gcm}/{iam}/{ssp}/")
      dir.create(output_folder, recursive = TRUE)
      write_csv(df, paste0(output_folder,
                           "/TINV_clim_integration_total_energy_fulladapt-histclim.csv"))  
      # return(df)
    }
    # } else {
    #   print(glue("{mean_path} doesn't exist, or"))
    #   print(glue("{sd_path} doesn't exist"))

    # }

}

####################
# test function
df = process_results(input_dir=input_dir, output_dir=output_dir, 
  gcm="CCSM4", ssp="SSP3", rcp="rcp85", iam="high")


# run all combinations
# rcp45
out = wrap_mapply(  
  input_dir=input_dir, 
  output_dir=output_dir, 
  gcm = gcms$rcp45,
  rcp="rcp45",
  iam = c("high","low"),
  ssp = c("SSP1","SSP2","SSP3","SSP4"),
  FUN=process_results,
  mc.cores=34,
  mc.silent=FALSE
)

# # rcp85
out = wrap_mapply(  
  input_dir=input_dir, 
  output_dir=output_dir, 
  gcm = gcms$rcp85,
  rcp="rcp85",
  iam = c("high","low"),
  ssp = c("SSP2","SSP3","SSP4","SSP5"),
  FUN=process_results,
  mc.cores=34,
  mc.silent=FALSE
)



