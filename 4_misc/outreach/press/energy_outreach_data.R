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
    resolution = ParamList[['resolution']]
    engine = ParamList[['engine']]

    region_list = return_region_list(resolution)

    geo_level_lookup = list(
        iso="aggregated", 
        states="aggregated", 
        all_IRs="levels", 
        global="aggregated")

    invargs = list.append(invargs, geo_level =  geo_level_lookup[[resolution]])

    # browser()
    df_list = wrap_mapply(
        impact_type = invargs$impact_type,
        geo_level = invargs$geo_level, 
        resolution = resolution,
        region = region_list, 
        fuel = invargs$fuel, 
        rcp = invargs$rcp, 
        stats  = invargs$stats,
        mc.cores=2,
        mc.silent=FALSE,
        FUN=get_energy_impacts
        ) 

    # browser()
    DT <- do.call("rbind", df_list) %>% dplyr::select(year, region, !!invargs$stats)
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

    # browser()
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

    if(resolution=="global") 
    DT[,resolution:="global"][]

    print("8")

    if (export)
    fwrite(
        DT,
        do.call(
            Path, c(invargs,
                list(
                    years=years,
                    resolution=resolution))))

    return(DT)

}



# get_energy_impacts(impact_type = "impacts_gj",
#     geo_level = "levels",
#     region = "USA.33.1854",
#     fuel = "electricity",
#     rcp = "rcp45",
#     stats = "mean")

get_energy_impacts = function(impact_type, resolution, geo_level, region, fuel, rcp, stats,...){

    # browser()
    if (impact_type == "impacts_gj" | impact_type == "impacts_kwh") {
        price_scen = NULL
        unit = "impactpc"
        spec = paste0("OTHERIND_", fuel)
    } else if (impact_type == "impacts_pct_gdp") {
        price_scen = "price014"
        unit = "damage"
        spec = "OTHERIND_total_energy"       
    } else {
        print("wrong fuel type")
    }
     
            df = load.median(conda_env = "risingverse-py27",
                                proj_mode = '', # '' and _dm are the two options
                                region = region, # needs to be specified for 
                                rcp = rcp, 
                                ssp = "SSP3", 
                                price_scen = price_scen, # have this as NULL, "price014", "MERGEETL", ...
                                unit =  unit, # 'damagepc' ($ pc) 'impactpc' (kwh pc) 'damage' ($ pc)
                                uncertainty = "full", # full, climate, values
                                geo_level = geo_level, # aggregated (ir agglomerations) or 'levels' (single irs)
                                iam = "low", 
                                model = "TINV_clim", 
                                adapt_scen = "fulladapt", 
                                clim_data = "GMFD", 
                                yearlist = seq(2020, 2099),  
                                spec = spec,
                                grouping_test = "semi-parametric")
            df = df %>% dplyr::select(year, region, !!stats)

            if (impact_type == "impacts_kwh") {
                gj_to_kwh <- function(x) (x * 0.0036) 
                df = df %>% dplyr::mutate_at(vars(-c(year,region)), gj_to_kwh)
                } else if (impact_type == "impacts_pct_gdp") {
                    gdp = return_region_gdp(resolution) 
                    if (region == "global") {
                        region = ""
                    }
                    gdp = gdp %>% filter(region == region)
                    df = left_join(df, gdp, by = c("region", "year")) 
                    df = df %>% rename(stats = !!stats) %>%
                    dplyr::mutate(stats = stats * 1000000000 / gdp / 0.0036) 
                    df = rename(df, !!stats:= stats)

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
    engine = get_energy_impacts
    stopifnot(!is.null(fuel), !is.null(rcp))
    invargs = list(
        impact_type = impact_type,
        rcp = rcp,
        fuel = fuel,
        stats = stats
        )
    return(list(invargs=invargs, resolution=resolution, engine=engine))
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
Path = function(impact_type, resolution, rcp, stats, years, suffix='', ...){
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

    if (regions == 'all_IRs'){
        return(c("JPN.41.R5148cbf71a2651b4","USA.33.1854"))
        # return(list$region.key)
    }
        # else if (regions == 'cities_500k'){
        #     cities_500k = memo.csv('/home/liruixue/repos/energy-code-release-2020/data/500k_cities.csv') %>%
        #     select(Region_ID)
        #     return(unique(cities_500k$Region_ID))
        # }
    else if (regions == 'iso')
        return(c("CAN","CHN"))
        # return(unique(substr(list$region.key, 1, 3)))
    else if (regions == 'states'){
        return(c("CAN","CHN"))
        # df = list %>% 
        # dplyr::filter(substr(region.key, 1, 3)=="USA") %>%
        # dplyr::mutate(region.key = gsub('^([^.]*.[^.]*).*$', '\\1', region.key))
        # return(unique(df$region.key))
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
         'SSP3-low-IR_level-gdppc-pop-gdp-all-years.csv')) 
    if (regions == 'all_IRs') {
            return(gdp[c("region","year","gdp")])
        } else if (regions == 'iso' | regions == "states") {
            regions = "states"
            regions_list = return_region_list(regions)
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
        } else if (regions == 'global') {
            global_gdp = gdp %>% group_by(year) %>%
                        summarise(gdp = sum(gdp))
            global_gdp$region = ""
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
