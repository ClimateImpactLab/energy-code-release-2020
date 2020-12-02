# Impacts by income deciles bar chart
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


# Take deciles of 2010 income/ clim data distribution of IRs, by getting equal populations in each population

get_deciles = function(df){
  
  deciles = df %>% 
    dplyr::filter(year == 2012) %>% group_by(loggdppc) %>%
    summarize() 
  # deciles = merge(df%>%select(iso, loggdppc))

  deciles$decile = ntile(deciles$loggdppc,10)
  countries = df %>% 
    dplyr::filter(year == 2012)
  deciles = merge(deciles, countries, by = "loggdppc")  
  return(deciles %>% dplyr::select(iso, decile))
}



cov_pixel_interaction= read_csv(paste0("/mnt/CIL_energy/code_release_data_pixel_interaction", 
  '/miscellaneous/covariates_FD_FGLS_719_Exclude_all-issues_break2_semi-parametric_TINV_clim.csv'))

country_inc = cov_pixel_interaction %>%
    dplyr::select(year, region, loggdppc)%>%
    rename(country_inc = loggdppc) %>% 
    mutate(iso = substr(region, 1,3)) 

country_inc_aggregated =  country_inc %>% group_by(iso, year) %>%
  summarize(loggdppc = mean(country_inc))

deciles = get_deciles(country_inc_aggregated)
# print(deciles %>% filter(decile == 5), n = 20)

country_inc_deciles = merge(country_inc, deciles, by = c("iso"))


country_inc_deciles %>% filter(iso == "CHN")
t = country_inc_deciles %>% filter(decile == 7, year == 2012)
countries = t %>% select(iso, year, country_inc) %>%
filter(year == 2012) %>% unique()
print(countries)



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
            total_pop_2099 = sum(pop99))%>%
  mutate(damagepc = total_damage_2099 / total_pop_2099 )


# Plot and save 
p = ggplot(data = df_plot) +
  geom_bar(aes( x=decile, y = damagepc ), 
           position="dodge", stat="identity", width=.8) + 
  theme_minimal() +
  ylab("Impact of Climate Change, 2019 USD") +
  xlab("2012 Income Decile") +
  scale_x_discrete(limits = seq(1,10))

ggsave(p, file = paste0(output, 
    "/fig_Appendix-H1-new_SSP3-high_rcp85-total-energy-price014-damages_by_country_inc_decile.pdf"), 
    width = 8, height = 6)


