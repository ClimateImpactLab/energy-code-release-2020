# risingverse
# colored version
rm(list = ls())
library(readr)
library(dplyr)
library(reticulate)
library(haven)
library(tidyr)
library(ggplot2)
library(glue)
cilpath.r:::cilpath()
library(readstata13)

source("/home/liruixue/projection_repos/post-projection-tools/mapping/imgcat.R") #this redefines the way ggplot plots. 

for (subset in c(2085)) {

	data = read_csv(glue("/mnt/CIL_energy/code_release_data_pixel_interaction/referee_comments/damage_function_estimation/percent_gdp_vs_dollar_df_comparison_{subset}.csv"))

	d1 = data %>% select(year, d_yh_1, p_yh_1) %>% rename(d_yh = d_yh_1, p_yh = p_yh_1)
	d2 = data %>% select(year, d_yh_2, p_yh_2) %>% rename(d_yh = d_yh_2, p_yh = p_yh_2)
	d3 = data %>% select(year, d_yh_3, p_yh_3) %>% rename(d_yh = d_yh_3, p_yh = p_yh_3)
	d4 = data %>% select(year, d_yh_4, p_yh_4) %>% rename(d_yh = d_yh_4, p_yh = p_yh_4)
	d5 = data %>% select(year, d_yh_5, p_yh_5) %>% rename(d_yh = d_yh_5, p_yh = p_yh_5)


	d = rbind(d1,d2,d3,d4,d5)

	p = ggplot(d, aes(x = p_yh, y = d_yh, color = year)) + 
		geom_point(size = 1) + 
		theme(aspect.ratio = 1) +
		labs(title = "Damage Function Comparison", x = "dollar damage converted from % GDP", y = "raw dollar damage")

	ggsave(p, file = glue('/home/liruixue/repos/energy-code-release-2020/figures/referee_comments/percent_gdp_vs_dollar_df_comparison_gradient_{subset}.pdf'))

}

