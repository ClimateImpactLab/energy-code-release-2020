# This script loads in GCM level mean and standard deviations, and outputs random draws from 
# the uncertainty space 

rm(list = ls())

# Load in the required packages, installing them if necessary 
if(!require("pacman")){install.packages(("pacman"))}
pacman::p_load(dplyr,
               readr, tidyr)
source(glue("~/repos/mortality/utils/wrap_mapply.R"))

library(vroom)

source(paste0("~/repos/energy-code-release-2020/2_projection/",
    "0_packages_programs_inputs/extract_projection_outputs/processing_debugging_package.R"))
input_dir = "/shares/gcp/social/parameters/energy_pixel_interaction/extraction/multi-models/rationalized_code/break2_Exclude_all-issues_semi-parametric/TINV_clim_GMFD/total_energy/price014/"
output_dir = "/shares/gcp/outputs/energy_pixel_interaction/impacts-blueghost/integration_resampled/"

projection_path = "/shares/gcp/outputs/energy_pixel_interaction/impacts-blueghost/median_OTHERIND_electricity_TINV_clim_GMFD/median/"

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



take_draws = function(df, num_iterations, 
                      directory, filename_prefix) {
  
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
      values_drop_na = FALSE)

  write_csv(df, paste0(directory, filename_prefix, 
                       "_TINV_clim_price014_total_energy_", num_iterations, "-draws.csv"))

  return(df)
    
}

process_results <- function(input_dir, output_dir, gcm, ssp, rcp, iam, num_iterations=15) {
  mean = vroom(glue("{input_dir}/{ssp}-{rcp}_{iam}_{gcm}_damage-price014_median_fulladapt-levels_press.csv"))
  sd = vroom(glue("{input_dir}/{ssp}-{rcp}_{iam}_{gcm}_damage-price014_median_fulladapt-levels_dm_press.csv"))

  mean = mean %>%
      rename(mean=value) %>% 
      dplyr::select(region, year, mean) %>%  
      mutate(mean = mean / 0.0036)

  sd = sd %>% 
        mutate(sd=sqrt(value))%>% 
        dplyr::select(region, year, sd) %>% 
        mutate(sd = sd / 0.0036)

  # browser()
  joined = left_join(mean, sd, by=c("region", "year"))
  
  filename_prefix = glue("{ssp}-{rcp}_{iam}_{gcm}")
  take_draws(joined, num_iterations, output_dir, filename_prefix)

}

####################

# df = process_results(input_dir=input_dir, output_dir=output_dir, 
#   gcm="CCSM4", ssp="SSP3", rcp="rcp85", iam="high", num_iterations=15)


out = wrap_mapply(  
  input_dir=input_dir, 
  output_dir=output_dir, 
  gcm = gcms$rcp45,
  rcp="rcp45",
  iam = c("high","low"),
  ssp = c("SSP3"),
  FUN=process_results,
  mc.cores=34,
  mc.silent=FALSE
)

out = wrap_mapply(  
  input_dir=input_dir, 
  output_dir=output_dir, 
  gcm = gcms$rcp85,
  rcp="rcp85",
  iam = c("high","low"),
  ssp = c("SSP3"),
  FUN=process_results,
  mc.cores=34,
  mc.silent=FALSE
)

