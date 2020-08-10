# Produces maps displayed in the energy paper. Uses Functions in mapping.R

rm(list = ls())

library(rnaturalearth)

library(ggplot2)
library(sp)
source("/home/liruixue/projection_repos/post-projection-tools/mapping/imgcat.R") #this redefines the way ggplot plots. 

# Load in the required packages, installing them if necessary 
if(!require("pacman")){install.packages(("pacman"))}
pacman::p_load(ggplot2, 
               dplyr,
               readr)

DB = '/mnt/norgay_synology_drive/'

DB_data = paste0(DB, "/GCP_Reanalysis/ENERGY/code_release_data_pixel_interaction")
root =  "/home/liruixue/repos/energy-code-release-2020"
output = "/mnt/norgay_synology_drive/GCP_Reanalysis/ENERGY/code_release_data_pixel_interaction/projection_system_outputs/21jul2020_pre_data/"


source(paste0(root, "/3_post_projection/0_utils/mapping.R"))

#############################################
# 1. Load in a world shapefile, containing Impact Region boundaries, and convert to a 
#     dataframe for plotting

mymap = load.map(shploc = paste0(DB_data, "/shapefiles/world-combo-new-nytimes"))

csr = "+proj=robin +lon_0=0 +x_0=0 +y_0=0 +ellps=WGS84 +datum=WGS84 +units=m +no_defs"

my_USA_border = ne_countries(country = "united states of america") %>%
        spTransform(CRS(csr)) 
my_IND_border = ne_countries(country = "india") %>%
        spTransform(CRS(csr)) 

#############################################
# 2. Figure 2 A

plot_2A = function(fuel, bound, DB_data, map=mymap, USA_border = my_USA_border, IND_border = my_IND_border ) {

  # Load in the impacts-pc data, and convert it to GJ
  df= read_csv(
    paste0(DB_data, '/projection_system_outputs/mapping_data/', 
           'main_model-', fuel, '-SSP3-rcp85-high-fulladapt-impact_pc-2099-map.csv')) 
  # Set scaling factor for map color bar
  scale_v = c(-1, -0.2, -0.05, -0.005, 0, 0.005, 0.05, 0.2, 1)
  rescale_value <- scale_v*bound
  browser()
  
  p = join.plot.map(map.df = map, 
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
  # add border to each impact region:
  # p + geom_path(data = mymap_USA, 
  #   aes(x=long, y=lat, group=group), 
  #   color = "black", 
  #   size=0.1, 
  #   alpha=1)

  # add border to a whole country
  p = p +  geom_polygon(data = USA_border, aes(x = long, y = lat, group = group), 
    color = "black", fill = NA, size = 0.2, alpha = 1) +
    geom_polygon(data = IND_border, aes(x = long, y = lat, group = group), 
      color = "black", fill = NA, size = 0.2, alpha = 1)
  
  ggsave(paste0(output, "/fig_2A_", fuel, "_impacts_map.pdf"), p)
}

plot_2A(fuel = "electricity", bound = 3, DB_data = DB_data)
plot_2A(fuel = "other_energy", bound = 18, DB_data = DB_data)





















