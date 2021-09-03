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

#############################################
# 1. Load in a world shapefile, containing Impact Region boundaries, and convert to a 
#     dataframe for plotting

mymap = load.map(shploc = paste0(DB_data, "/shapefiles/world-combo-new-nytimes"))


#############################################
# 3. Figure 3 A

plot_3A = function(DB_data, map, ssp, iam, rcp, fuel){
  
  # Load in the projected impacts data, which is in billions of 2019 dollars
  # Calculate each IRs damage as a proportion of it's SSP3 projected 2099 GDP
  df_damages = read_csv(
    paste0(DB_data, '/projection_system_outputs/mapping_data/', 
            glue('main_model-{fuel}-{ssp}-{rcp}-{iam}-fulladapt-integration-2099-map.csv'))) 
  
  # Load in GDP data
  covariates = read_csv(
    paste0(DB_data, '/projection_system_outputs/covariates/', 
           glue('{ssp}-{iam}-IR_level-gdppc_pop-2099.csv'))) 

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
                    map.title = glue("Per-GDP-integration-{ssp}-{rcp}-{iam}"))
  p = p + theme(
    panel.background = element_rect(fill = "transparent"), # bg of the panel
    plot.background = element_rect(fill = "transparent", color = NA), # bg of the plot
    panel.grid.major = element_blank(), # get rid of major grid
    panel.grid.minor = element_blank(), # get rid of minor grid
    legend.background = element_rect(fill = "transparent"), # get rid of legend bg
    legend.box.background = element_rect(fill = "transparent") # get rid of legend panel bg
  )
  ggsave(paste0(output, glue("/tool_scenario_sanity_checks/fig_3A_2099_{fuel}_{ssp}_{iam}_{rcp}_damages_proportion_gdp_map_integration.png")), p,  bg = "transparent")
}



for (ssp in c("SSP2", "SSP3", "SSP4")) {
  for (fuel in c("electricity", "other_energy", "total_energy")) {
    for (iam in c("low", "high")) {
      for (rcp in c("rcp85","rcp45")) {
 
        plot_3A(DB_data= DB_data, map = mymap,
         ssp=ssp, iam=iam, rcp=rcp, fuel=fuel )

      }
    }
  }
}








