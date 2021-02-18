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

print("test")
db = '/mnt/CIL_energy/'
output = '/mnt/CIL_energy/code_release_data_pixel_interaction/'

dir = paste0('/shares/gcp/social/parameters/energy_pixel_interaction/extraction/',
    'multi-models/rationalized_code/break2_Exclude_all-issues_semi-parametric/')

# Make sure you are in the risingverse-py27 for this... 
projection.packages <- paste0(REPO,"/energy-code-release-2020/2_projection/0_packages_programs_inputs/extract_projection_outputs/")
setwd(paste0(REPO))

# Source codes that help us load projection system outputs
miceadds::source.all(paste0(projection.packages,"load_projection/"))


# source(glue("{REPO}/mortality/2_projection/impacts.R"))
# source(glue("{REPO}/mortality/2_projection/econvar.R"))
# source(glue("{REPO}/mortality/3_valuation/2_calculate_damages/damages.R"))

#' Wrapper that calls get_mortality_impacts with converted parameters.
#' @param years what years to output ("averaged","all")
#' @param ... other parameters as in the DB outreach paper

#' @return Data table of processed impacts.
ProcessImpacts = function(years, export=FALSE, ...){

    ParamList = do.call(ParamConvert,list(...))

    print("1")
    invargs = ParamList[['invargs']]
    outvargs = ParamList[['outvargs']]
    engine = ParamList[['engine']]

    DT = do.call(engine, c(invargs, list(as.DT=TRUE)))
    print("2")
    # browser()

    if(list(...)$resolution=="state_abbrev") 
    DT = StatesNames(DT)
    print("3")

    years_list = list(
        all=NULL,
        averaged=list(
            seq(2020,2039),
            seq(2040,2059),
            seq(2080,2099)))
    print("4")

    if (!is.null(years_list[[years]]))
    DT = YearChunks(DT,years_list[[years]])
    else
    setnames(DT, old='year', new='years')
    print("5")

    # browser()
    DT = YearsReshape(DT)

    print("6")

    # browser()


    if(identical(names(DT), c("region", as.character(seq(2020, 2099))))) 
    setnames(
        DT, 
        as.character(seq(2020,2099)), 
        glue("year_{as.character(seq(2020,2099))}"))

    setnames(DT, "region", list(...)$resolution)
    print("7")

    if(list(...)$resolution=="global") 
    DT[,(list(...)$resolution):="global"][]

    print("8")

    if (export)
    fwrite(
        DT,
        do.call(
            Path, c(list(...),
                list(
                    years=years,
                    geography_name=outvargs$geography_name))))

    return(DT)

}


get_energy_impacts = function(impact_type, resolution, fuel, rcp, stats,...){

    # browser()
    if (impact_type == "impacts_gj") {
        price_scen = NULL
        unit = "impactpc"
        spec = paste0("OTHERIND_", fuel)
        } else if (impact_type == "impacts_kwh") {
            price_scen = NULL
            unit = "impactpc"
            spec = paste0("OTHERIND_", fuel)
            } else if (impact_type == "impacts_pct_gdp") {
                price_scen = "price014"
                unit = "damage"
                spec = "OTHERIND_total_energy"       
            } 

            if (resolution == "iso" ) {
                    level = "aggregated"
                    regions = return_region_list("iso")
                } else if (resolution == "states" ) {
                    level = "aggregated"
                    regions = return_region_list("states")
                    } else if (resolution == "global") {
                        level = "aggregated"
                        regions = return_region_list("global")
                        } else if (resolution == "cities_500k") {
                            level = "levels"
                            regions = return_region_list("cities_500k")
                            } else {
                                print("geo region wrong")
                            }
                            df = load.median(conda_env = "risingverse-py27",
                                proj_mode = '', # '' and _dm are the two options
                                region = regions, # needs to be specified for 
                                rcp = rcp, 
                                ssp = "SSP3", 
                                price_scen = price_scen, # have this as NULL, "price014", "MERGEETL", ...
                                unit =  unit, # 'damagepc' ($ pc) 'impactpc' (kwh pc) 'damage' ($ pc)
                                uncertainty = "full", # full, climate, values
                                geo_level = level, # aggregated (ir agglomerations) or 'levels' (single irs)
                                iam = "low", 
                                model = "TINV_clim", 
                                adapt_scen = "fulladapt", 
                                clim_data = "GMFD", 
                                yearlist = seq(2020, 2099),  
                                spec = spec,
                                grouping_test = "semi-parametric")
                            df = df %>% dplyr::select(year, region, !!stats)

                            if (impact_type == "impacts_kwh") {
                                df = df %>% dplyr::mutate(mean = mean * 0.0036)
                                } else if (impact_type == "impacts_pct_gdp") {

                                    browser()
                                    df = left_join(df, covariates, by = "region")

                                    %>%
                                    dplyr::mutate(stats = !!stats * 1000000000 / gdp99 / 0.0036)
                                    } else {
                                       return(df)
                                   }
                               }


#converts DB paper outreach requests into get_mortality_impacts parameters.
ParamConvert = function(
    years,
    impact_type, 
    resolution, 
    rcp=NULL, 
    # ssp=NULL, 
    stats=NULL,
    fuel = "electricity",
    ...){

    more_args = list(...)

    geography_names_list = list(
        ISO_code="country_level", 
        state_abbrev="US_states", 
        Region_ID="impact_regions", 
        Global="global")

    engine = get_energy_impacts
    # browser()

    stopifnot(!is.null(fuel), !is.null(rcp))

    invargs = list(
        impact_type = impact_type,
        resolution = resolution,
        rcp = rcp,
        fuel = fuel,
        stats = stats
        )

    outvargs = list(geography_name=geography_names_list[[resolution]])

    return(list(invargs=invargs, outvargs=outvargs, engine=engine))

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


    DT[,years:=dplyr:::case_when(year %in% intervals[[1]] ~ 'years_2020_2039',
        year %in% intervals[[2]] ~ 'years_2040_2059',
        year %in% intervals[[3]] ~ 'years_2080_2099')][,year:=NULL]

    DT=DT[!is.na(years)]

    DT=DT[,lapply(.SD, mean), by=.(region,years)]

    return(DT)
}


#directories and files names
Path = function(unit, geography_name, rcp, ssp, qtile, years, suffix='', ...){
    base = ""
    dir = glue("/mnt/CIL_energy/impacts_outreach/")
    file = glue("unit_{unit}_geography_{geography_name}_years_{years}_{rcp}{suffix}.csv")

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
    browser()
    DT=setkey(as.data.table(df),region)
    check = setkey(setnames(
        memo.csv('/shares/gcp/regions/hierarchy.csv', skip = 100),
        "region-key", "region")[,.(region, name)],region)
    DT=check[DT][,region:=name][,name:=NULL][]
    return(DT)
}


# Handles the regional hierarchy in the analysis, e.g., impact regions, ADM1 
# agglomerations, countries. 


#' Checks spatial resolution of regions as defined by impact region definitions.
#' 
#' Determines whether input region is an impact region or a more aggregated 
#' region. 
#'
#' @param region_list vector of IRs, ISOs, or regional codes in between.
#' @return List containing region codes at ir_level or aggregated resolutions.
check_resolution = function(region_list) {

    out = list()

    check = memo.csv('/shares/gcp/regions/hierarchy.csv') %>%
    data.frame()

    list = check %>%
    dplyr::filter(region.key %in% region_list)

    if (nrow(list)==0 & !('' %in% region_list))
    stop('Region not found!')

    if (any(list$is_terminal))
    out[['ir_level']] = dplyr::filter(list, is_terminal)$region.key
    if (any(!(list$is_terminal)))
    out[['aggregated']] = dplyr::filter(list, !(is_terminal))$region.key
    if ('' %in% region_list)
    out[['aggregated']] = c(out[['aggregated']], '')


    return(out)
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

    if (regions == 'cities_500k')
    return(list$region.key)
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


return_region_gdp = function(regions) {

    DB_data = "/mnt/CIL_energy/code_release_data_pixel_interaction"
    gdp = read_csv(
        paste0(DB_data, '/projection_system_outputs/covariates/', 
         'SSP3-high-IR_level-gdppc_pop-2099.csv')) 


    if (regions == 'cities_500k')
    return(gdp)
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
get_children("CAN")
