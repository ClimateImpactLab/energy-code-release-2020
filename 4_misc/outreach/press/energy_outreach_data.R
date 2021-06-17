library(glue)
library(R.cache)
library(readr)
library(dplyr)
library(reticulate)
library(parallel)
library(miceadds)
library(haven)
library(ncdf4)
library(tidyr)

# cilpath.r:::cilpath()
db = '/mnt/CIL_energy/'
output = '/mnt/CIL_energy/code_release_data_pixel_interaction/'

REPO <- "/home/liruixue/repos"

dir = paste0('/shares/gcp/social/parameters/energy_pixel_interaction/extraction/',
    'multi-models/rationalized_code/break2_Exclude_all-issues_semi-parametric/')

# Make sure you are in the risingverse-py27 for this... 
projection.packages <- paste0(REPO,"/energy-code-release-2020/2_projection/0_packages_programs_inputs/extract_projection_outputs/")
setwd(paste0(REPO))

# Source codes that help us load projection system outputs
miceadds::source.all(paste0(projection.packages,"load_projection/"))

#' Wrapper that calls get_energy_impacts, transform, reshape and save results
#' @param time_step what years to output ("averaged","all")
#' @param impact_type unit of output ("impacts_gj", "impacts_kwh", "impacts_pct_gdp")
#' @param resolution spatial resolution of output, ("all_IRs", "states", "iso", "global")
#' @param rcp ("rcp45", "rcp85")
#' @param stats the statistics to produce, ("mean", "q5", "q17", "q50", "q83", "q95")
#' @param fuel ("electricity", "other_energy")
#' @param export set to TRUE if want to write output to file
#' @param regenerate set to TRUE if want to re-run load.median function (use when the extraction is not done correctly) 

#' @return Data table of processed impacts.
ProcessImpacts = function(
    time_step,
    impact_type, 
    resolution, 
    rcp=NULL, 
    stats=NULL,
    fuel = NULL,
    export = TRUE,
    regenerate = FALSE,
    ...){

    # get a df with all impacts and all stats at that resolution
    df = wrap_mapply(
        impact_type = impact_type,
        resolution = resolution,
        fuel = fuel, 
        rcp = rcp, 
        regenerate = regenerate,
        mc.cores=1,
        mc.silent=FALSE,
        FUN=get_energy_impacts
        ) 

    df = select_and_transform(
        df = df, 
        impact_type = impact_type,
        resolution = resolution,
        stats = stats,
        ) 

    df = reshape_and_save(
        df = df, 
        stats = stats, 
        resolution = resolution, 
        impact_type = impact_type, 
        time_step = time_step,
        fuel = fuel, 
        rcp = rcp,
        export = export)

    return(df)

}


#' convert raw impacts to required impact type and keep only required statistics
#' @param df 
#' @param impact_type unit of output ("impacts_gj", "impacts_kwh", "impacts_pct_gdp")
#' @param resolution spatial resolution of output, ("all_IRs", "states", "iso", "global")
#' @param stats the statistics to produce, ("mean", "q5", "q17", "q50", "q83", "q95")
#' @return Data table of processed impacts.

select_and_transform = function(df, impact_type, resolution, stats, ...) {

    df_stats = do.call("rbind", df) %>% dplyr::select(year, region, !!stats) 
    if (impact_type == "impacts_gj") {
        return(df_stats)
    } else if (impact_type == "impacts_kwh") {
        gj_to_kwh <- function(x) (x * 0.0036) 
        df_stats = df_stats %>% dplyr::mutate_at(vars(-c(year,region)), gj_to_kwh)
        return(df_stats)        
    } else if (impact_type == "impacts_pct_gdp") {
        gdp = return_region_gdp(resolution)    
        df_stats = left_join(df_stats, gdp, by = c("region", "year")) 
        df_stats = df_stats %>% rename(stats = !!stats) %>%
        dplyr::mutate(stats = stats * 1000000000 * 100 / gdp / 0.0036) %>%
        dplyr::select(-gdp)
        df_stats = rename(df_stats, !!stats:= stats)
        return(df_stats)
    }
}


# reshape output and save to file
reshape_and_save = function(df, stats, resolution, impact_type, time_step, rcp, fuel, export,...) {

    rownames(df) <- c()
    if(resolution=="states") 
        df = StatesNames(df)

    years_list = list(
        all=NULL,
        averaged=list(
            seq(2020,2039),
            seq(2040,2059),
            seq(2080,2099)))

    if (!is.null(years_list[[time_step]]))
        df = YearChunks(df,years_list[[time_step]])
    else
        setnames(df, old='year', new='years')

    df = YearsReshape(df)

    if(identical(names(df), c("region", as.character(seq(2020, 2099))))) 
    setnames(
        df, 
        as.character(seq(2020,2099)), 
        glue("year_{as.character(seq(2020,2099))}"))

    # define a named vector to rename column names
    region_colname = c("Global","state_abbrev","ISO_code","Region_ID")
    names(region_colname) = c("global", "states", "iso", "all_IRs")
    setnames(df, "region", region_colname[resolution])

    if (export) {
        fwrite(
            df,
            do.call(
                Path, args = list(impact_type = impact_type, 
                        resolution = resolution,
                        rcp = rcp, 
                        stats = stats, 
                        fuel = fuel, 
                        time_step=time_step)))
    }

    return(df)
}

# identify which type of files to extract results from
# IR level - "levels.nc4" file, other levels - "aggeregated.nc4" files
get_geo_level = function(resolution) {

    geo_level_lookup = list(
        iso="aggregated", 
        states="aggregated", 
        all_IRs="levels", 
        global="aggregated")

    return(geo_level_lookup[[resolution]])
}


# a function to call load.median package and get projection output
# note that to percentage gdp impacts are only applicable for total energy (electricity + other energy)
get_energy_impacts = function(impact_type, fuel, rcp, resolution, regenerate,...) {

    # set parameters for the load.median function call based on impact_type parameter
    if (impact_type == "impacts_gj" | impact_type == "impacts_kwh"  ) {
        price_scen = NULL
        unit = "impactpc"
        spec = paste0("OTHERIND_", fuel)
        dollar_convert = "no"
    } else if (impact_type == "impacts_pct_gdp") {
        if (fuel != "total_energy") {
            print("to get percentage gdp, fuel must be total energy!")
            return()
        }
        price_scen = "price014"
        unit = "damage"
        spec = "OTHERIND_total_energy"       
        dollar_convert = "yes"
    } else {
        print("wrong fuel type")
    }

    geo_level = get_geo_level(resolution)
        
    if (geo_level == "aggregated") {

        # get a list of region codes to filter the data with
        regions = return_region_list(resolution)
        
        df = load.median(conda_env = "risingverse-py27",
                        proj_mode = '', # '' and _dm are the two options
                        # region = region, # needs to be specified for 
                        regions = regions,
                        regions_suffix = resolution,
                        rcp = rcp, 
                        ssp = "SSP3", 
                        price_scen = price_scen, # have this as NULL, "price014", "MERGEETL", ...
                        unit =  unit, # 'damagepc' ($ pc) 'impactpc' (kwh pc) 'damage' ($ pc)
                        uncertainty = "full", # full, climate, values
                        geo_level = "aggregated", # aggregated (ir agglomerations) or 'levels' (single irs)
                        iam = "low", 
                        model = "TINV_clim", 
                        adapt_scen = "fulladapt", 
                        clim_data = "GMFD", 
                        yearlist = seq(2020, 2099),  
                        spec = spec,
                        dollar_convert = dollar_convert,
                        grouping_test = "semi-parametric",
                        regenerate = regenerate)
    } else {
            df = load.median(conda_env = "risingverse-py27",
                        proj_mode = '', # '' and _dm are the two options
                        rcp = rcp, 
                        ssp = "SSP3", 
                        price_scen = price_scen, # have this as NULL, "price014", "MERGEETL", ...
                        unit =  unit, # 'damagepc' ($ pc) 'impactpc' (kwh pc) 'damage' ($ pc)
                        uncertainty = "full", # full, climate, values
                        geo_level = "levels", # aggregated (ir agglomerations) or 'levels' (single irs)
                        iam = "low", 
                        model = "TINV_clim", 
                        adapt_scen = "fulladapt", 
                        clim_data = "GMFD", 
                        yearlist = seq(2020, 2099),  
                        spec = spec,
                        dollar_convert = dollar_convert,
                        grouping_test = "semi-parametric",
                        regenerate = regenerate)

    }

    return(df)

}


#reshapes the data to get region in rows and years in columns
YearsReshape = function(df){

    var = names(df)[!(names(df) %in% c('region', 'years'))]
    setnames(df,var,"value")
    df=reshape2:::dcast(df,region + value ~ years, value.var='value')
    setDT(df)
    df[,value:=NULL]
    #super annoying trick
    df=df[,lapply(.SD, function(x) mean(x,na.rm=TRUE)), by=region] 
    return(df)
}

#get two-decades means
YearChunks = function(df,intervals,...){

    df = as.data.table(df)
    df[,years:=dplyr:::case_when(year %in% intervals[[1]] ~ 'years_2020_2039',
        year %in% intervals[[2]] ~ 'years_2040_2059',
        year %in% intervals[[3]] ~ 'years_2080_2099')][,year:=NULL]
    df=df[!is.na(years)]
    df=df[,lapply(.SD, mean), by=.(region,years)]
    return(df)
}


#directories and files names
Path = function(impact_type, resolution, rcp, stats, fuel, time_step, suffix='', ...){

    # define a named vector to rename folders and files
    geography = c("global","US_states","country_level","impact_regions")
    names(geography) = c("global", "states", "iso", "all_IRs")
    
    dir = glue("/mnt/CIL_energy/impacts_outreach/{geography[resolution]}/{rcp}/SSP3/")
    file = glue("unit_{fuel}_{impact_type}_geography_{geography[resolution]}_years_{time_step}_{rcp}_SSP3_quantiles_{stats}{suffix}.csv")

    print(glue('{dir}/{file}'))
    dir.create(dir, recursive = TRUE, showWarnings = FALSE)
    return(file.path(dir, file))
}


memo.csv = addMemoization(read.csv)

#add US states name to states ID
StatesNames = function(df){
    df=setkey(as.data.table(df),region)

    # index the hierarchy.csv file
    check = setkey(as.data.table(setnames(
        memo.csv('/shares/gcp/regions/hierarchy.csv', skip = 31),
        "region.key", "region"))[,.(region, name)],region)

    # replace region ID with region names 
    df=check[df][,region:=name][,name:=NULL][]
    return(df)
}


#' Translates key words into list of impact region codes.
#'
#' @param regions Regions, can be IRs or aggregated regions. Also accepts:
#' - all: all ~25k impact regions; 
#' - iso: country-level output; 
#' - global: global outputs; 
#' @return List of IRs or region codes.
return_region_list = function(regions) {

    if (length(regions) > 1) {
        return(regions)
    }
    check = memo.csv('/shares/gcp/regions/hierarchy.csv', skip = 31) %>%
    data.frame()

    list = check %>%
    dplyr::filter(is_terminal == "True")

    if (regions == 'all_IRs'){
        return(list$region.key)
    }

    else if (regions == 'iso')
        return(unique(substr(list$region.key, 1, 3)))
    else if (regions == 'states'){
        df = list %>% 
        dplyr::filter(substr(region.key, 1, 3)=="USA") %>%
        dplyr::mutate(region.key = gsub('^([^.]*.[^.]*).*$', '\\1', region.key))
        return(unique(df$region.key))
    }
    else if (regions == 'global')
    return('global')
    else
    return(regions)
}

# get regional GDP time series at the spatial resolution specified
return_region_gdp = function(resolution) {

    DB_data = "/mnt/CIL_energy/code_release_data_pixel_interaction"
    gdp = read_csv(
        paste0(DB_data, '/projection_system_outputs/covariates/', 
         'SSP3-low-IR_level-gdppc-pop-gdp-all-years.csv')) 

    if (resolution == 'all_IRs') {
            return(gdp[c("region","year","gdp")])
        } else if (resolution == 'iso' | resolution == "states") {
            regions_list = return_region_list(resolution)
            IR_list = get_children(regions_list)
            IR_df = data.frame(agg_region = rep(names(IR_list),sapply(IR_list, length))
                , region = unlist(IR_list)) 
            rownames(IR_df) = c()
            regions_gdp = inner_join(IR_df, gdp, by = "region")
            regions_gdp = regions_gdp %>% group_by(agg_region, year) %>%
                        summarise(gdp = sum(gdp))%>% 
                        select(agg_region, year, gdp) %>%
                        rename(region = agg_region)
            return(regions_gdp)
        } else if (resolution == 'global') {
            global_gdp = gdp %>% group_by(year) %>%
                        summarise(gdp = sum(gdp))
            global_gdp$region = NA
            return(global_gdp)
        }
    }

#' Identifies IRs within a more aggregated region code.
#'
#' @param region_list Vect. of aggregated regions.
#' @return List of IRs associated with each aggregated region.
get_children = function(region_list) {

    check = memo.csv('/shares/gcp/regions/hierarchy.csv', skip = 31) %>%
    data.frame()

    list = dplyr::filter(check, region.key %in% region_list)$region.key

    if ('global' %in% region_list)
    list = c('global', list)

    term = check %>%
    dplyr::filter(is_terminal == "True")

    substrRight = function(x, n) (substr(x, nchar(x)-n+1, nchar(x)))

    child = list()
    for (reg in list) {

        regtag = reg

        if (reg == 'global') {
            child[['global']] = term$region.key
            next
        }

        if (substrRight(reg, 1) != '.')
        reg = paste0(reg, '.')

        child[[regtag]] = dplyr::filter(
            term, grepl(reg, region.key, fixed=T))$region.key
    }

    return(child)
}
