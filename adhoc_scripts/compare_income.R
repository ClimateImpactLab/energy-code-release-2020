# Comparison of country-level income and IR-level, downscaled income at 2099 
# map country-level income and IR-level income
# map ratio of country-level income and IR-level income


rm(list = ls())
library(ggplot2)
library(sp)
library(glue)

library(dplyr)
library(readr)
library(haven)
cilpath.r:::cilpath()

source(paste0(REPO, "/post-projection-tools/mapping/imgcat.R")) #this redefines the way ggplot plots. 

# Load in the required packages, installing them if necessary 
if(!require("pacman")){install.packages(("pacman"))}
pacman::p_load(ggplot2, 
               dplyr,
               readr)

data = '/shares/gcp/social/parameters/energy_pixel_interaction/extraction/'

root =  paste0(REPO, "/energy-code-release-2020")
output = "/mnt/CIL_energy/pixel_interaction/projection_system_outputs/plot_single/"

source(paste0(root, "/3_post_projection/0_utils/mapping.R"))
source(paste0(root, "/3_post_projection/0_utils/time_series.R"))

#############################################
# 1. Load in a world shapefile, containing Impact Region boundaries, and convert to a 
#     dataframe for plotting

mymap = load.map(shploc = "/mnt/CIL_energy/code_release_data/shapefiles/world-combo-new-nytimes")


#############################################
# 2. plot map

plot_map = function(plot_title, plot_var, data, map=mymap, output = output) {

  p = join.plot.map(map.df = mymap, 
                   df = data, 
                   df.key = "region", 
                   plot.var = plot_var, 
                   topcode = T,
                   topcode.ub = round(max(data[plot_var]),2),
                   topcode.lb = round(min(data[plot_var]),2),
                   color.scheme = "div", 
                   round.minmax = 4,
                   colorbar.title = plot_var, 
                   map.title = paste0(plot_title,"_2099"))

  ggsave(paste0(output, "/", plot_title, "_map_not_topcoded.pdf"), p)
  return(p)

}

df_country= read_csv("/shares/gcp/outputs/energy_pixel_interaction/impacts-blueghost/single-OTHERIND_electricity_FD_FGLS_719_Exclude_all-issues_break2_semi-parametric_TINV_clim_GMFD/rcp85/CCSM4/high/SSP3/hddcddspline_OTHERIND_electricity-allcalcs-FD_FGLS_inter_OTHERIND_electricity_TINV_clim.csv", 
  skip = 114)%>% 
   dplyr::select(year, region, loggdppc)%>%
   dplyr::filter(year == 2099)

df_IR= read_csv("/mnt/battuta_shares/gcp/outputs/energy/impacts-blueghost/single-OTHERIND_electricity_FD_FGLS_719_Exclude_all-issues_break2_semi-parametric_TINV_clim_income_spline_GMFD/rcp85/CCSM4/high/SSP3/hddcddspline_OTHERIND_electricity-allcalcs-FD_FGLS_inter_climGMFD_Exclude_all-issues_break2_semi-parametric_poly2_OTHERIND_electricity_TINV_clim_income_spline.csv",
  skip = 112) %>% 
   dplyr::select(year, region, loggdppc)%>%
   dplyr::filter(year == 2099)

ratio = merge(df_country%>%dplyr::rename(loggdppc_country = loggdppc), 
  df_IR%>%dplyr::rename(loggdppc_IR = loggdppc), 
  by = c("year", "region")) %>% 
  dplyr::mutate(income_ratio =loggdppc_country / loggdppc_IR)


p = plot_map(plot_title = "country_level_income", plot_var = "loggdppc", 
  data = df_country, output = output)
q = plot_map(plot_title = "IR_level_income", plot_var = "loggdppc", 
  data = df_IR, output = output)
pq = plot_map(plot_title = "income_ratio", plot_var = "income_ratio", 
  data = ratio, output = output)


