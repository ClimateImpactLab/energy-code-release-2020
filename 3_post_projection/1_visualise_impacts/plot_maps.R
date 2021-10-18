# Produces maps displayed in the energy paper. Uses Functions in mapping.R
# done 26 aug 2020
rm(list = ls())
library(logr)
LOG <- Sys.getenv(c("LOG"))
log_open(file.path(LOG, "3_post_projection/1_visualise_impacts/plot_maps.R"), logdir = FALSE)


# Load in the required packages, installing them if necessary 
if(!require("pacman")){install.packages(("pacman"))}
pacman::p_load(ggplot2, 
               dplyr,
               readr)


REPO <- Sys.getenv(c("REPO"))
DATA <- Sys.getenv(c("DATA"))
OUTPUT <- Sys.getenv(c("OUTPUT"))
root =  paste0(REPO, "/energy-code-release-2020")

source(paste0(root, "/3_post_projection/0_utils/mapping.R"))

#############################################
# 1. Load in a world shapefile, containing Impact Region boundaries, and convert to a 
#     dataframe for plotting

mymap = load.map(shploc = paste0(DATA, "/shapefiles/world-combo-new-nytimes"))


#############################################
# 2. Figure 2 A

plot_2A = function(fuel, bound, OUTPUT, map=mymap) {

  # Load in the impacts-pc data
  df= read_csv(
    paste0(OUTPUT, '/projection_system_outputs/mapping_data/', 
           'main_model-', fuel, '-SSP3-rcp85-high-fulladapt-impact_pc-2099-map.csv')) 
  # Set scaling factor for map color bar
  scale_v = c(-1, -0.2, -0.05, -0.005, 0, 0.005, 0.05, 0.2, 1)
  rescale_value <- scale_v*bound
  
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
                                    "_TINV_clim_SSP3-rcp85_impactpc_high_fulladapt_2099"))
  p = p + theme(
    panel.background = element_rect(fill = "transparent"), # bg of the panel
    plot.background = element_rect(fill = "transparent", color = NA), # bg of the plot
    panel.grid.major = element_blank(), # get rid of major grid
    panel.grid.minor = element_blank(), # get rid of minor grid
    legend.background = element_rect(fill = "transparent"), # get rid of legend bg
    legend.box.background = element_rect(fill = "transparent") # get rid of legend panel bg
  )
  ggsave(paste0(OUTPUT, "/figures/fig_2A_", fuel, "_impacts_map.png"), p,  bg = "transparent")
}
plot_2A(fuel = "electricity", bound = 3, OUTPUT=OUTPUT)
plot_2A(fuel = "other_energy", bound = 18, OUTPUT=OUTPUT)


#############################################
# 3. Figure 3 A

plot_3A = function(OUTPUT, map){
  
  # Load in the projected impacts data, which is in billions of 2019 dollars
  # Calculate each IRs damage as a proportion of it's SSP3 projected 2099 GDP
  df_damages = read_csv(
    paste0(OUTPUT, '/projection_system_outputs/mapping_data/', 
            'main_model-total_energy-SSP3-rcp85-high-fulladapt-price014-2099-map.csv')) 
  
  # Load in GDP data
  covariates = read_csv(
    paste0(OUTPUT, '/projection_system_outputs/covariates/', 
           'SSP3-high-IR_level-gdppc_pop-2099.csv')) 

  # Join data, and calculate damages as percent of GDP for each region
  df = left_join(df_damages, covariates, by = "region")%>%
    mutate(damage_per_gdp99 = damage * 1000000000 / gdp99 / 0.0036)

  # Set plotting parameters, and save!
  bound= 0.03
  rescale_value <- c(-1, -0.2, -0.05, -0.005, 0, 0.005, 0.05, 0.2, 1) *bound
  
  p = join.plot.map(map.df = map, 
                    df = df, 
                    df.key = "region",
                    plot.var = "damage_per_gdp99", 
                    breaks_labels_val = seq(-bound, bound, bound/3),
                    topcode = T, 
                    topcode.ub = max(rescale_value), 
                    color.scheme = "div", 
                    rescale_val = rescale_value,
                    colorbar.title = "2099 Damages, Proportion of 2099 GDP", 
                    map.title = "Per-GDP-price014-ssp3-rcp85-high")
  p = p + theme(
    panel.background = element_rect(fill = "transparent"), # bg of the panel
    plot.background = element_rect(fill = "transparent", color = NA), # bg of the plot
    panel.grid.major = element_blank(), # get rid of major grid
    panel.grid.minor = element_blank(), # get rid of minor grid
    legend.background = element_rect(fill = "transparent"), # get rid of legend bg
    legend.box.background = element_rect(fill = "transparent") # get rid of legend panel bg
  )
  ggsave(paste0(OUTPUT, "/figures/fig_3/fig_3A_2099_damages_proportion_gdp_map.png"), p,  bg = "transparent")
}

plot_3A(OUTPUT=OUTPUT, map = mymap)



#############################################
# a comparison map between the pixel interaction version and the old version

plot_comparison = function(fuel, bound, OUTPUT, map=mymap){
  
  # Load in the impacts-pc data
  df_new = read_csv(
    paste0(OUTPUT, '/projection_system_outputs/mapping_data/', 
           'main_model-', fuel, '-SSP3-rcp85-high-fulladapt-impact_pc-2099-map.csv')) 
  
  # Load in the impacts-pc data, and convert it to GJ
  df_old = read_csv(
    paste0(OUTPUT, '/projection_system_outputs/mapping_data/', 
           'main_model-', fuel, '-SSP3-rcp85-high-fulladapt-impact_pc-2099-map.csv')) 

  df_diff = merge(df_new, df_old,  by = c("year", "region")) %>%
            dplyr::mutate(mean = mean.x - mean.y)

  # Set scaling factor for map color bar
  scale_v = c(-1, -0.2, -0.05, -0.005, 0, 0.005, 0.05, 0.2, 1)
  rescale_value <- scale_v*bound
  
  p = join.plot.map(map.df = map, 
                     df = df_diff, 
                     df.key = "region", 
                     plot.var = "mean", 
                     topcode = T, 
                     topcode.ub = max(rescale_value),
                     breaks_labels_val = seq(-bound, bound, bound/3),
                     color.scheme = "div", 
                     rescale_val = rescale_value,
                     colorbar.title = paste0(fuel, " imapacts, GJ PC, 2099"), 
                     map.title = paste0(fuel, 
                                    "_TINV_clim_SSP3-rcp85_impactpc_high_fulladapt_2099"))
  ggsave(paste0(OUTPUT, "/figures/fig_2A_", fuel, "_impacts_map_pixel-interaction-minus-old.pdf"), p)
}

plot_comparison(fuel = "electricity", bound = 3, OUTPUT=OUTPUT)
plot_comparison(fuel = "other_energy", bound = 3, OUTPUT=OUTPUT)



