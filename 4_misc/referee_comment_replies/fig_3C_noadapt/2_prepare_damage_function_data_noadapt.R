# Prepare code release data, and save it on Dropbox / Synology...
# Note - you need to be in the `risingverse-py27` conda environment to run this code for the first time (ie to extract impacts using quantiles.py)

rm(list = ls())
library(readr)
library(dplyr)
library(reticulate)
library(parallel)
library(miceadds)
library(haven)
library(tidyr)
cilpath.r:::cilpath()


db = '/mnt/CIL_energy/'
output = '/mnt/CIL_energy/code_release_data_pixel_interaction/'

data_dir = paste0(db,'/code_release_data_pixel_interaction/')

output = paste0(db, 
	'/code_release_data_pixel_interaction/projection_system_outputs/damage_function_estimation')
dir = paste0('/shares/gcp/social/parameters/energy_pixel_interaction/extraction/',
				'multi-models/rationalized_code/break2_Exclude_all-issues_semi-parametric/')

# Source codes that help us load projection system outputs
# Make sure you are in the risingverse-py27 for this... 
projection.packages <- paste0(REPO,
	"/energy-code-release-2020/2_projection/0_packages_programs_inputs/extract_projection_outputs/")
miceadds::source.all(paste0(projection.packages,"load_projection/"))


# Data needed to construct damage functions: 
# 1. GMST anomalies
# 2. Values csvs for each SSP/Price scenario we want to calculate a damage function for.

# 1. GMST anomolies: moving from our server into a shared directory
gmst_dir = "/mnt/Global_ACP/damage_function/GMST_anomaly"
gmst_df = read_csv(paste0(gmst_dir, "/GMTanom_all_temp_2001_2010_smooth.csv"))
write_csv(gmst_df, paste0(output, "/GMTanom_all_temp_2001_2010_smooth.csv"))

# 2. Values csvs to allow for draws from uncertainty 

# 2.1 Get population values, so we can convert PC impacts to impacts
pop_df = read_csv(paste0(data_dir,'/projection_system_outputs/covariates/' ,
	'SSP3_IR_level_population.csv')) %>% 
  group_by(year) %>%
  summarize(pop = sum(pop)) %>%
  tidyr::complete(year = seq(2010,2100,1)) %>%
  tidyr::fill(pop)

# 2.2 Extract and load values csvs
get_values_csv = function(price, fuel, years = NULL, pop_df= NULL, ssp = "SSP3", save = TRUE, 
	include_variance = TRUE, model = "TINV_clim", regenerate = FALSE) {
	
	# Function loads in mean and variances for a given price scenario
	# Deals with three cases: 
		# Price0, price014 and price03 are simply loading their means and variances
		# impacts (so price is null) are in pc, so are multiplied by population
		# other price scenarios are rcp specific 

	# set strings for saving outputs  
	if(is.null(price)){
		type = "impacts"
		price_tag = ""
	}else{
		type = "damages"
		price_tag = paste0("_", price)
	}
	if(model == "TINV_clim"){
		model_tag = ""
	}else if (model == "TINV_clim_lininter") {
		model_tag = "_lininter"
	}else if (model == "TINV_clim_lininter_double"){
		model_tag = "_lininter_double"
	}else if (model == "TINV_clim_lininter_half"){
		model_tag = "_lininter_half"
	}

	args = list(
            conda_env = "risingverse-py27",
            # proj_mode = '', # '' and _dm are the two options
            region = "global", # needs to be specified for 
            rcp = NULL, 
            ssp = ssp, 
            price_scen = price, # have this as NULL, "price014", "MERGEETL", ...
            unit =  "damage", # 'damagepc' ($ pc) 'impactpc' (kwh pc) 'damage' ($ pc)
            uncertainty = "values", # full, climate, values
            geo_level = "aggregated", # aggregated (ir agglomerations) or 'levels' (single irs)
            iam = NULL, 
            model = model, 
            adapt_scen = "noadapt", 
            clim_data = "GMFD", 
            yearlist = as.character(seq(2010,2099,1)),  
            dollar_convert = "yes",
            spec = paste(fuel),
            grouping_test = "semi-parametric",
            regenerate = regenerate)

    if(is.null(price)) {

		args$dollar_convert = NULL
		args$unit = "impactpc"

		mean = do.call(load.median, c(args, proj_mode = '')) %>%
			rename(mean=value) %>% 
			dplyr::select(rcp, year, gcm, iam, mean) %>% 
	      	left_join(pop_df, by=c("year")) %>%
			mutate(mean = mean * pop) %>%
			dplyr::select(-pop) 
			# %>% 
			# mutate(mean = mean * 0.0036)

		if(include_variance == TRUE){
			var = do.call(load.median, c(args, proj_mode = '_dm')) %>% 
				mutate(sd=sqrt(value))%>% 
				dplyr::select(rcp, year, gcm, iam, sd) %>% 
				left_join(pop_df, by=c("year")) %>%
				mutate(sd = sd * pop) %>%
				dplyr::select(-pop) 
		}

    } else{

    	if (price %in% c("price014", "price0", "price03")) {

		    mean = do.call(load.median, c(args, proj_mode = '')) %>%
				rename(mean=value) %>% 
				dplyr::select(rcp, year, gcm, iam, mean) %>% 
				mutate(mean = mean / 0.0036)

			if(include_variance == TRUE){	
				var = do.call(load.median, c(args, proj_mode = '_dm')) %>% 
					mutate(sd=sqrt(value))%>% 
					dplyr::select(rcp, year, gcm, iam, sd) %>% 
					mutate(sd = sd / 0.0036)
			}
   		} else{

	    	print('doing an rcp specific price!')
	    	args$price_scen = paste0(price, '_rcp45')

		    mean45 = do.call(load.median, c(args, proj_mode = '')) %>%
				rename(mean=value) %>% 
				dplyr::select(rcp, year, gcm, iam, mean) %>% 
				mutate(mean = mean / 0.0036)
			
			if(include_variance == TRUE){
		    	var45 = do.call(load.median, c(args, proj_mode = '_dm')) %>% 
					mutate(sd=sqrt(value))%>% 
					dplyr::select(rcp, year, gcm, iam, sd) %>% 
					mutate(sd = sd / 0.0036) 
		  	}

		    args$price_scen = paste0(price, '_rcp85')

		    mean85 = do.call(load.median, c(args, proj_mode = '')) %>%
				rename(mean=value) %>% 
				dplyr::select(rcp, year, gcm, iam, mean) %>% 
				mutate(mean = mean / 0.0036)
			
			if(include_variance == TRUE){
		   		var85 = do.call(load.median, c(args, proj_mode = '_dm')) %>% 
					mutate(sd=sqrt(value))%>% 
					dplyr::select(rcp, year, gcm, iam, sd)  %>% 
					mutate(sd = sd / 0.0036)
			}

		    mean = rbind(mean45, mean85)
		    
		    if(include_variance == TRUE){
		    	var = rbind(var45, var85)
			}
		}
    }
    print('all data loaded')
    if(include_variance == TRUE){
    	df_joined = left_join(mean, var, by=c("rcp", "year", "gcm", "iam"))
	}else{
		df_joined = mean
	}

    if(!is.null(years)){
    	df_joined = df_joined %>% 
    		dplyr::filter(year %in% years)
    }

    print('adding price information to dataframe')
    df_joined$price = price

    
    if(save == TRUE){
    	write_csv(df_joined, paste0(output, '/impact_values/gcm_', type, '_', fuel,price_tag, '_', ssp,model_tag,'_noadapt.csv'))
    	print(paste0(output, '/impact_values/gcm_', type, '_', fuel,price_tag, '_', ssp,model_tag,'_noadapt.csv',"  saved"))
	}else{
		return(df_joined)
	}
}


####################################
# Stuff needed for figure 3C...
df_elec = get_values_csv(price = NULL, fuel = "OTHERIND_electricity", pop_df = pop_df, save = TRUE, regenerate = TRUE) 

df_oe = get_values_csv(price = NULL, fuel = "OTHERIND_other_energy", pop_df = pop_df, save = TRUE) 

# Save values csvs needed for damage functions generally (starting with the price014 needed for )
df = get_values_csv(price = "price014", fuel = "OTHERIND_total_energy", save = FALSE) 
write_csv(df, paste0(output, '/impact_values/gcm_damages_OTHERIND_total_energy_price014_SSP3_noadapt.csv'))





