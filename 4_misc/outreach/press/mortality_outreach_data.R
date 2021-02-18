library(glue)
library(R.cache)

cilpath.r:::cilpath()
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
            NA, 'pop', 1, get_econvar), 
        long_run_av_temp_C=c(
            NA,'climtas', 1, get_mortality_covariates), 
        change_in_deathrate=c(
            "fulladapt", "rates", 1, get_mortality_impacts),
        mortality_risk=c(
            "fulladaptcosts", "rates", 1, get_mortality_impacts),
        adaptation_cost=c(
            "costs", "dollars", 1/1000000, get_mortality_damages),
        damages=c(
            'deathcosts', 'dollars', 1/1000000, get_mortality_damages),
        damages_percent_GDP=c(
            'deathcosts', 'share_gdp', 100, get_mortality_damages),
        excess_deaths=c(
            "fulladapt", "levels", 1, get_mortality_impacts))

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

    if (identical(engine[[1]], get_mortality_impacts) | 
        identical(engine[[1]], get_mortality_damages)) {

        stopifnot(!is.null(qtile), !is.null(rcp), !is.null(ssp))

        invargs = list(
            scn=paste(unit_list[[unit]][1]),
            units=paste(unit_list[[unit]][2]),
            scale_variable=unlist(unit_list[[unit]][3]),
            regions=geography_list[[geography]],
            rcp=rcp,
            ssp=ssp,
            qtile=qtile)

    } else if (identical(engine[[1]], get_econvar)) {

        stopifnot(!is.null(ssp))

        invargs = list(
            units=paste(unit_list[[unit]][2]),
            scale_variable=unlist(unit_list[[unit]][3]),
            regions=geography_list[[geography]],
            ssp=ssp)

    } else if (identical(engine[[1]], get_mortality_covariates)) {

        stopifnot(!is.null(rcp))
        rcp = glue('{DB}/2_projection/3_impacts/',
        'main_specification/raw/single/{rcp}/CCSM4/low/SSP3')

        invargs = list(
            single_path=rcp,
            units=paste(unit_list[[unit]][2]),
            regions=geography_list[[geography]])
    }

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
    base = "/mnt/norgay_synology_drive/Global ACP/MORTALITY/Replication_2018"
    if (unit =='long_run_av_temp_C') {
        dir = glue("{base}/3_Output/8_comms/impacts_outreach/{geography_name}/climate")
        file = glue("unit_{unit}_geography_{geography_name}_years_{years}_{rcp}{suffix}.csv")
    } else if (unit =='income_per_capita' | unit == 'population_projections') {
        dir = glue("{base}/3_Output/8_comms/impacts_outreach/{geography_name}/population_and_income")
        file = glue("unit_{unit}_geography_{geography_name}_years_{years}_{ssp}{suffix}.csv")
    } else {
        dir = glue("{base}/3_Output/8_comms/impacts_outreach/{geography_name}/{rcp}/{ssp}")
        file = glue("unit_{unit}_geography_{geography_name}_years_{years}_{rcp}_{ssp}_quantiles_{qtile}{suffix}.csv")
    }
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