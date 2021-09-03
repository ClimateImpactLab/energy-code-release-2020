# Produces maps displayed in the energy paper. Uses Functions in mapping.R
rm(list = ls())

source("/home/liruixue/projection_repos/post-projection-tools/mapping/imgcat.R") #this redefines the way ggplot plots. 

# Load in the required packages, installing them if necessary 
if(!require("pacman")){install.packages(("pacman"))}
pacman::p_load(ggplot2, 
               dplyr,
               readr)

library(glue)
DB = "/mnt/CIL_energy"

DB_data = paste0(DB, "/code_release_data_pixel_interaction")
root =  "/home/liruixue/repos/energy-code-release-2020"
output = paste0(root, "/figures")

source(paste0(root, "/3_post_projection/0_utils/mapping.R"))

fuel = "total_energy"
ssp = "SSP3"
iam = "high"
rcp = "rcp85"

df_damages = read_csv(
  paste0(DB_data, '/projection_system_outputs/mapping_data/', 
          glue('main_model-{fuel}-{ssp}-{rcp}-{iam}-fulladapt-integration-2099-map.csv'))) 

# Load in GDP data
covariates = read_csv(
  paste0(DB_data, '/projection_system_outputs/covariates/', 
         glue('{ssp}-{iam}-IR_level-gdppc_pop-2099.csv'))) 

# Join data, and calculate damages as percent of GDP for each region
df = left_join(df_damages, covariates, by = "region")%>%
  mutate(damage_per_gdp99 = damage * 1000000000 / gdp99 / 0.0036) %>%
  arrange((damage_per_gdp99)) %>% dplyr::select(c("region", "damage_per_gdp99"))


df_damages = read_csv(
  paste0(DB_data, '/projection_system_outputs/mapping_data/', 
          glue('main_model-{fuel}-{ssp}-{rcp}-{iam}-fulladapt-price014-2099-map.csv'))) 

# Load in GDP data
covariates = read_csv(
  paste0(DB_data, '/projection_system_outputs/covariates/', 
         glue('{ssp}-{iam}-IR_level-gdppc_pop-2099.csv'))) 

# Join data, and calculate damages as percent of GDP for each region
df = left_join(df_damages, covariates, by = "region")%>%
  mutate(damage_per_gdp99 = damage * 1000000000 / gdp99 / 0.0036) %>%
  arrange((damage_per_gdp99)) %>% dplyr::select(c("region", "damage_per_gdp99"))






