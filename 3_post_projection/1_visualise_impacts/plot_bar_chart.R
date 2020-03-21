# Purpose: Plot bar chart of impacts of climate change in 2099 relative to 
# 2010 consumption

rm(list = ls())

library(ggplot2)
library(dplyr)
library(tidyr)
library(readr)

DB = "C:/Users/TomBearpark/Dropbox"
DB_data = paste0(DB, "/GCP_Reanalysis/ENERGY/code_release_data")
data = paste0(DB_data, "/outputs")

root =  "C:/Users/TomBearpark/Documents/energy-code-release"
output = paste0(root, "/figures")


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

# Get a dataframe of the country names we want to plot, and put them in an order for plotting
dfsellist = dfsel[dfsel$country %in% 
                    c("BRA","CHN","ETH","IDN","IND","NGA","PAK","USA", "EUR"),] %>% 
              dplyr::filter(year==2010) %>%
              dplyr::arrange(-levels_electricity) %>%
              dplyr::select(country) %>%
      				mutate(order=1:n())

# Function to get a dataframe of 2099 change due to climate change percent of 2010 consumption
get_percent_change_df = function(fuel, df, list) {
  
  var_name = paste0("levels_", fuel)
  
  pchange = df %>% 
              dplyr::left_join(list) %>% 
              dplyr::filter(!is.na(order)) %>% 
    					dplyr::select(year,country_name,order,!!var_name) %>%
    					tidyr::spread(year,!!var_name,sep='_') %>%
              dplyr::mutate(pc=(year_2099/year_2010)*100, 
                                yval =if_else(year_2099<year_2010,year_2010,year_2099)) %>%
              mutate(pc = round(pc, 1))
  return(pchange)
}

# Function to plot the bar charts... 
plot_2B_bar_charts = function(fuel, df, list, output) {
  
  # Get the percentages
  pchange = get_percent_change_df(fuel = fuel, df = df, list = list) %>%
    as.data.frame()
  
  #Set fuel specific options
  if(fuel == "electricity"){
    print('electricity plot!!')
    title = "Electricity"
    limits = c(0, 15)
    var_name = "levels_electricity"
  }
  if(fuel == "other_energy"){
    print('other energy plot!!')
    title = "Other Fuels"
    limits = c(-10, 50)
    var_name = "levels_other_energy"
  }
  
  #subset the dataframe
  plot_df = df %>% 
    left_join(list) %>% 
    filter(!is.na(order))

  #Plot!!
  plt =	ggplot(plot_df) +
  		geom_bar(aes(x=reorder(country_name,-order),
  		            y = get(var_name), fill=factor(year, levels=c(2099,2010) )),
  		         position="dodge", stat="identity", width=.6) +
  		geom_hline(yintercept=0, colour = 'lightgray', size=0.5, linetype='solid') +
  		coord_flip() +
  		theme_minimal() +
  	  scale_y_continuous(limits = limits, expand = c(0,0)) +
  		labs(title=title) +
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

  ggsave(paste0(output,"/fig_2B_",fuel,"_consumption_compared_to_2099_impact_bars.pdf"), plot=plt, height=7.5, width=7.5)
  print("saved plot at location...")
  print(paste0(output,"/fig_2B_",fuel,"_consumption_compared_to_2099_impact_bars.pdf"))
  return(plt)
}
# Run the functions!
plt = plot_2B_bar_charts(fuel = "other_energy", df = dfsel, list = dfsellist, output  = output)
plt = plot_2B_bar_charts(fuel = "electricity", df = dfsel, list = dfsellist, output = output)


