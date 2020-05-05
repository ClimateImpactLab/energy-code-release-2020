# Purpose: Plot get the kernel density plots for Figure 3A
rm(list = ls())

  # Load in the required packages, using the pacman package
if(!require("pacman")){install.packages(("pacman"))}

pacman::p_load(ggplot2, # plotting functions
               dplyr,   # data manipulation functions
               tidyr,   # spread()
               readr)   # read_csv()

DB = "C:/Users/TomBearpark/Dropbox"
DB_data = paste0(DB, "/GCP_Reanalysis/ENERGY/code_release_data")
data = paste0(DB_data, "/outputs")

root =  "C:/Users/TomBearpark/Documents/energy-code-release"
output = paste0(root, "/figures")


# Source the KD plot code
source()


# 1. Functions for taking draws from a uniform distribution, with the number of draws
      # representing the weight a gcm has

take_draws <- function(seed, iterations, mean_sd_df, gcm_weight_df, year) {
  
  # Set seed for replicability 
  set.seed(seed)
  
  # 1. Take random draws from a uniform distribution
  p <- runif(iterations) %>% 
    as.data.frame() %>%
    rename(u = ".")
  
  # 2. Send this random variable to one of the gcms, by creating and then binning the cdf
  
  df_cdf <- gcm_weight_df %>%
    mutate(cdf = cumsum(norm_weight)) 
  p$gcm <- cut(p$u, breaks = c(0, df_cdf$cdf), labels=df_cdf$gcm)
  
  # 3. Join the draws with information about mean and variances
  p <- p %>%
    left_join(mean_sd_df, by="gcm")
  
  # 4. take draws from the relevant normal distributions
  p$value <- rnorm(iterations, mean = p$mean, sd = p$sd)
  print('taken the draws')
  # 5. Return a df in the form needed for Trin's plotting code
  p <- p %>% 
    dplyr::select(value) 
  p$year <- year
  p$weight <- 1
  
  return(p)
}


gen_plot_save_kd_energy <- 
          function(env, IR, ssp, rcp, 
                    product, price, iam, iterations, 
                    seed, output, year, title, unit, xmin, xmax, ymax, 
                    gdp_scale, df_gdp){
  
  fuel = product
  IR = "USA.14.608"
  iterations <- 1000
  seed = 123
  df_joined <- read_csv(
                    paste0(DB_data, 
                             "/select-IRs-gcm-level-price014-",
                             "total_energy_main_model_SSP3-",
                             "rcp85_damages_high_fulladapt_2099.csv")) %>%
    dplyr::filter(region == !!IR)
    
  gcm.weights = read_csv(paste0(DB_data, "/gcm_weights.csv")) %>%
    dplyr::select(gcm, norm_weight_rcp85) %>%
    dplyr::rename(norm_weight = norm_weight_rcp85)
  
  df_mc <- take_draws(seed = seed, iterations = iterations, year = 2099,
              mean_sd_df=df_joined, gcm_weight_df=gcm.weights) %>% 
    as.data.frame()
  
  if(!is.null(gdp_scale) ){
    df_gdp = read_csv(paste0(DB_data, )
    print('Converting the damage draws into percent of GDP')
    val = df_gdp$gdp[df_gdp$region == IR] %>% as.numeric()
    val = val / 1000000000 
    df_mc$value = df_mc$value / val
    tag = "percent_gdp-"
    print(paste0('max is ', max(df_mc$value), ' min is ', min(df_mc$value), ' mean is ', mean(df_mc$value)))
  }else{
    tag = NULL
  }
  
  print("done MC")
  print(paste0(fuel, "  ", IR))

  # kd_plot <-  plot_kd(df_mc=df_mc, year=year, fuel = fuel, title=title, iam=iam, rcp=rcp, xmax = xmax, xmin = xmin, ymax = ymax)
  kd_plot <- ggkd(df.kd = df_mc,
                  topcode.ub = NULL, topcode.lb = NULL, 
                  yr = year, ir.name = paste0(title, " ", fuel, "-", rcp, "-", iam), 
                  x.label = NULL, y.label = "Density", 
                  kd.color = "grey") 
  
  if(!is.null(xmin)){
    kd_plot = kd_plot + xlim(xmin, xmax) 
  } 
  if(!is.null(ymax)){
    kd_plot = kd_plot + ylim(0, ymax)
  } 

  # kd_plot
  print('saving')
  if(!is.null(xmin)) {
    ggsave(paste0(output, paste(tag, IR, ssp, rcp, unit, price, year, fuel, "xcomm", sep="_"), ".pdf"), kd_plot)
  }else{
    ggsave(paste0(output, paste(tag, IR, ssp, rcp, unit, price, year, fuel, sep="_"), ".pdf"), kd_plot)
  }
  print(val)
  return(kd_plot)
}

