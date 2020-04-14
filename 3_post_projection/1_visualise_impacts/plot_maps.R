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

plot_2A = function(fuel, bound) {

  df= read_csv(
    paste0(DB_data, 
      "/", fuel, "_TINV_clim_income_spline_SSP3-rcp85_impactpc_high_fulladapt_2099.csv")) %>%
    mutate(mean =mean * 0.0036)
  
  scale_v = c(-1, -0.2, -0.05, -0.005, 0, 0.005, 0.05, 0.2, 1)
  rescale_value <- scale_v*bound
  
  p = join.plot.map(map.df = mymap, 
                     df = df, 
                     df.key = "region", 
                     plot.var = "mean", 
                     topcode = T, 
                     topcode.ub = max(rescale_value),
                     breaks_labels_val = seq(-bound, bound, bound/3),
                     color.scheme = "div", 
                     rescale_val = rescale_value,
                     colorbar.title = paste0(fuel, " imapacts, GJ PC, 2099"), 
                     map.title = paste0(fuel, 
                                          "_TINV_clim_income_spline_SSP3-rcp85_impactpc_high_fulladapt_2099"))
  
  ggsave(paste0(output, "/fig_2A_", fuel, "_impacts_map.png"), p)
}
plot_2A(fuel = "electricity", bound = 3)
plot_2A(fuel = "other_energy", bound = 18)


#############################################
# 2. Figure 2 A

