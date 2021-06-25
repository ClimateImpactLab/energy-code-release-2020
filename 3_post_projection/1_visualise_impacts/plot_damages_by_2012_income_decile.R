# Plot impacts by income deciles bar chart
# done 26 aug 2020
# changed to income decile by country income oct 2020

rm(list = ls())
# Load in the required packages, installing them if necessary 
if(!require("pacman")){install.packages(("pacman"))}
pacman::p_load(ggplot2, 
               dplyr,
               readr)
source("/home/liruixue/projection_repos/post-projection-tools/mapping/imgcat.R") #this redefines the way ggplot plots. 

DB = "/mnt"
DB_data = paste0(DB, "/CIL_energy/code_release_data_pixel_interaction")
root =  "/home/liruixue/repos/energy-code-release-2020"
output = paste0(root, "/figures")


# Take deciles of 2012 income/ clim data distribution of IRs, by getting equal populations in each population
get_deciles = function(df){
  
  deciles = df %>% 
    dplyr::filter(year == 2012) %>% group_by(loggdppc) %>%
    summarize() 
  deciles$decile = ntile(deciles$loggdppc,10)
  countries = df %>% 
    dplyr::filter(year == 2012)
  deciles = merge(deciles, countries, by = "loggdppc")  
  return(deciles %>% dplyr::select(iso, decile))
}


# load covariates
cov_pixel_interaction= read_csv(paste0("/mnt/CIL_energy/code_release_data_pixel_interaction", 
  '/miscellaneous/covariates_FD_FGLS_719_Exclude_all-issues_break2_semi-parametric_TINV_clim.csv'))

# get IR level income
country_inc = cov_pixel_interaction %>%
    dplyr::select(year, region, loggdppc)%>%
    rename(country_inc = loggdppc) %>% 
    mutate(iso = substr(region, 1,3)) 

# aggregate to country income
country_inc_aggregated =  country_inc %>% group_by(iso, year) %>%
  summarize(loggdppc = mean(country_inc))

# generate deciles
deciles = get_deciles(country_inc_aggregated)
country_inc_deciles = merge(country_inc, deciles, by = c("iso"))


# Load in impacts data
df_impacts = read_csv(paste0(DB_data, '/projection_system_outputs/mapping_data',
                "/main_model-total_energy-SSP3-rcp85-high-fulladapt-price014-2099-map.csv")) %>%
  mutate(damage = damage * 1000000000 / 0.0036) %>% 
  mutate(iso = substr(region, 1,3)) %>% 
  left_join(deciles, by = "iso")

# Join with 2099 population data
df_pop99= read_csv(paste0(DB_data, '/projection_system_outputs/covariates', 
                                   '/SSP3-high-IR_level-gdppc_pop-2099.csv')) %>% 
  dplyr::select(region, pop99)

df_impacts = df_impacts %>% 
    left_join(df_pop99, by = "region")

# Collapse to decile level
df_plot = df_impacts %>% 
  group_by(decile) %>% 
  summarize(total_damage_2099 = sum(damage),
            total_q5_2099 = sum(q5),
            total_q95_2099 = sum(q95),
            total_pop_2099 = sum(pop99))%>%
  mutate(damagepc = total_damage_2099 / total_pop_2099,
         damagepc = total_q5_2099 / total_pop_2099,
         damagepc = total_q95_2099 / total_pop_2099)




# Plot and save 
p = ggplot(data = df_plot) +
  geom_bar(aes( x=decile, y = damagepc ), 
           position="dodge", stat="identity", width=.8) + 
  geom_errorbar(aes( x=decile, y = damagepc ), 
           position="dodge", stat="identity", width=.8) + 
  theme_minimal() +
  ylab("Impact of Climate Change, 2019 USD") +
  xlab("2012 Income Decile") +
  scale_x_discrete(limits = seq(1,10))

ggsave(p, file = paste0(output, 
    "/fig_Extended_Data_fig_4-H1-new_SSP3-high_rcp85-total-energy-price014-damages_by_country_inc_decile.pdf"), 
    width = 8, height = 6)


#######################################################################
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






