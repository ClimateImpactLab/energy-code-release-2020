# This script loads in GCM level mean and standard deviations, and outputs random draws from 
# the uncertainty space 

rm(list = ls())

# Load in the required packages, installing them if necessary 
if(!require("pacman")){install.packages(("pacman"))}
pacman::p_load(dplyr,
               readr, tidyr)


REPO <- Sys.getenv(c("REPO"))
DATA <- Sys.getenv(c("DATA"))
OUTPUT <- Sys.getenv(c("OUTPUT"))
root =  paste0(REPO, "/energy-code-release-2020")


# Set paths
dir = paste0(OUTPUT, "/projection_system_outputs/damage_function_estimation/")


# This function takes in a csv that contains means and variances of 
# each GCMs projected global impact for a given year. 
# Outputs a long dataframe for damage function estimation, plotting, and 
# uncertainty calculations


take_draws = function(price, ssp, fuel, num_iterations, 
                      directory) {
  
  # set seed for replicability:
  set.seed(123)
  
  # Set up strings used for loading in the data
  if(is.null(price)){
    type = "impacts"
    price_tag = ""
  }else{
    type = "damages"
    price_tag = paste0("_", price)
  }
  
  # Read in the gcm level means and standard deviations
  df = read_csv(paste0(directory, "impact_values/",
          "gcm_", type, "_OTHERIND_",fuel ,price_tag, "_",ssp, ".csv"))
  
  
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
                       "gcm_", type, "_OTHERIND_",fuel,
                       price_tag, "_",ssp,"-", num_iterations, "-draws.csv"))

  return(df)
    
}

####################
# 1. Get the data needed for the display in Figure 3C

df = take_draws(price = "price014", ssp = "SSP3", 
                fuel = "total_energy", num_iterations = 15, directory = dir)

df_oe = take_draws(price = NULL, ssp = "SSP3", 
                fuel = "other_energy", num_iterations = 15, directory = dir)

df_elec = take_draws(price = NULL, ssp = "SSP3", 
                fuel = "electricity", num_iterations = 15, directory = dir)



####################
# 2. Take 100 draws from all price scenarios, for use in quantile regressions
pricelist = c("price014", "price0", "price03", "WITCHGLOBIOM42", 
              "MERGEETL60", "REMINDMAgPIE1730", "REMIND17CEMICS", "REMIND17") 

lapply(pricelist, FUN = take_draws, 
       ssp = "SSP3", fuel = "total_energy", num_iterations = 100, directory = dir)



