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

print("test6")
cilpath.r:::cilpath()
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
ProcessImpacts = function(
    time_step,
    impact_type, 
    resolution, 
    rcp=NULL, 
    # ssp=NULL, 
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

    reshape_and_save(
        df = df, 
        stats = stats, 
        resolution = resolution, 
        impact_type = impact_type, 
        time_step = time_step,
        fuel = fuel, 
        rcp = rcp,
        export = export)


}

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

    setnames(df, "region", resolution)

    if(resolution=="global") 
    df[,resolution:="global"][]

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


get_geo_level = function(resolution) {

    geo_level_lookup = list(
        iso="aggregated", 
        states="aggregated", 
        all_IRs="levels", 
        global="aggregated")

    return(geo_level_lookup[[resolution]])
}


get_energy_impacts = function(impact_type, fuel, rcp, resolution, regenerate,...) {


    # browser()
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
    # browser()
        
    if (geo_level == "aggregated") {
        regions = return_region_list(resolution)
        # regions = get_regions_string(region_list)
    
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
    # %>%
    #     dplyr::filter(region %in% region_codes)


}


#reshapes the data to get region in rows and years in columns
YearsReshape = function(df){

    # browser()
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

    # browser()
    df = as.data.table(df)
    df[,years:=dplyr:::case_when(year %in% intervals[[1]] ~ 'years_2020_2039',
        year %in% intervals[[2]] ~ 'years_2040_2059',
        year %in% intervals[[3]] ~ 'years_2080_2099')][,year:=NULL]

    # bk = df
    df=df[!is.na(years)]

    df=df[,lapply(.SD, mean), by=.(region,years)]

    return(df)
}


#directories and files names
Path = function(impact_type, resolution, rcp, stats, fuel, time_step, suffix='', ...){
    dir = glue("/mnt/CIL_energy/impacts_outreach/")
    file = glue("{fuel}_{impact_type}_geography_{resolution}_years_{time_step}_SSP3_low_{rcp}_{stats}{suffix}.csv")

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
