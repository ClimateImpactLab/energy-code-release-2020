# Calculate % of the 2015-2099 change in 32 C electricity response 
# that is due to climate-driven adaptation (average across IRs)

# Purpose: Calculates response functions for purposes of plotting responses and
# visualizing temperature sensitivity (e.g., beta maps).  

rm(list = ls())
library(readr)
library(dplyr)
library(reticulate)
library(parallel)
library(miceadds)
library(haven)
library(ncdf4)
library(tidyr)
library(ggplot2)
library(glue)
library(data.table)

source("/home/liruixue/projection_repos/mortality/2_projection/1_utils/load_utils.R")

DB <- "/shares/gcp/estimation/mortality/release_2020/data"
OUTPUT <- "/shares/gcp/estimation/mortality/release_2020/output"

CSVV_DEFAULT = glue('{DB}/2_projection/3_impacts/main_specification/inputs/',
    'Agespec_interaction_GMFD_POLY-4_TINV_CYA_NW_w1.csvv')

MMT_DEFAULT = glue('{DB}/2_projection/3_impacts/main_specification/raw/',
    'single/rcp85/CCSM4/high/SSP3')

COV_DEFAULT = glue('{DB}/2_projection/3_impacts/main_specification/raw/',
    'single/rcp85/CCSM4/high/SSP3/mortality-allpreds.csv')

BETA_OUTPUT_DEFAULT = glue('{OUTPUT}/2_projection/figures/2a_beta_maps')
RF_OUTPUT_DEFAULT = glue('{OUTPUT}/2_projection/figures/2b_spaghettis')

#' Generates response functions, or betas (which we define as the sensitivity of
#' mortality to a given temperature day, i.e., the response function height at
#' X degrees celsius) for a given age group and future year. This function
#' is used primarily to generate values for plots, as the CIL projection
#' system handles generating response functions for actual impacts estimation. In
#' particular, this function supports Figures 5 and 6 in Carleton et al. (2019).
#' 
#' Inputs
#' ------
#' This function requires an age group and directories to the variables that
#' determine the response function in a given location and year, i.e., the
#' coefficients (`CSVV`), the minimum mortality temperature (`MMTdir`) and the
#' covariates (`covar`).
#' 
#' Outputs
#' -------
#' Dataframe long by region, temperature, year, with variables for various clipping
#' assumptions and diagnostic output. For example `betas_all_clip` corresponds to a
#' response function with all clipping assumptions used in our projections.
#' 
#' Parameters/Return
#' -----------------
#' @param age agegroup ('young', 'older', 'oldest')
#' @param CSVV Full path to CSVV file.
#' @param MMTdir Directory containing `polymins` file (usually single output
#' directory)
#' @param covar Full path to `allpreds` file (usually in single output
#' directory)
#' @param baseline baseline year for counterfactual approximation (2015)
#' @param yearlist Years for which to estimate response.
#' @param summ_temp Temperature at which to filter response to and generate
#' summary statistics with (NULL returns entire response function)
#' @param inc_adapt Determins whether income adaptation is calculated (T/F)
#' @return Dataframe containing responses for all regions in the specified
#' years, with various clipping assumptions.
calculate.beta = function(
    age,
    CSVV=CSVV_DEFAULT,
    MMTdir=MMT_DEFAULT,
    covar=COV_DEFAULT,
    baseline=2015,
    yearlist=c(2015, 2050, 2100),
    summ_temp=35,
    inc_adapt=F) {

    #load minimum ref temp 
    MMT = memo.csv(glue("{MMTdir}/",
        "Agespec_interaction_GMFD_POLY-4_TINV_CYA_NW_w1-{age}-polymins.csv"), 
        stringsAsFactors = F)

    #load covariates
    filt=glue('Agespec_interaction_GMFD_POLY-4_TINV_CYA_NW_w1-{age}')
    betas = memo.csv(covar) %>%
        dplyr::filter(
            model==filt,
            year %in% yearlist)

    #read csvv - switch this to dt fread to avoid the meta line issues.
    model = "poly"
    skip.no = ifelse(model == "poly", 18,  16) 
    csvv = read.csv(CSVV, skip = skip.no, header = F,
        sep= ",", stringsAsFactors = T)

    squish_function = stringr::str_squish

    # Update necessary additions to year list.
    if (!(baseline %in% yearlist))
        yearlist = c(baseline, yearlist)

    if (!is.null(summ_temp) & !(2100 %in% yearlist))
        yearlist = c(yearlist, 2100)

    #subset to relevant rows & remove blank spaces in characters
    csvv = csvv[-c(2,4,6, nrow(csvv)-1, nrow(csvv)), ] %>%
        rowwise() %>%
        mutate_all(~ squish_function(.)) %>%
        ungroup()

    #extract only cols from specified age group, transpose and put into df
    col.interval = ifelse(model == "poly", 11, 5) 
    if (age=="oldest")
        csvv = data.frame(t(csvv[1:3, (3+2*col.interval):(3+3*col.interval)]))
    else if (age == "young")
        csvv = data.frame(t(csvv[1:3, 1:(1+col.interval)]))
    else
        csvv = data.frame(t(csvv[1:3, (2+col.interval):(2+2*col.interval)]))

    names(csvv) = c("pred", "covar", "gamma")
    csvv$gamma = as.numeric(as.character(csvv$gamma))

    message('Data loaded. Calculating Betas...')

    # Calculate effective betas (full adaption)
    # Note that we define a "beta" as the temperature sensitivity of mortality at a given
    # daily average temp, i.e., the height of the response function at X degrees C.
    betas$tas = csvv$gamma[csvv$pred=="tas" & csvv$covar=="1"] + 
        csvv$gamma[csvv$pred=="tas" & csvv$covar=="climtas"]*betas$climtas + 
        csvv$gamma[csvv$pred=="tas" & csvv$covar=="loggdppc"]*betas$loggdppc

    betas$tas2 = csvv$gamma[csvv$pred=="tas2" & csvv$covar=="1"] + 
        csvv$gamma[csvv$pred=="tas2" & csvv$covar=="climtas"]*betas$climtas + 
        csvv$gamma[csvv$pred=="tas2" & csvv$covar=="loggdppc"]*betas$loggdppc

    betas$tas3 = csvv$gamma[csvv$pred=="tas3" & csvv$covar=="1"] + 
        csvv$gamma[csvv$pred=="tas3" & csvv$covar=="climtas"]*betas$climtas + 
        csvv$gamma[csvv$pred=="tas3" & csvv$covar=="loggdppc"]*betas$loggdppc

    betas$tas4 = csvv$gamma[csvv$pred=="tas4" & csvv$covar=="1"] + 
        csvv$gamma[csvv$pred=="tas4" & csvv$covar=="climtas"]*betas$climtas + 
        csvv$gamma[csvv$pred=="tas4" & csvv$covar=="loggdppc"]*betas$loggdppc

    # Calculate effective betas (clim adapt only) for clipping assumption that rising income
    # cannot increase temp. sensitivity of mortality (affectionately called "good-money" clipping).
    betas$tas_clim = csvv$gamma[csvv$pred=="tas" & csvv$covar=="1"] + 
        csvv$gamma[csvv$pred=="tas" & csvv$covar=="climtas"]*betas$climtas + 
        csvv$gamma[csvv$pred=="tas" & csvv$covar=="loggdppc"]*betas$loggdppc[betas$year==baseline]

    betas$tas2_clim = csvv$gamma[csvv$pred=="tas2" & csvv$covar=="1"] + 
        csvv$gamma[csvv$pred=="tas2" & csvv$covar=="climtas"]*betas$climtas + 
        csvv$gamma[csvv$pred=="tas2" & csvv$covar=="loggdppc"]*betas$loggdppc[betas$year==baseline]

    betas$tas3_clim = csvv$gamma[csvv$pred=="tas3" & csvv$covar=="1"] + 
        csvv$gamma[csvv$pred=="tas3" & csvv$covar=="climtas"]*betas$climtas + 
        csvv$gamma[csvv$pred=="tas3" & csvv$covar=="loggdppc"]*betas$loggdppc[betas$year==baseline]

    betas$tas4_clim = csvv$gamma[csvv$pred=="tas4" & csvv$covar=="1"] + 
        csvv$gamma[csvv$pred=="tas4" & csvv$covar=="climtas"]*betas$climtas + 
        csvv$gamma[csvv$pred=="tas4" & csvv$covar=="loggdppc"]*betas$loggdppc[betas$year==baseline]

    if (inc_adapt) {
        betas$tas_inc <- csvv$gamma[csvv$pred=="tas" & csvv$covar=="1"] +
            csvv$gamma[csvv$pred=="tas" & csvv$covar=="climtas"]*betas$climtas[betas$year==baseline] +
            csvv$gamma[csvv$pred=="tas" & csvv$covar=="loggdppc"]*betas$loggdppc
        betas$tas2_inc <- csvv$gamma[csvv$pred=="tas2" & csvv$covar=="1"] +
            csvv$gamma[csvv$pred=="tas2" & csvv$covar=="climtas"]*betas$climtas[betas$year==baseline] +
            csvv$gamma[csvv$pred=="tas2" & csvv$covar=="loggdppc"]*betas$loggdppc
        betas$tas3_inc <- csvv$gamma[csvv$pred=="tas3" & csvv$covar=="1"] +
            csvv$gamma[csvv$pred=="tas3" & csvv$covar=="climtas"]*betas$climtas[betas$year==baseline] +
            csvv$gamma[csvv$pred=="tas3" & csvv$covar=="loggdppc"]*betas$loggdppc
        betas$tas4_inc <- csvv$gamma[csvv$pred=="tas4" & csvv$covar=="1"] +
            csvv$gamma[csvv$pred=="tas4" & csvv$covar=="climtas"]*betas$climtas[betas$year==baseline] +
            csvv$gamma[csvv$pred=="tas4" & csvv$covar=="loggdppc"]*betas$loggdppc
    }


    #create vector of temperatures
    temp = seq(-20,50) 

    #expand dataframe by length(temp)
    betas.expanded = betas[rep(seq_len(nrow(betas)), length(temp)), ]
    betas.expanded = betas.expanded[order(betas.expanded$region, betas.expanded$year),]
    betas.expanded$temp = temp
    
    betas.expanded = left_join(betas.expanded, MMT, by = c("region"))

    response = calculate_response(betas.expanded, temp, inc_adapt)




################## want this part! #######################

    if (!is.null(summ_temp)) {

        # Calculate percentage decrease in marginal impacts caused by increasing incomes
        if (inc_adapt) {
            b_2015 = mean(response$betas_all_clip[
                response$year==baseline & response$temp==summ_temp])
            full_2100 = mean(response$betas_all_clip[
                response$year==2100 & response$temp==summ_temp])
            inc_2100 = mean(response$betas_all_clip_inc[
                response$year==2100 & response$temp==summ_temp]) 
            response$decline = (b_2015 - inc_2100)/(b_2015 - full_2100)*100 
        }

################### want this part! ######################

        # Store temperature distribution weighted average response to days above 30C in 
        # 2015 in Houston (Harris County USA.44.2628) and Seattle (King County USA.48.2971) 
        # relative to 20C (do this for each age group).

        # Houston: In sample proportion of days above 30C
        weights = list(
            '30' = .8344115,
            '31' = .1491691, 
            '32' = .0153181, 
            '33' = .0011013)

        vals = c()
        for (temp in c(30, 31, 32, 33)) {
            v = ( response$betas_all_clip[response$temp==temp &
                response$region=="USA.44.2628" & 
                response$year == baseline] - 
                response$betas_all_clip[response$temp==20 &
                response$region=="USA.44.2628" & 
                response$year == 2015] ) * weights[[paste(temp)]]
            vals = c(vals, v)
        }
        response$houston = sum(vals)

        # Seattle: only one day at 30C in our entire sample, so just 
        # taking the 30C beta.
        response$seattle = ( 
            response$betas_all_clip[response$temp==30 &
                response$region=="USA.48.2971" &
                response$year == baseline] - 
            response$betas_all_clip[response$temp==20 &
                response$region=="USA.48.2971" &
                response$year == 2015] )

        # Subset to just the necessary temperature
        response = subset(response, response$temp==summ_temp)
    }

    return(response)
}


#' This is merely a helper function for `calculate.beta` above. It uses the model
#' coefficients, MMT and covariaates to calculate the temperature-mortality
#' response accounting for the various clipping assumptions, which are noted
#' in-code but best outlined in the main text and appendix of Carleton et al. (2019).
#'
#' @param betas.expanded Intermediate dataframe from `calculate.beta` containing
# coefficients, MMT, and covariates.
#' @param temp Vector of temperatures at which to calculate the response. Note
#' that due to weak monotonicity clipping, this vector must include a wide range
#' of temperatures, even if the function is only mean to output the beta at one
#' particular temperature value.
#' @param inc_adapt Determins whether income adaptation is calculated (T/F)
#' @return Dataframe containing clipped response functions.


calculate_response = function( betas.expanded, temp, inc_adapt=F) {

    # Calculate response (full adaptation)
    # Note that we define a "beta" as the temperature sensitivity of mortality at a given
    # daily average temp, i.e., the height of the response function at X degrees C.
    betas.expanded$resp = betas.expanded$tas*(betas.expanded$temp) + 
        betas.expanded$tas2*(betas.expanded$temp^2) + 
        betas.expanded$tas3*(betas.expanded$temp^3) + 
        betas.expanded$tas4*(betas.expanded$temp^4)

    betas.expanded$resp_ref = betas.expanded$tas*(betas.expanded$analytic) + 
        betas.expanded$tas2*(betas.expanded$analytic^2) + 
        betas.expanded$tas3*(betas.expanded$analytic^3) + 
        betas.expanded$tas4*(betas.expanded$analytic^4)

    betas.expanded$betas = betas.expanded$resp - betas.expanded$resp_ref

    #calculate response (clim adapt)
    betas.expanded$resp_clim = betas.expanded$tas_clim*(betas.expanded$temp) + 
        betas.expanded$tas2_clim*(betas.expanded$temp^2) + 
        betas.expanded$tas3_clim*(betas.expanded$temp^3) + 
        betas.expanded$tas4_clim*(betas.expanded$temp^4)

    betas.expanded$resp_ref_clim = betas.expanded$tas_clim*(betas.expanded$analytic) + 
        betas.expanded$tas2_clim*(betas.expanded$analytic^2) + 
        betas.expanded$tas3_clim*(betas.expanded$analytic^3) + 
        betas.expanded$tas4_clim*(betas.expanded$analytic^4)

    betas.expanded$betas_clim = betas.expanded$resp_clim - betas.expanded$resp_ref_clim

    # Rising income cannot increase temp. sensitivity of mortality (goodmoney-clipping)
    # Compare climadapt and fulladapt response and take the lesser of the two.
    betas.expanded$clipped_gm_betas = pmin(betas.expanded$betas, betas.expanded$betas_clim) 

    #indicator variable
    betas.expanded$gm_clipping =ifelse(
        betas.expanded$clipped_gm_betas != betas.expanded$betas,
        1, 0)

    # No negative temp. sensitivity (Levels-clipping)
    betas.expanded$levels_clipping = ifelse(
        betas.expanded$clipped_gm_betas<0,
        TRUE, FALSE)

    betas.expanded$clipped_lvl_betas = ifelse(
        betas.expanded$clipped_gm_betas < 0, 
        0, betas.expanded$clipped_gm_betas)

    # Weak increasing monotonicity (U-clipping)
    betas.expanded$clipped_u_betas = ifelse(
        betas.expanded$temp >= betas.expanded$analytic, 
        betas.expanded$clipped_lvl_betas, 0) 

    betas.expanded$clipped_u_betas_cold = ifelse(
        betas.expanded$temp < betas.expanded$analytic, 
        betas.expanded$clipped_lvl_betas, 0) 

    betas.expanded = betas.expanded %>% 
        dplyr::group_by(region, year) %>% 
        dplyr::arrange(-temp, .by_group=T) %>%
        dplyr::mutate(clipped_u2_betas_cold = cummax(clipped_u_betas_cold)) %>%
        dplyr::arrange(temp, .by_group=T) %>%
        dplyr::mutate(clipped_u2_betas = cummax(clipped_u_betas),
            betas_all_clip = clipped_u2_betas + clipped_u2_betas_cold) %>%
        ungroup()

    betas.expanded$u_clipping = ifelse(
        betas.expanded$clipped_u_betas != betas.expanded$betas_all_clip,
        TRUE, FALSE)

    betas.expanded$clipped = ifelse(
        betas.expanded$u_clipping | betas.expanded$levels_clipping,
        1, 0)
    
    # Repeat beta calculation process for incadapt if it's needed.
    if (inc_adapt) {


        betas.expanded$resp_inc = betas.expanded$tas_inc*(betas.expanded$temp) + 
            betas.expanded$tas2_inc*(betas.expanded$temp^2) + 
            betas.expanded$tas3_inc*(betas.expanded$temp^3) + 
            betas.expanded$tas4_inc*(betas.expanded$temp^4)

        betas.expanded$resp_ref_inc = betas.expanded$tas_inc*(betas.expanded$analytic) + 
            betas.expanded$tas2_inc*(betas.expanded$analytic^2) + 
            betas.expanded$tas3_inc*(betas.expanded$analytic^3) + 
            betas.expanded$tas4_inc*(betas.expanded$analytic^4)

        betas.expanded$betas_inc = betas.expanded$resp_inc - betas.expanded$resp_ref_inc


        # Rising income cannot increase temp. sensitivity of mortality (goodmoney-clipping)
        betas.expanded$clipped_gm_betas_inc = pmin(
            betas.expanded$betas_inc, betas.expanded$betas_clim) 
        betas.expanded$gm_clipping_inc =ifelse(
            betas.expanded$clipped_gm_betas_inc != betas.expanded$betas_inc,
            1, 0) 
      
        # No negative temp. sensitivity (Levels-clipping)
        betas.expanded$levels_clipping_inc = ifelse(
            betas.expanded$clipped_gm_betas_inc<0,
            1, 0)

        betas.expanded$clipped_lvl_betas_inc = ifelse(
            betas.expanded$clipped_gm_betas_inc < 0,
            0, betas.expanded$clipped_gm_betas_inc)
      
        # Weak increasing monotonicity (U-clipping)
        betas.expanded$clipped_u_betas_inc = ifelse(
            betas.expanded$temp >= betas.expanded$analytic, 
            betas.expanded$clipped_lvl_betas_inc, 0) 

        betas.expanded$clipped_u_betas_inc_cold = ifelse(
            betas.expanded$temp < betas.expanded$analytic, 
            betas.expanded$clipped_lvl_betas_inc, 0) 

        betas.expanded = betas.expanded %>% 
            dplyr::group_by(region, year) %>% 
            dplyr::arrange(-temp, .by_group=T) %>%
            dplyr::mutate(clipped_u2_betas_inc_cold = cummax(clipped_u_betas_inc_cold)) %>%
            dplyr::arrange(temp, .by_group=T) %>%
            dplyr::mutate(clipped_u2_betas_inc = cummax(clipped_u_betas_inc),
                betas_all_clip_inc = clipped_u2_betas_inc + clipped_u2_betas_inc_cold) %>%
            ungroup()

        betas.expanded$u_clipping_inc = ifelse(
            betas.expanded$clipped_u_betas_inc != betas.expanded$betas_all_clip_inc,
            1, 0)
    }
    return(betas.expanded)
}


