# Purpose: Plot get the kernel density plots for Figure 3A

rm(list = ls())
library(logr)
LOG <- Sys.getenv(c("LOG"))
log_open(file.path(LOG, "3_post_projection/1_visualise_impacts/plot_kernel_density_functions.log"), logdir = FALSE)

  # Load in the required packages, using the pacman package
if(!require("pacman")){install.packages(("pacman"))}

pacman::p_load(ggplot2, # plotting functions
               dplyr,   # data manipulation functions
               tidyr,   # spread()
               readr)   # read_csv()


REPO <- Sys.getenv(c("REPO"))
DATA <- Sys.getenv(c("DATA"))
OUTPUT <- Sys.getenv(c("OUTPUT"))
root =  paste0(REPO, "/energy-code-release-2020")

dir.create(file.path(OUTPUT, "figures/fig_3"), showWarnings = FALSE)
# Source the Kernel Density plotting code
source(paste0(root, "/3_post_projection/0_utils/kernel_densities.R"))


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



# 2. Function for generating and plotting the kernely density functions for each IR in the paper
gen_plot_save_kd <- 
          function(IR, title, iterations, 
                    seed, output, xmin, xmax, ymax, DATA, OUTPUT){
  
  # Load in variance and mean impacts information
  df_joined <- read_csv(
                    paste0(OUTPUT, "/projection_system_outputs/IR_GCM_level_impacts/",
                           "gcm_damages-main_model-total_energy-SSP3-rcp85-",
                           "high-fulladapt-price014-2099-select_IRs.csv")) %>%
    dplyr::filter(region == !!IR)
  
  # Load in the gcm weights
  gcm.weights = read_csv(paste0(DATA, "/miscellaneous/gcm_weights.csv")) %>%
    dplyr::select(gcm, norm_weight_rcp85) %>%
    dplyr::rename(norm_weight = norm_weight_rcp85)
  
  # Take draws
  df_mc <- take_draws(seed = seed, iterations = iterations, year = 2099,
              mean_sd_df=df_joined, gcm_weight_df=gcm.weights) %>% 
    as.data.frame()
  
  message('Converting the damage draws into percent of GDP')
  df_gdp = read_csv(paste0(OUTPUT,"/projection_system_outputs/covariates/",
                           "/SSP3-high-IR_level-gdppc_pop-2099.csv"))
  val = df_gdp$gdp99[df_gdp$region == IR] %>% as.numeric()
  # Convert to dollars, since that 
  # was the units of the impacts was  billions of dollars
  val = val / 1000000000
  df_mc$value = df_mc$value / val / 0.0036

  print(paste0("plotting for ", IR))

  kd_plot <- ggkd(df.kd = df_mc,
                  yr = 2099, ir.name = paste0(title, " total_energy-rcp85-high"), 
                  x.label = NULL, y.label = "Density", 
                  kd.color = "grey") 
  
  # Add limits, so we can nicely compare across plots
  if(!is.null(xmin)){
    kd_plot = kd_plot + xlim(xmin, xmax) 
  } 
  if(!is.null(ymax)){
    kd_plot = kd_plot + ylim(0, ymax)
  } 
  ggsave(paste0(OUTPUT, "/figures/fig_3/fig_3A_kd_plot_",IR, ".pdf"), kd_plot)
  return(kd_plot)
}



# 3. Loop over the IR names that we want to plot for... 
IR_list = c("USA.14.608", "SWE.15", "CHN.2.18.78", "CHN.6.46.280", "IND.21.317.1249", "BRA.25.5235.9888")
IR_list_names = c("Chicago", "Stockholm", "Beijing", "Guangzhou", "Mumbai", "Sao Paulo")

args = list(iterations = 1000, seed = 123, xmax =0.03, xmin = -0.03, ymax = 800,
            DATA = DATA, OUTPUT = OUTPUT)

mapply(gen_plot_save_kd, IR = IR_list, title =IR_list_names, MoreArgs = args)

