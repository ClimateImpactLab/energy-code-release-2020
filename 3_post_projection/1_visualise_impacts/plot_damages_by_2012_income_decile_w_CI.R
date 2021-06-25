# Impacts by income deciles bar chart
# 
rm(list = ls())
library(RColorBrewer)
# Load in the required packages, installing them if necessary 
if(!require("pacman")){install.packages(("pacman"))}
pacman::p_load(ggplot2, 
               dplyr,
               readr,
               glue,
               parallel)


source("~/repos/labor-code-release-2020/0_subroutines/paths.R")
source("~/repos/post-projection-tools/mapping/imgcat.R") #this redefines the way ggplot plots. 

# Load in the required packages, installing them if necessary 
if(!require("pacman")){install.packages(("pacman"))}
pacman::p_load(ggplot2, 
               dplyr,
               readr)


DB_data = '/shares/gcp/estimation/labor/code_release_int_data/projection_outputs/covariates/'

# Take deciles of 2012 income/ clim data distribution of IRs, by getting equal populations in each population

get_deciles = function(df){
  
  deciles = df %>% 
    filter(year == 2012)
  
  # Get cut-off population levels for each quantile
  total_pop = sum(deciles$pop)
  pop_per_quantile = total_pop / 10
  
  deciles <- deciles[order(deciles$gdppc),] 
  deciles$cum_pop = cumsum(deciles$pop)
  deciles$decile = 10
  
  # Loop over deciles, assigning them to the ordered IRs up to the point where population is equal in each decile
  for (quant in 1:10){
    deciles$decile[deciles$cum_pop < quant* pop_per_quantile & deciles$cum_pop >= (quant-1)* pop_per_quantile] <- quant
  }
  
  deciles = deciles %>%
    dplyr::select(region, decile)
  
  return(deciles)
}

# Load in pop and income data
df_covariates = read_csv(paste0(DB_data,  
                        '/SSP3-high-IR_level-gdppc-pop-2012.csv'))

# Find each Impact region's 2012 decile of income per capita. 
deciles = get_deciles(df_covariates)

#################################################
# plot damage in percentage GDP by income decile

# Load in impacts data
df_pct_gdp_impacts = read_csv(glue('{ROOT_INT_DATA}/projection_outputs/extracted_data_mc/SSP3-rcp85_high_allrisk_fulladapt-gdp-levels_2099_map.csv'))%>%
  left_join(deciles, by = "region")

# Join with 2099 population dataSSP3-high-IR_level-gdppc_pop-2099
df_gdp99= read_csv(paste0(DB_data, '/SSP3-high-IR_level-gdppc_pop-2099.csv')) %>% 
  dplyr::select(region, gdp99)

df_pct_gdp_impacts = df_pct_gdp_impacts %>% 
    left_join(df_gdp99, by = "region")%>% 
    mutate(pct_x_gdp_mean = -mean * gdp99,
      pct_x_gdp_q1 = -q1 * gdp99,
      pct_x_gdp_q5 = -q5 * gdp99,
      pct_x_gdp_q10 = -q10 * gdp99,
      pct_x_gdp_q25 = -q25 * gdp99,
      pct_x_gdp_q50 = -q50 * gdp99,
      pct_x_gdp_q75 = -q75 * gdp99,
      pct_x_gdp_q90 = -q90 * gdp99,
      pct_x_gdp_q95 = -q95 * gdp99,
      pct_x_gdp_q99 = -q99 * gdp99
      ) %>%
    dplyr::select(pct_x_gdp_mean,
      pct_x_gdp_q1,
      pct_x_gdp_q5,
      pct_x_gdp_q10,
      pct_x_gdp_q25,
      pct_x_gdp_q50,
      pct_x_gdp_q75,
      pct_x_gdp_q90,
      pct_x_gdp_q95,
      pct_x_gdp_q99,
      region, year, gdp99, decile
      )
      
# Collapse to decile level
df_plot = df_pct_gdp_impacts %>% 
  group_by(decile) %>% 
  summarize(total_pct_x_gdp_2099_mean = sum(pct_x_gdp_mean, na.rm = TRUE), 
    total_pct_x_gdp_2099_q25 = sum(pct_x_gdp_q25, na.rm = TRUE), 
    total_pct_x_gdp_2099_q75 = sum(pct_x_gdp_q75, na.rm = TRUE), 
    total_pct_x_gdp_2099_q5 = sum(pct_x_gdp_q5, na.rm = TRUE), 
    total_pct_x_gdp_2099_q95 = sum(pct_x_gdp_q95, na.rm = TRUE), 
    total_pct_x_gdp_2099_q1 = sum(pct_x_gdp_q1, na.rm = TRUE), 
    total_pct_x_gdp_2099_q99 = sum(pct_x_gdp_q99, na.rm = TRUE), 
    total_pct_x_gdp_2099_q10 = sum(pct_x_gdp_q10, na.rm = TRUE), 
    total_pct_x_gdp_2099_q90 = sum(pct_x_gdp_q90, na.rm = TRUE), 
    total_pct_x_gdp_2099_q50 = sum(pct_x_gdp_q50, na.rm = TRUE), 
            total_gdp_2099 = sum(gdp99, na.rm = TRUE))%>%
  mutate(pct_gdp_mean = total_pct_x_gdp_2099_mean / total_gdp_2099 * 100,
  pct_gdp_q25 = total_pct_x_gdp_2099_q25 / total_gdp_2099 * 100,
  pct_gdp_q75 = total_pct_x_gdp_2099_q75 / total_gdp_2099 * 100,
  pct_gdp_q5 = total_pct_x_gdp_2099_q5 / total_gdp_2099 * 100,
  pct_gdp_q95 = total_pct_x_gdp_2099_q95 / total_gdp_2099 * 100,
  pct_gdp_q10 = total_pct_x_gdp_2099_q10 / total_gdp_2099 * 100,
  pct_gdp_q90 = total_pct_x_gdp_2099_q90 / total_gdp_2099 * 100,
  pct_gdp_q50 = total_pct_x_gdp_2099_q50 / total_gdp_2099 * 100,
  pct_gdp_q1 = total_pct_x_gdp_2099_q1 / total_gdp_2099 * 100,
  pct_gdp_q99 = total_pct_x_gdp_2099_q99 / total_gdp_2099 * 100,
  )



# Plot and save 
p = ggplot(data = df_plot) +
  geom_bar(aes( x=decile, y = pct_gdp_mean ), 
           position="dodge", stat="identity", width=.8) + 
  theme_minimal() +
  ylab("Impact of Climate Change, Percentage GDP") +
  xlab("2012 Income Decile") +
  scale_x_discrete(limits = seq(1,10)) +
  ggtitle("Decile %GDP impact bar chart")


ggsave(p, file = paste0(DIR_FIG, 
    "/mc/SSP3-high_rcp85-pct-gdp_by_inc_decile.pdf"), 
    width = 8, height = 6)



# mortality code
p = ggplot() + 
  geom_errorbar(
    data = df_plot,  
    aes(x=decile, ymin = pct_gdp_q5, ymax = pct_gdp_q95), 
    color = "dodgerblue4",
    lty = "solid",
    width = 0,
    alpha = 0.5,
    size = 0.5) +
  geom_boxplot(
    data = df_plot, 
    aes(group=decile, x=decile, ymin = pct_gdp_q10, ymax = pct_gdp_q90, 
      lower = pct_gdp_q25, upper = pct_gdp_q75, middle = pct_gdp_q50), 
    fill="dodgerblue4", 
    color="white",
    size = 0.2, 
    stat = "identity") + #boxplot 
  geom_point(
    data = df_plot, 
    aes(x=decile, y = pct_gdp_mean, group = 1), 
    size=0.5, 
    color="grey88", 
    alpha = 0.9) + 
  geom_abline(intercept=0, slope=0, size=0.1, alpha = 0.5) + 
  scale_fill_gradientn(
    colors = rev(brewer.pal(9, "RdGy"))) + 
  scale_color_gradientn(
    colors = rev(brewer.pal(9, "RdGy"))) + 
  scale_x_discrete(limits=seq(1,10),breaks=seq(1,10)) +
  theme_bw() +
  theme() +
  theme(
    panel.grid.major = element_blank(), 
    panel.grid.minor = element_blank(),
    panel.background = element_blank(),
    legend.position="none",
    axis.line = element_line(colour = "black")) +
  xlab("2015 Income Decile") +
  ylab("percent gdp")+
  # coord_cartesian(ylim = c(-350, 600)) +
  ggtitle(paste0("Decile %GDP impact bar chart")) 



ggsave(p, file = paste0(DIR_FIG, 
    "/mc/SSP3-high_rcp85-pct-gdp_by_inc_decile_w_CI.pdf"), 
    width = 8, height = 6)



