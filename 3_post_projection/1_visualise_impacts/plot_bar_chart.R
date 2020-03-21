# Purpose: Plot bar chart of impacts of climate change in 2099 relative to 
# 2010 consumption

rm(list = ls())

library(ggplot2)
library(dplyr)
library(tidyr)
library(readr)

DB = "C:/Users/TomBearpark/Dropbox"
DB_data = paste0(DB, "/GCP_Reanalysis/ENERGY/code_release_data")

root =  "C:/Users/TomBearpark/Documents/energy-code-release"
data = paste0(DB_data, "/outputs")
output = paste0(DB_data, "/figures")


###########################
# 1 Load in and format data
##########################

# Load in the bar chart data, made by code XX
# Drop countries where we don't have load information from the plotting dataframe

df = readr::read_csv(paste0(data,'/figure_2B_bar_chart_data.csv')) %>% 
  data.frame()%>%
  dplyr::filter(!is.na(electricity)) %>%
  dplyr::filter(electricity != 0) %>%
  dplyr::mutate(levels_electricity = levels_electricity / 1000000000, 
                levels_other_energy = levels_other_energy  /1000000000 )

# Merge with the country names strings for plotting
names = readr::read_csv(paste0(DB_data,"/country_names.csv")) %>% 
  data.frame()
df = left_join(df,names)

# Load information about the EU countries, so we can combine them into one regoin for the chat
eu = read_csv(paste0(DB_data,"/eu_countries.csv")) %>% 
      data.frame() %>%
      mutate(tag = 1)

df2 = left_join(df,eu) %>%
		dplyr::filter(tag==1) %>%
		select(c(year,levels_electricity, levels_other_energy)) %>%
		group_by(year) %>%
		summarize_all(sum) %>%
		data.frame() %>%
    mutate(country="EUR", country_name = "European Union")

dfsel = bind_rows(df,df2)

#################################
# 2 Plot Selected Countries 	  #
#################################


shortlist = c("BRA","CHN","ETH","IDN","IND","NGA","PAK","USA", "EUR")

# ELECTRICITY
####################


dfsellist = dfsel[dfsel$country %in% shortlist,] %>% 
              dplyr::filter(year==2010) %>%
      				arrange(-levels_electricity) %>%
              dplyr::select(country) %>%
      				slice(1:50) %>% 
      				mutate(order=1:n())

# Get a dataframe of 2099 change due to climate change percent of 2010 consumption

plot_bar = function(fuel, df) {
  pchange = dfsel %>% 
              dplyr::left_join(dfsellist) %>% 
              dplyr::filter(!is.na(order)) %>% 
    					dplyr::select(year,country_name,order,levels_electricity) %>%
    					tidyr::spread(year,levels_electricity,sep='_') %>%
              dplyr::mutate(pc=(year_2099/year_2010)*100, 
                                yval =if_else(year_2099<year_2010,year_2010,year_2099)) %>%
              mutate(pc = round(pc, 1))
}
plt =	dfsel %>% 
    left_join(dfsellist) %>% 
    filter(!is.na(order))%>%
		ggplot() +
		geom_bar(aes(x=reorder(country_name,-order), 
		            y = levels_electricity, fill=factor(year, levels=c(2099,2010) )), 
		         position="dodge", stat="identity", width=.6) +
		geom_hline(yintercept=0, colour = 'lightgray', size=0.5, linetype='solid') +
		coord_flip() +
		theme_minimal() +
	  scale_y_continuous(limits = c(0, 15), expand = c(0, 0)) +
		labs(title="Electricity") +
		ylab("EJ") +
		xlab("Country") +
		scale_fill_manual(values=c("#ffb961","#c05c7e"),name = "", 
		                  labels = c("End of Century Impact", "Current Consumption")) +
		theme(axis.text.y = element_text(size=9),
				axis.text.x = element_text(size=10, vjust=2),
				axis.title.y = element_blank(),
				legend.position=c(0.75, 0.25),
				legend.title = element_blank(),
				legend.spacing.x = unit(.2, 'cm'),
				panel.grid.major =element_blank(),
				panel.grid.minor =element_blank(),
				axis.line.x = element_line(colour = 'lightgray', size=0.5, linetype='solid'),
				panel.border = element_blank()) +
		geom_text(aes(x=reorder(country_name,-order), y=yval + 0.5, 
		              label = paste0(pc,'%'), fill = NULL), color="#2F4F4F", data = pchange, size=3)

plt


ggsave(paste0(dir,'energy_barchart_ele_levels_shortlist_v2.png'), plot=plt, height=7.5, width=7.5)






# OTHER ENERGY
####################


pchange = dfsel %>% left_join(dfsellist) %>% 
					filter(!is.na(order)) %>% 
					select(year,country_name,order,levels_other_energy) %>%
					spread(year,levels_other_energy,sep='_') %>%
					mutate(pc=(year_2099/year_2010)*100, yval =if_else(year_2099<year_2010,year_2010,year_2099))
pchange$pc = round(pchange$pc,1)


plt =	dfsel %>% left_join(dfsellist) %>% filter(!is.na(order)) %>%
		ggplot( ) +
		geom_bar(aes(x=reorder(country_name,-order), y = levels_other_energy, fill=factor(year, levels=c(2099,2010) )), position="dodge", stat="identity", width=.6) +
		geom_hline(yintercept=0, colour = 'lightgray', size=0.5, linetype='solid') +
		# geom_segment(aes(x=reorder(country_name,-order), y = -2000, xend =reorder(country_name,-order), yend = 0), colour = 'lightgray', size=0.25, linetype='solid') +
		geom_bar(aes(x=reorder(country_name,-order), y = levels_other_energy, fill=factor(year, levels=c(2099,2010) )), position="dodge", stat="identity", width=.6) +
		coord_flip() + 
		theme_minimal() +
		scale_y_continuous(limits = c(-2000, 12500), expand = c(0, 0), breaks=seq(4000,12000,4000)) +
		labs(title="Other Energy") +
		ylab("Billion kwh") +
		xlab("Country") +
		scale_fill_manual(values=c("#ffb961","#2d3561"),name = "", labels = c("End of Century Impact", "Current Consumption")) +
		theme(axis.text.y = element_text(size=9),
				axis.text.x = element_text(size=10, vjust=2),
				axis.title.y = element_blank(),
				legend.position=c(0.75, 0.25),
				legend.title = element_blank(),
				legend.spacing.x = unit(.2, 'cm'),
				panel.grid.major =element_blank(),
				panel.grid.minor =element_blank(),
				axis.line.x = element_line(colour = 'lightgray', size=0.5, linetype='solid'),
				panel.border = element_blank()) +
		geom_text(aes(x=reorder(country_name,-order), y=yval+700, label = paste0(pc,'%'), fill = NULL), color="#2F4F4F", data = pchange, size=3)

plt

ggsave(paste0(dir,'energy_barchart_oe_levels_shortlist_v2.png'), plot=plt, height=7.5, width=7.5)
