# Produces maps displayed in the energy paper. Uses functions in "0_utils/time_series.R"
# Contents: 
# 0. Set up
# 1. Code for replicating figure 2C
# 2. Code for replicating figure 3B


#########################################
# 0. Set up

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


#########################################
# 1. Figure 2C
# There are three functions needed for replicating this figure
    # "get.boxplot.vect" takes in a dataframe, and returns a vector of quantiles
    # "get_df_list_fig_2C" loads in the impacts projected data, and returns a formatted list of 
        # lines for plotting
    # "plot_ts_fig_2C" uses the above two functions, and the "time_series.R" code to 
        # replicate figure 2C


# Function for formatting a vector of the distribution of the data for a given year, for use in the box plots.
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
get_df_list_fig_2C = function(DB_data, fuel){
  
  # Load in the impacts data: 
  df = read_csv(paste0(DB_data, "/time_series_main_model_impacts_PC.csv"))
  
  # convert to GJ
  scale = function(x) (x* 0.0036)
  names = c("mean", "q50", "q5", "q95", "q10", "q90", "q75","q25")
  df= df %>%
    mutate_at(names, scale)
  
  # Subset and format for plotting
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

# Plotting function, for replicating Figure 2C. Note - coloring in the paper requires 
# post processing in illustrator 
plot_ts_fig_2C = function(fuel, output, DB_data){
  
  plot_df = get_df_list_fig_2C(DB_data = DB_data,fuel = fuel)
  
  p <- ggtimeseries(
    df.list = list(plot_df$df_85[,c('year', 'mean')] %>% as.data.frame() , 
                   plot_df$df_85.na[,c('year', 'mean')]%>% as.data.frame(),
                   plot_df$df_45[,c('year', 'mean')]%>% as.data.frame(),
                   plot_df$df_45.na[,c('year', 'mean')]%>% as.data.frame()), # mean lines
    df.u = plot_df$df.u %>% as.data.frame(), 
    ub = "q90_85", lb = "q10_85", #uncertainty - first layer
    ub.2 = "q90_45", lb.2 = "q10_45", #uncertainty - second layer
    uncertainty.color = "red", 
    uncertainty.color.2 = "blue",
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

p = plot_ts_fig_2C(DB_data = DB_data, fuel = "OTHERIND_other_energy", output = output)
q = plot_ts_fig_2C(DB_data = DB_data, fuel = "OTHERIND_electricity", output = output)


#########################################
# 2. Figure 3B

plot_ts_fig_3B = function(DB_data, output){
  
  # Load in the impacts data
  df_impacts = read_csv(paste0(DB_data, 
                       "/damages-total_energy-price014-SSP3-high-fulladapt-timeseries.csv"))
  
  # Load in gdp global projected SSP3 time series
  df_gdp = read_csv(paste0(DB_data, "/global_gdp_time_series.csv"))
  
  # Get separate dataframes for rcp45 and rcp85, for plotting
  format_df = function(rcp, df_impacts, df_gdp){
    
    df = df_impacts %>% 
      dplyr::filter(rcp == !!rcp) %>% 
      left_join(df_gdp, by = "year") %>%
      mutate(percent_gdp = (mean/gdp) *100, 
             ub = (q95/gdp) *100, 
             lb = (q5/gdp) *100)
    df_mean = df %>% dplyr::select(year, percent_gdp)
    
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
          "/fig_3/fig_3b_global_damage_time_series_percent_gdp_SSP3-high.pdf"), width = 8, height = 6)
  
  return(p)  
}
r = plot_ts_fig_3B(DB_data =DB_data, output = output)

























