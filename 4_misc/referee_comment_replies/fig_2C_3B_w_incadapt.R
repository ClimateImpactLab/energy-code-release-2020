# Produces maps displayed in the energy paper. Uses functions in "0_utils/time_series.R"
# Contents: 
# 0. Set up
# 1. Code for replicating figure 2C - per capita impacts by fuel
# 2. Code for replicating figure 3B - percent gdp impacts for total energy
# 3. Code for figure Appendix D.1 - time series by rcp and price scenario
# 4. Code for figure Appendix I.1 - Comparison to slow adaptation scenario single run
# 5. Code for figure Appendix I3 - Modelling tech trends 

# two singles not done
#########################################
# 0. Set up

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
output = paste0(root, "/figures/referee_comments/")

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
  load_df = function(rcp, adapt, fuel){
    print(rcp)
    df = read_csv(paste0(DB_data,   
                   '/projection_system_outputs/time_series_data/', 
                   'main_model-', fuel, '-SSP3-',rcp, '-high-',adapt,'-impact_pc.csv')
                         ) 
    return(df)
  }
  options = expand.grid(rcp = c("rcp45", "rcp85"), 
                        adapt = c("fulladapt", "incadapt"))
  df = mapply(load_df, rcp = options$rcp, adapt = options$adapt, 
              MoreArgs = list(fuel = fuel), SIMPLIFY = FALSE) %>% 
    bind_rows()

  # Subset and format for plotting

  bp_45 = df %>%
    dplyr::filter(rcp == "rcp45", adapt_scen == "fulladapt") %>%
    get.boxplot.vect(yr = 2099)
  
  bp_85 = df %>%
    dplyr::filter(rcp == "rcp85", adapt_scen == "fulladapt") %>%
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
        df_45.ia = df[df$rcp == "rcp45" & df$adapt_scen == "incadapt",], 
        df_85.ia = df[df$rcp == "rcp85" & df$adapt_scen == "incadapt",], 
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
                   plot_df$df_85.ia[,c('year', 'mean')]%>% as.data.frame(),
                   plot_df$df_45[,c('year', 'mean')]%>% as.data.frame(),
                   plot_df$df_45.ia[,c('year', 'mean')]%>% as.data.frame()), # mean lines
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
    legend.breaks = c("RCP85 Full Adapt", "RCP85 Inc Adapt", 
                      "RCP45 Full Adapt", "RCP45 Inc Adapt"),
    rcp.value = 'rcp85', ssp.value = 'SSP3', iam.value = 'high-fulluncertainty')+ 
  ggtitle(paste0(fuel, "-high", "-rcp85","-SSP3", "-fulluncertainty")) 
  
  ggsave(paste0(output, "/fig_2C_", fuel, "_time_series_incadapt.pdf"), p)
  return(p)
}

p = plot_ts_fig_2C(DB_data = DB_data, fuel = "other_energy", output = output)
q = plot_ts_fig_2C(DB_data = DB_data, fuel = "electricity", output = output)


#########################################
# 2. Figure 3B

plot_ts_fig_3B = function(DB_data, output){
  
  # Load in the impacts data
  df_impacts = read_csv(paste0(DB_data, '/projection_system_outputs/time_series_data/', 
                        'main_model-total_energy-SSP3-rcp85-high-incadapt-price014.csv'))%>% 
    mutate(rcp = "rcp85", adapt = "incadapt") %>% 
    bind_rows(
      read_csv(paste0(DB_data, '/projection_system_outputs/time_series_data/', 
                      'main_model-total_energy-SSP3-rcp85-high-fulladapt-price014.csv')) %>% 
        mutate(rcp = "rcp85", adapt = "fulladapt")
    )
  
  # Load in gdp global projected SSP3 time series
  df_gdp = read_csv(paste0(DB_data, '/projection_system_outputs/covariates/', 
                           "/SSP3-global-gdp-time_series.csv"))
  
  # Get separate dataframes for rcp45 and rcp85, for plotting
  format_df = function(adapt, df_impacts, df_gdp){

    df = df_impacts %>% 
      dplyr::filter(adapt == !!adapt) %>% 
      left_join(df_gdp, by = "year")%>% 
      mutate(mean = mean * 1000000000, q95 = q95 *1000000000 , q5 = q5* 1000000000) %>% #convert from billions of dollars 
      mutate(percent_gdp = (mean/gdp) *100 / 0.0036, 
             ub = (q95/gdp) *100 / 0.0036, 
             lb = (q5/gdp) *100 / 0.0036)
    
    df_mean = df %>% 
      dplyr::select(year, percent_gdp)
    
    return(list(df, df_mean))
  }
  
  df_inc = format_df(adapt = 'incadapt', df_impacts= df_impacts, df_gdp = df_gdp)
  df_full = format_df(adapt = 'fulladapt', df_impacts= df_impacts, df_gdp = df_gdp)
  
  # Call the ggtimeseries function, and also add on extra ribbons
  p <- ggtimeseries(df.list = list(as.data.frame(df_inc[2]), as.data.frame(df_full[2])), 
                    df.x = "year",
                    x.limits = c(2010, 2100),                               
                    y.limits=c(-0.8,0.2),
                    y.label = "% GDP", 
                    legend.title = "Adaptation Scenario", legend.breaks = c("Inc Adapt", "Full Adapt"), 
                    legend.values = c('blue', 'red')) + 
    geom_ribbon(data = df_inc[[1]], aes(x=df_inc[[1]]$year, ymin=df_inc[[1]]$ub, ymax=df_inc[[1]]$lb), 
                fill = "blue", alpha=0.1, show.legend = FALSE) +
    geom_ribbon(data = df_full[[1]], aes(x=df_full[[1]]$year, ymin=df_full[[1]]$ub, ymax=df_full[[1]]$lb), 
                fill = "red",  alpha=0.1, show.legend = FALSE) + 
    ggtitle("Damages as a percent of global gdp, ssp3-high-rcp85")

  ggsave(p, file = paste0(output, 
          "/fig_3b_global_damage_time_series_percent_gdp_SSP3-high-rcp85_incadapt.pdf"), width = 8, height = 6)
  
  return(p)  
}

r = plot_ts_fig_3B(DB_data =DB_data, output = output)






