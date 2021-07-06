# Script purpose: validating James's code for processing delta method output
# Script status: goal of functions in part 1 do not correctly execute at the moment... 
# tried to make functions flexible to pdf and cdf this created bugs I have yet to fully resolve
# for a pdf "working version" use functions in this piece of code: 
# https://gitlab.com/ClimateImpactLab/Impacts/gcp-energy/blob/6f243629f3843c8ac4853495a935e0f3afb16093/Robustness/delta_method_debugging/dm_processing_debugging.R
# working is in quotes because it doesn't perfectly match up with James's output for all years

library(numDeriv)
library(stats)
library(reticulate)
library(R.cache)
library(parallel)
library(rlist)
library(future)
library(testit)
library(data.table)
library(ncdf4)
library(reshape2)
library(stringr)
library(glue)


#########################################################################################################
# Part 0: Get 2 product variance 
#########################################################################################################

load.csvv <- function(csvv.name = '', csvv.dir = '', product = 'electricity', skip.no = 23, ...) {
	
	return(read.csv(paste0(csvv.dir, glue::glue(csvv.name),".csvv"), skip = skip.no, header = F, sep= ",", stringsAsFactors = T))
}

get.netcdf <- function(csvv.name = '', projection.output.dir = '', product = 'electricity',
						  clim_model = 'CCSM4', iam = 'high', ssp = 'SSP3', 
						  rcp = 'rcp85', adapt = 'noadapt', 
						  geo_level = '', ...) {
	netcdf.root = glue::glue(csvv.name)
	netcdf.dir = glue::glue(projection.output.dir)
	
	if (adapt == "fulladapt" | adapt == '') {
		netcdf = paste0(netcdf.dir, netcdf.root, geo_level, ".nc4")
	} else {
		netcdf = paste0(netcdf.dir, netcdf.root,"-", adapt, geo_level, ".nc4")
	}

	return(ncdf4::nc_open(netcdf))

}

get.beta.names <- function(csvv = NULL) {
  #Extract coefficients in order from csvv
  
  clim_var = as.list(csvv[1,])
  
  clim_var = t((csvv[1,])) #get climate var names in order
  clim_var = gsub(" ", "", clim_var)
  
  covar = t((csvv[3,])) #get covar names in order
  covar = gsub(" ", "", covar)

  #add vectors element wise
  coef_names = data.frame(cbind(clim_var,covar))
  coef_names$beta = paste(coef_names$X1,coef_names$X3, sep = "_")

  #return betas in order
  as.vector(coef_names$beta)
  
}

get.jake.variable.names <- function(netcdf = NULL, csvv = NULL) {

	#create vector of var names from coefficients and years in order

	year <- as.list(ncvar_get(netcdf, "year")) #list of years
	year <- paste0("y",year)

	betas <- get.beta.names(csvv = csvv) %>%
	rep(each=length(year))

	year <- rep(year, times = length(csvv))

	var_names = data.frame(cbind(betas,year))
	var_names$var = paste(var_names$year, var_names$betas, sep = "_")

	return(as.vector(var_names$var))
  
}

get.jacob <- function(region = 'ARE.3', ...) {

  	kwargs = list(...)
  	
  	# load netcdf

	netcdf = do.call(get.netcdf, kwargs)

	# load csvv

	csvv = do.call(load.csvv, kwargs)

  	#create data frame with jacobian vectors for each ir in a region for every year
  
  	vars = get.jake.variable.names(csvv = csvv, netcdf = netcdf)
	
	jacob = data.frame(ncvar_get(netcdf, "rebased_bcde"))
	colnames(jacob) <- vars

	hierid <- data.frame(ncvar_get(netcdf, "regions")) #create column of hierids 

	# make sure global is assigned '' not NA
	hierid[is.na(hierid)] <- ''
	
	jacob <- cbind(hierid,jacob)
	names(jacob)[1] <- c("hierid")
	jacob <- subset(jacob, hierid == region)

	jacob <- reshape2::melt(jacob, id= c("hierid")) %>%
		tidyr::separate(variable,c("year","clim_var", "covar"), "_" , 3)
	jacob$year <- as.numeric(substr(jacob$year,2,5))

	return(jacob)
  
}

get.jacob.memo = addMemoization(get.jacob)

load.jacobian <- function(adapt = 'incadapt', ...) {

	kwargs = list(...)

	kwargs.adapt = rlist::list.append(kwargs, adapt = adapt)
	kwargs.histclim = rlist::list.append(kwargs, adapt = 'histclim')

	jacob.adapt = do.call(get.jacob.memo, kwargs.adapt) %>%
    	plyr::rename(c('value' = 'adapt_scen'))

	if (!grepl("noadapt", adapt)) {
		jacob.histclim = do.call(get.jacob, kwargs.histclim) %>%
    		plyr::rename(c('value' = 'histclim'))
    	    	
    	jacob.clean = join(jacob.adapt, jacob.histclim, type = "right") %>%
    		dplyr::mutate(value = adapt_scen - histclim) %>%
    		dplyr::select(hierid, year, clim_var, covar, value, adapt_scen, histclim)
	} else {
		jacob.clean = jacob.adapt %>%
    	plyr::rename(c('adapt_scen' = 'value'))
	}

	return(jacob.clean)

}

load.jacobian.memo = addMemoization(load.jacobian)

load.stacked.vcv <- function(stacked.vcv = '/shares/gcp/social/parameters/energy/incspline0719/GMFD/TINV_clim_income_spline/FD_FGLS_inter_climGMFD_Exclude_all-issues_break2_semi-parametric_poly2_OTHERIND_TINV_clim_income_spline-fixed.csv') {

	return(read.csv(stacked.vcv, header = FALSE))

}

get.two.product.variance <- function(stacked.vcv = data.frame(), jake.e = data.frame(), jake.oe = data.frame(), yr = '2048') {
	
	# only getting variance for one year at a time
	jake.oe.subsetted = dplyr::filter(jake.oe, year == yr)
	jake.e.subsetted = dplyr::filter(jake.e, year == yr)

	# get stacked jacobian
	stacked.jake = dplyr::bind_rows(jake.oe.subsetted, jake.e.subsetted)

	print(glue::glue('Calculating variance for {yr}...'))
	mat = t(as.matrix(stacked.jake$value)) %*% as.matrix(stacked.vcv) %*% as.matrix(stacked.jake$value)
	return(as.numeric(mat))
	
}

get.two.product.variance.ts <- function(yearlist = c(as.character(seq(2010,2099,1))), ...) {
	
	stacked.vcv = load.stacked.vcv()

	kwargs = list(...)

	products = c('electricity', 'other_energy')
	
	jake.list = mcmapply(FUN = load.jacobian.memo, product = products, MoreArgs = kwargs, SIMPLIFY = FALSE, mc.silent=T, mc.cores=length(products))
	
	e = as.data.frame(jake.list$electricity)
	oe = as.data.frame(jake.list$other_energy)

	tpv.args = list(jake.e = e, jake.oe = oe, stacked.vcv = stacked.vcv)

	two.product.variance.ts = mcmapply(FUN = get.two.product.variance, yr = as.numeric(yearlist), MoreArgs = tpv.args, SIMPLIFY = TRUE, mc.silent=T, mc.cores=20)

	two.product.variance.df = data.frame(two.product.variance.ts, as.numeric(yearlist))
	names(two.product.variance.df) = c('variance', 'year')

	return(two.product.variance.df)

}

#########################################################################################################
# Part 1: creating mixture pdf or cdf and using canned root finder to extract quantiles
#########################################################################################################

#get list of gcms
get.gcm.list <- function(projection.path = glue::glue("/shares/gcp/outputs/energy/impacts-blueghost"), rcp = 'rcp85', ...) {
	kwargs = list(...)
	file.name = do.call(paste.median.file, kwargs)
	path.2.gcm.files = paste(projection.path, file.name,'median', rcp, sep = '/')
	list.gcms = list.dirs(path = path.2.gcm.files, full.names = FALSE, recursive = FALSE)
	return(list.gcms)
}

get.values.memo = addMemoization(get.values)

#Get gcm list of gcm weights for a given rcp
get.normalized.weights <- function (gcms, rcp) {
	weights.list = mapply(FUN = fetch_weight.memo, gcm = gcms, rcp = rcp, SIMPLIFY = FALSE)
	normalized.weights.list = mapply(FUN = `/`, weights.list, Reduce("+",weights.list), SIMPLIFY = FALSE)
	return(normalized.weights.list)
}

#construct weighted fxn for a specific gcm in a specific year
weighted.fxn <- function(w.fxn = NULL, weights = list(), means = list(), variances = list(), gcm = 'CCSM4', yr = 2048, rgn = '', ...) {
	kwargs = list(...)
	sd = sqrt(variances[[gcm]][region == rgn & year == yr][['mean']])
	mean = means[[gcm]][region == rgn & year == yr][['mean']]
	weight = weights[[gcm]]
	
	function(x) {
		weight * w.fxn(x, mean = mean, sd = sd)
	}
}

#get list of fxns (each fxn in list is for a given year)
m.weighted.fxn <- function(yearlist = c(), ...) {
	kwargs = list(...)
	yearly.pdf = mapply(FUN = weighted.fxn, yr = as.numeric(yearlist), MoreArgs = kwargs, SIMPLIFY = FALSE)
	return(yearly.pdf)
}

# create a mixture fxn 
# takes in a function matrix [year, gcm] and creates a function for each row which is the sum of fxns for a given year
# in other words returns a function which is the sum of all functions in a given row
mix <- function(x = NULL, function.mat = NULL, index = 1) {

	function(x) {
		Reduce("+",function.mat[index,][[1]](x))
  	}
}

load.md.components <- function(gcms = c(), variance.function = get.values.memo,  ...) {
	kwargs = list(...)
	
	print('Loading variances...')
	var.list = mcmapply(FUN = variance.function, clim_model = gcms, MoreArgs = c(kwargs, proj_type = '_dm'), SIMPLIFY = FALSE, mc.silent=T, mc.cores=length(gcms))
	
	print('Loading means...')
	mean.list = mcmapply(FUN = get.values.memo, clim_model = gcms, MoreArgs = c(kwargs, proj_type = ''), SIMPLIFY = FALSE, mc.silent=T, mc.cores=length(gcms))
	
	print('Loading weights...')
	weight.list = get.normalized.weights(gcm.list, kwargs$rcp)

	return(list(variances = var.list, means = mean.list, weights = weight.list))
}

load.md.components.memo = addMemoization(load.md.components)


# creates a vector of mixture distribution cdfs for each year
# returns a list of functions

m.mixture.fxn <- function(gcms = c(), ...) {
	
	kwargs = list(...)
	kwargs = rlist::list.append(kwargs, gcms = gcms)

	print("Loading Data...")
	data.list = do.call(load.md.components, kwargs)
	
	print("Appending arguments to kwargs list...")
	kwargs = rlist::list.append(kwargs, variances = data.list$variances, means = data.list$means, weights = data.list$weights)

	print("Creating matrix of yearly weighted fxns [years,gcms]...")
	weighted.fxns = mapply(FUN = m.weighted.fxn, gcm = gcms, MoreArgs = kwargs)
	weighted.fxns.mat = unlist(weighted.fxns, use.names=FALSE)
	dim(weighted.fxns.mat) = dim(weighted.fxns)

	print("Creating mixture pdf across gcms for each year...")
	mixed.fxn.vect = lapply(X = seq(1,length(kwargs$yearlist),1), FUN = mix, x = x, function.mat = weighted.fxns.mat)
	return(mixed.fxn.vect)
}

# converts a pdf to a cdf with alpha (the quantile of interest) subtracted off
# returns a function ready to be passed into a root finding function
convert.pdf.to.cdf <- function(x = NULL, alpha = .05, fxn.c = NULL, ...) {
	fxn.v = Vectorize(fxn.c)
	function(x) {
		integrate(f = fxn.v, lower = -Inf, upper = x, subdivisions = 1000,
	    stop.on.error = FALSE)$value - alpha
	}
}


cdf.minus.alpha <- function(x = NULL, alpha = .05, fxn.c = NULL, ...) {
	function(x) {
		fxn.c(x) - alpha
	}
}

# creates a vector of mixture distribution cdf - alpha (quantile of interest) functions
# returns a list of functions

m.fxn.4.root.finding <- function(...) {
	
	print("Loading fxns for each year...")
	kwargs = list(...)
	fxn.vect = do.call(m.mixture.fxn, kwargs)

	if (grepl("x",deparse(kwargs$w.fxn)[[1]])) {
		print("dnorm -> integrate...")
		fxn.2.vect = convert.pdf.to.cdf
	} else {
		print("pnorm -> do not integrate...")
		fxn.2.vect = cdf.minus.alpha
	}
	
	print("Converting cdfs to cdfs - alpha...")
	vect = mapply(FUN = fxn.2.vect, fxn.c = fxn.vect, MoreArgs = kwargs)
	return(vect)
}


# loads quantile data from James's code for comparison
load.comparison.data <- function(comparison.data.path = '/shares/gcp/social/parameters/energy/extraction/median_delta_method_test/', rcp = 'rcp85', ssp = 'SSP3', rgn = '', ...) {
	
	if (rgn == '') {
		rgn = 'global'
	}

	file = paste0(comparison.data.path, rcp, "-", ssp, "-",rgn, ".csv")
	data = readr::read_csv(file)
	return(as.data.frame(data))
}

# convert alpha into quantile variable name
alpha.2.q <- function(alpha = .05) {
	return(paste0("q",as.character(alpha * 100)))
}

# memoizes function -- only have to load data once per restart
memo.load.comparison.data <- addMemoization(load.comparison.data)

# uses James's quantiles to create an interval for my root searching function to search on 
get.search.interval <- function(alpha = .05, yr = 2048, range = 50, comparison.data = NULL, ...) {
	kwargs = list(...)
	
	# convert alpha into quantile variable name
	quantile = alpha.2.q(alpha)

	# construct interval
	estimate = floor(comparison.data[comparison.data[['year']] == yr, quantile])
	ub = estimate + range
	lb = estimate - range
	search.interval = c(lb, ub)
	return(search.interval)
}

m.get.search.interval <- function(yearlist = c(), ...) {
	kwargs = list(...)
	comparison.data = do.call(memo.load.comparison.data, kwargs)
	kwargs = rlist::list.append(kwargs, comparison.data = comparison.data)
	interval.vector = mapply(FUN = get.search.interval, yr = yearlist, MoreArgs = kwargs, SIMPLIFY = FALSE)
	return(interval.vector)
}

# finds root of a function
uniroot.modified <- function(fxn.u = NULL, tol = 0.00001, extendInt = 'yes', interval = c(), ... ) {

	#print(paste0("Searching for root along this interval: ", interval[1], ":", interval[2]))
	ur = do.call(uniroot, list(f = fxn.u, interval = interval, tol = tol, extendInt = extendInt))
	return(ur$root)

}

get.num.user.cores <- function() {
	workers <- future::availableWorkers()
	cat(sprintf("#workders/#availableCores/#totalCores: %d/%d/%d, workers:\n", length(workers), availableCores(), detectCores()))
	#print(workers)
	return(length(workers))
}

# alternate to newton.raphson
# goal: find root for each year
# input: vector of functions
# output: vector of roots
m.uniroot <- function(fxn.vect = NULL, ...) {
	
	kwargs = list(...)
	
	print("Deciding how many cores to use...")
	cores.avail = get.num.user.cores()
	if(length(fxn.vect) + 20 > cores.avail) {
		cores.2.use = cores.avail - 20
	} else {
		cores.2.use = length(fxn.vect)
	}

	print("Retrieving search intervals for each function...")
	search.interval.list = do.call(m.get.search.interval, kwargs)
	print("Finding roots...")
	testit::assert(length(fxn.vect) == length(search.interval.list)) 
	roots = mcmapply(uniroot.modified, fxn.u = fxn.vect, interval = search.interval.list, MoreArgs = kwargs, mc.silent=T, mc.cores=cores.2.use)
	return(roots)
}

roots = do.call(m.uniroot, args.a)

find.quantile <- function(alpha = .05, yearlist = c(), ... ) {
	
	kwargs = list(...)
	kwargs = rlist::list.append(kwargs, alpha = alpha, yearlist = yearlist)
	
	print("Getting cdf - alpha functions for each year...")
	fxn.vect = do.call(m.fxn.4.root.finding, kwargs)
	return(fxn.vect)
	kwargs = rlist::list.append(kwargs, fxn.vect = fxn.vect)	

	print("Getting a vector of roots for each year...")
	roots = do.call(m.uniroot, kwargs)
	
	# Make dataframe with roots and yearlist and return
	print("Returning dataframe with years and quantile")
	quantile = alpha.2.q(alpha)
	df = data.frame(as.numeric(yearlist),roots)
	names(df) = c("year",quantile)
	return(df)

}

fxn.vect = do.call(find.quantile, args)

compare.w.james <- function(alpha = .05, ...) {
	kwargs = list(...)
	kwargs = rlist::list.append(kwargs, alpha = alpha)
	quantile = alpha.2.q(alpha)
	m.df = do.call(find.quantile, kwargs)
	j.df = do.call(memo.load.comparison.data, kwargs) 
	df = dplyr::left_join(m.df, j.df, by = "year", suffix = c('.m','.j'))
	df['diff.j.m'] = df[paste0(quantile,'.j')] - df[paste0(quantile,'.m')]
	return(df)
}

comp = do.call(compare.w.james, args)

# newton.raphson <- function(function, lb, ub, tol = 1e-5, n = 1000) {
#   require(numDeriv) # Package for computing f'(x)
  
#   x0 <- lb # Set start value to supplied lower bound
#   k <- n # Initialize for iteration results
  
#   # Check the upper and lower bounds to see if approximations result in 0
#   flb <- f(lb)
#   if (flb == 0.0) {
#     return(lb)
#   }
  
#   fub <- f(ub)
#   if (fub == 0.0) {
#     return(ub)
#   }

#   for (i in 1:n) {
#     dx <- numDeriv::genD(func = function, x = x0)$D[1] # First-order derivative f'(x0)
#     x1 <- x0 - (f(x0) / dx) # Calculate next value x1
#     k[i] <- x1 # Store x1
#     # Once the difference between x0 and x1 becomes sufficiently small, output the results.
#     if (abs(x1 - x0) < tol) {
#       root.approx <- tail(k, n=1)
#       res <- list('root approximation' = root.approx, 'iterations' = k)
#       return(res)
#     }
#     # If Newton-Raphson has not yet reached convergence set x1 as x0 and continue
#     x0 <- x1
#   }
#   print('Too many iterations in method')
# }

# get.cdf <- function(x, alpha, FUN = fx) {
#   return(integrate(function(x, FUN = fx) FUN(x), -Inf, x, subdivisions = 1000, 
#     stop.on.error = FALSE)$value - alpha)
# }

#########################################################################################################
# Part 2: creating data for Ashwin simulation
#########################################################################################################


# clean up output from load.md.components for easier use
transform.component.dataframe <- function(component.list = list('means','variances','weights'), ...) {
	
	kwargs = list(...)
	
	#load components
	components.list = do.call(load.md.components.memo, kwargs)
	
	#create list that holds a data frame for each component 
	cc = list()
	
	for (component in component.list) {
		cc[[component]] = data.table::rbindlist(lapply(components.list[[component]], as.data.frame.list), idcol = TRUE)
	}
	
	return(cc)
}

# make subsetted projection directory for easier validation of James's code
# easier because less specs going into mixture distribution

make.test.directory <- function(gcm = 'CCSM4', rcp = 'rcp85', iam = 'high',
	projection.path = '/shares/gcp/outputs/energy/impacts-blueghost/{file.name}/median/{rcp}/{gcm}/{iam}/',
	projection.name = 'median_OTHERIND_electricity_TINV_clim_income_spline_GMFD',
	test.directory.name = 'median_OTHERIND_electricity_TINV_clim_income_spline_GMFD_test10', ...) {

	full.projection = paste0(glue::glue(projection.path, file.name = projection.name),"SSP3/")
	print('Full projection path:')
	print(full.projection)
	
	test.directory = glue::glue(projection.path, file.name = test.directory.name)
	print('Test directory path:')
	print(test.directory)

	print("Making test directory...")
	mkdir.cmd = glue::glue('mkdir -p {test.directory}')
	system(mkdir.cmd)

	print("Copying projection...")
	cp.cmd = glue::glue('cp -avr {full.projection} {test.directory}')
	system(cp.cmd)
}

