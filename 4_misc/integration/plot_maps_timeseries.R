# Produces maps displayed in the energy paper. Uses Functions in mapping.R
rm(list = ls())

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


#############################################
# 3. Figure 3 A

plot_3A = function(DB_data, map){
  
  # Load in the projected impacts data, which is in billions of 2019 dollars
  # Calculate each IRs damage as a proportion of it's SSP3 projected 2099 GDP
  df_damages = read_csv(
    paste0(DB_data, '/projection_system_outputs/mapping_data/', 
            'main_model-total_energy-SSP3-rcp85-high-fulladapt-integration-2099-map.csv')) 
  
  # Load in GDP data
  covariates = read_csv(
    paste0(DB_data, '/projection_system_outputs/covariates/', 
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
                    map.title = "Per-GDP-integration-ssp3-rcp85-high")
  p = p + theme(
    panel.background = element_rect(fill = "transparent"), # bg of the panel
    plot.background = element_rect(fill = "transparent", color = NA), # bg of the plot
    panel.grid.major = element_blank(), # get rid of major grid
    panel.grid.minor = element_blank(), # get rid of minor grid
    legend.background = element_rect(fill = "transparent"), # get rid of legend bg
    legend.box.background = element_rect(fill = "transparent") # get rid of legend panel bg
  )
  ggsave(paste0(output, "/fig_3/fig_3A_2099_damages_proportion_gdp_map_integration.png"), p,  bg = "transparent")
}
plot_3A(DB_data= DB_data, map = mymap)


#########################################
# plot timeseries

rm(list = ls())
source("/home/liruixue/projection_repos/post-projection-tools/mapping/imgcat.R") #this redefines the way ggplot plots. 

# Load in the required packages, installing them if necessary 
if(!require("pacman")){install.packages(("pacman"))}
pacman::p_load(ggplot2, 
               dplyr,
               readr, 
               DescTools,
               RColorBrewer)


# Set paths
DB = "/mnt/CIL_energy"

DB_data = paste0(DB, "/code_release_data_pixel_interaction")
root =  "/home/liruixue/repos/energy-code-release-2020"
output = paste0(root, "/figures")

# Source time series plotting codes
source(paste0("/home/liruixue/repos/post-projection-tools/", "/timeseries/ggtimeseries.R"))


#########################################
# 2. Figure 3B

plot_ts_fig_3B = function(DB_data, output){
  
  # Load in the impacts data
  df_impacts = read_csv(paste0(DB_data, '/projection_system_outputs/time_series_data/', 
                        'main_model-total_energy-SSP3-rcp45-high-fulladapt-integration.csv'))%>% 
    mutate(rcp = "rcp45") %>% 
    bind_rows(
      read_csv(paste0(DB_data, '/projection_system_outputs/time_series_data/', 
                      'main_model-total_energy-SSP3-rcp85-high-fulladapt-integration.csv')) %>% 
        mutate(rcp = "rcp85")
    )
  
  # Load in gdp global projected SSP3 time series
  df_gdp = read_csv(paste0(DB_data, '/projection_system_outputs/covariates/', 
                           "/SSP3-global-gdp-time_series.csv"))
  # Get separate dataframes for rcp45 and rcp85, for plotting
  format_df = function(rcp, df_impacts, df_gdp){

    df = df_impacts %>% 
      dplyr::filter(rcp == !!rcp) %>% 
      left_join(df_gdp, by = "year")%>% 
      mutate(mean = mean * 1000000000, q95 = q95 *1000000000 , q5 = q5* 1000000000) %>% #convert from billions of dollars 
      mutate(percent_gdp = (mean/gdp) *100 / 0.0036, 
             ub = (q95/gdp) *100 / 0.0036, 
             lb = (q5/gdp) *100 / 0.0036)
    
    df_mean = df %>% 
      dplyr::select(year, percent_gdp)
    
    return(list(df, df_mean))
  }
  
  df_45 = format_df(rcp = 'rcp45', df_impacts= df_impacts, df_gdp = df_gdp)
  df_85 = format_df(rcp = 'rcp85', df_impacts= df_impacts, df_gdp = df_gdp)
  
  # Call the ggtimeseries function, and also add on extra ribbons
  p <- ggtimeseries(df.list = list(as.data.frame(df_45[2]), as.data.frame(df_85[2])), 
                    df.x = "year",
                    x.limits = c(2010, 2100),                               
                    y.limits=c(-0.8,0.2),
                    y.label = "% GDP", 
                    legend.title = "RCP", legend.breaks = c("RCP 4.5", "RCP 8.5"), 
                    legend.values = c('blue', 'red')) + 
    geom_ribbon(data = df_45[[1]], aes(x=df_45[[1]]$year, ymin=df_45[[1]]$ub, ymax=df_45[[1]]$lb), 
                fill = "blue", alpha=0.1, show.legend = FALSE) +
    geom_ribbon(data = df_85[[1]], aes(x=df_85[[1]]$year, ymin=df_85[[1]]$ub, ymax=df_85[[1]]$lb), 
                fill = "red",  alpha=0.1, show.legend = FALSE) + 
    ggtitle("Damages as a percent of global gdp, ssp3-high")

  ggsave(p, file = paste0(output, 
          "/fig_3/fig_3b_global_damage_time_series_percent_gdp_SSP3-high_integration.pdf"), width = 8, height = 6)
  
  return(p)  
}
r = plot_ts_fig_3B(DB_data =DB_data, output = output)



