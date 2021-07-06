rm(list = ls()) 

library(dplyr)
library(ggplot2)
library(scales)
library(colortools)
library(viridis)
library(glue)
library(stringr)


DB = "/mnt"
coefs_dir = paste0(DB, "/CIL_energy/code_release_data_pixel_interaction/damage_function_estimation/coefficients")


output_path = "/home/liruixue/repos/energy-code-release-2020/figures/referee_comments/"
path = paste0(DB,
                "/CIL_energy/code_release_data_pixel_interaction", 
                "/referee_comments/crayola/")

#**********************************************************************************
for (subset in c(2010, 2050, 2085)) {
  df <- read.csv(paste0(path, 'crayola_level_v3_percent_gdp_',subset,'.csv'))


  cols <- c("nonpar" = "blue", "truth" = "black")

  ####### Set one -> compare to binreg

  df_data <- df %>% filter(model == "")
  df2 <- df %>% filter( model != "")


  # All on one plot. 
  g1 <- ggplot() +
    geom_point(data = df_data , aes(x = year , y = yh)) +
    geom_line(data = df2, aes(x = year, y = yhat, color = model), alpha = 1) +
    geom_hline(yintercept=0, color = "black") +
    facet_wrap(. ~ avrg, scales = "free") +
    ylab("Damage Function Levels") +
    xlab("Time") +
    scale_x_continuous(breaks = seq(subset,2105,10), limits = c(subset, 2106)) +
    theme_bw() + theme(plot.title=element_text(size=20),
                       axis.title.y=element_text(size = 16, vjust=+0.2),
                       axis.title.x=element_text(size = 16, vjust=-0.2),
                       axis.text.y=element_text(size = 14),
                       axis.text.x=element_text(size = 14),
                       panel.grid.major = element_blank(),
                       panel.grid.minor = element_blank(),
                       legend.position = "bottom" )

  ggsave(g1, filename = glue("{output_path}/crayola_plot_percent_gdp_{subset}.pdf", width = 8, height = 8))



  # Separate plots for each bin... 

  plot_crayola = function(df, avrg_val, output){
    
    d = df %>% dplyr::filter(avrg == avrg_val)
    
    # Get a string for the filename - which can't have a . in it on my PC
    avrg_val_string = gsub("\\.", "_", avrg_val)
    
    p = ggplot(d) +
      geom_point(data = d %>% filter(model == ""), aes(x = year, y = yh), group = 1) +
      geom_line(data = d %>% filter(model != ""), aes(x = year, y = yhat, color = model)) +
      ylab("Damage Function Levels") +
      xlab("Time")  +
      scale_x_continuous(breaks = seq(subset,2105,10), limits = c(subset, 2106)) +
      theme_bw() + theme(plot.title=element_text(size=20),
                         axis.title.y=element_text(size = 16, vjust=+0.2),
                         axis.title.x=element_text(size = 16, vjust=-0.2),
                         axis.text.y=element_text(size = 14),
                         axis.text.x=element_text(size = 14),
                         panel.grid.major = element_blank(),
                         panel.grid.minor = element_blank(),
                         legend.position = "bottom" ) +
      ggtitle(glue("GMST anomaly bin: {avrg_val}C"))
    ggsave(p, filename = glue("{output}/bin_specific_plots/{subset}/bin_{avrg_val_string}.png"), width = 8, height = 8)
  }

  # plot_crayola(df = df, avrg_val = 3.75, output = path )  
  gmst_list = unique(df$avrg)
  lapply(gmst_list, FUN = plot_crayola, 
         df = df, output = output_path)
    
}
  
