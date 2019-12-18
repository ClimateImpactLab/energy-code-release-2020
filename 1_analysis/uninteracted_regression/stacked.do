/*
Creator: Yuqi Song
Date last modified: 1/15/19 
Last modified by: Maya Norman

Purpose: Estimate stacked global dose response function

*/

****** Set Model Specification Locals ******************************************

local model $model

********************************************************************************
* Step 1: Load Data
********************************************************************************

use "$root/data/GMFD_`model'_regsort.dta", clear

********************************************************************************
* Step 2: Generate Population Weights for FD and FD_FGLS Regressions
********************************************************************************

//Generate population weights of countries relative to world in a year
bysort year product flow: egen year_product_flow_total_pop = total(pop)  
gen pop_weight = pop / year_product_flow_total_pop
					
// Generate the relative population weights within a FE for variance weighting
bysort region_i: egen sum_of_weights_in_FE = total(pop_weight)
gen for_variance_weighting = pop_weight / sum_of_weights_in_FE

********************************************************************************
* Step 3: Prepare Regressors and Run Regression
********************************************************************************

//time set
sort region_i year 
tset region_i year

* precip

local precip_r = ""

forval pg=1/2 {
	forval k = 1/2 {
		local precip_r = "`precip_r' c.indp`pg'#c.indf1#c.FD_precip`k'_GMFD"
	}		
}

* temp

local temp_r = ""

forval pg=1/2 {
	forval k=1/4 {
		local temp_r = "`temp_r' c.indp`pg'#c.indf1#c.FD_temp`k'_GMFD"
	}
}		
				
// run first stage regression
reghdfe FD_load_pc `temp_r' `precip_r' [pw=pop_weight], absorb(i.flow_i#i.product_i#i.year#i.subregionid) cluster(region_i) residuals(resid)
estimates save "$root/sters/FD_global_`model'", replace
					
// Generate variance weights using Equation for weights in the FGLS note 

//Generate count variable to identify singletons (ie for use in the replace line below)
drop if resid == .
    
// Generate the weighted mean at the fixed effect level    
gen weighted_residual = for_variance_weighting * resid
bysort region_i: egen weighted_mean_resid_FE_level = mean(weighted_residual)
					
// Calculate the weighted variance within each fixed effect 
gen square_term_weighted = for_variance_weighting * (resid - weighted_mean_resid_FE_level)^2
bysort region_i: egen weighted_residual_variance = total(square_term_weighted)    

// Calculate the FGLS weighs which are the pop weights divided by the variance weights in each FE found above 
gen FGLS_weight = pop_weight / (weighted_residual_variance)

//run second stage FGLS regression
reghdfe FD_load_pc `temp_r' `precip_r'  [pw=FGLS_weight], absorb(i.flow_i#i.product_i#i.year#i.subregionid) cluster(region_i)
estimates save "$root/sters/FD_FGLS_global_`model'", replace

