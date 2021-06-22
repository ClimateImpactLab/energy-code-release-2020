library(yaml)
library(parallel)
library(glue)
library(skimr)
library(glue)
library(data.table)
library(ncdf4)
library(easyNCDF)


#' Converts the N-dimensional array data of a netcdf into a flat, tabular data.
#' @param nc_file character. The full path to the netcdf file, including '.nc4'. 
#' @param impact_var character. The name(s) of the variable(s) containing the values to pull out of the netcdf. If multiple, should be a vector. 
#' @param dimvars list of named characters. The list represents the dimensions of the `impact_var` array stored in the netcdf. The list ordering (see below) and names should be consistent 
#' with that of the netcdf. In addition, each character should have a name. This is because usually, in a netcdf, the dimensions of the variables have their 'values' (or 'names') stored in unidimensional variables, separately. For example, 
#' if there is in the set of variables of the netcdf a variable response[region, year] (a matrix), then there will be also a variable region[region] and year[year]. But those 
#' could also be regions[region] and years[year]. That is, the name of the dimension 'as a variable' is not necessarily the name of the dimension 'as a dimension'. Therefore, 
#' in the 'dimvars' list, each value is the name of the dimension 'as a VARIABLE', and each value's name is the name of the dimension 'as a DIMENSION'. The latter is the one 
#' used as an additional column in the subsequent tabular data. 
#' 
#' One painful point is to know what the ordering is. ncdump -h doesn't show the actual one (for example it might show response(region, year) while the true ordering is (year, region)). There
#' are two solutions here : 1/ trial and error until you get the right order 2/ use the easyNCDF:::NcReadDims() function to get the true ordering. 
#' @param to.data.frame logical. If TRUE, returns a data.frame. 
#' @param print.nc logical. If TRUE, prints nc_file. 
#' @param convert_all logical. Should I try to force a type conversion for all the columns of the tabular data? Careful, this is slow.
#' 
#' @return a data frame or a data table which is a flat, tabular representation of the netcdf's requested variables. this means the table will have 
#' (length(dimvars) + length(impact_var)) columns, and the product of the dimensions length as number of rows. If a datatable, names of `dimvars` are used as keys.
nc_to_DT <- function(nc_file, impact_var='rebased', dimvars=list(region='regions', year='year'), to.data.frame=FALSE, print.nc=TRUE, convert_all=FALSE){

	if(print.nc) print(nc_file)
	nc <- nc_open(nc_file)

	#verifying that dimvars matches the dimensionality of the netcdf
	dims_attr <- sapply(X=impact_var, FUN=function(x) NcReadDims(nc_file, var_names=x), simplify = FALSE)
	dims_attr <- lapply(X=dims_attr, FUN=function(x) x[names(x)!='var'])
	dimchecks <- lapply(X=dims_attr, function(x) identical(names(x), names(dimvars)))
	
	if(!all(unlist(dimchecks))) stop("dimvars doesn't match the dimension names of all the variables requested, either in the ordering or the actual content")
	
	#pull the values
	values <- sapply(X=impact_var, FUN=function(x) NcToArray(file_to_read=nc_file, vars_to_read=x), simplify = FALSE)
	values <- lapply(X=values, function(x) adrop.sel(x, omit=which(names(dim(x)) %in% names(dimvars))))

	#pull the dimension 'values' (or 'names')
	dimvalues <- sapply(X=dimvars, FUN=function(x) c(ncvar_get(nc, x)), simplify = FALSE)

	#close because who knows what can happen
	nc_close(nc)

	#assign dimension values to dimension names of the data array
	values <- Map(function(x) {dimnames(x) <- dimvalues; x}, values) #for a reason I ignore, Map() works, but not apply(). 

	#convert the array into tabular data (each dimension becomes a column)
	if(length(dimvars)<=2){ #this is faster I think, so keep that method for N=2
		tabular_values <- lapply(X=values, FUN=function(x) as.data.table(as.table(t(x))))
		tabular_values <- lapply(X=impact_var, FUN=function(x) setnames(tabular_values[[x]], 'N', x))
	} else { 
		tabular_values <- lapply(X=values, FUN=function(x) as.data.table(as.data.frame.table(x, stringsAsFactors=FALSE)))
		#tabular_values <- lapply(X=tabular_values, FUN=function(x) setnames(x, names(x)[names(x)!='Freq'], names(dimvars)))
		tabular_values <- lapply(X=impact_var, FUN=function(x) setnames(tabular_values[[x]], 'Freq', x))
	}

	lapply(tabular_values, function(x) setkeyv(x, names(dimvars)))

	tabular_values <- Reduce(merge, tabular_values)

	if(convert_all){ #this is relatively slow, so not the default behavior. It forces a type conversion for all variables (e.g. what can be integer becomes integer)
		tabular_values <- tabular_values[,lapply(X=.SD, FUN=function(x) type.convert(x, as.is=TRUE))]
	} else {
		if('year' %in% names(tabular_values)) tabular_values <- tabular_values[,year:=as.integer(year)][]
	}

	setkeyv(tabular_values, names(dimvars))
	
	if(to.data.frame) tabular_values <- as.data.frame(tabular_values) 

	return(tabular_values)

}


#' Selectively drop singleton dimensions in an array.
#' @param x array. 
#' @param omit integer. vector of indexes of the singleton dimensions to not drop. 
#' 
#' @return the array x without its singleton dimensions, except those indicated by omit. 
adrop.sel <- function(x, omit){
  ds <- dim(x)
  dv <- ds == 1 & !(seq_along(ds) %in% omit)
  abind:::adrop(x, dv)
}


#' reads a projection netcdf file and returns a list defining the scenarios represented by this target directory.
#' 
#' @param target_dir a character.  The path of a target directory, starting from the batch (if a monte-carlo run) or the rcp scenario and ending with a netcdf file, or any other file after ssp.
#' For example : 'rcp45/CCSM4/high/SSP3/myfile.nc4'
#' @param base a character. The base name of an impact netcdf, i.e omitting adaptation suffix. For example : 'cassava-031020' for files named e.g. 'cassava-031020-histclim.nc4'
#' @param impacts.folder a character. The full path of the folder containing the target directory. Example : '/shares/gcp/outputs/agriculture/impacts-mealy/cassava-median-010120'. 

#' @return a list of 6 named charactes : impacts.folder, impacts.file, [batch if montecarlo run], rcp, climate_model, iam, ssp, adapt. 
DecomposeTargetDir <- function(target_dir, base, impacts.folder){

	if (grepl('batch', target_dir)){
		batch <- gsub("/..*", "", target_dir)
		target_dir <- gsub(paste0(batch, "/"), "", target_dir)
	}
	if (grepl('median', target_dir)){
		batch <- gsub("/..*", "", target_dir)
		target_dir <- gsub(paste0(batch, "/"), "", target_dir)
	}

	rcp <- gsub("/..*", "", target_dir)
	target_dir <- gsub(paste0(rcp, "/"), "", target_dir)
	climate_model <- gsub("/..*", "", target_dir)
	target_dir <- gsub(paste0(climate_model, "/"), "", target_dir)
	iam <- gsub("/..*", "", target_dir)
	target_dir <- gsub(paste0(iam, "/"), "", target_dir)
	ssp <- gsub("/..*", "", target_dir)
	impacts.file <- gsub(paste0(ssp, "/"), "", target_dir)

	# 
	if ((grepl('aggregated', target_dir)) | (grepl('levels', target_dir))){
		adapt <- gsub('.nc4', '', gsub(base, '', impacts.file))
	} else {
		adapt <- nc_adapt_to_suf(adapt=gsub('.nc4', '', gsub(base, '', impacts.file)), inverse=TRUE)
	}

	out <- list(impacts.folder=impacts.folder, impacts.file=impacts.file, rcp=rcp, climate_model=climate_model, iam=iam, ssp=ssp, adapt=adapt)

	if (exists('batch')) out[['batch']] <- batch
	return(out)

} 


#' converts an intuitive definition of an adaptation scenario to the suffix of impacts nc4 files.  
#' @param adapt character. 'fulladapt', 'incadapt', 'noadapt', 'histclim'
#' @param inverse logical. if TRUE, the function is inverted. 
 
#' @return a character, belonging to the set of suffixes that exist for nc4 files : c("", "-incadapt", "-noadapt","-histclim")
nc_adapt_to_suf <- function(adapt, inverse=FALSE){
	
	sufs = c(fulladapt="", incadapt="-incadapt", noadapt="-noadapt",histclim="-histclim")

	if (inverse){
		return(names(sufs)[sufs==adapt])
	} else {
		return(sufs[[adapt]])
	}

}


#' DEPRECATED. Do not use this function.
#' 
#' This function distributes a non-empty set of i elements to a non-empty set of j sub-groups
#' A typical usage is to uniquely distribute tasks to cores in a parallel job. 
#' 
#' @param i integer, greater or equal to j. 
#' @param j integer, greater than 0. 
#' 
#' @return a vector of length i, each element falling in one of j. 
#' if j isn't a divider of i, i-N elements are used, and the remaining 
#' N elements are individually assigned sequentially to the first N groups.  
Distribute <- function(i, j){
	
	stop("This function is deprecated")
	
	if(!(i>=j & i>0 & j>0 & i%%1==0 & j%%1==0)){
		stop('j should be an integer greater than 0, i an integer greater or equal than j')	
	} 

	ids_j <- 1:j
	portions <- i%/%j
	distribution <- c(sapply(FUN=function(x) rep(x, portions), X=ids_j))

	if (length(distribution)!=i){
		remaining <- i%%j
		distribution <- c(distribution, 1:remaining)
	}

	stopifnot(length(distribution)==i & all(unique(distribution) %in% 1:j))

	return(distribution)
}

#' reads a specific netcdf file containing impacts, in a specific target directory, and performs checks of the values contained in it. 
#' @param spec a list of named single characters describing a target directory, as returned by DecomposeTargetDir() defined in this code. 
#' @param impacts.var a character. the name of the impact variable on which to perform checks.
#' @param years_search a numeric vector of size 2 : the first and last year defining the sequence of years one expects to see in the data. 
#' 
#' @return a data table -- 9 or 10 columns  (batch),rcp, gcm, iam, ssp, adapt, type , obs, regions, years -- 4 rows for 4 different types (Inf, NaN, 0 and missing).
#' If the netcdf file was not readable, {type , obs, regions, years} are filled with "can't open" strings.
ReadAndCheck <- function(spec, impacts.var, years_search){

	list2env(spec, environment())

	if ('batch' %in% names(spec)) {
		spec_DT <- data.table(batch=batch, rcp=rcp, gcm=climate_model, iam=iam, ssp=ssp, adapt=adapt)
		file_path <- file.path(impacts.folder, batch, rcp, climate_model, iam, ssp, impacts.file)
	} else {
		spec_DT <- data.table(rcp=rcp, gcm=climate_model, iam=iam, ssp=ssp, adapt=adapt)
		file_path <- file.path(impacts.folder, rcp, climate_model, iam, ssp, impacts.file)		
	}

	DT <- try(nc_to_DT(nc_file=file_path, impact_var=impacts.var))


	if (is.data.table(DT)){
		DT <- DT[year %in% years_search]

		infDT <- DT[is.infinite(get(impacts.var))]
		nanDT <- DT[is.nan(get(impacts.var))]
		naDT <- DT[is.na(get(impacts.var))]
		zeroDT <- DT[get(impacts.var)==0]

		shouldbe_DT <- as.data.table(expand.grid(region=fread('/shares/gcp/regions/hierarchy.csv')[is_terminal==TRUE][[1]], year=years_search, stringsAsFactors = FALSE))
		setkey(shouldbe_DT, region, year)

		infDT <- data.table(type='inf', obs=nrow(infDT), regions=length(unique(infDT[, region])), years=length(unique(infDT[,year])))
		nanDT <- data.table(type='nan', obs=nrow(nanDT), regions=length(unique(nanDT[, region])), years=length(unique(nanDT[,year])))
		naDT <- data.table(type='na', obs=nrow(naDT), regions=length(unique(naDT[, region])), years=length(unique(naDT[,year])))

		zeroDT <- data.table(type='zero', obs=nrow(zeroDT), regions=length(unique(zeroDT[, region])), years=length(unique(zeroDT[,year])))

		missing_obs <- nrow(shouldbe_DT)-nrow(DT)
		missing_regions=length(unique(shouldbe_DT[,region]))-length(unique(DT[,region]))
		missing_years=length(unique(shouldbe_DT[,year]))-length(unique(DT[,year]))
		missDT <- data.table(type='missing', obs=missing_obs, regions=missing_regions, years=missing_years)
	

		out <- cbind(spec_DT[rep(1,4),], rbind(infDT, nanDT, naDT, zeroDT, missDT))

	} else {

		errorDT <- data.table(type="can't open", obs="can't open", regions="can't open", years="can't open")
		out <- cbind(spec_DT, errorDT)

	}
	

	return(out)
}

#' reads a full set of projection target directories produced by a projection run, and returns a 
#' data table containing checks for each nc4 file of the type 'adapt' in this projection run. 
#' 
#' @param impacts.folder a character. The full path of the folder containing the target directory. Example : '/shares/gcp/outputs/agriculture/impacts-mealy/cassava-median-010120'. 
#' @param impacts.var a character. The impact variable contained in netcdfs on which to perform checks. For example, 'rebased'.
#' @param threads an integer. Number of cores to parallelize over. Each netcdf file will be assigned to a unique core. 
#' @param output_dir a character. The directory where to save the csv containing the checks.
#' @param base a character. The base name of an impact netcdf. 
#' @param output_title a character. It will be appended to the csv name and should be ideally the last folder of the projection directory, for example 'csvv-median-010120'.
#' 
#' @return the data table containing the checks for each selected nc4 file in the projection directory.   
ApplyReadAndCheck <- function(impacts.folder, base, impacts.var, years_search=seq(1981,2097), threads=1, output_dir, output_title, start_at=FALSE, end_at=FALSE){


	files <- list.files(path=impacts.folder, pattern='.nc4', all.files = TRUE, recursive = TRUE)
	files <- grep(pattern=base, x=files, value=TRUE)
	
	# files <- files[!grepl(pattern='aggregated', x=files)]	
	# files <- files[!grepl(pattern='levels', x=files)]	
	files <- files[ifelse(isFALSE(start_at), 1, start_at):ifelse(isFALSE(end_at), length(files), end_at)]
	# browser()
	specs <- mapply(FUN=DecomposeTargetDir, target_dir=files, MoreArgs = list(impacts.folder=impacts.folder, base=base), SIMPLIFY = FALSE)
	
	if (threads>1){

		checks <- mcmapply(FUN=ReadAndCheck, spec=specs, MoreArgs=list(impacts.var=impacts.var, years_search=years_search), SIMPLIFY=FALSE, mc.cores=threads, mc.preschedule=TRUE)

	} else if (threads==1){

		checks <- mapply(FUN=ReadAndCheck, spec=specs, MoreArgs=list(impacts.var=impacts.var, years_search=years_search), SIMPLIFY=FALSE)

	} else {

		stop('invalid number of threads')

	}
	
	out <- rbindlist(checks)

	fwrite(out, file.path(output_dir, glue('checks_{output_title}.csv')))

	return(out)
}



#' reads a specific target directory and performs checks on the pvals.yml file csvv seed.
#' @param spec a list of named single characters : impacts.folder, batch, rcp, climate_model, iam, ssp, impacts.file.base.
#' 
#' @return a data table with spec information and check result (character). 
PvalReadAndCheck <- function(spec){

	list2env(spec, environment())

	yml <- file.path(impacts.folder, batch, rcp, climate_model, iam, ssp, 'pvals.yml')
	
	impacts.file.base <- gsub(x=list.files(file.path(impacts.folder, batch, rcp, climate_model, iam, ssp), '*-incadapt.nc4'), pattern='*-incadapt.nc4', replacement='')

	if (!file.exists(yml)) {
		type <- 'file missing'
	} else {
		yml_list <- read_yaml(yml)

		if ('seed-csvv' %in% names(yml_list[[impacts.file.base]])) {

			if (is.integer(yml_list[[impacts.file.base]][['seed-csvv']])){
				type <- 'OK'
			} else {
				type <- 'invalid seed'
			}

		} else {

			type <- 'seed missing'

		}
	}

	DT <- data.table(batch=batch, rcp=rcp, gcm=climate_model, iam=iam, ssp=ssp, result=type)

	return(DT)
}


#' reads a full set of projection target directories produced by a projection run, and checks the pval.yml csvv seeds. 
#' 
#' @param impacts.folder a character. The full path of the folder containing the target directory. Example : '/shares/gcp/outputs/agriculture/impacts-mealy/cassava-median-010120'. 
#' @param threads an integer. Number of cores to parallelize over. Each netcdf file will be assigned to a unique core. 
#' @param output_dir a character. The directory where to save the csv containing the checks.
#' @param output_title a character. It will be appended to the csv name and should be ideally the last folder of the projection directory, for example 'csvv-median-010120'.
#' 
#' @return a data table with all reports and directories info, and saves it beforehand. 
ApplyPvalReadAndCheck <- function(impacts.folder, threads=30, output_dir, output_title, keep_only_not_OK=FALSE){


	files <- list.files(impacts.folder, '*-incadapt.nc4', all.files = TRUE, recursive = TRUE)
	specs <- mcmapply(FUN=DecomposeTargetDir, target_dir=files, MoreArgs = list(impacts.folder=impacts.folder), SIMPLIFY = FALSE, mc.cores=threads)
	
	if (threads>1){

		checks <- mcmapply(FUN=PvalReadAndCheck, spec=specs, SIMPLIFY = FALSE, mc.cores=threads)

	} else if (threads==1){

		checks <- mapply(FUN=PvalReadAndCheck, spec=specs, SIMPLIFY = FALSE)

	} else {

		stop('invalid number of threads')

	}

	out <- rbindlist(checks)

	out <- out[batch!='not_used_ACCESS1-0']
	
	setnames(out, c('batch-list', 'rcp-list', 'model-list', 'iam-list', 'ssp-list', 'result'))

	if (keep_only_not_OK) out <- out[result!='OK']

	fwrite(out, file.path(output_dir, glue('checks_pval_{output_title}.csv')))

	return(out)

}


#' This function calls nc_to_DT and checks that the returned value is a data table
#' @param ... parameters passed to nc_to_DT
#' 
#' @return logical
DoNcToDT <- function(...){

	DT <- do.call(nc_to_DT, list(...))

	out <- is.data.table(DT)

	rm(DT)
	
	return(out)

}

#' reads and converts to data table a full set of projection target directories 
#' 
#' @param impacts.folder a character. The full path of the folder containing the target directory. Example : '/shares/gcp/outputs/agriculture/impacts-mealy/cassava-median-010120'. 
#' @param threads an integer. Number of cores to parallelize over. Each netcdf file will be assigned to a unique core. 
#' @param base a character. The base name of an impact netcdf. 
#' 
#' @return a list of data tables.   
ApplyDoNcToDT <- function(impacts.folder, threads=40, base){


	files <- list.files(path=impacts.folder, pattern='.nc4', all.files = TRUE, recursive = TRUE, full.names = TRUE)
	files <- grep(pattern=base, x=files, value=TRUE)

	DT <- mcmapply(FUN=DoNcToDT, nc_file=files, SIMPLIFY = FALSE, mc.cores=threads)

	return(DT)

}



#' Summarizes the output of ApplyReadAndCheck, showing which scenarios have missing or nan values. 
#' @param file character. ApplyReadAndCheck output path, a csv.
#' @param types character vector. Which value types to include in the sum of observations?
#' @param do_montecarlo logical. Is that output from a montecarlo ?
#' 
#' @return a data table, with only scenarios that have a number of observation strictly positive. 
SummarizeChecks <- function(file, types=c('nan', 'missing'), do_montecarlo=TRUE){

	DT <- fread(file)[type %in% types]
	if (do_montecarlo) {
		DT <- DT[,.(obs=sum(obs)), by=.(batch, rcp, gcm, iam, ssp)]
	} else {
		DT <- DT[,.(obs=sum(obs)), by=.(rcp, gcm, iam, ssp)]
	}
	
	DT <- DT[obs!=0]
	  

	return(DT) 

}



ApplyReadAndCheck(impacts.folder = "/shares/gcp/outputs/energy_pixel_interaction/impacts-blueghost/median_OTHERIND_electricity_TINV_clim_GMFD", 
	base = "FD_FGLS_inter_OTHERIND_electricity_TINV_clim", 
	impacts.var = "rebased", 
	years_search=seq(1990,2099), 
	threads=45, 
	"/shares/gcp/outputs/energy_pixel_interaction/impacts-blueghost/median_OTHERIND_electricity_TINV_clim_GMFD", 
	"invalid_values", 
	start_at=FALSE, 
	end_at=FALSE)



ApplyReadAndCheck(impacts.folder = "/shares/gcp/outputs/energy_pixel_interaction/impacts-blueghost/median_OTHERIND_other_energy_TINV_clim_GMFD", 
	base = "FD_FGLS_inter_OTHERIND_other_energy_TINV_clim", 
	impacts.var = "rebased", 
	years_search=seq(1990,2099),
	threads=45, 
	"/shares/gcp/outputs/energy_pixel_interaction/impacts-blueghost/median_OTHERIND_other_energy_TINV_clim_GMFD", 
	"invalid_values", 
	start_at=FALSE, 
	end_at=FALSE)



ApplyReadAndCheck(impacts.folder = "/shares/gcp/outputs/energy_pixel_interaction/impacts-blueghost/median_OTHERIND_electricity_TINV_clim_GMFD_dm", 
	base = "FD_FGLS_inter_OTHERIND_electricity_TINV_clim_dm", 
	impacts.var = "rebased", 
	years_search=seq(1990,2099),
	threads=45, 
	"/shares/gcp/outputs/energy_pixel_interaction/impacts-blueghost/median_OTHERIND_electricity_TINV_clim_GMFD_dm", 
	"invalid_values", 
	start_at=FALSE, 
	end_at=FALSE)


ApplyReadAndCheck(impacts.folder = "/shares/gcp/outputs/energy_pixel_interaction/impacts-blueghost/median_OTHERIND_other_energy_TINV_clim_GMFD_dm", 
	base = "FD_FGLS_inter_OTHERIND_other_energy_TINV_clim_dm", 
	impacts.var = "rebased", 
	years_search=seq(1990,2099),
	threads=45, 
	"/shares/gcp/outputs/energy_pixel_interaction/impacts-blueghost/median_OTHERIND_other_energy_TINV_clim_GMFD_dm", 
	"invalid_values", 
	start_at=FALSE, 
	end_at=FALSE)




d = read_csv("/shares/gcp/outputs/energy_pixel_interaction/impacts-blueghost/median_OTHERIND_other_energy_TINV_clim_GMFD/checks_invalid_values.csv")
summary(d %>% filter(adapt == "-histclim-price014-aggregated"))


d = read_csv("/shares/gcp/social/parameters/energy_pixel_interaction/extraction/multi-models/rationalized_code/break2_Exclude_all-issues_semi-parametric/TINV_clim_GMFD/total_energy/SSP3-rcp85_states_damage-price014_median_fulluncertainty_low_fulladapt-aggregated.csv")
d %>% filter(region == "USA.10", year == 2021)


d = read_csv("/shares/gcp/social/parameters/energy_pixel_interaction/extraction/multi-models/rationalized_code/break2_Exclude_all-issues_semi-parametric/TINV_clim_GMFD/median_OTHERIND_electricity_TINV_clim_GMFD/SSP3-rcp85_global_impactpc_median_fulluncertainty_low_fulladapt-aggregated.csv")
 




