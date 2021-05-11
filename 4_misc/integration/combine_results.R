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

input_dir = "/shares/gcp/outputs/energy_pixel_interaction/impacts-blueghost/integration_resampled/"
output_dir = "/shares/gcp/outputs/energy_pixel_interaction/impacts-blueghost/integration_resampled/merged/"
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

read_file = function(input_dir=input_dir, 
  gcm="CCSM4", ssp="SSP3", rcp="rcp85", iam="high", batch=1) {

  df = vroom(glue("{input_dir}/{ssp}-{rcp}_{iam}_{gcm}_TINV_clim_price014_total_energy_batch", batch, ".csv")) 
  df = df %>% mutate(ssp = ssp, rcp = rcp,  gcm = gcm, iam = iam)
  return(df) 
}


combine_results = function(batch, input_dir, output_dir) {

  files_45 = wrap_mapply(  
    input_dir=input_dir, 
    batch = batch,
    gcm = gcms$rcp45,
    rcp="rcp45",
    iam = c("high","low"),
    ssp = c("SSP3"),
    FUN=read_file,
    mc.cores=34,
    mc.silent=FALSE
  )
  files_85 = wrap_mapply(  
    input_dir=input_dir, 
    batch = batch,
    gcm = gcms$rcp85,
    rcp="rcp85",
    iam = c("high","low"),
    ssp = c("SSP3"),
    FUN=read_file,
    mc.cores=34,
    mc.silent=FALSE
  )

  df = as.data.frame(data.table::rbindlist(c(files_45, files_85)))
  
  # batch numbers start with 0, so we shift draw numbers by 1
  batch_number = batch - 1

  df = df%>% mutate(iam = ifelse(iam == "low", "IIASA GDP", "OECD Env-Growth"),
    batch = paste0("batch",batch_number))
  return(df)

}



for (i in 2:15) {
  df = combine_results(1, input_dir, output_dir)
  write_csv(df, paste0(output_dir, "test.csv"))
  gc()
}

