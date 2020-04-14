# Produces maps displayed in the energy paper. Uses Functions in mapping.R

rm(list = ls())

# Load in the required packages, installing them if necessary 
if(!require("pacman")){install.packages(("pacman"))}
pacman::p_load(ggplot2, 
               dplyr,
               readr, 
               DescTools)


# Set paths
DB = "C:/Users/TomBearpark/Dropbox"

DB_data = paste0(DB, "/GCP_Reanalysis/ENERGY/code_release_data")
root =  "C:/Users/TomBearpark/Documents/energy-code-release"
output = paste0(root, "/figures")

# Source time series plotting codes
source(paste0(root, "/3_post_projection/0_utils/time_series.R"))

# Load in the impacts data: 
df = read_csv(paste0(DB_data, "/time_series_main_model_impacts_PC.csv"))

# convert to GJ
scale = function(x) (x* 0.0036)
names = c("mean", "q50", "q5", "q95", "q10", "q90", "q75","q25")
df= df %>%
  mutate_at(names, scale)


# Function for getting quantiles of the data, for use in the box plots.
get.boxplot.vect <- function(df = NULL, yr = 2099) {
  boxplot <- c(as.numeric(df[df$year==yr,'q5']), 
               as.numeric(df[df$year==yr,'q10']),
               as.numeric(df[df$year==yr,'q25']),
               as.numeric(df[df$year==yr,'mean']),
               as.numeric(df[df$year==yr,'q75']),
               as.numeric(df[df$year==yr,'q90']),
               as.numeric(df[df$year==yr,'q95']))
  return(boxplot)
}

# Function that takes in the long data, subsets it and returns a list of dataframes 
# and vectors needed to plot the time series for a given fuel
get_df_list = function(fuel, df){
  
  df = df %>%
    dplyr::filter(spec == !!fuel)
  
  bp_45 = df %>%
    filter(rcp == "rcp45", adapt_scen == "fulladapt") %>%
    get.boxplot.vect(yr = 2099)
  
  bp_85 = df %>%
    filter(rcp == "rcp85", adapt_scen == "fulladapt") %>%
    get.boxplot.vect(yr = 2099 )
  

  u_85 = df %>% 
    dplyr::filter(rcp == "rcp85", adapt_scen == "fulladapt") %>% 
    dplyr::select(year, q10, q90) %>%
    rename(q10_85 = q10, 
           q90_85 = q90)
  
  u_45 = df %>% 
    dplyr::filter(rcp == "rcp45", adapt_scen == "fulladapt") %>% 
    dplyr::select(year, q10, q90) %>%
    rename(q10_45 = q10, 
           q90_45 = q90)
  
  df.u = left_join(u_85, u_45, by = "year")
  
  return(
      list(
        df_45 = df[df$rcp == "rcp45" & df$adapt_scen == "fulladapt",], 
        df_85 = df[df$rcp == "rcp85" & df$adapt_scen == "fulladapt",], 
        df_45.na = df[df$rcp == "rcp45" & df$adapt_scen == "noadapt",], 
        df_85.na = df[df$rcp == "rcp85" & df$adapt_scen == "noadapt",], 
        df.u = df.u,
        bp_45 = bp_45, 
        bp_85 = bp_85
        )
    )
}

# Plotting function

plot_ts = function(df, fuel){
  
  plot_df = get_df_list(fuel = fuel, df = df)
  
  p <- ggtimeseries(
    df.list = list(plot_df$df_85[,c('year', 'mean')] %>% as.data.frame() , 
                   plot_df$df_85.na[,c('year', 'mean')]%>% as.data.frame(),
                   plot_df$df_45[,c('year', 'mean')]%>% as.data.frame(),
                   plot_df$df_45.na[,c('year', 'mean')]%>% as.data.frame()), # mean lines
    df.u = plot_df$df.u %>% as.data.frame(), #uncertainty - first layer
    ub = "q90_85", lb = "q10_85", #uncertainty - first layer
    ub.2 = "q90_45", lb.2 = "q10_45", #uncertainty - second layer
    uncertainty.color = "red", uncertainty.color.2 = "blue",
    df.box = plot_df$bp_85, 
    df.box.2 = plot_df$bp_45,
    x.limits = c(2010, 2099),
    y.label = 'Hot and cold impacts: change in GJ/pc',
    legend.values = c("red", "black", "blue", "orange"), #color of mean line
    legend.breaks = c("RCP85 Full Adapt", "RCP85 No Adapt", 
                      "RCP45 Full Adapt", "RCP45 No Adapt"),
    rcp.value = 'rcp85', ssp.value = 'SSP3', iam.value = 'high-fulluncertainty')+ 
  ggtitle(paste0(fuel, "-high", "-rcp85","-SSP3", "-fulluncertainty")) 
  
  ggsave(paste0(output, "/fig_2C_", fuel, "time_series.pdf"), p)
  return(p)
  }

p = plot_ts(df = df, fuel = "OTHERIND_other_energy")
q = plot_ts(df = df, fuel = "OTHERIND_electricity")











