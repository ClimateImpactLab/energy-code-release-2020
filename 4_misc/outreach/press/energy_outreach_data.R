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
cilpath.r:::cilpath()

print("test2")
db = '/mnt/CIL_energy/'
output = '/mnt/CIL_energy/code_release_data_pixel_interaction/'

dir = paste0('/shares/gcp/social/parameters/energy_pixel_interaction/extraction/',
    'multi-models/rationalized_code/break2_Exclude_all-issues_semi-parametric/')

# Make sure you are in the risingverse-py27 for this... 
projection.packages <- paste0(REPO,"/energy-code-release-2020/2_projection/0_packages_programs_inputs/extract_projection_outputs/")
setwd(paste0(REPO))

# Source codes that help us load projection system outputs
miceadds::source.all(paste0(projection.packages,"load_projection/"))

#' Wrapper that calls get_mortality_impacts with converted parameters.
#' @param years what years to output ("averaged","all")
#' @param ... other parameters as in the DB outreach paper

#' @return Data table of processed impacts.
ProcessImpacts = function(...){

    ParamList = do.call(ParamConvert,list(...))

    print("1")

    invargs = ParamList[['invargs']]
    # resolution = ParamList[['resolution']]
    # engine = ParamList[['engine']]

    # browser()
    # get a df with all impacts and all stats at that resolution
    df = wrap_mapply(
        impact_type = invargs$impact_type,
        # geo_level = invargs$geo_level, 
        resolution = invargs$resolution,
        # region = region_list, 
        fuel = invargs$fuel, 
        rcp = invargs$rcp, 
        # stats  = invargs$stats,
        mc.cores=1,
        mc.silent=FALSE,
        FUN=get_energy_impacts
        ) 
    gdp = return_region_gdp(invargs$resolution)    

    # browser()
    region_list = return_region_list(invargs$resolution)
    # browser()

    # get_region_stats(
    #     df = df, 
    #     gdp = gdp,
    #     impact_type = invargs$impact_type,
    #     resolution = invargs$resolution,
    #     region = region_list,
    #     years = invargs$years,
    #     all_stats = invargs$all_stats,
    #     fuel = invargs$fuel, 
    #     rcp = invargs$rcp, 
    #     all_stats = invargs$all_stats
    #     ) 
# 
    # browser()
    wrap_mapply(
        df = df, 
        gdp = gdp,
        impact_type = invargs$impact_type,
        resolution = invargs$resolution,
        region = region_list,
        years = invargs$years,
        # geo_level = geo_level, 
        # resolution = resolution,
        all_stats = invargs$all_stats,
        fuel = invargs$fuel, 
        rcp = invargs$rcp, 
        mc.cores=1,
        mc.silent=FALSE,
        FUN=get_region_stats
        ) 

}

# get_regions_string(c("CHN","JPN"))
# ... = years, fuel, rcp
get_region_stats = function(df, gdp, impact_type, resolution, region, all_stats, ...) {

    # browser()
    # df_backup = df

    if (region != "global") {
    df = df %>% filter(region == !!region)
    } 
    for (stats in all_stats) {
        df_stats = df %>% dplyr::select(year, region, !!stats) 
        if (impact_type == "impacts_qty") {
            reshape_and_save(df_stats, stats, resolution, "impacts_gj", ...)
            gj_to_kwh <- function(x) (x * 0.0036) 
            df_stats = df_stats %>% dplyr::mutate_at(vars(-c(year,region)), gj_to_kwh)
            reshape_and_save(df_stats, stats, "impacts_kwh", ...)
        } else if (impact_type == "impacts_pct_gdp") {
            gdp = gdp %>% filter(region == !!region)

            df_stats = left_join(df_stats, gdp, by = c("region", "year")) 
            df_stats = df_stats %>% rename(stats = !!stats) %>%
            dplyr::mutate(stats = stats * 1000000000 * 100 / gdp / 0.0036) 
            df_stats = rename(df_stats, !!stats:= stats)
            reshape_and_save(df_stats, stats, resolution, "impacts_pct_gdp", ...)
        }
    }
}



reshape_and_save = function(df, stats, resolution, impact_type, ...) {
        # browser()
    more_args = list(...)
    browser()
    DT <- do.call("rbind", df_list) %>% dplyr::select(year, region, stats)
    # DT <- df %>% dplyr::select(year, region, !!stats)

    rownames(DT) <- c()

    print("2")

    if(resolution=="states") 
    DT = StatesNames(DT)
    print("3")

    years_list = list(
        all=NULL,
        averaged=list(
            seq(2020,2039),
            seq(2040,2059),
            seq(2080,2099)))
    print("4")

    if (!is.null(years_list[[more_args$years]]))
    DT = YearChunks(DT,years_list[[more_args$years]])
    else
    setnames(DT, old='year', new='years')
    print("5")

    # browser()

    DT = YearsReshape(DT)

    print("6")


    if(identical(names(DT), c("region", as.character(seq(2020, 2099))))) 
    setnames(
        DT, 
        as.character(seq(2020,2099)), 
        glue("year_{as.character(seq(2020,2099))}"))

    setnames(DT, "region", list(...)$resolution)
    print("7")

    if(resolution=="global") 
    DT[,resolution:="global"][]

    print("8")

    if (export)
    fwrite(
        DT,
        do.call(
            Path, c(more_args,
                list(
                    years=more_args$years,
                    resolution=resolution))))

    return(DT)
}



get_geo_level = function(resolution) {

    geo_level_lookup = list(
        iso="aggregated", 
        states="aggregated", 
        all_IRs="levels", 
        global="aggregated")

    return(geo_level_lookup[[resolution]])

}



# get_energy_impacts(impact_type = "impacts_qty",
#  resolution = "global", fuel = "electricity", rcp = "rcp85")

get_energy_impacts = function(impact_type, fuel, rcp, resolution,...) {


    # browser()
    if (impact_type == "impacts_qty" ) {
        price_scen = NULL
        unit = "impactpc"
        spec = paste0("OTHERIND_", fuel)
        dollar_convert = "no"
    } else if (impact_type == "impacts_pct_gdp") {
        price_scen = "price014"
        unit = "damage"
        spec = "OTHERIND_total_energy"       
        dollar_convert = "yes"
    } else {
        print("wrong fuel type")
    }

    geo_level = get_geo_level(resolution)
    region_list = return_region_list(resolution)
        
    if (geo_level == "aggregated" ){
        regions = get_regions_string(region_list)
    
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
                        grouping_test = "semi-parametric")
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
                        grouping_test = "semi-parametric")

    }
    return(df)
    # %>%
    #     dplyr::filter(region %in% region_codes)


}


get_regions_string = function(regions_list) {
    s = paste0("[", paste(unlist(regions_list), collapse=','), "]")
    return(s)
}



#converts DB paper outreach requests into get_mortality_impacts parameters.
ParamConvert = function(
    years,
    impact_type, 
    resolution, 
    rcp=NULL, 
    # ssp=NULL, 
    all_stats=NULL,
    fuel = "electricity",
    export = TRUE,
    ...){

    more_args = list(...)
    # engine = get_energy_impacts
    stopifnot(!is.null(fuel), !is.null(rcp))
    invargs = list(
        impact_type = impact_type,
        rcp = rcp,
        fuel = fuel,
        all_stats = all_stats,
        resolution = resolution,
        years = years,
        export = export
        )
    return(list(invargs=invargs))
}

#reshapes the data to get region in rows and years in columns
YearsReshape = function(DT){

    # browser()
    var = names(DT)[!(names(DT) %in% c('region', 'years'))]
    setnames(DT,var,"value")
    DT=reshape2:::dcast(DT,region + value ~ years, value.var='value')
    setDT(DT)
    DT[,value:=NULL]
    #super annoying trick
    DT=DT[,lapply(.SD, function(x) mean(x,na.rm=TRUE)), by=region] 
    return(DT)
}

#get two-decades means
YearChunks = function(DT,intervals,...){

    # browser()
    DT = as.data.table(DT)
    DT[,years:=dplyr:::case_when(year %in% intervals[[1]] ~ 'years_2020_2039',
        year %in% intervals[[2]] ~ 'years_2040_2059',
        year %in% intervals[[3]] ~ 'years_2080_2099')][,year:=NULL]

    # bk = DT
    DT=DT[!is.na(years)]

    DT=DT[,lapply(.SD, mean), by=.(region,years)]

    return(DT)
}


#directories and files names
Path = function(impact_type, resolution, rcp, stats, fuel, years, suffix='', ...){
    base = ""
    dir = glue("/mnt/CIL_energy/impacts_outreach/")
    file = glue("unit_{impact_type}_geography_{resolution}_years_{years}_{rcp}{suffix}.csv")

    print(glue('{dir}/{file}'))
    dir.create(dir, recursive = TRUE, showWarnings = FALSE)
    return(file.path(dir, file))

}


#open the processed data
OpenProcessed = function(...){

    fread(do.call(Path,list(...)))

}

memo.csv = addMemoization(read.csv)

#add US states name to states ID
StatesNames = function(df){
    DT=setkey(as.data.table(df),region)

    # index the hierarchy.csv file
    check = setkey(as.data.table(setnames(
        memo.csv('/shares/gcp/regions/hierarchy.csv', skip = 31),
        "region.key", "region"))[,.(region, name)],region)

    # replace region ID with region names 
    DT=check[DT][,region:=name][,name:=NULL][]
    return(DT)
}



#' Translates key words into list of impact region codes.
#'
#' @param regions Regions, can be IRs or aggregated regions. Also accepts:
#' - all: all ~25k impact regions; 
#' - iso: country-level output; 
#' - global: global outputs; 
#' @return List of IRs or region codes.
return_region_list = function(regions) {

    # browser()
    if (length(regions) > 1) {
        return(regions)
    }
    check = memo.csv('/shares/gcp/regions/hierarchy.csv', skip = 31) %>%
    data.frame()

    list = check %>%
    dplyr::filter(is_terminal == "True")

    # browser()
    if (regions == 'all_IRs'){
        # return(c("JPN.41.R5148cbf71a2651b4","USA.33.1854"))
        return(list$region.key)
    }
    else if (regions == 'cities_500k'){
            cities_500k = memo.csv('/home/liruixue/repos/energy-code-release-2020/data/500k_cities.csv') %>%
            select(Region_ID)
            return(unique(cities_500k$Region_ID))
    }
    else if (regions == 'iso')
        # return(c("CAN","CHN"))
        return(unique(substr(list$region.key, 1, 3)))
    else if (regions == 'states'){
        # return(c("CAN","CHN"))
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


return_region_gdp = function(resolution) {

    DB_data = "/mnt/CIL_energy/code_release_data_pixel_interaction"
    gdp = read_csv(
        paste0(DB_data, '/projection_system_outputs/covariates/', 
         'SSP3-low-IR_level-gdppc-pop-gdp-all-years.csv')) 
    # browser()
    if (resolution == 'all_IRs') {
            return(gdp[c("region","year","gdp")])
        } else if (resolution == 'iso' | resolution == "states") {
            # regions = "states"
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

# return_region_gdp("all_IRs")

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
