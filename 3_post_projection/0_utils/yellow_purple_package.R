#------------------------------------------------------------------------------------------
# This script plots the response function of impactregion-years.
#------------------------------------------------------------------------------------------

source(paste0("/home/liruixue/repos/", '/post-projection-tools/nc_tools/misc_nc.R'))

library(parallel)
library(pbmcapply)
library(ggplot2)
library(mvtnorm)
library(magrittr)
library(plyr)
library(dplyr)
library(stringr)
library(readstata13)
library(viridis)
library(gridExtra)
library(grid)
library(lattice)
library(ncdf4)
library(rlist)
library(narray)
library(tidyr)
library(cowplot)
library(gdata)
library(gtable)
library(R.cache)
library(data.table)
library(dtplyr)
library(tibble)
library(rlang)
library(abind)
library(glue)
library(fst)
library(stats)

`%notin%` <- Negate(`%in%`)

#this selectively drops dimensions of an array that are singletons. drop() does it for all singleton dimensions, annoying. 
adrop.sel <- function(x, omit){
  ds <- dim(x)
  dv <- ds == 1 & !(seq_along(ds) %in% omit)
  abind:::adrop(x, dv)
}

substrRight <- function(x, n){
  substr(x, nchar(x)-n+1, nchar(x))
}

read.csvv = function(filepath, vars=c('gamma','prednames','covarnames'), het.list=NULL, ...) {

	csvv = list()
	if (!is.null(het.list)){
		for (kw in names(het.list)) {
			csvv[[kw]] = het.list[[kw]]
		}
	}

	squish_function <- stringr::str_squish
	con = file(filepath, "r")
	vcv = c()

	while ( TRUE ) {
		if ('gammavcv' %in% vars) {
			line = squish_function(readLines(con, n = 1))
			if (line %in% c('gamma')) {
				data = readLines(con, n = 1) %>%
						strsplit(",") %>%
						unlist() %>%
						squish_function()
				glen = length(data)
			}
			if  ('gammavcv' %in% line ) {
				while (TRUE) {
					line = readLines(con, n = 1) 
					if (line %in% c('residvcv')) {
						close(con)
						vcv = t(array(vcv, dim=c(glen,glen)))
						if (!is.null(het.list)) {
							for (kw in names(het.list)) {
								vcv = vcv[which(het.list[[kw]] %in% get(kw)),which(het.list[[kw]] %in% get(kw))]
							}
						}
						return(vcv)
					}
					line = line %>%
							strsplit(",") %>%
							unlist() %>%
							squish_function() %>%
							as.numeric()
					vcv = c(vcv, line)
				}
			}
		} else {

			line = squish_function(readLines(con, n = 1))
			if ( line %in% vars ) {
				data = readLines(con, n = 1) %>%
						strsplit(",") %>%
						unlist() %>%
						squish_function()
				if (line %in% c('gamma', 'residvcv')) {
					data = as.numeric(data)
				}
				csvv[[line]] = data[data != ""]
				if (length(names(csvv))==length(vars)+length(names(het.list))) {
					close(con)
					return(as.data.frame.list(csvv))
				  
				}
			}
			# Prevent infinite loop, if something has been mis-specified 
			if ( length(line) == 0 ) {
			  message("couldn't find all variables")
			  close(con)
			  break
			}
		}
	}
}

get.gamma <- function(csvv, ...) {
	het.supply = list(...)
	for (kw in names(het.supply)) {
		csvv = csvv[csvv[[kw]] == het.supply[[kw]],]
	}
	 if (nrow(csvv) == 1) {
		return(csvv[1,'gamma'])
	}
	else {
		stop("cannot identify gamma from inputs")
	}
}


get.curve.mortality <- function(TT, csvv, climtas, loggdppc, age=NULL, model="poly", gamma_vect=NULL, ...) { 
	if (is.null(gamma_vect)) {
		if (model == "poly"){
			
			beta1 <- get.gamma(csvv, prednames='tas', covarnames='1', age=age) + get.gamma(csvv, prednames='tas', covarnames='climtas', age=age) * climtas + get.gamma(csvv, prednames='tas', covarnames='loggdppc', age=age) * loggdppc
			beta2 <- get.gamma(csvv, prednames='tas2', covarnames='1', age=age) + get.gamma(csvv, prednames='tas2', covarnames='climtas', age=age) * climtas + get.gamma(csvv, prednames='tas2', covarnames='loggdppc', age=age) * loggdppc
			beta3 <- get.gamma(csvv, prednames='tas3', covarnames='1', age=age) + get.gamma(csvv, prednames='tas3', covarnames='climtas', age=age) * climtas + get.gamma(csvv, prednames='tas3', covarnames='loggdppc', age=age) * loggdppc
			beta4 <- get.gamma(csvv, prednames='tas4', covarnames='1', age=age) + get.gamma(csvv, prednames='tas4', covarnames='climtas', age=age) * climtas + get.gamma(csvv, prednames='tas4', covarnames='loggdppc', age=age) * loggdppc
			
			return(beta1 * TT + beta2 * TT^2 + beta3 * TT^3 + beta4 * TT^4)
			
		} else { #spline -- depricated
			
			stop('spline not functional')
			
		}
	} else {

		gamma_mat = t(array(gamma_vect, dim=c(length(unique(csvv$covarnames)),length(unique(csvv$prednames)))))
		beta1 = gamma_mat[1,1] + gamma_mat[1,2] * climtas + gamma_mat[1,3] * loggdppc
		beta2 = gamma_mat[2,1] + gamma_mat[2,2] * climtas + gamma_mat[2,3] * loggdppc
		beta3 = gamma_mat[3,1] + gamma_mat[3,2] * climtas + gamma_mat[3,3] * loggdppc
		beta4 = gamma_mat[4,1] + gamma_mat[4,2] * climtas + gamma_mat[4,3] * loggdppc
		return(beta1 * TT + beta2 * TT^2 + beta3 * TT^3 + beta4 * TT^4)
	}
}

mortality.uncertainty <- function(TT, MMT, csvv, CI, ...) {
	
	gamma_vect = csvv[csvv$age==3,'gamma']
	vcv = read.csvv(filepath = paste0(csvv.dir,csvv.name), vars='gammavcv', ...)
	func <- function(TT, MMT, ...) {
		get.curve.mortality(TT=TT, ...) - get.curve.mortality(TT=MMT, ...)
	}
	nd = numDeltaMethod(func=func,TT=TT, MMT=MMT,  x=gamma_vect, vcv=vcv, csvv=csvv, ...)
	if (CI=='upper') {
		out = nd[,'Estimate'] + 1.96*nd[,'SE']   
	} else if (CI=='lower') {
		out = nd[,'Estimate'] - 1.96*nd[,'SE']
	}
	return(out)

}

grad <- function(func,x,...) {
	h <- .Machine$double.eps^(1/3)*ifelse(abs(x)>1,abs(x),1)
	temp <- x+h
	h.hi <- temp-x
	temp <- x-h
	h.lo <- x-temp
	twoeps <- h.hi+h.lo
	nx <- length(x)
	ny <- length(func(gamma_vect=x,...))
	if (ny==0L) stop("Length of function equals 0")
	df <- if(ny==1L) rep(NA, nx) else matrix(NA, nrow=nx,ncol=ny)
	for (i in 1L:nx) {
		hi <- lo <- x
		hi[i] <- x[i] + h.hi[i]
		lo[i] <- x[i] - h.lo[i]
		if (ny==1L)
			df[i] <- (func(gamma_vect=hi, ...) - func(gamma_vect=lo, ...))/twoeps[i]
		else df[i,] <- (func(gamma_vect=hi, ...) - func(gamma_vect=lo, ...))/twoeps[i]
	}
	return(df)
}

numDeltaMethod <- function(func, x, vcv, gd=NULL,...) {
	est <- func(gamma_vect=x,...)
	Sigma <- vcv
	if (is.null(gd)) {
		gd <- grad(func,x,...)
	}
	## se.est <- as.vector(sqrt(diag(t(gd) %*% Sigma %*% gd)))
	se.est <- as.vector(sqrt(colSums(gd* (Sigma %*% gd))))
	data.frame(Estimate = est, SE = se.est)
}

get.clipped.curve.mortality <- function(csvv, climtas, loggdppc, age, year, region, adapt='full', base_year=2010, TT_lower_bound=-23, TT_upper_bound=45, TT_step = 1, model="poly", minpoly_constraint=30, do.clipping=T, goodmoney.clipping=T, do.diffclip=T, get.covariates=F, covars=NULL, covar.names=NULL, list.names=NULL, CI='central', ...) {
	TT=seq(TT_lower_bound, TT_upper_bound, TT_step/2)
	years = c(base_year,year)
	if (get.covariates) {
		if (is.null(covars)) {
			stop("need to provide covariates dataframe -- try load.covariates(...)")
		} else {
			cov.list = get.covariates(covars=covars, region=region, years=years, covar.names=covar.names, list.names=list.names)
			climtas = cov.list$climtas
			loggdppc = cov.list$loggdppc
			if (length(climtas) != length(years) & length(loggdppc) != length(years)  ) {
				stop("covariates are incorrect size!")
			}
		}
	}
	if (model == "poly") {         
		if (do.clipping) { #levels-clipping

			yy0 <- get.curve.mortality(TT=TT, csvv=csvv, climtas=climtas[1], loggdppc=loggdppc[1], age=age) 
			ii.min <- which.min(yy0[TT >= 10 & TT <= minpoly_constraint]) + which(TT == 10) - 1 
			if (CI == 'upper' | CI == 'lower') {
				yy0 = mortality.uncertainty(TT=TT, MMT=TT[ii.min], CI=CI, csvv=csvv, climtas=climtas[1], loggdppc=loggdppc[1], age=age,...)
				yy1 = mortality.uncertainty(TT=TT, MMT=TT[ii.min], CI=CI, csvv=csvv, climtas=climtas[2], loggdppc=loggdppc[2], age=age,...)
				yyg = mortality.uncertainty(TT=TT, MMT=TT[ii.min], CI=CI, csvv=csvv, climtas=climtas[2], loggdppc=loggdppc[1], age=age,...)
			} else {
				yy0 <- yy0 - yy0[ii.min]
				yy1 <- get.curve.mortality(TT=TT, csvv=csvv, climtas=climtas[2], loggdppc=loggdppc[2], age=age) #full adapt
				yy1 <- yy1 - yy1[ii.min]
				yyg <- get.curve.mortality(TT=TT, csvv=csvv, climtas=climtas[2], loggdppc=loggdppc[1], age=age) #climate adapt only (No income adapt)
				yyg <- yyg - yyg[ii.min]
				yyi <- get.curve.mortality(TT=TT, csvv=csvv, climtas=climtas[1], loggdppc=loggdppc[2], age=age) #climate adapt only (No income adapt)
				yyi <- yyi - yyi[ii.min]

			}
			#ii.min <- which.min(yy0[TT >= 10]) + which(TT == 10) - 1 
			message(paste0('Region: ',region,'; Age: ',age,'; MMT: ',TT[ii.min]))
			
			if (goodmoney.clipping) {
				yy <- pmax(pmin(yy1, yyg), 0) # Good money and levels clipping
			} else {
				yy <- pmax(yy1, 0) # only levels clipping (no good money)
			}
			if (adapt == 'income') {
				yy <- pmax(pmin(yyi,yy0), 0)
			} else if (adapt == 'no') {
				yy <-  pmax(yy0, 0)
			} else if (adapt != 'full') {
				stop('mispecified adaptation scenario, choose from [full, income, no]')
			}
		} else { #no levels-clipping
			
			yy0 <- get.curve.mortality(TT=TT, csvv=csvv, climtas=climtas[1], loggdppc=loggdppc[1], age=age) 
			ii.min <- which.min(yy0[TT >= 10 & TT <= minpoly_constraint]) + which(TT == 10) - 1 
			if (CI == 'upper' | CI == 'lower') {
				yy0 = mortality.uncertainty(TT=TT, MMT=TT[ii.min], CI=CI, csvv=csvv, climtas=climtas[1], loggdppc=loggdppc[1], age=age,...)
				yy1 = mortality.uncertainty(TT=TT, MMT=TT[ii.min], CI=CI, csvv=csvv, climtas=climtas[2], loggdppc=loggdppc[2], age=age,...)
				yyg = mortality.uncertainty(TT=TT, MMT=TT[ii.min], CI=CI, csvv=csvv, climtas=climtas[2], loggdppc=loggdppc[1], age=age,...)
			} else {
				yy0 <- yy0 - yy0[ii.min]
				yy1 <- get.curve.mortality(TT=TT, csvv=csvv, climtas=climtas[2], loggdppc=loggdppc[2], age=age) #full adapt
				yy1 <- yy1 - yy1[ii.min]
				yyg <- get.curve.mortality(TT=TT, csvv=csvv, climtas=climtas[2], loggdppc=loggdppc[1], age=age) #climate adapt only (No income adapt)
				yyg <- yyg - yyg[ii.min]
			}
			
			if (goodmoney.clipping) {
				yy <- pmin(yy1, yyg) # Good money clipping only, no levels
			} else {
				yy <- yy1  # no Good money, no levels
			}
			if (adapt == 'income') {
				yy <- yyg
				suff = '_IA'
			} else if (adapt == 'no') {
				yy <- yy0
				suff = '_NA'
			} else if (adapt != 'full') {
				stop('mispecified adaptation scenario, choose from [full, income, no]')
			}
		}
		
		if (do.diffclip) { #u-clipping
			yy.nd <- yy
			yy[ii.min:length(yy)] <- cummax(yy[ii.min:length(yy)]) #returns a vector with the cum max value ('max value to date')
			#yy[1:(ii.min-1)] <- rev(cummax(rev(yy[1:(ii.min-1)])))
			yy[1:(ii.min)] <- rev(cummax(rev(yy[1:(ii.min)])))
		}

		return(format.curve(curve=yy, year=year, base_year=base_year, region=region, TT=TT, adapt=adapt))
	}
}

format.curve <- function(curve, year, base_year, region, TT, adapt = 'full', new_tag = NULL, ...){
	if (adapt == 'full') {
		year_dim = year
	} else if (adapt == 'income') {
		year_dim = paste0(toString(year),'_IA')
	} else if (adapt == 'no') {
		year_dim = paste0(toString(base_year),'_NA')
	} else if (adapt == 'tbar') {
		year_dim = paste0(toString(year),'_TA')
	} else if (!is.null(new_tag)) {
		year_dim = paste0(toString(base_year),new_tag)
	} else {
		stop('Pick scenario or add a label, new_tag')
	}
	return(array(curve,dim=c(length(curve),1,1), dimnames= list(TT, year_dim, region)))
}

load.covariates <- function(regions, years, cov.dir, covarkey, covar.names, filetype='csv', subset_list=NULL, skip_lines_cov=0, ...) {
	
	memo.csv = addMemoization(data.table::fread)
	if (filetype=='csv') {
		covars = memo.csv(cov.dir, stringsAsFactors=F, skip=skip_lines_cov)  #cmd = paste0("grep ',' ", cov.dir)
		covars = covars[,unique(names(covars)),with=FALSE]

	} else if (filetype == 'dta') {
		covars = as.data.table(haven:::read_dta(cov.dir))
	} else if (filetype == 'fst') {
		covars = read_fst(cov.dir, as.data.table = TRUE)
	}

	if (!is.null(subset_list)) {
		for (ss in names(subset_list)) {
			covars = covars[covars[[ss]] == subset_list[[ss]],]
		}
	}

	covars = covars[,c(covarkey,'year', covar.names), with=FALSE] #covars[,c(covarkey,'year',covar.names)]
	covars$year = as.integer(covars$year)
	region.year = covars[year %in% (years-1) & get(covarkey) %in% regions][,year:=year + 1]

	setnames(region.year, covarkey, 'region')
	setkey(region.year, region, year)

	return(as.data.frame(region.year))
}


get.covariates <- function(covars, region, years, covar.names, list.names=NULL, ...) {
	outlist = list()
	covars = covars[(covars['region']==region) & (covars$year %in% years),] %>% arrange(year)
	if (is.null(list.names)) {
		list.names = covar.names
	}
	for (ii in seq(1, length(covar.names))) {
		outlist[[list.names[ii]]] = covars[,covar.names[ii]]
	}
	outlist[['years']] = covars[,'year']
	if (length(years)==2 & years[1]==years[2]) {
		for (nn in names(outlist)) {
			outlist[[nn]] = append(outlist[[nn]], outlist[[nn]])
		}
	}
	return(outlist)
}

apply_curve <- function(region, func, ...) {
	# want this to output 
	kwargs = list(...)

	if (!is.null(kwargs[['TT']])) {
		if (typeof(kwargs[['TT']]) == "list" ) {
			kwargs[['TT']] = kwargs[['TT']][[region]]
		}
	}
	kwargs = rlist::list.append(kwargs, region=region)
	
	curve = do.call(func,kwargs)
	return(curve)
}


mapply_curve <- function(regions, years, adapt='full', curve_ds=NULL, export.list=F, ...){
	vect = expand.grid(regions=regions, years=years)
	kwargs=list(...)
	kwargs = rlist::list.append(kwargs, adapt=adapt)
	dslist = mapply(FUN=apply_curve, region=paste(vect[,'regions']), year=vect[,'years'], MoreArgs=kwargs, SIMPLIFY=FALSE)
	if (export.list==F) {
		ds = narray::stack(dslist, along=1)
	} else if (export.list==T){
		ds = dslist
	}

	if (!is.null(curve_ds)) {
		ds = narray::stack(list(ds,curve_ds), along = 1)
	}
	return(ds)
}

mapply_curve_adapts <- function(regions, years, base_year,adapts, curve_ds=NULL, export.list=F,covars, ...){
	vect = expand.grid(regions=regions, years=years, adapt=adapts)
	covars = covars[(covars[,'region'] %in% regions) & (covars$year %in% c(years,base_year)),]
	kwargs=list(...)
	kwargs = rlist::list.append(kwargs, covars=covars)
	dslist = mapply(FUN=apply_curve, region=paste(vect[,'regions']), year=vect[,'years'], adapt=vect[,'adapt'],MoreArgs=kwargs, SIMPLIFY=FALSE)
	if (export.list==F) {
		ds = narray::stack(dslist, along=1)
	} else if (export.list==T){
		ds = dslist
	}
	if (!is.null(curve_ds)) {
		ds = narray::stack(list(ds,curve_ds), along = 1)
	}
	return(ds)
}

extract_climate_data <- function(year, gcm='CCSM4', tas_value='tas', climpath = NULL, tas.path=NULL, is.gcm=T, ncname = '1.1', rcp='rcp85', ...){
	if (is.gcm == T) {

		if (is.null(climpath)){
			climpath = ifelse(year <=2005, paste0(tas_value,"/historical/",gcm,"/",year), paste0(tas_value,"/",rcp,"/",gcm,"/",year)) 
		}
		if (is.null(tas.path)){
			tas.path = '/shares/gcp/climate/BCSD/hierid/popwt/daily/'
		}
		#open netcdf
		if (substr(gcm, 1,9)=="surrogate"){
			ncin = nc_open(paste0(tas.path,climpath,"/",ncname,".nc4"))
		} else {
			ncin = nc_open(paste0(tas.path,climpath,"/",ncname,".nc4"))
		}
		hierid = ncvar_get(ncin, "hierid") #extract hierid
		tas.df = t(ncvar_get(ncin, tas_value)) #extract climate data

		ta = array(tas.df, dim=c(dim(tas.df),1), dimnames=list(paste0('X', seq(1,365)), hierid, year))

	} else if (is.gcm == F) {
		climpath = ifelse(is.null(climpath),'/shares/gcp/climate/GHCND/stations/raw/daily/tas/historic/',climpath)
		ncin = nc_open(paste0(climpath,year,'/',ncname,'.nc4'))
		hierid = data.frame(ncvar_get(ncin, "hierid")) #extract hierid
		tas.df = data.frame(ncvar_get(ncin, tas_value)) #extract climate data
		# tas.master = data.frame(hierid, tas.df) #put into dataframe
		# names(tas.master)[1] = "hierid"
		check = t(as.matrix(tas.df))
		rownames(check) <- as.matrix(hierid)
		tc = t(check)
		dimnames(tc)[[1]] <- paste0('X', seq(1,365))
		ta = array(tc, dim=c(dim(tc),1), dimnames=append(dimnames(tc),year))
	}

	return(ta)
}

extract_monthly_edd <- function(year, gcm='CCSM4', tas_value='edd_monthly', climpath = NULL, tas.path=NULL, is.gcm=T, ncname = '1.3', rcp='rcp85', ...){

	if (is.gcm == T) {

		if (is.null(climpath)){
			climpath = ifelse(year <=2005, paste0(tas_value,"/historical/",gcm,"/",year), paste0(tas_value,"/",rcp,"/",gcm,"/",year)) 
		}
		if (is.null(tas.path)){
			tas.path = '/shares/gcp/climate/BCSD/hierid/cropwt/monthly/'
		}

		#open netcdf
		if (substr(gcm, 1,9)=="surrogate"){
			ncin = nc_open(paste0(tas.path,climpath,"/",ncname,".nc4"))
		} else {
			ncin = nc_open(paste0(tas.path,climpath,"/",ncname,".nc4"))
		}
		hierid = ncvar_get(ncin, "hierid") #extract hierid
		reftemp = ncvar_get(ncin, "refTemp") #extract climate data
		month.df =ncvar_get(ncin, "month")
		edd.df = ncvar_get(ncin, tas_value)
		
		ta = array(edd.df, dim=c(dim(edd.df),1), dimnames= list(hierid, month.df, reftemp, year))

	} 

	return(ta)
}

extract_monthly_climate_data <- function(year, gcm='CCSM4', tas_value='pr', climpath = NULL, tas.path=NULL, is.gcm=T, ncname = '1.0', rcp='rcp85', ...){

	if (is.gcm == T) {

		if (is.null(climpath)){
			climpath = ifelse(year <=2005, paste0(tas_value,"/historical/",gcm,"/",year), paste0(tas_value,"/",rcp,"/",gcm,"/",year)) 
		}
		if (is.null(tas.path)){
			tas.path = '/shares/gcp/climate/BCSD/hierid/cropwt/monthly/'
		}

		#open netcdf
		if (substr(gcm, 1,9)=="surrogate"){
			ncin = nc_open(paste0(tas.path,climpath,"/",ncname,".nc4"))
		} else {
			ncin = nc_open(paste0(tas.path,climpath,"/",ncname,".nc4"))
		}
		hierid = ncvar_get(ncin, "hierid") #extract hierid
		month.df =ncvar_get(ncin, "month")
		tas.df = ncvar_get(ncin, tas_value)
		ta = array(tas.df, dim=c(dim(tas.df),1), dimnames= list(hierid, month.df, year))

	} 

	return(ta)

}


mapply_extract_climate_data <- function(years, climate_func=extract_climate_data, ...){
	kwargs = list(...)
	dslist = mapply(FUN=climate_func, year=years, MoreArgs = kwargs, SIMPLIFY=FALSE)
	ds = narray::stack(dslist, along=3)
	return(ds)
	
}

#' returns an array of projected weather data for a season and crop passed as an argument. 
#' @param weather.dir character. Master path for which weather data is strored in.
#' @param weather.file character. Name of the weather data file within the master path.
#' @param season character. 
#' @param crop character. 

extract_ready_weather_data <- function(year, region, gcm='CCSM4', weather.file = NULL, weather.name, weather.dir=NULL, is.gcm=T, rcp='rcp85', season, crop, ...){
	if (is.gcm == T) {

		#season = growing_season_identifier(region = region, weather.name = weather.name)
		if (is.null(weather.file)){
			weather.file <- paste0(crop,'-',season,'_',weather.name)
		}
		if (is.null(weather.dir)){
			weather.dir = paste0('/shares/gcp/outputs/temps/',rcp,"/",gcm,'/')
		}

		ncin = nc_open(paste0(weather.dir,weather.file,".nc4"))
		
		year.nc <- which( ncin$dim$year$vals == year)
		hierid = ncvar_get(ncin, "regions")
		covar.df =ncvar_get(ncin, "covars")
		year.df <- ncvar_get( ncin, "year")[year.nc ]

		if (weather.name == "seasonaltasmin") {
			tas.df = ncvar_get(ncin, "annual")[,year.nc]
			check = t(as.matrix(tas.df))
			ta = array(check, dim=c(dim(check),1), dimnames= list(covar.df, hierid, year))
			dimnames(ta)[[1]] <- paste0('X', 1)
		} else if (weather.name == "seasonaledd") { 
			tas.df = ncvar_get(ncin, "annual")[,,year.nc] 
			ta = array(tas.df, dim=c(dim(tas.df),1), dimnames= list(covar.df, hierid, year)) #covar.df = c("seasonalgdd, seasonalkdd")
		} else if (weather.name =="monthbinpr"){
			tas.df = ncvar_get(ncin, "annual")[,,year.nc]
			ta = array(tas.df, dim=c(dim(tas.df),1), dimnames= list(covar.df, hierid, year))
			ta = aperm(ta, c(2, 1, 3))
		}
	}
	return(ta)
}

#' returns a character vector of seasons for a given region depending on its growing months of season.
#' the purpose is to identify regions that have fall and winter seasons. As a result, if region doesn't have a specific season, we won't make a delta-beta for it.
#' if growing months of season is less than 5, it will return "summer". Means there won't be fall and winter delta-betas for these regions.
#' if 6 or 7, it will return "summer" for tasmin and "fall" for the rest-- the reason being we don't use fall tasmin.
#' if gs > 7, it will return "winter" for tasmin and c("winter", "fall") for the rest. Since all regions must have summer, there's no need to include it.
#' @param region character.
#' @param weather.name string. Ex: seasonaltasmin or seasonaledd or monthlybinpr. 
#' @param daily_seasonal_climate string. 

growing_season_identifier <- function(region, weather.name = "seasonaltasmin", daily_seasonal_climate="tasmin"){

	gs_out = process_growing_season(region)
	if (daily_seasonal_climate == 'tasmin') {
		if (length(gs_out$ind) <= 5) {
			season = "summer"
		} else if(length(gs_out$ind) == 6 | length(gs_out$ind) == 7) {
			season = "summer"
		} else if(length(gs_out$ind) >= 8) {
			season = "winter"
		}
	} else {
		if (length(gs_out$ind) <= 5) {
			season = "summer"
		} else if(length(gs_out$ind) == 6 | length(gs_out$ind) == 7) {
			season = "fall"
		} else if(length(gs_out$ind) >= 8) {
			season = c("winter", "fall")
		}
	}

	return(season)
}

#' applies growing_season_identifier over regions.
#' returns a list of regions of growing_season_identifier returned values.
#' @param regions character vector.

mapply_gs_identifier <- function(regions, ...){
	vect = expand.grid(regions=regions)
	kwargs = list(...)
	dslist = mapply(FUN=growing_season_identifier, region=paste(vect[,'regions']), MoreArgs=kwargs, SIMPLIFY=FALSE)
	
	#ds = narray::stack(dslist, along=1)
	return(dslist)
}


#' returns the month of a day 
#' @param day integer, falling in the interval ]0, 365]
#' @return integer, falling in the sequence {0-12}.
day_to_month_collapser <- function(day) {

	if(day<=0 | day>365) stop("day should be falling in the interval ]0, 365]")

	return(ceiling(day/30.4167)) #replicating the projection system. Check it out : https://gitlab.com/ClimateImpactLab/Impacts/impact-calculations/-/blob/master/climate/discover.py#L556

}
# NOTE: because delta-beta table for edds show different values than what its histogram shows 
# (total growing season degree days vs. daily temperature), edd.collapse and bin.clim must be separate in Ag.
#' @param clim array. Weather data for the given year: year
#' @param clim_next array. Weather data for year + 1 (mainly used to extract multi-year growing season data)
#' @param region character.
#' @param year integer.
#' @param TT_lower_bound integer. 
#' @param TT_upper_bound integer.
#' @param TT_step integer.
#' @param daily_seasonal_climate character. No need to change the default unless Ag ("edd" or "precip")
#' @param crop character. Set to "wheat-winter" if delta-beta's for winter wheat, otherwise, no need to change the default.
#' @param season character. Unless crop == "wheat-winter" don't change the default. If wheat-winter, can set it to "summer","fall","winter" (used in Ag only)
#' @param binnedstuff logical. Whether final array show counts or not (available for "precip" only).
#' @return array used for the histogram and the delta-beta table. (For edds, will return an array for the histogram only)
bin.clim <- function(clim, clim_next=NULL, region, year, TT_lower_bound=-23, TT_upper_bound=45, TT_step = 1, daily_seasonal_climate = '',crop='', season='', binnedstuff=TRUE, ...){
	if (daily_seasonal_climate == 'edd') {
		if (crop == "wheat-winter") {
			gs_out = process_growing_season(region,...)
			clim <- clim[,region,paste(year),drop=F]
			clim = clim/(length(gs_out$ind)*30.4167) # converting total gs edds to daily average edds (due to the initial structure of the data).

		} else {
			gs = get_growing_season(region, gs_file, time_scale='daily', ...)
			if (gs[1] > gs[2]) {	
				ind = c(seq(gs[1],365), seq(1, gs[2]))
				multiyear = seq(1, gs[2])		
				clim = clim[paste0('X',ind),,,drop=F]
				clim_next = clim_next[paste0('X',ind),,,drop=F]
				clim = stack(clim, clim_next, along=1)
				clim = apply(FUN=sum, X=clim, MARGIN=c(1,3),na.rm=TRUE)

			} else {	
				ind = seq(floor(gs[1]), ceiling(gs[2]))
				multiyear = NULL
				clim = clim[paste0('X',ind),,,drop=F]
			}
		}
		TT=seq(TT_lower_bound, TT_upper_bound, TT_step)
		h = hist(clim[,region,toString(year)], breaks = TT, include.lowest=TRUE, plot=FALSE)
		if (crop == "wheat-winter") {
			h$counts <- h$counts*(length(gs_out$ind)*30.4167)
		}
		ds = array(h$counts,dim=c(length(h$counts),1,1),dimnames=list(h$mids,year,region))
		
		return(ds)
	} else if (daily_seasonal_climate == 'precip') {
		TT=seq(TT_lower_bound, TT_upper_bound, TT_step)
		if (crop == "wheat-winter"){
			h = hist(clim["monthbinpr_bin1",region,toString(year)], breaks = TT, include.lowest=TRUE, plot=FALSE)
		} else {
			h = hist(clim[,region,toString(year)], breaks = TT, include.lowest=TRUE, plot=FALSE)
		}
		ds = array(h$counts,dim=c(length(h$counts),1,1),dimnames=list(h$mids,year,region))
		ind <- c(which(ds!=0))
		clim<-clim[,region,paste(year),drop=FALSE] 
		if (!binnedstuff) ds[ind[1], ind[2], ind[3]] <- as.numeric(clim)
		
		return(ds)
	} else {

		TT=seq(TT_lower_bound, TT_upper_bound, TT_step)
		h = hist(clim[,region,toString(year)], breaks = TT, include.lowest=TRUE, plot=FALSE)
		ds = array(h$counts,dim=c(length(h$counts),1,1),dimnames=list(h$mids,year,region))
		return(ds) 

	}

}

bound_to_hist <- function(region,years,binclim,...){
	yearlist = list()
	for (year in years) {
		index = binclim[,toString(year),region] > 0
		yearlist[[toString(year)]] = c(min(as.numeric(dimnames(binclim)[[1]][index])), max(as.numeric(dimnames(binclim)[[1]][index])))
	}
	return(yearlist)
}

mapply_bound_to_hist <- function(regions, ...){
	kwargs= list(...)
	ds = mapply(region=regions,FUN=bound_to_hist,MoreArgs=kwargs,SIMPLIFY=FALSE)
	return(ds)
}

#' @param regions character vector.
#' @param years integer vector.
#' @return a list of regions over years of bin.clim returned values.
mapply_bin_clim <- function(regions,years,...){
	vect = expand.grid(regions=regions, years=years)
	kwargs = list(...)
	dslist = mapply(FUN=bin.clim, region=paste(vect[,'regions']), year=vect[,'years'],MoreArgs=kwargs, SIMPLIFY=FALSE)
	ds = narray::stack(dslist, along=1)
	return(ds)
}

plot_hist <- function(region, binclim, h.tempcol=1, h.valuecol=3, h.yearcol=2, x.lim=c(-15,60), 
	hist.breaks = seq(0, 60, by = 20), hist.y.lim=c(0,70), hist.y.lab = "Number of days", 
	hist.x.lab = "Daily temperature (C)", colors = rev(c("#ff6961","#FBC17D", "#81176D")), 
	alpha=0.8, h.margin=c(.05,.25,.25,.25),...) {
	
	df = reshape2::melt(binclim[,,region]) %>% mutate_all(function(x) as.numeric(as.character(x)))
	
	ggplot(data = df) +
		geom_bar(aes(x = df[,h.tempcol], y = df[,'value'], fill=factor(df[,h.yearcol])), 
			stat="identity", position="dodge", alpha = alpha, orientation = "x") + 
		theme_minimal() +
		scale_x_continuous(expand=c(0, 0)) + 
		scale_y_continuous(expand=c(0, 0), breaks = hist.breaks) + 
		ylab(hist.y.lab) + xlab(hist.x.lab) +
		coord_cartesian(xlim = x.lim, ylim=hist.y.lim)  + 
		scale_fill_manual(values = colors, name="Year") +
		theme( legend.position="none",
					panel.grid.major = element_blank(), 
					panel.grid.minor = element_blank(),
					panel.background = element_blank(),
					panel.border = element_rect(colour = "black", fill=NA, size=1),
					plot.margin = unit(h.margin, "in"))

}

plot_curve = function(region, curve_ds,  y.lim=NULL, c.tempcol=1, c.valuecol=4, c.yearcol=2, x.lim=c(-15,60), colors=rev(c("#faafaf","#ff6961","#FBC17D", "#81176D")), c.margin=c(.25,.25,0,.25),bounds=NULL, y.lab="Change in deaths / 100,000", ...) {
	kwargs = list(...)
	if (typeof(curve_ds)=='list') {
		curve_ds = curve_ds[[region]]
	}
	df = melt(curve_ds[,,region, drop=F])
	colnames(df)[c.yearcol] <- "year"
	colnames(df)[c.tempcol] <- "temp"
	if(length(unique(df$year)) > 1) {
		sort.list = c(paste0(kwargs[['base_year']],'_NA'), paste(kwargs[['years']]))
		if (T %in% grepl('IA', unique(df$year))){
			sort.list = c(sort.list,paste0(kwargs[['years']],'_IA'))
		} 
		if (T %in% grepl('TA', unique(df$year))){
			sort.list = c(sort.list,paste0(kwargs[['years']],'_TA'))
		}
		df$year = gdata::reorder.factor(df$year,new.order=sort.list)
		df = df %>% arrange(year)
	}
	if (!is.null(bounds)) {
		dflist = list()
		for (year in names(bounds[[region]])) {
			dflist[[year]] = df %>% dplyr::filter(  temp > floor((bounds[[region]][[year]][1])) &
													temp < ceiling((bounds[[region]][[year]][2])) & 
													year == as.numeric(year))
		}
		df = bind_rows(dflist)
	}
	ggplot(data=df, aes(x = as.numeric(df[,c.tempcol]), y = df[,'value'], group = df[,c.yearcol])) +
		geom_line(aes(colour=factor(df[,c.yearcol])), size = 1.5) +
		geom_hline(yintercept=0, size=.2) + #zeroline
		theme_minimal() + #display min/max change in impacts for that year in caption) 
		ylab(y.lab) +
		coord_cartesian(ylim = y.lim,xlim = x.lim)  +
		scale_x_continuous(expand=c(0, 0)) +
		scale_linetype_discrete(name=NULL) +
		scale_color_manual(values = colors, name="Year") +
		theme(legend.justification=c(0,1), 
					legend.position=c(0.05, 0.95),
					panel.grid.major = element_blank(), 
					panel.grid.minor = element_blank(),
					panel.background = element_blank(),
					axis.title.x = element_blank(),
					panel.border = element_rect(colour = "black", fill=NA, size=1),
					plot.margin = unit(c.margin, "in"))
}

yellow_purple <- function(region, curve_plot, hist_plot, mat=rbind(c(1,1),c(1,1),c(2,2)), location.dict=NULL,...) {
	plist = list('curve'=curve_plot, 'hist'=hist_plot)
	if (is.null(location.dict) | is.null(location.dict[[region]])) {
		location.dict= list()
		location.dict[[region]] = region
	}
	plot = plot_grid(plotlist=plist, align = "v", nrow = 2, rel_heights = c(2/3, 1/3))
	title <- ggdraw() + draw_label(location.dict[[region]], fontface='bold')
	plot = plot_grid(title, plot, ncol=1, rel_heights=c(0.05, 1))
	# plot = arrangeGrob(grobs = plist,layout_matrix = mat,top=location.dict[[region]], widths)
	return(plot)
}

mapply_plot_curve <- function(regions, ...){
	kwargs= list(...)
	ds = mapply(region=regions,FUN=plot_curve,MoreArgs=kwargs,SIMPLIFY=FALSE)
}

mapply_plot_hist <- function(regions, ...){
	kwargs= list(...)
	ds = mapply(region=regions,FUN=plot_hist,MoreArgs=kwargs, SIMPLIFY=FALSE)
}

mapply_yellow_purple <- function(regions, curve_plots, hist_plots, kwargs=NULL, ...) {
	kwargs= list(...)
	ds = mapply(region=regions,curve_plot=curve_plots, hist_plot=hist_plots, FUN=yellow_purple, MoreArgs=kwargs, SIMPLIFY=FALSE)
}

yp_matrix <- function(yp, export.path, ne='matrix', mat.file='matrix_plot', matrix.mat=rbind(c(1,2,3),c(4,5,6)), width=12, height=12, page.title=NULL, suffix='', preface = 'yellow-purple_', ...) {
	kwargs = list(...)
	plot = marrangeGrob(grobs = yp, layout_matrix = matrix.mat, top=page.title)
	ggsave(paste0(export.path,preface,mat.file,suffix,".pdf"),plot=plot, width=width, height=height, units='in')
}

mapply_delta_beta <- function(regions, years, ...){
	vect = expand.grid(regions=regions, years=years)
	kwargs = list(...)
	dslist = mapply(FUN=delta_beta, region=paste(vect[,'regions']), year=vect[,'years'], MoreArgs=kwargs, SIMPLIFY=FALSE)
	return(dslist)
}

mapply_responses <- function(regions, years,...){
	vect = expand.grid(regions=regions, years=years)
	kwargs = list(...)
	rplist = mapply(FUN=get_TA_responses, region=paste(vect[,'regions']), year=vect[,'years'], MoreArgs=kwargs, SIMPLIFY=FALSE)
	responses = rbindlist(rplist)
	return(responses)
}

standard_delta_beta <- function(region, curve_ds, binclim, year, base_year, rnd.digits = 2, drop_zero_bins = T, rel.20 = T, bin=NULL, ...) {
	dims = dimnames(binclim)[[1]]
	FA_effect_y = curve_ds[dims,paste0(year),region]*binclim[dims,paste(year),]
	IA_effect_y = curve_ds[dims,paste0(year,'_IA'),region]*binclim[dims,paste(year),]
	IA_effect_by = curve_ds[dims,paste0(year,'_IA'),region]*binclim[dims,paste(base_year),]
	NA_effect_y = curve_ds[dims,paste0(base_year,'_NA'),region]*binclim[dims,paste(year),]
	NA_effect_by = curve_ds[dims,paste0(base_year,'_NA'),region]*binclim[dims,paste(base_year),]
	if (is.null(bin)) {
		diff = mean(diff(as.numeric(dimnames(binclim)[[1]])))/2
		bin = paste0('(',as.numeric(dimnames(binclim)[[1]])-diff,',',as.numeric(dimnames(binclim)[[1]])+diff,']')		
	}
	deltabeta = data.frame( list(
			bin=bin,
			T_y = binclim[dims,paste(year),],
			T_by = binclim[dims,paste(base_year),],
			T_diff = binclim[dims,paste(year),] - binclim[dims,paste(base_year),],
			beta_fa = curve_ds[dims,paste0(year),region],
			beta_ia = curve_ds[dims,paste0(year,'_IA'),region],
			beta_na = curve_ds[dims,paste0(base_year,'_NA'),region],
			effect_fa = FA_effect_y - IA_effect_by,
			effect_ia = IA_effect_y - IA_effect_by,
			effect_na = NA_effect_y - NA_effect_by
		) , stringsAsFactors=F
	)

	# rounding
	deltabeta[,colnames(deltabeta)[grepl('T_',colnames(deltabeta))]] = round(deltabeta[,colnames(deltabeta)[grepl('T_',colnames(deltabeta))]], digits = 0 )
	deltabeta[,colnames(deltabeta)[grepl('beta_',colnames(deltabeta))]] = round(deltabeta[,colnames(deltabeta)[grepl('beta_',colnames(deltabeta))]], digits = rnd.digits )
	deltabeta[,colnames(deltabeta)[grepl('effect_',colnames(deltabeta))]] = round(deltabeta[,colnames(deltabeta)[grepl('effect_',colnames(deltabeta))]], digits = 2 )

	under20 = round( apply(deltabeta[which(as.numeric(rownames(deltabeta)) < 20),(ncol(deltabeta)-2):ncol(deltabeta)],2,sum), digits = 2)
	over20 = round( apply(deltabeta[which(as.numeric(rownames(deltabeta)) > 20),(ncol(deltabeta)-2):ncol(deltabeta)],2,sum), digits = 2)
	total = round( apply(deltabeta[,(ncol(deltabeta)-2):ncol(deltabeta)],2,sum), digits = 2)

	if (drop_zero_bins == T) {
		deltabeta = dplyr::filter(deltabeta,(T_y > 0 | T_by > 0 | T_y < 0 | T_by < 0))
	}
	if (rel.20==T) {
		df = bind_rows(under20, over20, total) %>% 
			data.frame(bin=as.character(c('Total <20C', 'Total >20C', 'Total')), stringsAsFactors=F) 
	} else {
		df = bind_rows( total) %>% 
			data.frame(bin=as.character(c('Total')), stringsAsFactors=F) 
	}
	
	db_table = bind_rows(deltabeta,df) %>%
				mutate_all(as.character) %>% 
				mutate_all(~ if_else(is.na(.x),'',.x))
	colnames(db_table)= c( 'bin', paste0('T[',year,']'), paste0('T[',base_year,']'), 'T[diff]',
							'beta^F', 'beta^I', 'beta^N',
							paste0('beta^F*T[',year,']-beta^I*T[',base_year,']'),
							paste0('beta^I*T[',year,']-beta^I*T[',base_year,']'),
							paste0('beta^N*T[',year,']-beta^N*T[',base_year,']')) 
	return(db_table)
}


delta_beta_TA <- function(region, curve_ds, binclim, year, base_year, rnd.digits = 2, drop_zero_bins = T, rel.20 = T, bin=NULL, ...) {

	dims = dimnames(binclim)[[1]]

		FA_effect_y = curve_ds[dims,paste0(year),region]*binclim[dims,paste(year),]
		IA_effect_y = curve_ds[dims,paste0(year,'_IA'),region]*binclim[dims,paste(year),]
		IA_effect_by = curve_ds[dims,paste0(year,'_IA'),region]*binclim[dims,paste(base_year),]
		TA_effect_y = curve_ds[dims,paste0(year,'_TA'),region]*binclim[dims,paste(year),]
		TA_effect_by = curve_ds[dims,paste0(year,'_TA'),region]*binclim[dims,paste(base_year),]
		NA_effect_y = curve_ds[dims,paste0(base_year,'_NA'),region]*binclim[dims,paste(year),]
		NA_effect_by = curve_ds[dims,paste0(base_year,'_NA'),region]*binclim[dims,paste(base_year),]



	if (is.null(bin)) {
		diff = mean(diff(as.numeric(dimnames(binclim)[[1]])))/2
		bin = paste0('(',as.numeric(dimnames(binclim)[[1]])-diff,',',as.numeric(dimnames(binclim)[[1]])+diff,']')		
	}

	deltabeta = data.frame( list(
			bin=bin,
			T_y = binclim[dims,paste(year),],
			T_by = binclim[dims,paste(base_year),],
			T_diff = binclim[dims,paste(year),] - binclim[dims,paste(base_year),],
			beta_fa = curve_ds[dims,paste0(year),region],
			beta_ta = curve_ds[dims,paste0(year,'_TA'),region],
			beta_ia = curve_ds[dims,paste0(year,'_IA'),region],
			beta_na = curve_ds[dims,paste0(base_year,'_NA'),region],
			effect_fa = FA_effect_y,			
			effect_fa = FA_effect_y - IA_effect_by,
			effect_ta = TA_effect_y - IA_effect_by,
			effect_ia = IA_effect_y - IA_effect_by,
			effect_na = NA_effect_y - NA_effect_by
		) , stringsAsFactors=F
	)

	# rounding
	deltabeta[,colnames(deltabeta)[grepl('T_',colnames(deltabeta))]] = round(deltabeta[,colnames(deltabeta)[grepl('T_',colnames(deltabeta))]], digits = 0 )
	deltabeta[,colnames(deltabeta)[grepl('beta_',colnames(deltabeta))]] = round(deltabeta[,colnames(deltabeta)[grepl('beta_',colnames(deltabeta))]], digits = rnd.digits )
	deltabeta[,colnames(deltabeta)[grepl('effect_',colnames(deltabeta))]] = round(deltabeta[,colnames(deltabeta)[grepl('effect_',colnames(deltabeta))]], digits = 2 )

	under20 = round( apply(deltabeta[which(as.numeric(rownames(deltabeta)) < 20),(ncol(deltabeta)-2):ncol(deltabeta)],2,sum), digits = 2)
	over20 = round( apply(deltabeta[which(as.numeric(rownames(deltabeta)) > 20),(ncol(deltabeta)-2):ncol(deltabeta)],2,sum), digits = 2)
	total = round( apply(deltabeta[,(ncol(deltabeta)-4):ncol(deltabeta)],2,sum), digits = 2)

	if (drop_zero_bins == T) {
		deltabeta = dplyr::filter(deltabeta,(T_y > 0 | T_by > 0 | T_y < 0 | T_by < 0))
	}
	if (rel.20==T) {
		df = bind_rows(under20, over20, total) %>% 
			data.frame(bin=as.character(c('Total <20C', 'Total >20C', 'Total')), stringsAsFactors=F) 
	} else {
		df = bind_rows( total) %>% 
			data.frame(bin=as.character(c('Total')), stringsAsFactors=F) 
	}
	
	db_table = bind_rows(deltabeta,df) %>%
				mutate_all(as.character) %>% 
				mutate_all(~ if_else(is.na(.x),'',.x))
	colnames(db_table)= c('bin', paste0('T[',year,']'), paste0('T[',base_year,']'), 'T[diff]',
							'beta^F','beta^T', 'beta^I', 'beta^N',paste0('beta^F*T[',year,']'),
							paste0('beta^F*T[',year,']-beta^I*T[',base_year,']'),
							paste0('beta^T*T[',year,']-beta^I*T[',base_year,']'),
							paste0('beta^I*T[',year,']-beta^I*T[',base_year,']'),
							paste0('beta^N*T[',year,']-beta^N*T[',base_year,']')) 
	return(db_table)
}

delta_beta_TA_responses <- function(region, curve_ds, binclim, year, base_year, rnd.digits = 2, drop_zero_bins = T, rel.20 = T, bin=NULL, ...){

	dims = dimnames(binclim)[[1]]
	FA_effect_y = curve_ds[dims,paste0(year),region]*binclim[dims,paste(year),]
	TA_effect_y = curve_ds[dims,paste0(year,'_TA'),region]*binclim[dims,paste(year),]
	IA_effect_y = curve_ds[dims,paste0(year,'_IA'),region]*binclim[dims,paste(year),]
	#NA_effect_y = curve_ds[dims,paste0(base_year,'_NA'),region]*binclim[dims,paste(year),]

	responses = data.table(region=region, year=year,full=sum(FA_effect_y),tbar=sum(TA_effect_y),inc=sum(IA_effect_y))

	return(responses)
}

delta_beta_fa_only <- function(region, curve_ds, binclim, year, base_year, rnd.digits = 2, drop_zero_bins = T, rel.20 = T, bin=NULL, ...) {
	dims = dimnames(binclim)[[1]]
	FA_effect_y = curve_ds[dims,paste0(year),region]*binclim[dims,paste(year),]
	IA_effect_y = curve_ds[dims,paste0(year,'_IA'),region]*binclim[dims,paste(year),]
	IA_effect_by = curve_ds[dims,paste0(year,'_IA'),region]*binclim[dims,paste(base_year),]
	NA_effect_y = curve_ds[dims,paste0(base_year,'_NA'),region]*binclim[dims,paste(year),]
	NA_effect_by = curve_ds[dims,paste0(base_year,'_NA'),region]*binclim[dims,paste(base_year),]
	if (is.null(bin)) {
		diff = mean(diff(as.numeric(dimnames(binclim)[[1]])))/2
		bin = paste0('(',as.numeric(dimnames(binclim)[[1]])-diff,',',as.numeric(dimnames(binclim)[[1]])+diff,']')		
	}
	deltabeta = data.frame( list(
			bin=bin,
			T_y = binclim[dims,paste(year),],
			T_by = binclim[dims,paste(base_year),],
			T_diff = binclim[dims,paste(year),] - binclim[dims,paste(base_year),],
			beta_fa = curve_ds[dims,paste0(year),region],
			beta_ia = curve_ds[dims,paste0(year,'_IA'),region],
			beta_na = curve_ds[dims,paste0(base_year,'_NA'),region],
			effect_fa = FA_effect_y,
			effect_ia = IA_effect_by,
			effect_total = FA_effect_y - IA_effect_by
		) , stringsAsFactors=F
	)

	# rounding
	deltabeta[,colnames(deltabeta)[grepl('T_',colnames(deltabeta))]] = round(deltabeta[,colnames(deltabeta)[grepl('T_',colnames(deltabeta))]], digits = 0 )
	deltabeta[,colnames(deltabeta)[grepl('beta_',colnames(deltabeta))]] = round(deltabeta[,colnames(deltabeta)[grepl('beta_',colnames(deltabeta))]], digits = rnd.digits )
	deltabeta[,colnames(deltabeta)[grepl('effect_',colnames(deltabeta))]] = round(deltabeta[,colnames(deltabeta)[grepl('effect_',colnames(deltabeta))]], digits = 2 )

	under20 = round( apply(deltabeta[which(as.numeric(rownames(deltabeta)) < 20),(ncol(deltabeta)-2):ncol(deltabeta)],2,sum), digits = 2)
	over20 = round( apply(deltabeta[which(as.numeric(rownames(deltabeta)) > 20),(ncol(deltabeta)-2):ncol(deltabeta)],2,sum), digits = 2)
	total = round( apply(deltabeta[,(ncol(deltabeta)-2):ncol(deltabeta)],2,sum), digits = 2)

	if (drop_zero_bins == T) {
		deltabeta = dplyr::filter(deltabeta,(T_y > 0 | T_by > 0 | T_y < 0 | T_by < 0))
	}
	if (rel.20==T) {
		df = bind_rows(under20, over20, total) %>% 
			data.frame(bin=as.character(c('Total <20C', 'Total >20C', 'Total')), stringsAsFactors=F) 
	} else {
		df = bind_rows( total) %>% 
			data.frame(bin=as.character(c('Total')), stringsAsFactors=F) 
	}
	
	db_table = bind_rows(deltabeta,df) %>%
				mutate_all(as.character) %>% 
				mutate_all(~ if_else(is.na(.x),'',.x))
	colnames(db_table)= c( 'bin', paste0('T[',year,']'), paste0('T[',base_year,']'), 'T[diff]',
							'beta^F', 'beta^I', 'beta^N',
							paste0('beta^F*T[',year,']'),
							paste0('beta^I*T[',base_year,']'),
							paste0('beta^F*T[',year,']-beta^I*T[',base_year,']')) 
	return(db_table)
}

get_TA_responses <- function(region, year, base_year, curve_ds, binclim, export.path,covars, covarkey, add.cov.table=F, return.db = F, db.suffix='', db.prefix='deltabeta_',  db.height=10, db.width=16, append.results=F,weather=NULL, ...){

	if(!is.null(weather)){
		covars = data.table(covars)
		covars = covars[order(year, region)]
		weather = weather[order(year, region)]
		weather = weather[,c('region', 'year'):=NULL]
		covars = cbind(covars, weather)
	}

	curve_ds = curve_ds[,,region,drop=F]
	binclim = binclim[,,region,drop=F]
	responses = delta_beta_TA_responses(region, curve_ds, binclim, year, base_year, ...)

	return(responses)
}

delta_beta <- function(region, year, base_year, curve_ds, binclim, yp, export.path, db.style=standard_delta_beta,covars, covarkey, add.cov.table=F, return.db = F, db.suffix='', db.prefix='deltabeta_',  db.height=10, db.width=16, append.results=F,weather=NULL, csv=TRUE, ...){
	
	if(!is.null(weather)){
		covars = data.table(covars)
		covars = covars[order(year, region)]
		weather = weather[order(year, region)]
		weather = weather[,c('region', 'year'):=NULL]
		covars = cbind(covars, weather)
	}

	curve_ds = curve_ds[,,region,drop=F]
	binclim = binclim[,,region,drop=F]
	db_table = db.style(region, curve_ds, binclim, year, base_year, ...)

	too_big = sum(grepl("-", names(db_table)))>3
	font_scale = ifelse(too_big,0.6,1)
	col_scale = ifelse(too_big,0.75,1)

	split_db = split.deltabeta(deltabeta=db_table, covarkey = covarkey, font_scale=font_scale, col_scale=col_scale, ...)
	plots = list()
	for (ii in seq(1,length(split_db))) {
		if (add.cov.table==T & append.results==T) {
			impacts = get_impacts(region, year, base_year, return.table = T, ...)
			ct = covar.table(covars, region, covarkey)
			ct = plot_grid(ct, impacts, nrow = 1, rel_widths = c(1,1))
			ct = plot_grid(split_db[[ii]], ct, nrow = 2, rel_heights = c(1,1))
			pp = plot_grid(ct,yp[[region]], nrow = 1, rel_widths = c(3/5, 2/5))			
		} else if (add.cov.table==T & append.results==F) {
			ct = covar.table(covars, region, covarkey)
			ct = plot_grid(split_db[[ii]], ct, nrow=2, rel_heights = c(1,1))
			pp = plot_grid(ct,yp[[region]], nrow = 1, rel_widths = c(3/5, 2/5))
		} else if (add.cov.table==F & append.results==T) {
			impacts = get_impacts(region, year, base_year, return.table = T, ...)
			ct = plot_grid(split_db[[ii]], impacts, nrow=2, rel_heights = c(1,1))
			pp = plot_grid(ct,yp[[region]], nrow = 1, rel_widths = c(3/5, 2/5))
		} else {
			pp = plot_grid(split_db[[ii]],yp[[region]], nrow = 1, rel_widths = c(3/5, 2/5))
		}
		
		plots = rlist::list.append(plots, pp)
	}
	plot = marrangeGrob(grobs = plots, nrow=1,ncol=1)
	if (return.db == T) {
		return(plot)
	} else {
		ggsave(paste0(export.path,db.prefix,region,'-',year,db.suffix,".pdf"), plot=plot, width=db.width, height=db.height, units='in')
		if (csv) write.csv(db_table, paste0(export.path,db.prefix,region,'-',year,db.suffix,".csv"))
	}
	
}


check_responses <- function(check=FALSE,computed,region, yr, impacts.dir, impacts.name, impacts.var, suf){
	
	netcdf = glue("{impacts.dir}{impacts.name}{suf}")
	nc <- nc_open(netcdf)

	value = ncvar_get(nc, impacts.var)
	dimnames(value) = list(regions=c(ncvar_get(nc, "regions")),year=c(ncvar_get(nc, "year")))
	done = as.data.table(as.table(t(value)))
	setnames(done,'N','value')
	done = done[regions==region & year==yr]
	if (check){
		stopifnot(done[,value]==computed)

	}
	return(done)

}

get_impacts <- function(region, year, impacts.dir, impacts.name, impacts.var, return.table=F, add_incadapt=T, font_scale=0.7,col_scale=2.1,...) {
	# impacts.var = sym(impacts.var)
	yr = year
	impacts = list()

	ifelse(add_incadapt, suflist <- list('fulladapt' = "", 'incadapt' = "-incadapt", 'histclim' = "-histclim"), suflist <- list('fulladapt' = "", 'histclim' = "-histclim"))

	for (scn in names(suflist)){

		impacts[[scn]] = nc_to_DT(nc_file=paste0(impacts.dir,impacts.name,suflist[[scn]],'.nc4'), impact_var=impacts.var, to.data.frame=TRUE, print.nc=FALSE) %>% 
			dplyr::select(regions='region', year, impacts = impacts.var) %>%
			dplyr::filter(regions == region) %>%
			dplyr::filter(year %in% c(yr, seq(2001,2010))) %>%
			dplyr::mutate(value = ifelse(year < 2015, 'rebase', 'response')) %>%
			group_by(value) %>%
			summarize(scn = mean(impacts)) %>%
			data.frame() %>%
			spread('value','scn') %>%
			dplyr::mutate(rebased_value = response - rebase) %>%
			data.table::melt(id=NULL) 
	}

	impacts = bind_rows(impacts, .id='scenario')
	impacts = impacts %>%
		spread('scenario','value') %>%
		arrange(match(variable, c('response','rebase','rebased_value'))) %>%
		mutate(fulladapt_impact = ifelse(variable=='rebased_value', fulladapt - histclim, NaN))

	if (return.table == T) {

		t1 <- ttheme_default(colhead=list(fg_params = list(parse=TRUE,fontface="bold",cex=font_scale)),
	    	core=list(
	        fg_params=list(fontface=c(rep("plain", dim(impacts)[1] ), "bold"),cex=font_scale),
	        bg_params = list(fill=rep_len(c("grey95", "grey90"),length.out=dim(impacts)[1] ),
	                         alpha = rep(c(1,1), dim(impacts)[1] ))
	        ))
		impacts[-1] = round(impacts[-1], digits=2)
		impacts = impacts %>%
			mutate_all(as.character) %>% 
			mutate_all(~ if_else(.x=='NaN','',.x))
		g = tableGrob(impacts, rows=NULL, theme=t1)
		g$widths <- unit(rep(1/11.5*col_scale, ncol(impacts)), "npc")

		return(g)
	} else {
		return(impacts)
	}


}

filter_col_val <- function(df, fld, sval) {
	df %>% dplyr::filter(.data[[fld]]==sval)
}


covar.table <- function(covars, region, covarkey, ...) {
	covarkey = sym(covarkey)
	c = covars %>% dplyr::filter( !!covarkey == !!region ) 
	c = c %>% dplyr::select(-(!!covarkey))
	ct = data.frame(t(c))
	names(ct) = as.character(unlist(ct[1,]))
	ct = ct[-1,]

	t1 <- ttheme_default(colhead=list(fg_params = list(parse=TRUE,fontface="bold")),
    	core=list(
        fg_params=list(fontface=c(rep("plain", dim(ct)[1] ), "bold")),
        bg_params = list(fill=rep_len(c("grey95", "grey90"),length.out=dim(ct)[1] ),
                         alpha = rep(c(1,1), dim(ct)[1] ))
        ))
	ct = round(ct, digits=2)
	ct = tibble::rownames_to_column(ct, "Covariate")
	g = tableGrob(ct, rows=NULL, theme=t1)
	return(g)

}



split.deltabeta <- function(font_scale=1, col_scale=1, deltabeta, rel.20 = T, total_rows_per_page = 30 , start_row = 1,  ...) {
	# if (nrow(deltabeta)==30) {
	# 	total_rows_per_page=27
	# }

	if (rel.20 == T) {
		rel = 3
	} else {
		rel = 1
	}
	while (mod(nrow(deltabeta),total_rows_per_page) <= rel) {
    		message("reformatting delta-beta rows...")
    		total_rows_per_page = total_rows_per_page - 1
	}
	split_db = list()
	# if (mod(nrow(deltabeta),total_rows_per_page)-rel <=0) { total_rows_per_page = total_rows_per_page-2 }
    t1 <- ttheme_default(rowhead=list(fg_params=list(cex=font_scale)),
    	colhead=list(fg_params = list(cex=font_scale,parse=TRUE,fontface="bold")),
    	core=list(
        fg_params=list(cex=font_scale,fontface=c(rep("plain", total_rows_per_page), "bold")),
        bg_params = list(fill=rep_len(c("grey95", "grey90"),length.out=total_rows_per_page),
                         alpha = rep(c(1,1), total_rows_per_page))
        ))
    t2 <- ttheme_default(rowhead=list(fg_params=list(cex=font_scale)),
    	colhead=list(fg_params = list(parse=TRUE, cex=font_scale)), 
    	core=list(
        fg_params=list(cex=font_scale,fontface=c(rep("plain", mod(nrow(deltabeta),total_rows_per_page)-rel), rep("bold", rel))),
        bg_params = list(fill=c(rep_len(c("grey95", "grey90"), length.out=mod(nrow(deltabeta),total_rows_per_page)-rel),rep("#B0D7FF", 3)),
                         alpha = rep(c(1,1), total_rows_per_page))
        ))



   	if(total_rows_per_page > nrow(deltabeta)){
         end_row = nrow(deltabeta)
    }else {
         end_row = total_rows_per_page 
    } 

    for(i in 1:ceiling(nrow(deltabeta)/total_rows_per_page)){
    	if (i == ceiling(nrow(deltabeta)/total_rows_per_page)) {
    		tt=t2
    	} else {
    		tt=t1
    	}
    	g = tableGrob(deltabeta[start_row:end_row, ], rows=NULL, theme=tt)
    	g = gtable_add_grob(g,
			grobs = rectGrob(gp = gpar(fill = NA, lwd = 2)),
			t = 2, b = nrow(g), l = 1, r = ncol(g))
		g = gtable_add_grob(g,
			grobs = rectGrob(gp = gpar(fill = NA, lwd = 2)),
			t = 1, l = 1, r = ncol(g))
		db.col = ncol(deltabeta)
		db.effects.col = sum(grepl("-", names(deltabeta)))
		g$widths <- unit(c(rep(1/11.5*col_scale, db.col-db.effects.col), c(rep(1.5/11.5*col_scale,db.effects.col))), "npc")
		split_db = rlist::list.append(split_db, g )
		start_row = end_row + 1

       if((total_rows_per_page + end_row) < nrow(deltabeta)){

            end_row = total_rows_per_page + end_row

		}else {

			end_row = nrow(deltabeta)
		}    
	}
	return(split_db)
}

generate_response_functions <- function(regions, years, base_year=2010, bounds=NULL, adapt='full', curve_ds = NULL, ...) {
	kwargs = list(...)
	all_years = sort(c(years, base_year))
	message('loading csvv...')
	csvv = read.csvv(filepath = paste0(csvv.dir,csvv.name),...)
	message('loading covariates...')
	covars = load.covariates(regions=regions, years=all_years, ...)
	message('drawing response functions...')
	message(paste0('scn: ',adapt))
	curve_ds = mapply_curve(regions=regions, years=years, csvv=csvv, covars=covars, curve_ds=curve_ds,  base_year=base_year, adapt=adapt, ...)
	return(curve_ds)
}



generate_yellow_purple <- function(regions, years, csvv.name, csvv.dir, base_year=2010,  bounds=NULL, inc.adapt=F, load.covariates=T, delta.beta=F, ...) {
	
	kwargs = list(...)
	all_years = sort(c(years, base_year))
	if (!is.null(csvv.name)){
	    message('loading csvv...')
	    csvv = read.csvv(filepath = paste0(csvv.dir,csvv.name), ...)
	} else{ csvv = NULL }
	message('loading covariates...')
	if (load.covariates==T) {
		covars = load.covariates(regions=regions, years=all_years, ...)
	} else { covars=NULL }
	message('loading climate data...')
	clim = mapply_extract_climate_data(years=all_years, ...)
	message('binning climate data...')
	binclim = mapply_bin_clim(regions=regions, years=all_years, clim=clim, ...)
	if (!is.null(kwargs[['bound_to_hist']])){
		if (kwargs[['bound_to_hist']]==T) {
			bounds = mapply_bound_to_hist(regions=regions, years=all_years, binclim=binclim)
		}
	}
	message('drawing response functions...')
	message('---full adapt')
	curve_ds = mapply_curve(regions=regions,years=years, csvv=csvv, covars=covars, base_year=base_year, ...)
	message('---no adapt')
	curve_ds = mapply_curve(regions=regions,years=years, csvv=csvv, covars=covars, curve_ds=curve_ds, adapt='no', base_year=base_year, ...)
	if (delta.beta==T) {
		inc.adapt = T
	}
	if (inc.adapt == T){
		message('---income adapt')
		curve_ds = mapply_curve(regions=regions, years=years, csvv=csvv, covars=covars, curve_ds=curve_ds, adapt='income', base_year=base_year, ...)
	}
	message('plotting...')
	curve_plots = mapply_plot_curve(regions=regions,curve_ds=curve_ds, bounds=bounds, years=years, base_year=base_year, ...)
	hist_plots = mapply_plot_hist(regions=regions,binclim=binclim, ...)
	yp = mapply_yellow_purple(regions=regions,curve_plots=curve_plots, hist_plots=hist_plots, ...)
	export.yp(yp=yp,regions=regions, ...)
	if (delta.beta==T) {
		message('delta-beta...')
		mapply_delta_beta(regions=regions, years=years, covars=covars, base_year=base_year, binclim=binclim, curve_ds=curve_ds, yp=yp, ...)
	}
	return(yp)
}

generate_yellow_purple_ag_tmin <- function(regions, years, csvv.name, csvv.dir, base_year=2010,  bounds=NULL, inc.adapt=F, load.covariates=T, delta.beta=F, gs_file=NULL, crop="non-wheat", season="growing_season", ...) {
	kwargs = list(...)
	all_years = sort(c(years, base_year))
	if (!is.null(csvv.name)){
	    message('loading csvv...')
	    csvv = read.csvv(filepath = paste0(csvv.dir,csvv.name), ...)
	} else { csvv = NULL }
	if (season != "summer" & crop == "wheat-winter") {
		gs <- mapply_gs_identifier(regions=regions, daily_seasonal_climate="tasmin")
		regions_to_remove <- c()
		for (i in 1:length(regions)) {
			if (gs[[i]] != season) {
				regions_to_remove <- c(regions_to_remove, names(gs[i]))
			}
		}
		message("---printing regions to remove")
		print(regions_to_remove)
		regions <- regions[!(regions %in% regions_to_remove)]
		message("---printing regions after removing regions that don't have enough months")
		print(regions)
		if (length(regions) == 0) { stop("THERE IS NO REGION IN THE LIST THAT HAS ENOUGH MONTHS OF GROWING SEASON TO PRODUCE YELLOW PURPLES.")}
	}
	message('loading covariates...')
	if (load.covariates==T) {
		covars = load.covariates(regions=regions, years=all_years, ...)
	} else { covars=NULL }
	message('loading climate data...')
	if (crop == "wheat-winter"){
		clim = mapply_extract_climate_data(years=all_years, climate_func=extract_ready_weather_data, crop=crop, season = season, weather.name = "seasonaltasmin", ...)
		clim_next = mapply_extract_climate_data(years=all_years+1,climate_func=extract_ready_weather_data, crop=crop, season=season, weather.name = "seasonaltasmin", ...)
	}
	else {
		clim = mapply_extract_climate_data(years=all_years, ...) #daily minimum temperature X REGIONS X DAYS X YEARS
		clim_next = mapply_extract_climate_data(years=all_years+1, ...)
	}
	clim = clim[,regions,,drop=F]
	clim_next = clim_next[,regions,,drop=F]
	message('binning climate data...')
	binclim = mapply_tmin_collapse(regions=regions, years=all_years, clim=clim, clim_next=clim_next, crop=crop, MoreArgs=c(kwargs, list(bin=FALSE)), SIMPLIFY=FALSE)

	if (!is.null(kwargs[['bound_to_hist']])){
		if (kwargs[['bound_to_hist']]==T) {
			bounds = mapply_bound_to_hist(regions=regions, years=all_years, binclim=binclim)
		}
	}

	message('drawing response functions...')
	message('---full adapt')
	curve_ds = mapply_curve(regions=regions,years=years, csvv=csvv, covars=covars, base_year=base_year, crop=crop, season=season, ...)
	message('---no adapt')
	curve_ds = mapply_curve(regions=regions,years=years, csvv=csvv, covars=covars, curve_ds=curve_ds, adapt='no', base_year=base_year, crop=crop, season=season, ...)
	if (delta.beta==T) {
		inc.adapt = T
	}
	if (inc.adapt == T){
		message('---income adapt')
		curve_ds = mapply_curve(regions=regions, years=years, csvv=csvv, covars=covars, curve_ds=curve_ds, adapt='income', base_year=base_year, crop=crop, season=season, ...)
	}
	message('plotting...')
	curve_plots = mapply_plot_curve(regions=regions,curve_ds=curve_ds, bounds=bounds, years=years, base_year=base_year, ...)
	hist_plots = mapply_plot_hist(regions=regions,binclim=binclim, ...)
	yp = mapply_yellow_purple(regions=regions,curve_plots=curve_plots, hist_plots=hist_plots, ...)
	export.yp(yp=yp,regions=regions, ...)

	if (delta.beta==T) {
		message('delta-beta...')
		ag_delta_beta_wrapper(regions=regions, years=years, csvv = csvv, covars = covars, base_year=base_year, yp=yp, crop=crop, season=season, ...)
	}
	return(yp)
}


generate_yellow_purple_ag_edd <- function(regions, years, base_year=2010, bounds=NULL, inc.adapt=F, load.covariates=T, delta.beta=F, interacted_weather=FALSE,weather=NULL,p.bins=NULL, tbar.adapt=FALSE, crop="non-wheat", season="growing_season",...) {
	kwargs = list(...)
	all_years = sort(c(years, base_year))
	if (season != "summer" & crop == "wheat-winter") {
		gs <- mapply_gs_identifier(regions=regions, daily_seasonal_climate="edd")
		regions_to_remove <- c()

		for (i in 1:length(regions)) {
			if (!any(grepl(paste0(season), gs[[i]]))) {
				regions_to_remove <- c(regions_to_remove, names(gs[i]))
			}
		}
		message("---printing regions to remove")
		print(regions_to_remove)
		regions <- regions[!(regions %in% regions_to_remove)]
		message("---printing regions after removing regions that don't have enough months")
		print(regions)
		if (length(regions) == 0) { stop("THERE IS NO REGION IN THE LIST THAT HAS ENOUGH MONTHS OF GROWING SEASON TO PRODUCE YELLOW PURPLES.")}
	}
	
	message('loading csvv...')
	csvv = read.csvv(filepath = paste0(csvv.dir,csvv.name),...)
	message('loading covariates...')
	if (load.covariates==T) {
		covars = load.covariates(regions=regions, years=all_years, ...)
	} else { covars=NULL }
	
	if (interacted_weather==TRUE){
		message('loading interacted precip...')
		precip = mapply_extract_climate_data(years=all_years, tas_value = 'pr', climate_func=extract_monthly_climate_data, ...)
		precip_next = mapply_extract_climate_data(years=all_years+1, tas_value = 'pr', climate_func=extract_monthly_climate_data, ...)
		precip2 = mapply_extract_climate_data(years=all_years, tas_value = 'pr-monthsum-poly-2', climate_func=extract_monthly_climate_data, ...)
		precip2_next = mapply_extract_climate_data(years=all_years+1, tas_value = 'pr-monthsum-poly-2', climate_func=extract_monthly_climate_data, ...)
		interacted_weather = list(mapply_ag_process_precip(regions=regions, clim=precip, clim_tp1=precip_next,p.bins=p.bins,all_years=all_years,...),
			mapply_ag_process_precip(regions=regions, clim=precip2, clim_tp1=precip2_next,p.bins=p.bins,all_years=all_years,...))
		interacted_weather = lapply(FUN=function(x) adrop.sel(x, omit=c(1,2,3)), X=interacted_weather)
		weather=interacted_weather[[1]]
		names(dimnames(weather)) = c('month', 'region', 'year')
		weather = data.table(plyr::adply(weather, c(1,2,3)))
		setnames(weather, old='V1', new='precip')	
		weather = weather[,.('precip'=sum(precip, na.rm=TRUE)), by=c('region', 'year')]
	}

	message('drawing response functions...')
	message('---full adapt')
	curve_ds = mapply_curve(regions=regions,years=years, csvv=csvv, covars=covars, base_year=base_year,interacted_weather=interacted_weather, crop=crop, season=season, ...)
	message('---no adapt')
	curve_ds = mapply_curve(regions=regions,years=years, csvv=csvv, covars=covars, curve_ds=curve_ds, adapt='no', base_year=base_year, interacted_weather=interacted_weather, crop=crop, season=season, ...)
	if (delta.beta==T) {
		inc.adapt = T
	}
	if (inc.adapt == T){
		message('---income adapt')
		curve_ds = mapply_curve(regions=regions, years=years, csvv=csvv, covars=covars, curve_ds=curve_ds, adapt='income', base_year=base_year,interacted_weather=interacted_weather, crop=crop, season=season, ...)
	}
	if (tbar.adapt==T){
		message('---income & tbar adapt')
		curve_ds = mapply_curve(regions=regions, years=years, csvv=csvv, covars=covars, curve_ds=curve_ds, adapt='tbar', base_year=base_year,interacted_weather=interacted_weather, crop=crop, season=season, ...)
	}
	message('plotting response function...')
	curve_plots = mapply_plot_curve(regions=regions,curve_ds=curve_ds, bounds=bounds, years=years, base_year=base_year, ...)
	message('loading climate data...')
	if (crop == "wheat-winter") {
		clim = mapply_extract_climate_data(years=all_years, climate_func=extract_ready_weather_data, weather.name="seasonaledd", crop=crop, season=season, ...)
		clim_next = mapply_extract_climate_data(years=all_years+1, climate_func=extract_ready_weather_data, weather.name="seasonaledd", crop=crop, season=season, ...)
	} else {
		clim = mapply_extract_climate_data(years=all_years, tas_value = 'tasmax', ...)
		clim_next = mapply_extract_climate_data(years=all_years+1, tas_value = 'tasmax', ...)
	}
	binclim = mapply_bin_clim(regions=regions, years=all_years, clim=clim, clim_next=clim_next, crop=crop, season=season, ...)
	message('plotting histogram...')	
	hist_plots = mapply_plot_hist(regions=regions,binclim=binclim, ...)
	yp = mapply_yellow_purple(regions=regions,curve_plots=curve_plots, hist_plots=hist_plots, ...)
	export.yp(yp=yp,regions=regions, ...)
	if (delta.beta==T) {
		message('delta-beta...')
		ag_delta_beta_wrapper(regions=regions, years=years, csvv = csvv, covars = covars, base_year=base_year, yp=yp, interacted_weather=interacted_weather,weather=weather,tbar.adapt=tbar.adapt, crop=crop, season=season,...)
		
	}
	
	return(yp)
}

generate_yellow_purple_ag_precip <- function(regions, years, p.bins=NULL, export.path=NULL, db.suffix=NULL, base_year=2010, bounds=NULL, inc.adapt=F, tbar.adapt=F, load.covariates=T, delta.beta=F, db.height=10, db.width=16, interacted_weather=FALSE, weather=NULL,crop="non-wheat",season="growing_season",...) {

	kwargs = list(...)
	all_years = sort(c(years, base_year))
	if (season != "summer" & crop == "wheat-winter") {
		gs <- mapply_gs_identifier(regions=regions, daily_seasonal_climate="edd")
		regions_to_remove <- c()
		for (i in 1:length(regions)) {
			if (!any(grepl(paste0(season), gs[[i]]))) {
				regions_to_remove <- c(regions_to_remove, names(gs[i]))
			}
		}
		message("---printing regions to remove")
		print(regions_to_remove)
		regions <- regions[!(regions %in% regions_to_remove)]
		message("---printing regions after removing regions that don't have enough months")
		print(regions)
		if (length(regions) == 0) { stop("THERE IS NO REGION IN THE LIST THAT HAS ENOUGH MONTHS OF GROWING SEASON TO PRODUCE YELLOW PURPLES.")}
	}
	message('loading csvv...')
	csvv = read.csvv(filepath = paste0(csvv.dir,csvv.name),...)
	message('loading covariates...')
	if (load.covariates==T) {
		covars = load.covariates(regions=regions, years=all_years, ...)
	} else {covars=NULL }
	if (interacted_weather==TRUE){
		message('loading interacted degree days...')
		int.edds = mapply_extract_climate_data(years=all_years, climate_func=extract_monthly_edd, ...)
		int.edds.next = mapply_extract_climate_data(years=all_years+1, climate_func=extract_monthly_edd, ...)
		kinks = c()
		pred.vars = unique(as.character(csvv$prednames))
		precip.vars = pred.vars[grepl("pr", pred.vars)]
		for (dd in c('gdd','kdd')) {
 			int.dd.vars = precip.vars[grepl( paste0(dd,"*"), precip.vars)][1]
			int.dd.kinks = as.numeric( unlist(strsplit(gsub("\\*.*","",int.dd.vars), '-'))[-1] )
			kinks = c(kinks,int.dd.kinks[1])
		}

		interacted_weather = mapply_edd_collapse(regions=regions, years=all_years, kinks=kinks, edds=int.edds, edds_next=int.edds.next, ...)
		weather = interacted_weather
		names(dimnames(weather)) = c('kink', 'year', 'region')
		weather = data.table(plyr::adply(weather, c(1,2,3)))
		setnames(weather, old='V1', new='edd')	
		tidyr::spread(weather, kink, edd)
		weather = dcast(weather, year + region ~ kink, value.var='edd')
		setnames(weather, paste(c('', '', 'gdd_', 'kdd_'),names(weather), sep=''))
	}
	message('loading climate data...')
	if (crop == "wheat-winter"){
		precip = mapply_extract_climate_data(years=all_years, climate_func=extract_ready_weather_data, crop=crop, season = season, weather.name = "monthbinpr", ...)
		precip_next = mapply_extract_climate_data(years=all_years+1,climate_func=extract_ready_weather_data, crop=crop, season=season, weather.name = "monthbinpr", ...)
	}else{
		precip = mapply_extract_climate_data(years=all_years, tas_value = 'pr', climate_func=extract_monthly_climate_data, ...)
		precip_next = mapply_extract_climate_data(years=all_years+1, tas_value = 'pr', climate_func=extract_monthly_climate_data, ...)
	}
	allclim = mapply_ag_process_precip(regions=regions, clim=precip, clim_tp1=precip_next,p.bins=p.bins,all_years=all_years,crop=crop,...)
	message('drawing response functions...')
	message('---full adapt')
	curve_ds_all = mapply_curve(regions=regions,years=years, csvv=csvv, covars=covars, base_year=base_year, climate.var = 'precip', p.bins=p.bins,interacted_weather=interacted_weather, crop=crop, season=season,return.betas=F,clim=allclim, ...)
	message('---no adapt')
	curve_ds_all = mapply_curve(regions=regions,years=years, csvv=csvv, covars=covars, curve_ds=curve_ds_all, adapt='no', base_year=base_year, climate.var = 'precip', p.bins=p.bins,interacted_weather=interacted_weather, crop=crop, season=season,return.betas=F,clim=allclim, ...)
	if (delta.beta==T) {
		inc.adapt = T
	}
	if (inc.adapt == T){
		message('---income adapt')
		curve_ds_all = mapply_curve(regions=regions, years=years, csvv=csvv, covars=covars, curve_ds=curve_ds_all, adapt='income', base_year=base_year, climate.var = 'precip', p.bins=p.bins,interacted_weather=interacted_weather, crop=crop, season=season,return.betas=F,clim=allclim, ...)
	}
	if (tbar.adapt==T){
		message('---income & tbar adapt')
		curve_ds_all = mapply_curve(regions=regions, years=years, csvv=csvv, covars=covars, curve_ds=curve_ds_all, adapt='tbar', base_year=base_year, climate.var = 'precip', p.bins=p.bins,interacted_weather=interacted_weather, crop=crop, season=season, return.betas=F,clim=allclim,...)

	}
	if (is.null(p.bins)) {
		p.bins  = as.numeric(unlist(dimnames(curve_ds_all)[4]))
	}

	message('plotting curves and delta beta')
	done = mapply_ag_yp_delta_beta_precip(regions=regions, p.bins=p.bins,interacted_weather=interacted_weather,
		allclim=allclim,curve_ds_all=curve_ds_all,all_years=all_years, bounds=bounds,years=years,base_year=base_year,
		delta.beta=delta.beta,covars=covars,db.suffix=db.suffix,db.height=db.height, db.width=db.width,export.path=export.path,weather=weather,binnedstuff=T, return.betas=F, crop=crop,...)

	return(done)

}


ag_process_precip <- function(region, clim, clim_tp1, p.bins=NULL,all_years, crop, ...) {
	gs = process_growing_season(region,...)
	ind = gs$ind
	multiyear=gs$multiyear
	b=1
	message('- precip bin ',b,' -')
	while (b > 0) {
		if (crop != "wheat-winter") {
			bb.ind = ind[seq(1:p.bins[b])]
			bb.ind = bb.ind[!is.na(bb.ind)]
		
			if (length(bb.ind[bb.ind %in% multiyear]) > 0) {
				bb.y2 = bb.ind[bb.ind %in% multiyear]
				bb.y1 = bb.ind[bb.ind %notin% multiyear]
				clim_y2 = aperm(clim_tp1[region,paste(bb.y2),, drop=F],c(2,1,3))
				dimnames(clim_y2)[[3]] = paste(all_years)
				if (length(bb.y1) > 0) {
					clim_y1 = aperm(clim[region,paste(bb.y1),, drop=F],c(2,1,3))
					allprecip = stack(clim_y1, clim_y2, along=1 )
				} else {
					allprecip = clim_y2
				}
			} else {
				allprecip = aperm(clim[region,paste(bb.ind),, drop=F],c(2,1,3))
			}
		} else {
			allprecip = aperm(clim[region,,, drop=F], c(2,1,3))
		}
		#this stage has monthbinpr, hierid, year

		if (b==1){
			allprecip_ls <- narray:::stack(allprecip)
		}
		else{
			allprecip <- narray:::stack(allprecip) #a weird trick to create the bin dimension
			allprecip_ls <- narray:::stack(allprecip_ls, allprecip, along=4)

		}
		#if nothing more remaining, end of while. 
		ind = ind[-seq(1:p.bins[b])]
		if (length(ind) > 0) {
			b = b + 1
		} else {
			b = 0
		}
	}

	N = length(dim(allprecip_ls))
	dimnames(allprecip_ls)[[N]] <- as.character(paste(seq(1:dim(allprecip_ls)[N])))
	return(allprecip_ls)

}

mapply_ag_process_precip <- function(regions, ...){
	kwargs = list(...)
	dslist = mapply(FUN=ag_process_precip, region=regions, MoreArgs=kwargs, SIMPLIFY=FALSE)
	ds = narray::stack(dslist, along=1)
	return(ds)
}

ag_yp_delta_beta_precip <- function(region, allclim, curve_ds_all,all_years,years, base_year,bounds,delta.beta,covars,p.bins,db.suffix,
	db.height, db.width,export.path, weather,...) {

	#here you need to have an array with each bin
	#you need to have a plot list 
	#and you need to loop over the bins
	regionclim  = narray::subset(allclim, index=region, along=2, drop=F) 
	gs = process_growing_season(region,...)
	ind = gs$ind
	multiyear=gs$multiyear
	b=1
	plots = list()
	while (b > 0) {	
		clim = narray::subset(regionclim, index=paste(b), along=4, drop=F)
		clim = adrop.sel(clim, omit=c(1,2,3))
		clim = narray::map(X=clim, along=1,FUN=function(x) x[!is.na(x)], drop=F)
		curve_ds = narray::flatten(curve_ds_all[,,region,b])
		curve_ds = array(curve_ds,dim=c(dim(curve_ds),1), dimnames= append(dimnames(curve_ds), region))
		message('binning climate data...')
		binclim = mapply_bin_clim(regions=region, years=all_years, clim=clim, ...)
		message('plotting...')
		curve_plots = mapply_plot_curve(regions=region,curve_ds=curve_ds, bounds=bounds, years=years, base_year=base_year, ...)
		hist_plots = mapply_plot_hist(regions=region,binclim=binclim, ...)
		yp = mapply_yellow_purple(regions=region,curve_plots=curve_plots, hist_plots=hist_plots, ...)
		suffix=paste0('_precip-bin',b)
		export.yp(yp=yp,regions=regions, suffix=suffix, export.path=export.path, ...)
		if (delta.beta==T) {
			message('delta-beta...')
			db = mapply_delta_beta(regions=region, years=years, base_year=base_year, binclim=binclim, curve_ds=curve_ds, yp=yp, return.db=T, covars = covars,weather=weather, ...)
			plots = rlist::list.append(plots, db)
		}
		ind = ind[-seq(1:p.bins[b])]
		if (length(ind) > 0) {
			b = b + 1
		} else {
			b = 0
		}
	}
	if (delta.beta==T) {
		plots = unlist(unlist(plots, recursive=F), recursive=F)
		plot = marrangeGrob(grobs = plots, top = quote(grid::textGrob(paste("Bin", g, "of", npages))), nrow=1,ncol=1)
		ggsave(paste0(export.path,region,'-',paste(years, sep='-'),'_precip',db.suffix,".pdf"), plot=plot, width=db.width, height=db.height, units='in')
	}

	return(glue('done for {region}'))

}

mapply_ag_yp_delta_beta_precip <- function(regions,...){
	kwargs = list(...)
	mapply(FUN=ag_yp_delta_beta_precip, region=regions, MoreArgs=kwargs, SIMPLIFY=FALSE)
}

#' A wrapper to produce delta betas for ag. 
ag_delta_beta_wrapper <- function(regions, years, csvv, covars, base_year,  yp,interacted_weather=FALSE, weather, tbar.adapt, daily_seasonal_climate = 'edd', crop, season, ...) {
	message('---running betas')
	if (daily_seasonal_climate == 'tasmin') {
		curve_ds = mapply_curve(regions=regions,years=years, csvv=csvv, covars=covars, base_year=base_year, return.betas=T, interacted_weather=interacted_weather, crop=crop, season=season,...)
		curve_ds = mapply_curve(regions=regions,years=years, csvv=csvv, covars=covars, curve_ds=curve_ds, adapt='no', base_year=base_year, return.betas=T, interacted_weather=interacted_weather,crop=crop,season=season,...)
		curve_ds = mapply_curve(regions=regions, years=years, csvv=csvv, covars=covars, curve_ds=curve_ds, adapt='income', base_year=base_year, return.betas=T, interacted_weather=interacted_weather,crop=crop,season=season, ...)
		if (tbar.adapt==T){
			message('---income & tbar adapt')
			curve_ds = mapply_curve(regions=regions, years=years, csvv=csvv, covars=covars, curve_ds=curve_ds, adapt='tbar', base_year=base_year, return.betas=T,interacted_weather=interacted_weather,crop=crop,season=season, ...)
		}
		all_years = sort(c(years, base_year))
		if (crop == "wheat-winter"){
			clim = mapply_extract_climate_data(years=all_years, climate_func=extract_ready_weather_data, crop=crop, season=season, weather.name="seasonaltasmin", ...)
			clim_next = mapply_extract_climate_data(years=all_years+1,climate_func=extract_ready_weather_data, crop=crop, season=season, weather.name="seasonaltasmin", ...)
		} else {
			clim = mapply_extract_climate_data(years=all_years, ...)
			clim_next = mapply_extract_climate_data(years=all_years+1, ...)
		}
		clim = clim[,regions,,drop=F]
		clim_next = clim_next[,regions,,drop=F]
		kwargs = list(...)
		kwargs = rlist::list.append(kwargs,clim=clim,clim_next=clim_next,years=all_years)
		if (crop == "wheat-winter") {
			binclim = mapply(FUN=mapply_tmin_collapse,regions=regions, crop=crop, MoreArgs=c(kwargs, list(bin=FALSE)), SIMPLIFY=FALSE)
		} else { binclim = mapply(FUN=mapply_tmin_collapse,regions=regions, crop=crop, MoreArgs=c(kwargs, list(bin=FALSE)), SIMPLIFY=FALSE) }
		binclim = narray::stack(binclim, along=1)
		mapply_delta_beta(regions=regions, years=years, base_year=base_year, binclim=binclim, curve_ds=curve_ds, yp=yp, covars = covars, ...)

	} else {

		curve_ds = mapply_curve(regions=regions,years=years, csvv=csvv, covars=covars, base_year=base_year, return.betas=T, interacted_weather=interacted_weather,crop=crop,season=season,...)
		curve_ds = mapply_curve(regions=regions,years=years, csvv=csvv, covars=covars, curve_ds=curve_ds, adapt='no', base_year=base_year, return.betas=T,interacted_weather=interacted_weather,crop=crop,season=season, ...)
		curve_ds = mapply_curve(regions=regions, years=years, csvv=csvv, covars=covars, curve_ds=curve_ds, adapt='income', base_year=base_year, return.betas=T,interacted_weather=interacted_weather,crop=crop,season=season, ...)
		if (tbar.adapt==T){
			message('---income & tbar adapt')
			curve_ds = mapply_curve(regions=regions, years=years, csvv=csvv, covars=covars, curve_ds=curve_ds, adapt='tbar', base_year=base_year, return.betas=T,interacted_weather=interacted_weather, crop=crop,season=season,...)
		}

		message('---generating and collapsing edds')
		pred.vars = unique(as.character(csvv$prednames))
		kinks = c()
		for (dd in c('gdd','kdd')) {
			if (crop == "wheat-winter"){
				if (season == "summer") { 
					dd.vars = pred.vars[grepl( paste0(dd,".*end"), pred.vars)]
				} else if (season == "fall") { 
					dd.vars = pred.vars[grepl( paste0(dd,".*begin"), pred.vars)]
				} else if (season == "winter") { 
					dd.vars = pred.vars[grepl( paste0(dd,".*r"), pred.vars)] 
				}
				if( dd == "gdd") {
					dd.kinks = as.numeric( unlist(strsplit(gsub("\\*.*","",dd.vars[1]), '-'))[-c(1,4)] )
					kinks = c(kinks, dd.kinks[1])
				} else {
					dd.kinks = as.numeric( unlist(strsplit(gsub("\\*.*","",dd.vars[1]), '-'))[-c(1,3)] )
					kinks = c(kinks, dd.kinks[1])
				}
			} else {
				dd.vars = pred.vars[grepl( paste0(dd,"*"), pred.vars)][1]
				dd.kinks = as.numeric( unlist(strsplit(dd.vars, '-'))[-1] )
				kinks = c(kinks,dd.kinks[1])
			}
		}

		all_years = sort(c(years, base_year))
		if (crop == "wheat-winter"){
			clim = mapply_extract_climate_data(years=all_years, climate_func=extract_ready_weather_data, weather.name="seasonaledd", crop=crop, season=season, ...)
			clim_next = mapply_extract_climate_data(years=all_years+1, climate_func=extract_ready_weather_data, weather.name="seasonaledd", crop=crop, season=season, ...)
			clim = clim[,paste(regions),,drop=F]
			clim_next = clim_next[,paste(regions),,drop=F]
		}
		else {
			clim = mapply_extract_climate_data(years=all_years, climate_func=extract_monthly_edd, ...)
			clim_next = mapply_extract_climate_data(years=all_years+1, climate_func=extract_monthly_edd, ...)
			clim = clim[paste(regions),,paste(kinks),,drop=F] 
			clim_next = clim_next[paste(regions),,paste(kinks),,drop=F] 
		}
		kwargs=list(...)
		kwargs = rlist::list.append(kwargs, kinks=kinks,clim=clim,clim_next=clim_next,years=all_years, crop=crop, season=season)
		
		binclim = mapply(FUN=mapply_edd_collapse,regions=regions, MoreArgs=kwargs, SIMPLIFY=FALSE)
		binclim = narray::stack(binclim, along=1)
		dimnames(binclim)[[1]] = c(kinks[1], kinks[2])
		bin = c(paste0('[', kinks[1], ',', kinks[2], ']'), paste0('[', kinks[2], ',Inf]'))

		mapply_delta_beta(regions=regions, years=years, base_year=base_year, binclim=binclim, curve_ds=curve_ds, yp=yp, bin=bin, covars = covars, weather=weather,...)
	}

}

#' retrieve growing season information from a specific region
#' @param region character : the name of an impact region, as appears in the hierachy file
#' @param gsfile character : full path to the file containing growing season info
#' @param time_scale character : one of c('monthly', 'daily')
#' @return integer vector of length two : planting and harvesting dates. If time_scale=='month', those are month ranks in a calendar year, else those are day ranks.
get_growing_season <- function(region, gsfile=gs_file, time_scale='monthly', ...) {

	df = fread(gsfile)

	if(!(c('plant_month', 'harvest_month', 'plant_date', 'harvest_date') %in% names(df))) stop('incompatible growing season information dataset')

	df = df %>% dplyr::filter(hierid == region)
	if (time_scale == 'monthly'){
		out = c(df$plant_month, df$harvest_month)
	} else if (time_scale == 'daily') {
		out = c(df$plant_date, df$harvest_date)
	}
	return(out)
}


#' processes growing season information, inferring from planting and harvesting dates the time span of a growing season given a time unit. 
#' @param region character : the name of an impact region, as appears in the hierachy file
#' @param ... optional parameters passed to get_growing_season
#' @return a list : first element is an integer sequence of time unit ranks in one or two calendar years identifying a growing season, the second is either NULL 
#' if the growing season doesn't cover two sequential years, otherwise it is an integer sequence of the time units ranks covering the second-year part of the 
#' growing season. Typically used to properly filter the growing-season part of climate data for a given region. 
process_growing_season <- function(region, time_scale, ...){
	gs = get_growing_season(region, ...)
	if (gs[1] > gs[2]) {
		ind = c(seq(gs[1],12), seq(1, gs[2]))
		multiyear = seq(1, gs[2])
	} else {
		ind = seq(gs[1], gs[2])
		multiyear = NULL
	}
	return(list(ind=ind, multiyear=multiyear))

}

mapply_edd_collapse <- function(regions,years,clim,clim_next, ...){
	vect = expand.grid(regions=regions, years=years)
	kwargs = list(...)
	kwargs = rlist::list.append(kwargs,clim=clim,clim_next=clim_next)
	dslist = mapply(FUN=edd.collapse, region=paste(vect[,'regions']), year=vect[,'years'], MoreArgs=kwargs, SIMPLIFY=FALSE)
	
	ds = narray::stack(dslist, along=1)
	return(ds)
}

#' applies tmin.collapse over a combination of regions and years
#' @param regions character vector
#' @param years integer vector
#' @return an [regions, years] array of tmin.collapse returned values
mapply_tmin_collapse <- function(regions,years,crop, ...){
	#### Before subsetting regions, make a function that drops regions with not enough months of gs. 
	
	vect = expand.grid(regions=regions, years=years)
	kwargs = list(...)
	dslist = mapply(FUN=tmin.collapse, region=paste(vect[,'regions']), year=vect[,'years'], crop=crop, MoreArgs=kwargs, SIMPLIFY=FALSE)
	ds = narray::stack(dslist, along=1)

	return(ds)
}

#' collapses two-sequential years [day, region, year] daily minimum temperature data at the growing season level
#' @param region character
#' @param year integer
#' @param bin logical. should the final array show counts ? 
#' @param TT_lower_bound integer
#' @param TT_upper_bound integer
#' @param TT_step double

#' @return if bin=TRUE, a [bin, year, region] array of counts giving the frequency of periods falling in bins determined by [TT_lower_bound,TT_upper_bound,TT_step]. In fact, 
#' since the final tmin value used is yearly (growing-season), among all the bins, all we have zeros, and only one will have a count of one. 
#' if bin=FALSE, the structure of the array returned is exactly the same ([bin, year, region]) but the counts are replaced by the actual value of tmin.
#' This is to allow for proper values in the delta beta table for tmin. 

tmin.collapse <- function(region, year, bin=TRUE, TT_lower_bound=-100, TT_upper_bound=250, TT_step = 1, clim, clim_next, crop, ...){
	
	
	gs = process_growing_season(region,...)

	ind = gs$ind
	multiyear = gs$multiyear
	if (crop != "wheat-winter"){	
		day_to_month=paste0("X", sapply(1:dim(clim)[1], day_to_month_collapser)) 
		
		clims <- list(clim[,,paste(year),drop=FALSE], clim_next[,,paste(year+1),drop=FALSE])
		clims <- Map(function(x) {dimnames(x)[[1]] <- day_to_month; x}, clims)
		clims <- lapply(X=clims, FUN=function(x) x[,paste(region),,drop=FALSE])  #monthly average daily tmin
		clims_average <- lapply(X=clims, FUN=function(x) apply(x, c(2,3), by, day_to_month, mean, drop=FALSE))  #monthly average daily tmin
		
		if(!is.null(multiyear)){

			y1 <- ind[ind %notin% multiyear]
			y2 <- multiyear

			clims_average_gs <- list()
			clims_average_gs[[1]] <- clims_average[[1]][paste0('X',y1),region,paste(year),drop=FALSE] #subset to growing months of season
			clims_average_gs[[2]] <- clims_average[[2]][paste0('X',y2),region,paste(year+1),drop=FALSE]
			allclims <-  stack(clims_average_gs, along=3)
			
			allclims <- narray::map(allclims, along=1, FUN=function(x) sum(x, na.rm=TRUE), drop=FALSE) # take sum of monthly average tmin over growing season
			allclims <- narray::map(allclims, along=3, FUN=function(x) sum(x, na.rm=TRUE), drop=FALSE) # take sum of monthly average tmin over growing season

			
			dimnames(allclims)[[3]] <- paste(year)
			

		} else {
			y1 <- ind
			allclims <- clims_average[[1]][paste0('X',y1),region,paste(year),drop=FALSE] #subset to growing months of season
			allclims <- narray::map(allclims, along=1, FUN=function(x) sum(x, na.rm=TRUE), drop=FALSE) # take sum of monthly average tmin over growing season

		}
	} else {
		
		allclims <- clim[paste0('X',1),region,paste(year),drop=FALSE] #subset to region
	}

	TT=seq(TT_lower_bound, TT_upper_bound, TT_step) #for histogram
	h = hist(allclims[,region,toString(year)], breaks = TT, include.lowest=TRUE, plot=FALSE)
	binnedstuff <- array(h$counts,dim=c(length(h$counts),1,1),dimnames=list(h$mids,year,region))

	if (nrow(which(binnedstuff!=0))!=1) stop("you yearly tmin binned array of yearly tmin has more than one count. Something weird is going on")

	ind <- c(which(binnedstuff!=0)) #this is a unique value


	if (!bin) binnedstuff[ind[1], ind[2], ind[3]] <- as.numeric(allclims)
	return(binnedstuff)


}

edd.collapse <- function(region, year, kinks, clim, clim_next, crop, TT_lower_bound, TT_upper_bound, TT_step, season=NULL, ...) {

	gs = process_growing_season(region,...)
	ind = gs$ind
	multiyear = gs$multiyear
	if (crop != "wheat-winter") {
		if (!is.null(multiyear)){
			y1 = ind[ind %notin% multiyear]
			y2 = multiyear
			edds_y1 = clim[region,paste(y1),paste(kinks),paste(year),drop=FALSE]
			edds_y2 = clim_next[region,paste(y2),paste(kinks),paste(year+1),drop=FALSE]
			alledds = stack(edds_y1, edds_y2, along=1)
			
			alledds = apply(FUN=sum, X=alledds,MARGIN=c(1,3,4),na.rm=TRUE)

			alledds[region,paste(kinks[1]), paste(year)] = alledds[region,paste(kinks[1]), paste(year)]-alledds[region,paste(kinks[2]), paste(year)]
			alledds[region,paste(kinks[1]), paste(year+1)] = alledds[region,paste(kinks[1]), paste(year+1)]-alledds[region,paste(kinks[2]), paste(year+1)]

			alledds[region,paste(kinks[1]), paste(year)] = alledds[region,paste(kinks[1]), paste(year)]+alledds[region,paste(kinks[1]), paste(year+1)]
			alledds[region,paste(kinks[2]), paste(year)] = alledds[region,paste(kinks[2]), paste(year)]+alledds[region,paste(kinks[2]), paste(year+1)]
			alledds=alledds[,,paste(year),drop=FALSE]
			alledds = aperm(alledds, c(2,3,1))
		}
		else {
			y1 = ind
			alledds = clim[region,paste(y1),paste(kinks),paste(year),drop=FALSE]
			alledds = apply(alledds,c(1,3,4),sum)
			alledds[region,paste(kinks[1]),paste(year)] = alledds[region,paste(kinks[1]),paste(year)] - alledds[region,paste(kinks[2]),paste(year)]
			alledds = aperm(alledds, c(2,3,1))	

		}
	} else {

			alledds = clim[,region,paste(year),drop=FALSE] #kinks, region, year (1,2,3) ==> kinks, year, region (1, 3, 2)
			alledds = aperm(alledds, c(1, 3, 2))
		
	}
	
	return(alledds)
}

export.yp <- function(yp, regions, export.path, suffix='', export.singles=F, export.matrix=F, prefix="yellow-purple_", ...) {
	if (export.singles==T) {
		for (region in regions){
			message(paste0('exporting ',region,'...'))
			ggsave(paste0(export.path,prefix,region,suffix,".pdf"),plot=yp[[region]])
		}
	}
	if (export.matrix==T) {
		message('exporting matrix...')
		yp_matrix(yp = yp, export.path = export.path, suffix=suffix, ...)
	}
}

deathbot.climate.data <- function(regions, years, base_period, clim, day.range, ...) {
	clim_base = apply(clim[ ,regions, paste(seq(base_period[1],base_period[2])), drop = FALSE],c(1,2),mean)
	clim_base = array(clim_base, dim=c(dim(clim_base),1), dimnames=append(dimnames(clim_base),'1000'))
	clim = narray::stack(list(clim[ ,regions, paste(years) , drop = FALSE],clim_base), along = 3)
	doy = c(format(as.Date(paste0("2010","-",day.range[1]),"%Y-%m-%d"),"%j"), format(as.Date(paste0("2010","-",day.range[2]),"%Y-%m-%d"),"%j"))
	doy_vect = seq(doy[1], doy[2])
	return(clim[paste0("X", doy_vect),,,drop=F])
}

append.to.TT <- function(region, clim, years, TT, ...) {
	for (yr in years) {
		TT = c(TT, unname(clim[,region,toString(yr)]))
	}
	return(sort(unique(TT)))
}

mapply.append.to.TT <- function(regions, ...) {
	kwargs= list(...)
	TT = mapply(region=regions,FUN=append.to.TT,MoreArgs=kwargs,SIMPLIFY=FALSE)
	return(TT)
}

deathbot_calc <- function(region, year, day.range, clim, curve_dslist, ...) {
	doy = c(format(as.Date(paste0("2010","-",day.range[1]),"%Y-%m-%d"),"%j"), format(as.Date(paste0("2010","-",day.range[2]),"%Y-%m-%d"),"%j"))
	doy_vect = seq(doy[1], doy[2])
	curve_ds = curve_dslist[[region]]
	temps_scn = unname(clim[paste0("X", doy_vect),  region, toString(year)])
	ds_out = curve_ds[paste(temps_scn),,]
	return(array(ds_out,dim=c(length(ds_out),1,1),dimnames= list(paste0("X", doy_vect), year, region)))
}

db.timeseries <- function(regions, ds, years, age, suffix='', ...){
	suffix = paste0(suffix,'_age',age)
	ds_l = mapply.convert.to.levels(regions=regions, deathbot=ds, age=age, ...)
	ds = apply(ds_l,c(2,3),sum)
	plots = mapply_plot_ts(regions=regions, ds=ds, years=years, age=age, ...)
	export.yp(yp=plots,regions=regions, suffix=suffix, age=age, ...)
}

mapply_plot_ts <- function(regions, ...){
	kwargs= list(...)
	ds = mapply(region=regions,FUN=plot_ts,MoreArgs=kwargs,SIMPLIFY=FALSE)
}

plot_ts = function(region, ds,  y.lim, base_period, years, t.valuecol=3, t.yearcol=1,  colors=c('#e41a1c','#4daf4a','#984ea3','#ff7f00','#ffff33','#a65628','#f781bf'), t.margin=c(0.2,0.2,0.2,0.2), y.lab="Number of Deaths", location.dict=NULL, ...) {
	kwargs = list(...)
	df_base = melt(ds[paste(seq(base_period[1],base_period[2])),region, drop=F])
	df_scn = melt(ds[paste(years),region, drop=F])
	colnames(df_base)[t.yearcol] <- "year"
	colnames(df_scn)[t.yearcol] <- "year"
	plot = ggplot() +
		geom_hline(data=df_scn, aes(yintercept=value, colour=as.factor(year)), size = 1.0 , linetype = "dashed") +
		geom_line(data=df_base, aes(x = year, y = value), colour='#377eb8', size = 1.0) +
		geom_hline(yintercept=0, size=.5) + #zeroline
		theme_minimal() + 
		ylab(y.lab) +
		xlab("Baseline Year") +
		# coord_cartesian(ylim = y.lim )  + #xlim = x.lim
		scale_x_continuous(expand=c(0, 0)) +
		scale_linetype_discrete(name=NULL) +
		scale_color_manual(values = colors, name="Scenario Year") +
		theme(legend.justification=c(0,1), 
					legend.position=c(0.05, 0.25),
					panel.grid.major = element_blank(), 
					panel.grid.minor = element_blank(),
					panel.background = element_blank(),
					panel.border = element_rect(colour = "black", fill=NA, size=1),
					plot.margin = unit(t.margin, "in"))

	if (is.null(location.dict) | is.null(location.dict[[region]])) {
		location.dict= list()
		location.dict[[region]] = region
	}
	title <- ggdraw() + draw_label(location.dict[[region]], fontface='bold')
	plot = plot_grid(title, plot, ncol=1, rel_heights=c(0.05, .95))
	return(plot)
}

mapply_deathbot_calc <- function(regions, years, base_period, export.timeseries=F, ts_allage=F, ...){
	all_years = sort(c(seq(base_period[1],base_period[2]),years))
	vect = expand.grid(regions=regions, years=all_years)
	kwargs=list(...)
	dslist = mapply(FUN=deathbot_calc, region=paste(vect[,'regions']), year=vect[,'years'], MoreArgs=kwargs, SIMPLIFY=FALSE )
	ds = narray::stack(dslist, along=1)
	if (ts_allage == T) {
		return(ds)
	}
	if (export.timeseries == T) {
		message('plotting timeseries...')
		db.timeseries(regions=regions, ds=ds, years=years, base_period=base_period, ...)
	}
	base = apply(ds[ , paste(seq(base_period[1],base_period[2])), regions, drop=F],c(1,3),mean)
	dsout = sweep(ds[,paste(years),,drop=F],c(1,3), base)
	base2 = replicate(length(years),base, simplify=FALSE)	
	base2 = aperm(narray::stack(base2,along=3),c(1,3,2))
	dimnames(base2)[[2]] = years
	ds_out = narray::stack(list(dsout, ds[,paste(years), ,drop=F], base2),along=4)
	dimnames(ds_out)[[4]] = c('delta','scn','base')
	return(ds_out)
}

convert.to.levels <- function(region, deathbot, pop, ...) {
	if (length(dim(deathbot)) == 4) {
		db_l = deathbot[,,region,,drop=F]*(pop/100000)
	} else {
		db_l = deathbot[,,region,drop=F]*(pop/100000)
	}
	return(db_l)
}

mapply.convert.to.levels <- function(regions, pop.dir, age, ...) {
	kwargs = list(...)
	pop = read.csv(pop.dir, stringsAsFactors=F)
	regiondf = data.frame(region=regions, stringsAsFactors=F)
	regiondf = regiondf %>% left_join(pop, by = 'region')
	dslist = mapply(FUN=convert.to.levels, region=regiondf[,'region'], pop=regiondf[,paste0('pop',age)], MoreArgs=kwargs, SIMPLIFY=FALSE)
	ds = narray::stack(dslist, along=1)
	return(ds)
}

popweight.rates <- function(db_out, pop.dir, varn, ...) {
	pop = read.csv(pop.dir, stringsAsFactors=F)
	pop = melt(pop)
	db_out$region = as.character(db_out$region)
	pop$age = as.numeric(substr(pop$variable,4,4))
	db_out = db_out %>%	left_join(pop, by = c('region', 'age')) %>%
					 	group_by_at(c(varn)) %>%
						summarize(weighted.mean(rates,value)) %>%
						data.frame()
	colnames(db_out)[ncol(db_out)] = 'rates'
	return(db_out)
}

print_db <- function(dancing=F,txtfile='/home/dylanhogan/repositories/mortality/10_projection/responsefunctions/db.txt',...) {
	sink("/dev/null")
	art = dput(readLines(txtfile, warn=FALSE))
	sink()
	cat(art, sep = "\n")

	if(dancing==T) {
		sink("/dev/null")
		art2 = dput(readLines('/home/dylanhogan/repositories/mortality/10_projection/responsefunctions/db2.txt', warn=FALSE))
		sink()
		while (TRUE==TRUE) {
		    cat(art2, sep = "\n")
		    Sys.sleep(0.4)
	    	cat(art, sep = "\n")
	    	Sys.sleep(0.4)
	  	}			
	}
}

deathbot <- function(regions, years, base_period=c(1960,1980), response_year=2010, TT_lower_bound=-23, TT_upper_bound=45, TT_step, export.unit='rates', export.time='daily', export.fn=NULL, collapse.age=F, agelist=c(1,2,3), to.plot=F, location.dict=NULL, all.uncertainty=F, CI='central', ...) {
	TT=seq(TT_lower_bound, TT_upper_bound, TT_step)
	kwargs = list(...)
	all_years = sort(c(seq(base_period[1],base_period[2]),years))
	message('loading covariates...')
	covars = load.covariates(regions=regions, years=response_year, ...)
	message('loading climate data...')
	clim = mapply_extract_climate_data(years=all_years,...)
	TT = mapply.append.to.TT(regions=regions, clim=clim, TT=TT, years=all_years, ...)
	message('loading csvv...')
	
	if (all.uncertainty==T) {
		uncert.list = c('central','upper','lower')
	} else {
		uncert.list = c(CI)
	}
	db_out=data.frame()
	for (uncert in uncert.list) {
		message('')		
		message('################################')
		message('Estimate:', uncert)
		message('################################')
		db_age=data.frame()
		for (age in agelist) {
			message('')
			message('------------------------')
			message(paste('Age:',age))
			message('------------------------')
			csvv = read.csvv(filepath = paste0(csvv.dir,csvv.name), age=age, ...)
			message('drawing response functions...')
			message('---no_adapt')
			curve_dslist = mapply_curve(regions=regions, years=response_year, csvv=csvv, covars=covars, TT=TT, base_year=response_year, adapt='no', export.list=T, age=age, CI=uncert, ...)
			if (to.plot==T) {
				message(paste0('plotting...'))
				deathplot(regions=regions, years=years, clim=clim, base_period=base_period, curve_ds=curve_dslist, age=age, location.dict=location.dict, ...)
			}
			message('deathbot...')
			deathbot = mapply_deathbot_calc(regions=regions, years=years, base_period=base_period, clim=clim, curve_dslist=curve_dslist, age=age, location.dict=location.dict, ...)

			if (export.unit == 'levels') {
				message("---levels output")
				deathbot = mapply.convert.to.levels(deathbot=deathbot, regions=regions, age=age, ...)
			} else if (export.unit == 'rates') {
				message("---rates output")
			}
			if (export.time == 'yearly') {
				message("---yearly output")
				deathbot = apply(deathbot,c(2,3,4),sum)
				varn = c('year', 'region','scn')
			} else if (export.time == 'daily') {
				message("---daily output")
				varn = c('day','year','region','scn')
			}
			deathbot = melt(deathbot, value.name=export.unit, varnames=varn)
			deathbot$age = age
			db_age = bind_rows(db_age,deathbot)
		}
		if (collapse.age==T & export.unit=='levels') {
			message('collapsing...')
			db_age = db_age %>% group_by_at(c(varn)) %>% summarise_each(sum) 
			db_age = data.frame(db_age[, !names(db_age) %in% c("age")] )
		} else if (collapse.age==T & export.unit=='rates') {
			db_age = popweight.rates(db_age=db_age, varn=varn,...)
		}
		db_age = db_age %>% spread('scn',export.unit) %>% 
							mutate(percent = delta/base)
		db_age$estimate = uncert
		db_out = bind_rows(db_out, db_age)
	}
	if (is.null(location.dict) == F) {
		db_out$name = ''
		for (reg in regions) {
			db_out[db_out$region==reg,'name'] = location.dict[[reg]]
		}
	}
	if (is.null(export.fn) == F) {
		message('exporting csv...')
		write.csv(db_out, file=paste0(kwargs[['export.path']],export.fn), row.names=FALSE)
	}
	message('DONE')
	print_db(...)
	return(db_out)
}

deathplot <- function(regions, clim, years, base_period, curve_ds, export.path, y.lim.dict, age, suffix='',...) {
	y.lim = y.lim.dict[[age]]
	suffix = paste0(suffix,'_age',age)
	clim = deathbot.climate.data(regions=regions,clim=clim, years=years, base_period=base_period, ...)
	binclim = mapply_bin_clim(regions=regions, years=c('1000',paste(years)), clim=clim, ...)
	curve_plots = mapply_plot_curve(regions=regions,curve_ds=curve_ds, bounds=NULL, years=years, base_year=2010, y.lim=y.lim, ...)
	hist_plots = mapply_plot_hist(regions=regions,binclim=binclim, ...)
	yp = mapply_yellow_purple(regions=regions,curve_plots=curve_plots, hist_plots=hist_plots, ...)
	export.yp(yp=yp,regions=regions,export.path=export.path, suffix=suffix,...)
}

deathbot_allts <- function(regions, years, base_period=c(1960,1980), response_year=2010,TT_lower_bound, TT_upper_bound, TT_step, export.unit='rates', export.time='daily', export.fn=NULL, collapse.age=F, agelist=c(1,2,3), to.plot=F, location.dict=NULL, all.uncertainty=F, CI='central', ...) {
 	TT=seq(TT_lower_bound, TT_upper_bound, TT_step)
	kwargs = list(...)
	all_years = sort(c(seq(base_period[1],base_period[2]),years))
	message('loading covariates...')
	covars = load.covariates(regions=regions, years=response_year, ...)
	message('loading climate data...')
	clim = mapply_extract_climate_data(years=all_years,...)
	TT = mapply.append.to.TT(regions=regions, clim=clim, TT=TT, years=all_years, ...)
	message('loading csvv...')
	
	if (all.uncertainty==T) {
		uncert.list = c('central','upper','lower')
	} else {
		uncert.list = c(CI)
	}
	db_out=data.frame()
	for (uncert in uncert.list) {
		message('')		
		message('################################')
		message('Estimate:', uncert)
		message('################################')
		db_age.list=list()
		for (age in agelist) {
			message('')
			message('------------------------')
			message(paste('Age:',age))
			message('------------------------')
			csvv = read.csvv(filepath = paste0(csvv.dir,csvv.name), age=age, ...)
			message('drawing response functions...')
			message('---no_adapt')
			curve_dslist = mapply_curve(regions=regions, years=response_year, csvv=csvv, covars=covars, TT=TT, base_year=response_year, adapt='no', export.list=T, age=age, CI=uncert, ...)
			deathbot = mapply_deathbot_calc(regions=regions, years=years, base_period=base_period, clim=clim, curve_dslist=curve_dslist, age=age, location.dict=location.dict, ...)
			ds_l = mapply.convert.to.levels(regions=regions, deathbot=deathbot, age=age, ...)
			db_age.list[[age]]=ds_l
		}
	}
	ds = db_age.list[[1]] + db_age.list[[2]] + db_age.list[[3]]
	ds = apply(ds,c(2,3),sum)
	plots = mapply_plot_ts(regions=regions, ds=ds, years=years, age=age, base_period=base_period,location.dict=location.dict, ...)
	export.yp(yp=plots,regions=regions, suffix='combined', age=age, location.dict=location.dict,...)
	return(ds)
}



generate_responses_ag_edd <- function(maxcores=NULL,regions, years, base_year=2010, bounds=NULL, inc.adapt=F, load.covariates=T, delta.beta=F, interacted_weather=FALSE,weather=NULL,p.bins=NULL, tbar.adapt=FALSE,...) {
	kwargs = list(...)
	all_years = sort(c(years, base_year))
	message('loading csvv...')
	csvv = read.csvv(filepath = paste0(csvv.dir,csvv.name),...)
	message('loading covariates...')
	if (load.covariates==T) {
		covars = load.covariates(regions=regions, years=all_years, ...)
	} else {
		covars=NULL
	 }

	if (interacted_weather==TRUE){
		message('loading interacted precip...')
		precip = mapply_extract_climate_data(years=all_years, tas_value = 'pr', climate_func=extract_monthly_climate_data, ...)
		precip_next = mapply_extract_climate_data(years=all_years+1, tas_value = 'pr', climate_func=extract_monthly_climate_data, ...)
		precip2 = mapply_extract_climate_data(years=all_years, tas_value = 'pr-monthsum-poly-2', climate_func=extract_monthly_climate_data, ...)
		precip2_next = mapply_extract_climate_data(years=all_years+1, tas_value = 'pr-monthsum-poly-2', climate_func=extract_monthly_climate_data, ...)
		interacted_weather = list(mapply_ag_process_precip(regions=regions, clim=precip, clim_tp1=precip_next,p.bins=p.bins,all_years=all_years,...),
			mapply_ag_process_precip(regions=regions, clim=precip2, clim_tp1=precip2_next,p.bins=p.bins,all_years=all_years,...))
		interacted_weather = lapply(FUN=function(x) adrop.sel(x, omit=c(1,2,3)), X=interacted_weather)
		weather=interacted_weather[[1]]
		names(dimnames(weather)) = c('month', 'region', 'year')
		weather = data.table(plyr::adply(weather, c(1,2,3)))
		setnames(weather, old='V1', new='precip')	
		weather = weather[,.('precip'=sum(precip, na.rm=TRUE)), by=c('region', 'year')]
	}

	responses = responses_wrapper_ag_edd(maxcores=maxcores,regions=regions, years=years, csvv = csvv, covars = covars, base_year=base_year, interacted_weather=interacted_weather,weather=weather,tbar.adapt=tbar.adapt,...)
	
	return(responses)
}


responses_wrapper_ag_edd <- function(maxcores,regions, years, csvv, covars, base_year,interacted_weather=FALSE, weather, tbar.adapt,...) {
	message('---computing KDD and GDD responses for each scenario')
	message('---splitting IRs across cores')
	
	kwargs = list(...)
	kwargs = rlist::list.append(kwargs, return.betas=TRUE, csvv=csvv,covars=covars,base_year=base_year,interacted_weather=interacted_weather,adapts=c('full','tbar','income'),years=years)	
	curve_ds = pbmcmapply(FUN=mapply_curve_adapts, regions=regions, MoreArgs=kwargs, SIMPLIFY=FALSE, mc.cores=maxcores)
	curve_ds = narray::stack(curve_ds, along=1)


	message('---computing KDD and GDD values')
	pred.vars = unique(as.character(csvv$prednames))
	kinks = c()
	for (dd in c('gdd','kdd')) {
		dd.vars = pred.vars[grepl( paste0(dd,"*"), pred.vars)][1]
		dd.kinks = as.numeric( unlist(strsplit(dd.vars, '-'))[-1] )
		kinks = c(kinks,dd.kinks[1])
	}

	message('--- .... extracting the data')
	all_years = sort(c(years, base_year))
	edds = mapply_extract_climate_data(years=all_years, climate_func=extract_monthly_edd, ...)
	edds_next = mapply_extract_climate_data(years=all_years+1, climate_func=extract_monthly_edd, ...)
	edds = edds[paste(regions),,paste(kinks),,drop=F] #memory efficient
	edds_next = edds_next[paste(regions),,paste(kinks),,drop=F] #memory efficient


	message('--- .... collapsing the data')
	message('---splitting IRs across cores')
	kwargs=list(...)
	kwargs = rlist::list.append(kwargs, kinks=kinks,clim=edds,clim_next=edds_next,years=all_years)


	binclim = mcmapply(FUN=mapply_edd_collapse,regions=regions, MoreArgs=kwargs, mc.cores=2, SIMPLIFY=FALSE)
	binclim = narray::stack(binclim,along=1)
	
	message('---computing response')
	message('---splitting IRs across cores')
	bin = c(paste0('[', kinks[1], ',', kinks[2], ']'), paste0('[', kinks[2], ',Inf]'))
	kwargs=list(...)
	kwargs = rlist::list.append(kwargs, base_year=base_year,binclim=binclim, curve_ds=curve_ds,bin=bin,covars=covars, weather=weather,years=years)

	responses = pbmcmapply(FUN=mapply_responses, regions=regions,MoreArgs=kwargs, mc.cores=maxcores, SIMPLIFY=FALSE)
	responses = rbindlist(responses)

	return(responses)

}

generate_betas_ag_edd <- function(regions, years, base_year=2010, bounds=NULL, inc.adapt=F, load.covariates=T, delta.beta=F, interacted_weather=FALSE,weather=NULL,p.bins=NULL, tbar.adapt=FALSE,...) {
	kwargs = list(...)
	all_years = sort(c(years, base_year))
	message('loading csvv...')
	csvv = read.csvv(filepath = paste0(csvv.dir,csvv.name),...)
	message('loading covariates...')
	if (load.covariates==T) {
		covars = load.covariates(regions=regions, years=all_years, ...)
	} else { covars=NULL }

	if (interacted_weather==TRUE){
		message('loading interacted precip...')
		precip = mapply_extract_climate_data(years=all_years, tas_value = 'pr', climate_func=extract_monthly_climate_data, ...)
		precip_next = mapply_extract_climate_data(years=all_years+1, tas_value = 'pr', climate_func=extract_monthly_climate_data, ...)
		precip2 = mapply_extract_climate_data(years=all_years, tas_value = 'pr-monthsum-poly-2', climate_func=extract_monthly_climate_data, ...)
		precip2_next = mapply_extract_climate_data(years=all_years+1, tas_value = 'pr-monthsum-poly-2', climate_func=extract_monthly_climate_data, ...)
		interacted_weather = list(mapply_ag_process_precip(regions=regions, clim=precip, clim_tp1=precip_next,p.bins=p.bins,all_years=all_years,...),
			mapply_ag_process_precip(regions=regions, clim=precip2, clim_tp1=precip2_next,p.bins=p.bins,all_years=all_years,...))
		interacted_weather = lapply(FUN=function(x) adrop.sel(x, omit=c(1,2,3)), X=interacted_weather)
		weather=interacted_weather[[1]]
		names(dimnames(weather)) = c('month', 'region', 'year')
		weather = data.table(plyr::adply(weather, c(1,2,3)))
		setnames(weather, old='V1', new='precip')	
		weather = weather[,.('precip'=sum(precip, na.rm=TRUE)), by=c('region', 'year')]
	}

	betas = betas_wrapper_ag_edd(regions=regions, years=years, csvv = csvv, covars = covars, base_year=base_year, interacted_weather=interacted_weather,weather=weather,tbar.adapt=tbar.adapt,...)
	
	return(betas)
}


betas_wrapper_ag_edd <- function(regions, years, csvv, covars, base_year,interacted_weather=FALSE, weather, tbar.adapt,...) {
	message('---computing KDD and GDD betas')
	kwargs = list(...)
	kwargs = rlist::list.append(kwargs, return.betas=TRUE, csvv=csvv,covars=covars,base_year=base_year,interacted_weather=interacted_weather,adapts=c('full'),years=years)	
	betas = mapply(FUN=mapply_curve_adapts, regions=regions, MoreArgs=kwargs, SIMPLIFY=FALSE)
	betas = as.data.table(narray::stack(betas, along=1))
	setnames(betas, c("kinks","year","region","beta"))
	return(betas)
}


na_growing_season <- function(file, time_scale="monthly"){
	dt = fread(file)
	ifelse(time_scale=="monthly", done <- dt[is.na(plant_month) & is.na(harvest_month),hierid],
		done <- dt[is.na(plant_date) & is.na(harvest_date),hierid])	

	return(done)
}
