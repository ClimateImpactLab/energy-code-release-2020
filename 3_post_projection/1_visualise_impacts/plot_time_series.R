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
library(logr)
LOG <- Sys.getenv(c("LOG"))
log_open(file.path(LOG, "3_post_projection/1_visualise_impacts/plot_time_series.R"), logdir = FALSE)


# Load in the required packages, installing them if necessary 
if(!require("pacman")){install.packages(("pacman"))}
pacman::p_load(ggplot2, 
               dplyr,
               readr, 
               DescTools,
               RColorBrewer)


# Set paths

REPO <- Sys.getenv(c("REPO"))
DATA <- Sys.getenv(c("DATA"))
OUTPUT <- Sys.getenv(c("OUTPUT"))
root =  paste0(REPO, "/energy-code-release-2020")

# Source time series plotting codes
# source(paste0("/home/liruixue/repos/post-projection-tools/", "/timeseries/ggtimeseries.R"))
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
get_df_list_fig_2C = function(OUTPUT, fuel){
  
  # Load in the impacts data: 
  load_df = function(rcp, adapt, fuel){
    print(rcp)
    df = read_csv(paste0(OUTPUT,   
                   '/projection_system_OUTPUTs/time_series_data/', 
                   'main_model-', fuel, '-SSP3-',rcp, '-high-',adapt,'-impact_pc.csv')
                         ) 
    return(df)
  }
  options = expand.grid(rcp = c("rcp45", "rcp85"), 
                        adapt = c("fulladapt", "noadapt"))
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

plot_ts_fig_2C = function(fuel, OUTPUT){
  
  plot_df = get_df_list_fig_2C(OUTPUT = OUTPUT,fuel = fuel)
  
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
  
  ggsave(paste0(OUTPUT, "/figures/fig_2C_", fuel, "_time_series.pdf"), p)
  return(p)
}

p = plot_ts_fig_2C(OUTPUT = OUTPUT, fuel = "other_energy")
q = plot_ts_fig_2C(OUTPUT = OUTPUT, fuel = "electricity")


#########################################
# 2. Figure 3B

plot_ts_fig_3B = function(OUTPUT){
  
  # Load in the impacts data
  df_impacts = read_csv(paste0(OUTPUT, '/projection_system_OUTPUTs/time_series_data/', 
                        'main_model-total_energy-SSP3-rcp45-high-fulladapt-price014.csv'))%>% 
    mutate(rcp = "rcp45") %>% 
    bind_rows(
      read_csv(paste0(OUTPUT, '/projection_system_OUTPUTs/time_series_data/', 
                      'main_model-total_energy-SSP3-rcp85-high-fulladapt-price014.csv')) %>% 
        mutate(rcp = "rcp85")
    )
  
  # Load in gdp global projected SSP3 time series
  df_gdp = read_csv(paste0(OUTPUT, '/projection_system_OUTPUTs/covariates/', 
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

  ggsave(p, file = paste0(OUTPUT, 
          "/figures/fig_3/fig_3b_global_damage_time_series_percent_gdp_SSP3-high.pdf"), width = 8, height = 6)
  
  return(p)  
}
r = plot_ts_fig_3B(OUTPUT =OUTPUT)


#########################################
# 3. Figure Appendix D.1 - Time series by price scenario

df_gdp = read_csv(paste0(OUTPUT, '/projection_system_OUTPUTs/covariates/', 
                         "/SSP3-global-gdp-time_series.csv"))


# Helper function for loading time series data, and converting to 
# percent of gdp

load_timeseries = function(rcp, price, df_gdp){
  
  df = read_csv(paste0(OUTPUT, '/projection_system_OUTPUTs/time_series_data/',
                'main_model-total_energy-SSP3-',rcp,'-high-fulladapt-',price,'.csv'))  %>% 
    left_join(df_gdp, by="year") %>% 
    mutate(mean = mean * 1000000000)%>% 
    mutate(percent_gdp = (mean/gdp) *100 / 0.0036) %>%
    dplyr::select(year, percent_gdp) %>% 
    as.data.frame()
  
  return(df)
}

plot_prices = function(rcp, pricelist, OUTPUT) {
  
  df = mapply(load_timeseries, price=pricelist, 
              MoreArgs = list(rcp = rcp, df_gdp = df_gdp),
              SIMPLIFY = FALSE)
  
  colourCount = length(pricelist)
  print('plotting')
  
  p <- ggtimeseries(df.list = df, 
                    df.x = "year",
                    x.limits = c(2010, 2100),                               
                    # y.limits=c(-0.8,0.2),
                    y.label = "Total Damages, % GDP", 
                    legend.title = "Price scenario", 
                    legend.breaks = pricelist, 
                    legend.values = brewer.pal(colourCount, "Spectral"),
                    rcp.value = rcp, ssp.value = "SSP3", iam.value = "high") 
  
  ggsave(p, file = paste0(OUTPUT, 
                          "/figures/fig_Extended_Data_fig_5_global_total_energy_timeseries_all-prices-", 
                          rcp, ".pdf"), width = 8, height = 6)
}

pricelist = c("price0", "price014", "price03", "WITCHGLOBIOM42", 
              "MERGEETL60", "REMINDMAgPIE1730", "REMIND17CEMICS", "REMIND17") 

plot_prices(pricelist = pricelist, rcp = "rcp45",  OUTPUT = OUTPUT)
plot_prices(pricelist = pricelist, rcp = "rcp85",  OUTPUT = OUTPUT)


#########################################
# 4. Figure Appendix I.1 - Comparison to slow adaptation scenario single run

get_plot_df_by_fuel = function(fuel, OUTPUT) {
  
  df_SA = read_csv(paste0(OUTPUT, "/projection_system_OUTPUTs/time_series_data/CCSM4_single/",
              "SA_single-", fuel, "-SSP3-high-fulladapt-impact_pc.csv"))
  
  df_main = read_csv(paste0(OUTPUT, "/projection_system_OUTPUTs/time_series_data/CCSM4_single/", 
              "main_model_single-", fuel, "-SSP3-high-fulladapt-impact_pc.csv"))

  df <- rbind(df_SA, df_main) %>%
    mutate(legend = paste0(type,"_", rcp))
  
  return(df)

}

plot_and_save_appendix_I1 = function(fuel, OUTPUT){
  
  df = get_plot_df_by_fuel(fuel = fuel, OUTPUT = OUTPUT)
  p = ggplot() +
    geom_line(data = df, aes(x = year, y = mean, color = rcp, linetype = type)) +
    scale_colour_manual(values=c("blue", "red", "steelblue", "tomato1")) +
    scale_linetype_manual(values=c("dashed", "solid"))+
    scale_x_continuous(breaks=seq(2010, 2100, 10))  +
    geom_hline(yintercept=0, size=.2) +
    scale_alpha_manual(name="", values=c(.7)) +
    theme_bw() +
    theme(panel.grid.major = element_blank(), 
          panel.grid.minor = element_blank(),
          panel.background = element_blank(), 
          axis.line = element_line(colour = "black")) +
    ggtitle(paste0(fuel, "-SSP3-CCSM4-High")) +
    ylab("Impacts (GJ PC)") + xlab("")
  
  ggsave(p, file = paste0(OUTPUT, 
                          "/figures/fig_Appendix-G1_Slow_adapt-global_", fuel, "_timeseries_impact-pc_CCSM4-SSP3-high.pdf"), 
                          width = 8, height = 6)
  return(p)
}

plot_and_save_appendix_I1(fuel = "electricity", OUTPUT = OUTPUT)
plot_and_save_appendix_I1(fuel = "other_energy", OUTPUT = OUTPUT)

########################################
# 4. Figure Appendix I.3 - modelling tech trends 


plot_ts_appendix_I3 = function(fuel, OUTPUT){
  
  
  spec = paste0("OTHERIND_", fuel)
  
  # Load in data for each scenario
  df_lininter = read_csv(paste0(
    OUTPUT, '/projection_system_OUTPUTs/time_series_data/',
    'lininter_model-', fuel,'-SSP3-rcp85-high-fulladapt-impact_pc.csv')) %>% 
    mutate(type = "lininter")
  
  df_main = read_csv(paste0(
      OUTPUT, '/projection_system_OUTPUTs/time_series_data/',
      'main_model-', fuel,'-SSP3-rcp85-high-fulladapt-impact_pc.csv'))%>% 
    dplyr::filter(rcp =="rcp85" )%>% 
    dplyr::filter(adapt_scen =="fulladapt" )%>% 
    dplyr::filter(spec ==!!spec )%>%
    dplyr::select(year, mean) %>%  
    mutate(type = "main model")
  
  p = ggtimeseries(df.list = list(as.data.frame(df_lininter), as.data.frame(df_main)), 
                   y.label = "Impacts per capita, Gigajoules", 
                   legend.title = "Scenario", legend.breaks = c("Full adapt Tech Trends",
                                                                "Full adapt Main Model"), 
                   rcp.value = paste0(spec, '-rcp85'), ssp.value = "SSP3", iam.value = "high", 
                   x.limits =c(2010, 2100),
                   y.limits=c(-4,8)) + scale_y_continuous(breaks=seq(-3,7,3))

  ggsave(p, file = paste0(OUTPUT, 
                          "/figures/fig_Appendix-G3_lininter-global_", fuel, "_timeseries_impact-pc_SSP3-high-rcp85.pdf"), 
         width = 8, height = 6)
}


plot_ts_appendix_I3(fuel = "electricity", OUTPUT = OUTPUT)
plot_ts_appendix_I3(fuel = "other_energy", OUTPUT = OUTPUT)



