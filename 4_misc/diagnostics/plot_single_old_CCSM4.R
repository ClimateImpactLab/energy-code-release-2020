# plot 
# Produces maps displayed in the energy paper. Uses Functions in mapping.R

rm(list = ls())


library(ggplot2)
library(sp)
library(glue)
source("/home/liruixue/projection_repos/post-projection-tools/mapping/imgcat.R") #this redefines the way ggplot plots. 

# Load in the required packages, installing them if necessary 
if(!require("pacman")){install.packages(("pacman"))}
pacman::p_load(ggplot2, 
               dplyr,
               readr)

data = '/shares/gcp/social/parameters/energy_pixel_interaction/extraction/'

root =  "/home/liruixue/repos/energy-code-release-2020"
output = "/mnt/CIL_energy/code_release_data_pixel_interaction/projection_system_outputs/plot_single/"

source(paste0(root, "/3_post_projection/0_utils/mapping.R"))
source(paste0(root, "/3_post_projection/0_utils/time_series.R"))

#############################################
# 1. Load in a world shapefile, containing Impact Region boundaries, and convert to a 
#     dataframe for plotting

mymap = load.map(shploc = "/mnt/CIL_energy/code_release_data_pixel_interaction/shapefiles/world-combo-new-nytimes")


#############################################
# 2. Figure 2 A (map)

plot_2A = function(fuel, bound, data, map=mymap, USA_border = my_USA_border, IND_border = my_IND_border ) {

  # Load in the impacts-pc data, and convert it to GJ
  df= read_csv(glue(
   "{data}/single-OTHERIND_{fuel}_FD_FGLS_719_Exclude_all-issues_break2_semi-parametric_TINV_clim_GMFD/single_energy_rcp85_ccsm4_high_SSP3_OTHERIND_{fuel}_FD_FGLS.csv")) 
  df = df%>%dplyr::filter(year == 2099)%>%dplyr::mutate(value = value * 0.0036)
  # Set scaling factor for map color bar
  scale_v = c(-1, -0.2, -0.05, -0.005, 0, 0.005, 0.05, 0.2, 1)
  rescale_value <- scale_v*bound
  
  p = join.plot.map(map.df = mymap, 
                     df = df, 
                     df.key = "region", 
                     plot.var = "value", 
                     topcode = T, 
                     topcode.ub = max(rescale_value),
                     breaks_labels_val = seq(-bound, bound, bound/3),
                     color.scheme = "div", 
                     rescale_val = rescale_value,
                     colorbar.title = paste0(fuel, " imapacts, GJ PC, 2099"), 
                     map.title = paste0(fuel, 
                                    "_TINV_clim_SSP3-rcp85_impactpc_high_fulladapt_2099"))

  ggsave(paste0(output, "/fig_2A_", fuel, "_impacts_map_old.pdf"), p)

 
  p = join.plot.map(map.df = mymap, 
                     df = df, 
                     df.key = "region", 
                     plot.var = "value", 
                     topcode = F, 
                     breaks_labels_val = seq(-bound, bound, bound/3),
                     color.scheme = "div", 
                     rescale_val = rescale_value,
                     colorbar.title = paste0(fuel, " imapacts, GJ PC, 2099"), 
                     map.title = paste0(fuel, 
                                    "_TINV_clim_SSP3-rcp85_impactpc_high_fulladapt_2099"))

  ggsave(paste0(output, "/fig_2A_", fuel, "_impacts_map_old_not_topcoded.pdf"), p)



}

plot_2A(fuel = "electricity", bound = 3, data = data)
plot_2A(fuel = "other_energy", bound = 18, data = data)






#########################################
# 1. Figure 2C
# There are three functions needed for replicating this figure
    # "get.boxplot.vect" takes in a dataframe, and returns a vector of quantiles
    # "get_df_list_fig_2C" loads in the impacts projected data, and returns a formatted list of 
        # lines for plotting
    # "plot_ts_fig_2C" uses the above two functions, and the "time_series.R" code to 
        # replicate figure 2C


# Function that takes in the long data, subsets it and returns a list of dataframes 
# and vectors needed to plot the time series for a given fuel

get_df_list_fig_2C = function(data, fuel){
  
  # Load in the impacts data: 
  df= read_csv(glue(
  "{data}/single-OTHERIND_{fuel}_FD_FGLS_719_Exclude_all-issues_break2_semi-parametric_TINV_clim_GMFD/single-aggregated_energy_rcp85_ccsm4_high_SSP3_OTHERIND_{fuel}_FD_FGLS.csv")) 
  df = df %>% filter(is.na(region)) %>% dplyr::select(c("year","value")) %>% dplyr::mutate(value = value * 0.0036)
  # browser()
  return(df)
}

# Plotting function, for replicating Figure 2C. Note - coloring in the paper requires 

# post processing in illustrator 
plot_ts_fig_2C = function(fuel, output, data){
  
  plot_df = get_df_list_fig_2C(data = data,fuel = fuel)
  
  p <- ggtimeseries(
    df.list = list(plot_df %>% as.data.frame()),
    x.limits = c(2010, 2099),
    y.label = 'Hot and cold impacts: change in GJ/pc',
    rcp.value = 'rcp85', ssp.value = 'SSP3', iam.value = 'high')+ 
  ggtitle(paste0(fuel, "-high", "-rcp85","-SSP3"))   
  # browser()
  ggsave(paste0(output, "/fig_2C_", fuel, "_time_series_old.pdf"), p)
  return(p)
}

p = plot_ts_fig_2C(data = data, fuel = "other_energy", output = output)
q = plot_ts_fig_2C(data = data, fuel = "electricity", output = output)





