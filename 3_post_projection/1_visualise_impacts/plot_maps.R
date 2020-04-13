# Produces maps displayed in the energy paper. Uses Functions in mapping.R

rm(list = ls())

# Load in the required packages, installing them if necessary 
if(!require("pacman")){install.packages(("pacman"))}
pacman::p_load(ggplot2, 
               dplyr,
               readr)

DB = "C:/Users/TomBearpark/Dropbox"

DB_data = paste0(DB, "/GCP_Reanalysis/ENERGY/code_release_data")
root =  "C:/Users/TomBearpark/Documents/energy-code-release"
output = paste0(root, "/figures")

source(paste0(root, "/3_post_projection/0_utils/mapping.R"))

#############################################
# 1. Load in a world shapefile, containing Impact Region boundaries, and convert to a 
#     dataframe for plotting

mymap = load.map(shploc = paste0(DB_data, "/world-combo-new-nytimes"))


#############################################
# 2. Figure 2 A

df_electricity = read_csv(
  paste0(DB_data, 
    "/electricity_TINV_clim_income_spline_SSP3-rcp85_impactpc_high_fulladapt_2099.csv")) %>%
  mutate(mean =mean * 0.0036)

scale_v = c(-1, -0.2, -0.05, -0.005, 0, 0.005, 0.05, 0.2, 1)
bound = 3
rescale_value <- scale_v*bound

p2A_elec = join.plot.map(map.df = mymap, 
                         df = df_electricity, 
                         df.key = "region", 
                         plot.var = "mean", 
                         topcode = T, 
                         topcode.ub = max(rescale_value),
                         breaks_labels_val = seq(-bound, bound, bound/3),
                         color.scheme = "div", 
                         rescale_val = rescale_value,
                         colorbar.title = "Electricity imapacts, GJ PC, 2099", 
                         map.title = "electricity_TINV_clim_income_spline_SSP3-rcp85_impactpc_high_fulladapt_2099")

ggsave(paste0(output, "/fig_2A_electricity_impacts_map.png"), p2A_elec)


df_other_fuels = read_csv(
  paste0(DB_data, 
         "/other_energy_TINV_clim_income_spline_SSP3-rcp85_impactpc_high_fulladapt_2099.csv")) %>%
  mutate(mean =mean * 0.0036)

scale_v = c(-1, -0.2, -0.05, -0.005, 0, 0.005, 0.05, 0.2, 1)
bound = 18
rescale_value <- scale_v*bound

p2A_other_fuels = join.plot.map(map.df = mymap, 
                         df = df_other_fuels, 
                         df.key = "region", 
                         plot.var = "mean", 
                         topcode = T, 
                         topcode.ub = max(rescale_value),
                         breaks_labels_val = seq(-bound, bound, bound/3),
                         color.scheme = "div", 
                         rescale_val = rescale_value,
                         colorbar.title = "Other fuels imapacts, GJ PC, 2099", 
                         map.title = "other_energy_TINV_clim_income_spline_SSP3-rcp85_impactpc_high_fulladapt_2099")

ggsave(paste0(output, "/fig_2A_other_fuels_impacts_map.png"), p2A_other_fuels)
