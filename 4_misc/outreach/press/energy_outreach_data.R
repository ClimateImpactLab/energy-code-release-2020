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


db = '/mnt/CIL_energy/'
output = '/mnt/CIL_energy/code_release_data_pixel_interaction/'

dir = paste0('/shares/gcp/social/parameters/energy_pixel_interaction/extraction/',
                'multi-models/rationalized_code/break2_Exclude_all-issues_semi-parametric/')

# Make sure you are in the risingverse-py27 for this... 
projection.packages <- paste0(REPO,"/energy-code-release-2020/2_projection/0_packages_programs_inputs/extract_projection_outputs/")
setwd(paste0(REPO))

# Source codes that help us load projection system outputs
miceadds::source.all(paste0(projection.packages,"load_projection/"))


source(glue("{REPO}/mortality/2_projection/impacts.R"))
source(glue("{REPO}/mortality/2_projection/econvar.R"))
source(glue("{REPO}/mortality/3_valuation/2_calculate_damages/damages.R"))

#' Wrapper that calls get_mortality_impacts with converted parameters.
#' @param years what years to output ("averaged","all")
#' @param ... other parameters as in the DB outreach paper
 
#' @return Data table of processed impacts.
ProcessImpacts = function(years, export=FALSE, ...){

    ParamList = do.call(ParamConvert,list(...))

    invargs = ParamList[['invargs']]
    outvargs = ParamList[['outvargs']]
    engine = ParamList[['engine']]

    DT = do.call(engine[[1]], c(invargs, list(as.DT=TRUE)))

    if(list(...)$geography=="state_abbrev") 
        DT = StatesNames(DT)

    years_list = list(
    all=NULL,
    averaged=list(
        seq(2020,2039),
        seq(2040,2059),
        seq(2080,2099)))

    if (!is.null(years_list[[years]]))
        DT = YearChunks(DT,years_list[[years]])
    else
        setnames(DT, old='year', new='years')


    DT = YearsReshape(DT)
   
    if(identical(names(DT), c("region", as.character(seq(2020, 2099))))) 
        setnames(
            DT, 
            as.character(seq(2020,2099)), 
            glue("year_{as.character(seq(2020,2099))}"))

    setnames(DT, "region", list(...)$geography)

    if(list(...)$geography=="Global") 
        DT[,(list(...)$geography):="Global"][]

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




get_impacts_pct_gdp = function(fuel, price_scen, unit, year, output){
    
    spec = paste0("OTHERIND_", fuel)
    df = load.median(conda_env = "risingverse-py27",
                    proj_mode = '', # '' and _dm are the two options
                    region = NULL, # needs to be specified for 
                    rcp = "rcp85", 
                    ssp = "SSP3", 
                    price_scen = price_scen, # have this as NULL, "price014", "MERGEETL", ...
                    unit = "damage", # 'damagepc' ($ pc) 'impactpc' (kwh pc) 'damage' ($ pc)
                    uncertainty = "climate", # full, climate, values
                    geo_level = "levels", # aggregated (ir agglomerations) or 'levels' (single irs)
                    iam = "high", 
                    model = "TINV_clim", 
                    adapt_scen = "fulladapt", 
                    clim_data = "GMFD", 
                    yearlist = year,  
                    spec = spec,
                    grouping_test = "semi-parametric") %>%
        dplyr::select(region, year, mean) %>%
        dplyr::filter(year == !!year)

    price_tag = ifelse(is.null(price_scen), "impact_pc", price)

    df_gdp = read_csv(paste0(DB_data, '/projection_system_outputs/covariates/', 
                           "/SSP3-global-gdp-time_series.csv"))

}

get_impacts_gj = function(fuel, rcp, unit, year, levels){
    
    spec = paste0("OTHERIND_", fuel)
    df = load.median(conda_env = "risingverse-py27",
                    proj_mode = '', # '' and _dm are the two options
                    region = NULL, # needs to be specified for 
                    rcp = rcp, 
                    ssp = "SSP3", 
                    price_scen = NULL, # have this as NULL, "price014", "MERGEETL", ...
                    unit =  unit, # 'damagepc' ($ pc) 'impactpc' (kwh pc) 'damage' ($ pc)
                    uncertainty = "climate", # full, climate, values
                    geo_level = "levels", # aggregated (ir agglomerations) or 'levels' (single irs)
                    iam = "low", 
                    model = "TINV_clim", 
                    adapt_scen = "fulladapt", 
                    clim_data = "GMFD", 
                    yearlist = year,  
                    spec = spec,
                    grouping_test = "semi-parametric") %>%
        dplyr::select(region, year, mean) %>%
        dplyr::filter(year == !!year)

    price_tag = ifelse(is.null(price_scen), "impact_pc", price)
    return(df)
}



#converts DB paper outreach requests into get_mortality_impacts parameters.
ParamConvert = function(
    unit, 
    geography, 
    rcp=NULL, 
    ssp=NULL, 
    qtile=NULL,
    ...){

    # c(scn, units, scale_variable, engine)
    unit_list = list(
        income_per_capita=c(
            NA, 'gdppc', 1, get_econvar), 
        population_projections=c(
            NA, 'pop', 1, get_econvar))

    geography_list = list(
        ISO_code="iso", 
        state_abbrev="states", 
        Region_ID="all", 
        Global="global")

    geography_names_list = list(
        ISO_code="country_level", 
        state_abbrev="US_states", 
        Region_ID="impact_regions", 
        Global="global")

    engine=unlist(unit_list[[unit]][4])

    outvargs = list(geography_name=geography_names_list[[geography]])

    return(list(invargs=invargs, outvargs=outvargs, engine=engine))

}


#reshapes the data to get region in rows and years in columns
YearsReshape = function(DT){

    var = names(DT)[!(names(DT) %in% c('region', 'years'))]
    setnames(DT,var,"value")
    DT=data.table:::dcast(DT,region + value ~ years, value.var='value')
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


#add US states name to states ID
StatesNames = function(df){

    DT=setkey(as.data.table(df),region)
    check = setkey(setnames(
        memo.csv(glue('{DB}/2_projection/1_regions/hierarchy.csv')),
        "region-key", "region")[,.(region, name)],region)
    DT=check[DT][,region:=name][,name:=NULL][]
    return(DT)

}