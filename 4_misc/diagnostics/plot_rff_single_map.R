# plot electricity quantities map for rff single
rm(list = ls())
# library(ncdf4)

source("/home/liruixue/projection_repos/post-projection-tools/mapping/imgcat.R") #this redefines the way ggplot plots. 

# Load in the required packages, installing them if necessary 
if(!require("pacman")){install.packages(("pacman"))}
pacman::p_load(ggplot2, 
               dplyr,
               readr)

DB = "/mnt/CIL_energy"

DB_data = paste0(DB, "/code_release_data_pixel_interaction")
root =  "/home/liruixue/repos/energy-code-release-2020"
output = paste0(root, "/figures")

source(paste0(root, "/3_post_projection/0_utils/mapping.R"))

#############################################
# 1. Load in a world shapefile, containing Impact Region boundaries, and convert to a 
#     dataframe for plotting

mymap = load.map(shploc = paste0(DB_data, "/shapefiles/world-combo-new-nytimes"))

# # # python code:
# import xarray as xr 
# fulladapt = xr.open_dataset("/shares/gcp/outputs/energy_pixel_interaction/impacts-blueghost/median/rcp85/CCSM4/rff/6546/FD_FGLS_inter_OTHERIND_electricity_TINV_clim.nc4")
# histclim = xr.open_dataset("/shares/gcp/outputs/energy_pixel_interaction/impacts-blueghost/median/rcp85/CCSM4/rff/6546/FD_FGLS_inter_OTHERIND_electricity_TINV_clim-histclim.nc4")
# full = fulladapt.to_dataframe().reset_index()[['year','regions','rebased']]
# hist = histclim.to_dataframe().reset_index()[['year','regions','rebased']]
# full = full.set_index(['year','regions'])
# hist = hist.set_index(['year','regions'])
# diff= full - hist
# diff.reset_index().to_csv("/shares/gcp/outputs/energy_pixel_interaction/impacts-blueghost/median/rcp85/CCSM4/rff/6546/fulladapt-histclim.csv")
#############################################
# 2. Figure 2 A

df= read_csv("/shares/gcp/outputs/energy_pixel_interaction/impacts-blueghost/median/rcp85/CCSM4/rff/6546/fulladapt-histclim.csv") 
# browser()
# Set scaling factor for map color bar
bound = 18
df = df %>% filter(year == 2099) 
scale_v = c(-1, -0.2, -0.05, -0.005, 0, 0.005, 0.05, 0.2, 1)
rescale_value <- scale_v*bound
fuel = "electricity"

p = join.plot.map(map.df = mymap, 
                   df = df, 
                   df.key = "regions", 
                   plot.var = "rebased", 
                   topcode = F, 
                   topcode.ub = max(rescale_value),
                   breaks_labels_val = seq(-bound, bound, bound/3),
                   color.scheme = "div", 
                   rescale_val = rescale_value,
                   colorbar.title = paste0(fuel, " imapacts, GJ PC, 2099"), 
                   map.title = paste0(fuel, 
                                  "_TINV_clim_SSP3-rcp85_impactpc_high_fulladapt_2099"))

p = p + theme(
  panel.background = element_rect(fill = "transparent"), # bg of the panel
  plot.background = element_rect(fill = "transparent", color = NA), # bg of the plot
  panel.grid.major = element_blank(), # get rid of major grid
  panel.grid.minor = element_blank(), # get rid of minor grid
  legend.background = element_rect(fill = "transparent"), # get rid of legend bg
  legend.box.background = element_rect(fill = "transparent") # get rid of legend panel bg
)
# browser()
ggsave(paste0(output, "/rff_map_topcode_18.pdf"), p,  bg = "transparent")




