# This script loads in GCM level mean and standard deviations, and outputs random draws from 
# the uncertainty space 

rm(list = ls())

# Load in the required packages, installing them if necessary 
if(!require("pacman")){install.packages(("pacman"))}
pacman::p_load(dplyr,
               readr, tidyr)

library(vroom)

source(paste0("~/repos/energy-code-release-2020/2_projection/",
    "0_packages_programs_inputs/extract_projection_outputs/processing_debugging_package.R"))


# Set paths
DB = "/mnt/"
DB_data = paste0(DB, "/CIL_energy/code_release_data_pixel_interaction")
dir = paste0(DB_data, "/projection_system_outputs/integration/")


# This function takes in a csv that contains means and variances of 
# each GCMs projected global impact for a given year. 
# Outputs a long dataframe for damage function estimation, plotting, and 
# uncertainty calculations

input_path = "/shares/gcp/social/parameters/energy_pixel_interaction/extraction/multi-models/rationalized_code/break2_Exclude_all-issues_semi-parametric/TINV_clim_GMFD/total_energy/price014/"
projection_path = "/shares/gcp/outputs/energy_pixel_interaction/impacts-blueghost/median_OTHERIND_electricity_TINV_clim_GMFD/median/"

gcms = list()

gcms$"rcp45" = c(list.dirs(path = paste0(projection_path, "rcp45/"), 
  full.names = FALSE,
  recursive = FALSE))

gcms$"rcp85" = c(list.dirs(path = paste0(projection_path, "rcp85/"), 
  full.names = FALSE,
  recursive = FALSE))

save_files <- function(ssp, rcp, dir) {
  dt_mean = vroom(glue("{path}/{ssp}-{rcp}_damage-price014_median_fulladapt-levels_press.csv"))
  dt_sd = vroom(paste0(path, "SSP3-rcp85_damage-price014_median_fulladapt-levels_press.csv"))


}

ssp = "SSP3"
rcp = "rcp45"
dt_mean = vroom(glue("{input_path}/{ssp}-{rcp}_damage-price014_median_fulladapt-levels_dm_press.csv"))
dt_sd = vroom(glue("{input_path}/{ssp}-{rcp}_damage-price014_median_fulladapt-levels_dm_press.csv"))

dt_mean_gcms = split(dt_mean , f = dt_mean$gcm)
dt_sd_gcms = split(dt_sd , f = dt_sd$gcm)


dt45_mean = dt45_mean %>%
    rename(mean=value) %>% 
    dplyr::select(region, year, gcm, iam, mean) %>%  
    mutate(mean = mean / 0.0036, rcp = "rcp45")

dt45_sd = dt45_sd %>% 
      mutate(sd=sqrt(value))%>% 
      dplyr::select(region, year, gcm, iam, sd) %>% 
      mutate(sd = sd / 0.0036, rcp = "rcp45")


dt85_mean = dt85_mean %>%
    rename(mean=value) %>% 
    dplyr::select(region, year, gcm, iam, mean) %>%  
    mutate(mean = mean / 0.0036, rcp = "rcp85")

dt85_sd = dt85_sd %>% 
      mutate(sd=sqrt(value))%>% 
      dplyr::select(region, year, gcm, iam, sd) %>% 
      mutate(sd = sd / 0.0036, rcp = "rcp85")


save_gcm <- function(df_mean, df_var, gcm, ssp, rcp, dir) {
  df
}
df_joined = left_join(dt45_mean, dt45_sd, by=c("region", "year", "rcp", "gcm", "iam"))


output = paste0('/mnt/CIL_energy/', 
  '/code_release_data_pixel_interaction/projection_system_outputs/damage_function_estimation')

write_csv(df_joined, paste0(output, '/impact_values/SSP3_TINV_clim_price014_total_energy_mean_sd_valuescsv.csv'))


take_draws = function(df, price, fuel, num_iterations, 
                      directory) {
  
  # set seed for replicability:
  set.seed(123)
  
  # Take draws
  l = length(df$mean)
  for(i in 1:num_iterations) {
    x = paste0("batch", i)
    df[x] = rnorm(l, mean = df$mean, sd = df$sd)
  }
  
  # Reshape the df to make it long for the quantile regression code
  print('reshaping')
  df <- df %>%
    dplyr::select(-c(mean, sd)) %>%
    tidyr::pivot_longer(
      cols = starts_with("batch"), 
      names_to = "batch", 
      values_to = paste0(price, "value"),
      values_drop_na = FALSE)

  write_csv(df, paste0(directory, "resampled_data/",
                       "SSP3_TINV_clim_price014_total_energy_", num_iterations, "-draws.csv"))

  return(df)
    
}

####################

df = take_draws(df_joined, price = "price014",  
                num_iterations = 15, directory = dir)


