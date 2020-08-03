# Produces maps displayed in the energy paper. Uses Functions in mapping.R

rm(list = ls())

source("/home/liruixue/projection_repos/post-projection-tools/mapping/imgcat.R") #this redefines the way ggplot plots. 

# Load in the required packages, installing them if necessary 
if(!require("pacman")){install.packages(("pacman"))}
pacman::p_load(ggplot2, 
               dplyr,
               readr)

DB = "/mnt/CIL_energy"

DB_data = paste0(DB, "/pixel_interaction")
root =  "/home/liruixue/repos/energy-code-release-2020"
output = paste0(root, "/figures")

source(paste0(root, "/3_post_projection/0_utils/mapping.R"))

#############################################
# 1. Load in a world shapefile, containing Impact Region boundaries, and convert to a 
#     dataframe for plotting

mymap = load.map(shploc = paste0(DB_data, "/shapefiles/world-combo-new-nytimes"))


#############################################
# 2. Figure 2 A

plot_2A = function(fuel, bound, DB_data, map=mymap) {

  # Load in the impacts-pc data, and convert it to GJ
  df= read_csv(
    paste0(DB_data, '/projection_system_outputs/mapping_data/', 
           'main_model-', fuel, '-SSP3-rcp85-high-fulladapt-impact_pc-2099-map.csv')) 
  df = df %>% dplyr::mutate(mean = 1 / 0.0036 * mean)
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
  ggsave(paste0(output, "/fig_2A_", fuel, "_impacts_map.pdf"), p)
}
plot_2A(fuel = "electricity", bound = 3, DB_data = DB_data)
plot_2A(fuel = "other_energy", bound = 18, DB_data = DB_data)


#############################################
# 3. Figure 3 A

plot_3A = function(DB_data, map){
  
  # Load in the projected impacts data, which is in billions of 2019 dollars
  # Calculate each IRs damage as a proportion of it's SSP3 projected 2099 GDP
  df_damages = read_csv(
    paste0(DB_data, '/projection_system_outputs/mapping_data/', 
            'main_model-total_energy-SSP3-rcp85-high-fulladapt-price014-2099-map.csv')) 
  
  # Load in GDP data
  covariates = read_csv(
    paste0(DB_data, '/projection_system_outputs/covariates/', 
           'SSP3_IR_level_gdppc_pop_2099.csv')) 

  # Join data, and calculate damages as percent of GDP for each region
  df = left_join(df_damages, covariates, by = "region")%>%
    mutate(damage_per_gdp99 = damage * 1000000000 / gdp99)

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
  
  ggsave(paste0(output, "/fig_3/fig_3A_2099_damages_proportion_gdp_map.png"), p)
}
plot_3A(DB_data= DB_data, map = mymap)
































