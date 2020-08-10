/*
Creator: Yuqi Song
modified by: Maya Norman
Last modified by: Ruixue Li

# Calculate % of the 2015-2099 change in 32 C electricity response 
# that is due to climate-driven adaptation (average across IRs)


Create data for beta maps

*/

clear all
set more off
pause on


*SET UP RELEVANT PATHS

local DROPBOX "/mnt/norgay_synology_drive"

******Set Data and Model Type********************************************************

* select data set specification
local data_type "replicated_data"
local case "Exclude" 
*"Exclude" "Include"
local bknum "break2"
local IF "_all-issues" 
*second-reading-issues revised-first-reading-issues matched-issues all-issues face-value first-reading-issues

* select econometric model specification
local grouping_test "semi-parametric" 
local model "TINV_clim" 
*TINV_clim, TINV_both, TINV_clim_EX
local submodel "income_spline"

if ("`submodel'" != "") {
	loc model_name = "`model'_`submodel'"
}
else {
	loc model_name = "`model'"
}

*Define if covariates are MA15 or TINV
if ("`model'" != "TINV_both") {
	*Climate Var Average type
	local ma_clim "TINV"
	*Income Var Average type
	local ma_inc "MA15"
}
else if ("`model'" == "TINV_both") {
    *Climate Var Average type
	local ma_clim "TINV"
	*Income Var Average type
	local ma_inc "TINV"
}

*Climate Data type
local clim_data "GMFD"

*Flow product type
local product_list "electricity other_energy"
di "`model_name'"

********************************************************************************

*Setting path shortcuts

local misc_data "/mnt/norgay_synology_drive/GCP_Reanalysis/ENERGY/code_release_data_pixel_interaction/projection_system_outputs/21jul2020_pre_data/"
local analysis_data "`DROPBOX'/GCP_Reanalysis/ENERGY/IEA_Replication/Data/Analysis/`clim_data'/rationalized_code/replicated_data/"
local projection_data "`DROPBOX'/GCP_Reanalysis/ENERGY/IEA_Replication/Projection/elver_projection/data/covariates"

* Check this lines up with your model!
local covariates "`DROPBOX'/GCP_Reanalysis/ENERGY/IEA_Replication/Data/Projection/covariates/FD_FGLS_719_Exclude_all-issues_break2_semi-parametric_TINV_clim_income_spline.csv"

***********************************************************************************
*Step 1: Load in covariate data for the future and assign income groups
***********************************************************************************

* i) get income group cutoffs
qui use "`analysis_data'/data/break10_clim`clim_data'_`case'`IF'_`bknum'_`grouping_test'_`model'_`data_type'.dta", clear
di "`analysis_data'/data/break10_clim`clim_data'_`case'`IF'_`bknum'_`grouping_test'_`model'_`data_type'.dta"

*break code if there aren't 2 income groups for each product (...currently code is not set up for other numbers of large income groups)
foreach var in `product_list' {
	sum largegpid_`var' 
	assert `r(max)' == 2
}

foreach gp of varlist largegpid_electricity largegpid_other_energy {
	preserve
		qui duplicates drop `gp', force
		sort `gp'
		local `gp'_bound0=-3
		forval i=1/2 {
			local `gp'_bound`i'=maxInc_`gp'[`i']
			di "group `gp', bound`i' ``gp'_bound`i''"
		}
	restore
}



* ii) load future covariates and calculate
***************************
**** calculate 2015 and 2099 FA ****
***************************
*load in covariates for present day
qui insheet using "`covariates'", comma names clear
keep region year loggdppc climtashdd20 climtascdd20
keep if inlist(year,2015,2099)


**************
*************
*************

* iii) assign income groups using income group cutoffs from i and future covariate data from ii


foreach var in `product_list' {
	gen deltacut_subInc_`var' = .
	qui gen lg_`var' = .
	qui replace lg_`var'=1 if loggdppc<=`largegpid_`var'_bound1'
	qui replace lg_`var'=2 if loggdppc>`largegpid_`var'_bound1' & loggdppc`yr'<=`largegpid_`var'_bound2'
	qui replace lg_`var'=2 if loggdppc>`largegpid_`var'_bound2'
	assert lg_`var' != .

	di "`var'"
	di "group 1 `largegpid_`var'_bound1'"
	di "group 2 `largegpid_`var'_bound2'"

	replace deltacut_subInc_`var' = loggdppc - `largegpid_`var'_bound1'
}


**************************************************************************************
*Step 2: Generate Impact Region Response to Reference Temp
**************************************************************************************

*load ster file
di "`analysis_data'/sters/FD_FGLS/FD_FGLS_inter_clim`clim_data'_`case'`IF'_`bknum'_`grouping_test'_poly2_`model_name'.ster"
estimates use "`analysis_data'/sters/FD_FGLS/FD_FGLS_inter_clim`clim_data'_`case'`IF'_`bknum'_`grouping_test'_poly2_`model_name'.ster"


*generate temp variables 

gen temp = .
gen temp20 = 20 
* this is weird not sure why it was here... easier to just keep #pathdependencywinning
gen abovetwenty = .
gen belowtwenty = .


*generate product specific response to a given temperature

foreach reftemp of num 32 0 {

	replace temp = `reftemp'
	replace abovetwenty = (temp >= 20)
    replace belowtwenty = (temp < 20)

 
	*generate response
	foreach var in "other_energy" "electricity" {
		
		*assign product and flow locals

		local fg = 1 
		*only one flow
		
		if "`var'"=="electricity" local pg=1
		if "`var'"=="other_energy" local pg=2

		gen response`var'`reftemp' = .

		* Loop over income groups 
		forval lg= 1(1)2 { 

			if ("`submodel'" == "income_spline") {

				di "------------- `model_name' -----------------"
				di "lg_`var'"
				di "`lg'"

				replace response`var'`reftemp' = ///
					 _b[c.indp`pg'#c.indf`fg'#c.FD_temp1_`clim_data'] * (temp - temp20) ///
					+ _b[c.indp`pg'#c.indf`fg'#c.FD_temp2_`clim_data'] * (temp^2 - temp20^2) ///
					+ _b[c.indp`pg'#c.indf`fg'#c.FD_dc1_lgdppc_MA15I`lg'temp1] * deltacut_subInc_`var' * (temp - temp20) ///
					+ _b[c.indp`pg'#c.indf`fg'#c.FD_dc1_lgdppc_MA15I`lg'temp2] * deltacut_subInc_`var' * (temp^2 - temp20^2) ///
					+ abovetwenty *_b[c.indp`pg'#c.indf`fg'#c.FD_cdd20_TINVtemp1_GMFD] * climtascdd20 * (temp - temp20) ///
					+ abovetwenty *_b[c.indp`pg'#c.indf`fg'#c.FD_cdd20_TINVtemp2_GMFD] * climtascdd20 * (temp^2 - temp20^2) ///
					+ belowtwenty *_b[c.indp`pg'#c.indf`fg'#c.FD_hdd20_TINVtemp1_GMFD] * climtashdd20 * (temp20 - temp) ///
					+ belowtwenty *_b[c.indp`pg'#c.indf`fg'#c.FD_hdd20_TINVtemp2_GMFD] * climtashdd20 * (temp20^2 - temp20) if lg_`var' == `lg'
			}

			else{
				replace response`var'`reftemp' = 
				_b[c.indp`pg'#c.indf`fg'#c.FD_I`lg'temp1_`clim_data'] * (temp - temp20) ///
					+ abovetwenty*_b[c.indp`pg'#c.indf`fg'#c.FD_cdd20_`ma_clim'I`lg'temp1_`clim_data'] * climtascdd20 * (temp - temp20) ///
					+ belowtwenty *_b[c.indp`pg'#c.indf`fg'#c.FD_hdd20_`ma_clim'I`lg'temp1_`clim_data']* climtashdd20 * (temp20 - temp) ///
					+ _b[c.indp`pg'#c.indf`fg'#c.FD_I`lg'temp2_`clim_data'] * (temp^2 - temp20^2) ///
					+ abovetwenty*_b[c.indp`pg'#c.indf`fg'#c.FD_cdd20_`ma_clim'I`lg'temp2_`clim_data'] * climtascdd20 * (temp^2 - temp20^2) ///
					+ belowtwenty *_b[c.indp`pg'#c.indf`fg'#c.FD_hdd20_`ma_clim'I`lg'temp2_`clim_data']* climtashdd20 * (temp20^2 - temp^2) if lg_`var' == `lg'

				if (("`model'" == "TINV_clim_ui" | "`submodel'" == "ui") & `lg' == 2) {
					replace response`var'`reftemp' = response`var'`reftemp' ///
					+ _b[c.indp`pg'#c.indf`fg'#c.FD_lgdppc_`ma_inc'I`lg'temp1_`clim_data']* loggdppc * (temp - temp20) ///
					+ _b[c.indp`pg'#c.indf`fg'#c.FD_lgdppc_`ma_inc'I`lg'temp2_`clim_data']* loggdppc * (temp^2 - temp20^2) if lg_`var' == `lg'
				}
			}
		}
	}
}

//clean up shop

keep region year response*
reshape long responseother_energy responseelectricity, i(region year) j(temp)
reshape long response, i(region year temp) j(product) string
**************
*************
*************

* old file: used for checking format
*local misc_data "/mnt/norgay_synology_drive/GCP_Reanalysis/ENERGY/IEA_Replication/Data/Miscellaneous"
*insheet using "`misc_data'/FD_FGLS_inter_climGMFD_Exclude_all-issues_break2_semi-parametric_poly2_TINV_clim_income_spline_beta_maps.csv"


outsheet using "`misc_data'/fulladapt.csv", comma names replace


***************************
**** calculate 2099 IA ****
***************************
* 2099 IA uses 2099 income, but 2015 climate
* so we repalce 2099 climate with 2015 climate


qui insheet using "`covariates'", comma names clear
keep region year loggdppc climtashdd20 climtascdd20
keep if inlist(year,2015,2099)
reshape wide loggdppc climtascdd20 climtashdd20, i(region) j(year)
replace climtascdd202099 = climtascdd202015
replace climtashdd202099 = climtashdd202015
reshape long loggdppc climtascdd20 climtashdd20, i(region) j(year)

**************
*************
*************

* iii) assign income groups using income group cutoffs from i and future covariate data from ii


foreach var in `product_list' {
	gen deltacut_subInc_`var' = .
	qui gen lg_`var' = .
	qui replace lg_`var'=1 if loggdppc<=`largegpid_`var'_bound1'
	qui replace lg_`var'=2 if loggdppc>`largegpid_`var'_bound1' & loggdppc`yr'<=`largegpid_`var'_bound2'
	qui replace lg_`var'=2 if loggdppc>`largegpid_`var'_bound2'
	assert lg_`var' != .

	di "`var'"
	di "group 1 `largegpid_`var'_bound1'"
	di "group 2 `largegpid_`var'_bound2'"

	replace deltacut_subInc_`var' = loggdppc - `largegpid_`var'_bound1'
}


**************************************************************************************
*Step 2: Generate Impact Region Response to Reference Temp
**************************************************************************************

*load ster file
di "`analysis_data'/sters/FD_FGLS/FD_FGLS_inter_clim`clim_data'_`case'`IF'_`bknum'_`grouping_test'_poly2_`model_name'.ster"
estimates use "`analysis_data'/sters/FD_FGLS/FD_FGLS_inter_clim`clim_data'_`case'`IF'_`bknum'_`grouping_test'_poly2_`model_name'.ster"


*generate temp variables 

gen temp = .
gen temp20 = 20 
* this is weird not sure why it was here... easier to just keep #pathdependencywinning
gen abovetwenty = .
gen belowtwenty = .


*generate product specific response to a given temperature

foreach reftemp of num 32 0 {

	replace temp = `reftemp'
	replace abovetwenty = (temp >= 20)
    replace belowtwenty = (temp < 20)

 
	*generate response
	foreach var in "other_energy" "electricity" {
		
		*assign product and flow locals

		local fg = 1 
		*only one flow
		
		if "`var'"=="electricity" local pg=1
		if "`var'"=="other_energy" local pg=2

		gen response`var'`reftemp' = .

		* Loop over income groups 
		forval lg= 1(1)2 { 

			if ("`submodel'" == "income_spline") {

				di "------------- `model_name' -----------------"
				di "lg_`var'"
				di "`lg'"

				replace response`var'`reftemp' = ///
					 _b[c.indp`pg'#c.indf`fg'#c.FD_temp1_`clim_data'] * (temp - temp20) ///
					+ _b[c.indp`pg'#c.indf`fg'#c.FD_temp2_`clim_data'] * (temp^2 - temp20^2) ///
					+ _b[c.indp`pg'#c.indf`fg'#c.FD_dc1_lgdppc_MA15I`lg'temp1] * deltacut_subInc_`var' * (temp - temp20) ///
					+ _b[c.indp`pg'#c.indf`fg'#c.FD_dc1_lgdppc_MA15I`lg'temp2] * deltacut_subInc_`var' * (temp^2 - temp20^2) ///
					+ abovetwenty *_b[c.indp`pg'#c.indf`fg'#c.FD_cdd20_TINVtemp1_GMFD] * climtascdd20 * (temp - temp20) ///
					+ abovetwenty *_b[c.indp`pg'#c.indf`fg'#c.FD_cdd20_TINVtemp2_GMFD] * climtascdd20 * (temp^2 - temp20^2) ///
					+ belowtwenty *_b[c.indp`pg'#c.indf`fg'#c.FD_hdd20_TINVtemp1_GMFD] * climtashdd20 * (temp20 - temp) ///
					+ belowtwenty *_b[c.indp`pg'#c.indf`fg'#c.FD_hdd20_TINVtemp2_GMFD] * climtashdd20 * (temp20^2 - temp20) if lg_`var' == `lg'
			}

			else{
				replace response`var'`reftemp' = 
				_b[c.indp`pg'#c.indf`fg'#c.FD_I`lg'temp1_`clim_data'] * (temp - temp20) ///
					+ abovetwenty*_b[c.indp`pg'#c.indf`fg'#c.FD_cdd20_`ma_clim'I`lg'temp1_`clim_data'] * climtascdd20 * (temp - temp20) ///
					+ belowtwenty *_b[c.indp`pg'#c.indf`fg'#c.FD_hdd20_`ma_clim'I`lg'temp1_`clim_data']* climtashdd20 * (temp20 - temp) ///
					+ _b[c.indp`pg'#c.indf`fg'#c.FD_I`lg'temp2_`clim_data'] * (temp^2 - temp20^2) ///
					+ abovetwenty*_b[c.indp`pg'#c.indf`fg'#c.FD_cdd20_`ma_clim'I`lg'temp2_`clim_data'] * climtascdd20 * (temp^2 - temp20^2) ///
					+ belowtwenty *_b[c.indp`pg'#c.indf`fg'#c.FD_hdd20_`ma_clim'I`lg'temp2_`clim_data']* climtashdd20 * (temp20^2 - temp^2) if lg_`var' == `lg'

				if (("`model'" == "TINV_clim_ui" | "`submodel'" == "ui") & `lg' == 2) {
					replace response`var'`reftemp' = response`var'`reftemp' ///
					+ _b[c.indp`pg'#c.indf`fg'#c.FD_lgdppc_`ma_inc'I`lg'temp1_`clim_data']* loggdppc * (temp - temp20) ///
					+ _b[c.indp`pg'#c.indf`fg'#c.FD_lgdppc_`ma_inc'I`lg'temp2_`clim_data']* loggdppc * (temp^2 - temp20^2) if lg_`var' == `lg'
				}
			}
		}
	}
}

//clean up shop

keep region year response*
reshape long responseother_energy responseelectricity, i(region year) j(temp)
reshape long response, i(region year temp) j(product) string
**************
*************
*************
keep if year == 2099
outsheet using "`misc_data'/incadapt.csv", comma names replace


* reshape and calculate
insheet using "/mnt/norgay_synology_drive/GCP_Reanalysis/ENERGY/code_release_data_pixel_interaction/projection_system_outputs/21jul2020_pre_data//incadapt.csv", clear
keep if product == "electricity" & temp == 32
drop product year temp
rename response incadapt2099
save incadapt2099, replace


insheet using "/mnt/norgay_synology_drive/GCP_Reanalysis/ENERGY/code_release_data_pixel_interaction/projection_system_outputs/21jul2020_pre_data//fulladapt.csv", clear
keep if year == 2015
keep if product == "electricity" & temp == 32
drop product year temp
rename response fulladapt2015
save fulladapt2015, replace

insheet using "/mnt/norgay_synology_drive/GCP_Reanalysis/ENERGY/code_release_data_pixel_interaction/projection_system_outputs/21jul2020_pre_data//fulladapt.csv", clear
keep if year == 2099
keep if product == "electricity" & temp == 32
drop product year temp
rename response fulladapt2099
save fulladapt2099, replace

use fulladapt2099, clear
merge 1:1 region using fulladapt2015, nogen
merge 1:1 region using incadapt2099, nogen
gen pct = (fulladapt2099 - incadapt2099) / (fulladapt2099 - fulladapt2015)

mean(pct)
