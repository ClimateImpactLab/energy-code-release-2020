/*
Creator: Yuqi Song
Date last modified: 1/15/19 
Last modified by: Maya Norman

Purpose: Run stacked global regression (generate sters)

Climate Data Options: BEST, GMFD, GMFD_v3
Model Options: TINV_clim, TINV_both_64, TINV_clim_EX

*/

//SET UP RELEVANT PATHS

if "`c(username)'" == "mayanorman"{

	local DROPBOX "/Users/`c(username)'/Dropbox"

}
else if "`c(username)'" == "manorman"{
	// This path is for running the code on Sacagawea
	local DROPBOX "/home/`c(username)'"
	local RAWDATA "/shares/gcp/estimation/energy/IEA"

}

******Set Script Toggles********************************************************

local data_type $data_type

//Number of data subsets used to estimate
local bknum $bknum

local case $case // "Exclude" "Include"

local region $region //options are OECD or global

//winsorized data

local winsorization $winsorization
local level $level

//income grouping test
local grouping_test $grouping_test

//whether dd's are interacted for all temps or just below and above 20
local clim_interaction $clim_interaction 

local clim_inter_type $clim_inter_type //Tmean or cdd/hdd ("")

******Set Model Parameters******************************************************

	//Model type-- Options: TINV_clim, TINV_both, TINV_clim_EX
		local model $model
		local model_name $model
	
	//Climate Data type
		local clim_data $clim_data
		
	//Issue Fix
	
	local IF $IF
	
	
	//Specification:
	
		local FD $FD
		
		if ("`FD'" == "noFD") {

			local fd ""
	
		}
		else if ("`FD'" == "FD") {

			local fd "FD_"

		}
	
	//Define if covariates are MA15 or TINV
	if ("$model" != "TINV_both") {
		//Climate Var Average type
		local ma_clim "TINV"

		//Income Var Average type
		local ma_inc "MA15"

	}
	else if ("$model" == "TINV_both") {
	
		//Climate Var Average type
		local ma_clim "TINV"

		//Income Var Average type
		local ma_inc "TINV"
		
		//set submodel at default
		local submodel ""
		
	}


********************************************************************************

//Setting path shortcuts

local data "`DROPBOX'/GCP_Reanalysis/ENERGY/IEA_Replication/Data/Analysis/`clim_data'/rationalized_code/$data_type/data"	
local ster "`DROPBOX'/GCP_Reanalysis/ENERGY/IEA_Replication/Data/Analysis/`clim_data'/rationalized_code/$data_type/sters"	

if ("$data_type"=="historic_data") {
	local DATA "`DROPBOX'/GCP_Reanalysis/ENERGY/IEA/Yuqi_Codes/Data"
}
else if ("$data_type"=="replicated_data") {
	local DATA "`DROPBOX'/GCP_Reanalysis/ENERGY/IEA_Replication/Data"
}

//bring in oecd identifier
insheet using "`DROPBOX'/GCP_Reanalysis/ENERGY/IEA_Replication/Data/Cleaning/cleaned_coded_issues.csv", clear
keep country oecd
collapse (mean) oecd, by(country)
tempfile OECD
save `OECD', replace

use "`data'/clim`clim_data'_`case'`IF'_`bknum'_`grouping_test'_`model'_`data_type'_regsort.dta", clear

merge m:1 country using `OECD', keep(1 3)
// clean data  - replace the non-OECD missing values with zeros
replace oecd = 1 if country == "LVA"
replace oecd = 0 if country == "YUGOND"
replace oecd = 0 if country == "PRK"
replace oecd = 0 if country == "PHL"
replace oecd = 0 if country == "PAN"
replace oecd = 0 if country == "MUS"
replace oecd = 0 if country == "AGO"
replace oecd = 0 if country == "ARG"
replace oecd = 0 if country == "COL"
replace oecd = 0 if country == "FSUND"
replace oecd = 0 if inlist(country,"BGR","NPL", "COD", "NIC", "MLI")
drop if _merge == 2
//drop _merge

if ("`region'" == "OECD") {
	keep if oecd == 1
}

//tab product
*1=electricity, 2=other_energy*
tab product, gen(indp)
egen product_i = group(product)

//tab flow
*1=COMMPUB, 2=RESIDENT, 3=TOTIND*
tab flow, gen(indf)
egen flow_i = group(flow)
summ flow_i
local fn = `r(max)'

********************************************************************************
**                           RUNNING REGRESSIONS                              **
********************************************************************************
*--Global Total Energy Consumption Polynomial Regression for FD-FGLS-FE Model--*

//Generate population weights of countries relative to world in a year
bysort year product flow: egen year_product_flow_total_pop = total(pop)  
gen pop_weight = pop / year_product_flow_total_pop
					
// Generate the relative population weights within a FE for variance weighting
bysort region_i: egen sum_of_weights_in_FE = total(pop_weight)
gen for_variance_weighting = pop_weight / sum_of_weights_in_FE

//time set
sort region_i year 
tset region_i year
				
pause

//interacted temp coef, beta by large group
local tempregressor=""
forval pg=1/2 {
	local tempgroupC`pg'=""
	forval fg=1/`fn' {
		local tempgroupB`fg'=""
		forval k=1/4 {
			local add="c.indp`pg'#c.indf`fg'#c.FD_temp`k'"
			local tempgroupB`fg'="`tempgroupB`fg'' `add'"
		}
		local tempgroupC`pg'="`tempgroupC`pg'' `tempgroupB`fg''"
	}
	local tempregressor="`tempregressor' `tempgroupC`pg''"
}
					

//interacted precip coef, controls, not varying across groups
local precipregressor=""
	forval pg=1/2 {
		local precipgroupC`pg'=""
		forval fg=1/`fn' {
			local precipgroupB`fg'=""
			forval k=1/2 {
				local add="c.indp`pg'#c.indf`fg'#c.FD_precip`k'"
				local precipgroupB`fg'="`precipgroupB`fg'' `add'"
			}
			local precipgroupC`pg'="`precipgroupC`pg'' `precipgroupB`fg''"
		}
		local precipregressor="`precipregressor' `precipgroupC`pg''"
}
				
				
di "`tempregressor'"
pause
//run first stage regression
reghdfe FD_load_`spe'pc `tempregressor' `precipregressor'  [pw=pop_weight], absorb(i.flow_i#i.product_i#i.year#i.subregionid) cluster(cluster_i) residuals(resid)
estimates save "`ster'/`FD'/`region'_`FD'_clim`clim_data'_`case'`IF'_`bknum'_poly4_`model_name'", replace
					
// Generate variance weights using Equation for weights in the FGLS note 
pause
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
reghdfe FD_load_`spe'pc `tempregressor' `precipregressor' [pw=FGLS_weight], absorb(i.flow_i#i.product_i#i.year#i.subregionid) cluster(cluster_i)
estimates save "`ster'/`FD'_FGLS/`region'_`FD'_FGLS_clim`clim_data'_`case'`IF'_`bknum'_poly4_`model_name'", replace

