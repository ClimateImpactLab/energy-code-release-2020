library(parallel)
library(glue)
library(vroom)
source(glue("{REPO}/energy-code-release-2020/4_misc/",
    "outreach/press/energy_outreach_data.R"))
data_root <- "/mnt/CIL_energy/impacts_outreach/"



# Check completeless of data
## year: verify that files with the following filenames have the corresponding columns
# 1. "*years_all*" : year_2020 ~ year_2099
# 2. "*years_averaged*" : years_2020_2039, years_2040_2059, years_2080_2099


# a function that checks if a column is in a file
check_col_existence <- function(file, col) {
	print(glue("checking {col} in {file}"))
	
	dat <- vroom(glue("{data_root}/{file}"))
	if (!(col %in% colnames(dat))) {
		return(glue("{col} not in {file}"))
	}
}



# check that files have correct columns
years_all_files <- list.files(path = data_root, pattern='*years_all*', all.files = TRUE, recursive = TRUE)
years_all_cols <- sprintf("year_%s", seq(2020, 2099))

d = do.call(rbind, mcmapply(
	FUN = check_col_existence,
	file = years_all_files,
	col = years_all_cols,
	SIMPLIFY = FALSE,
	mc.cores = 60
	))


years_avg_files <- list.files(path = data_root, pattern='*years_averaged*', all.files = TRUE, recursive = TRUE)
years_avg_cols <- c("years_2020_2039","years_2040_2059","years_2080_2099")

d = do.call(rbind, mcmapply(
	FUN = check_col_existence,
	file = years_avg_files,
	col = years_avg_cols,
	SIMPLIFY = FALSE,
	mc.cores = 60
	))

# check that files have correct number of rows
len_all_IRs = length(return_region_list("all_IRs"))
len_states = length(return_region_list("states"))
len_isos = length(return_region_list("iso"))
len_global = length(return_region_list("global"))
len_cities_500k = nrow(read_csv("~/repos/energy-code-release-2020/data/500k_cities.csv")%>% 
	select(city, country, Region_ID))

# a function that checks if a file has correct number of entries
check_row_number <- function(file, N) {
	dat <- vroom(glue("{data_root}/{file}"))
	if (!(nrow(dat) == N)) {
		return(glue("{file} doesnt have {N} rows!"))
	}
}


all_IRs_files <- list.files(path = data_root, pattern='*impact_regions*', all.files = TRUE, recursive = TRUE)
d = do.call(rbind, mcmapply(
	FUN = check_row_number,
	file = all_IRs_files,
	N = len_all_IRs,
	SIMPLIFY = FALSE,
	mc.cores = 60
	))


states_files <- list.files(path = data_root, pattern='*US_states*', all.files = TRUE, recursive = TRUE)
d = do.call(rbind, mcmapply(
	FUN = check_row_number,
	file = states_files,
	N = len_states,
	SIMPLIFY = FALSE,
	mc.cores = 60
	))
d

global_files <- list.files(path = data_root, pattern='*global*', all.files = TRUE, recursive = TRUE)
d = do.call(rbind, mcmapply(
	FUN = check_row_number,
	file = global_files,
	N = len_global,
	SIMPLIFY = FALSE,
	mc.cores = 60
	))
d

isos_files <- list.files(path = data_root, pattern='*country_level*', all.files = TRUE, recursive = TRUE)
d = do.call(rbind, mcmapply(
	FUN = check_row_number,
	file = isos_files,
	N = len_isos,
	SIMPLIFY = FALSE,
	mc.cores = 60
	))
d

cities_500k_files <- list.files(path = data_root, pattern='*500kcities*', all.files = TRUE, recursive = TRUE)
d = do.call(rbind, mcmapply(
	FUN = check_row_number,
	file = cities_500k_files,
	N = len_cities_500k,
	SIMPLIFY = FALSE,
	mc.cores = 60
	))

# some cities missing, trying to see which ones
cities_500k = read_csv("~/repos/energy-code-release-2020/data/500k_cities.csv")%>% 
	select(city, country, Region_ID)
dat <- vroom(glue("{data_root}/{cities_500k_files[1]}"))
anti_join(cities_500k, dat)



# check for nulls, nas, zeros

check_invalid_values <- function(file) {
	dat <- suppressMessages(vroom(glue("{data_root}/{file}")))
	apply_function <- function(func, dat) {
		# margin = 2 indicates that we want to check columns
		x <- apply(dat[,-1], MARGIN = 2, func)
		# a syntax trick to fix a bug 
		if (is.null(dim(x))) { x <- matrix(x, length(x),1)}
		y <- any(apply(x,MARGIN = 2, any))
		if (!is.na(y)) return(y)
		else return(FALSE)
	}
	if (apply_function(func = function(x) x==0, dat)) {return(glue("{file} has zeros"))}
	if (apply_function(func = function(x) is.na(x), dat)) {return(glue("{file} has NAs"))}
	if (apply_function(func = function(x) is.nan(x), dat)) {return(glue("{file} has NaNs"))}
	if (apply_function(func = function(x) is.infinite(x), dat)) {return(glue("{file} has Infs"))}
	if (apply_function(func = function(x) abs(x) > 10e30, dat)) {return(glue("{file} has large values"))}
}

# check all files for any suspicious value
all_files <- list.files(path = data_root, all.files = TRUE, recursive = TRUE)

# lapply version for debugging
# d = do.call(rbind, lapply(
# 	X = all_files,
# 	FUN = check_invalid_values
# 	))

d1 = do.call(rbind, mcmapply(
	FUN = check_invalid_values,
	file = all_files,
	SIMPLIFY = FALSE,
	mc.cores = 70
	))



# check pct gdp is less than 1
pct_gdp_files <- list.files(path = data_root, pattern='*pct_gdp*', all.files = TRUE, recursive = TRUE)

check_pct_gdp <- function(file) {
	dat <- suppressMessages(vroom(glue("{data_root}/{file}")))
	apply_function <- function(func, dat) {
		# margin = 2 indicates that we want to check columns
		x <- apply(dat[,-1], MARGIN = 2, func)
		# a syntax trick to fix a bug 
		if (is.null(dim(x))) { x <- matrix(x, length(x),1)}
		y <- any(apply(x,MARGIN = 2, any))
		if (!is.na(y)) return(y)
		else return(FALSE)
	}
	if (apply_function(func = function(x) abs(x)>=100, dat)) {return(glue("{file} has >100 values"))}
}

d = do.call(rbind, mcmapply(
	FUN = check_pct_gdp,
	file = pct_gdp_files,
	SIMPLIFY = FALSE,
	mc.cores = 70
	))


## check kwh and gj conversion 

gj_files <- list.files(path = data_root, pattern='*gj*', all.files = TRUE, recursive = TRUE)

check_unit_conversion <- function(file) {
	# browser()

	print(glue("{data_root}/{file}"))
	dat_gj <- suppressMessages(vroom(glue("{data_root}/{file}")))
	dat_kwh <- suppressMessages(vroom(str_replace(glue("{data_root}/{file}"), "gj", "kwh")))

	matrix_gj = data.matrix(dat_gj[,-1])
	matrix_kwh = data.matrix(dat_kwh[,-1])
	r = matrix_gj / matrix_kwh

	# a function that apply a user-defined function to every element of a dataset
	apply_function <- function(func, dat) {
		# browser()
		# margin = 2 indicates that we want to check columns
		x <- apply(dat, MARGIN = 2, func)
		# a syntax trick to fix a bug 
		if (is.null(dim(x))) { x <- matrix(x, length(x),1)}
		y <- any(apply(x,MARGIN = 2, any))
		if (!is.na(y)) return(y)
		else return(FALSE)
	}
	if (!apply_function(func = function(x) floor(x)==277, r)) {return(glue("{file} has conversion problem"))}
}

d = do.call(rbind, mcmapply(
	FUN = check_unit_conversion,
	file = gj_files,
	SIMPLIFY = FALSE,
	mc.cores = 70
	))

# check actual values

d = vroom(paste0("/shares/gcp/social/parameters/energy_pixel_interaction/extraction/multi-models/",
	"rationalized_code/break2_Exclude_all-issues_semi-parametric/TINV_clim_GMFD/total_energy/",
	"SSP3-rcp85_states_damage-price014_median_fulluncertainty_low_fulladapt-aggregated.csv"))

d %>% filter(region == "USA.10", year == 2020)


