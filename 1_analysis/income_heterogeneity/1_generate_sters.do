/*
Creator: Yuqi Song
Date last modified: 6/17/19
//added Income Linear Interaction after First Income Group and changed to common controls to income decile regression 
//added income spline interaction with knot at break between income group 1 and income group 2
Last modified by: Maya Norman

Purpose: Generate Sters for Income Group Tests (PValue and MSE), Income Linear Interaction after First Group, and Income Spline 

*/

clear all
set more off
macro drop _all
pause on //turn pause on to troubleshoot or look for errors

//SET UP RELEVANT PATHS

if "`c(username)'" == "mayanorman"{

	local DROPBOX "/Users/`c(username)'/Dropbox"

}
else if "`c(username)'" == "manorman"{
	// This path is for running the code on Sacagawea
	local DROPBOX "/home/`c(username)'"
	local RAWDATA "/shares/gcp/estimation/energy/IEA"

}


////////////////////////////////////////////////////////////////////////////////

******Set Script Toggles********************************************************

//Set data type ie historic or replicated
global data_type "replicated_data"
local data_type $data_type

//Set zero subset case
global case "Exclude"
local case $case
global bknum "break2"
local bknum $bknum


global grouping_test "visual"
local grouping_test $grouping_test

	//Poly
	global o 2
	local o $o

	//Issue Fix
	global IF "_all-issues" //second-reading-issues revised-first-reading-issues matched-issues all-issues face-value first-reading-issues
	local IF $IF
	
******Set Model Parameters******************************************************


	//Model type-- Options: TINV_clim, TINV_both, TINV_clim_EX
		global model "TINV_clim"
		local model $model

	//Climate Data type
		global clim_data "GMFD"
		local clim_data $clim_data

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

		
	}
	
********************************************************************************

//Setting path shortcuts

local data "`DROPBOX'/GCP_Reanalysis/ENERGY/IEA_Replication/Data/Analysis/`clim_data'/rationalized_code/$data_type/data"	
local ster "`DROPBOX'/GCP_Reanalysis/ENERGY/IEA_Replication/Data/Analysis/`clim_data'/rationalized_code/$data_type/sters"	

*********************************************************************************
*Step 0: Write Programs
*********************************************************************************

//decifer from grouping string how to break up quintiles and generate income group variable

program define gen_income_groups	

syntax , grouping(string)
	
	local grouping_list ""
	
	//from grouping find: number of characters in string and number of income groups
	local qt = ceil(length("`grouping'")/2) 
	local num_chars = 2*`qt' - 1 //had some bug issues with length() so 
			
	di "`grouping' number of groups: `qt'" 
	//pause //turn pause on to check to make sure code is working as desired
			
	local g_split = "`grouping'"
		
	forval g=1/`qt' {
			
		local group`g' = substr("`g_split'", 1,1)
		local g_split = substr("`g_split'", 3,`num_chars')
		local num_chars = `num_chars' - 2
		local grouping_list "`grouping_list' group`g': `group`g''"
			
	}
			
	di "`grouping'"
	di "`grouping_list'"	
	
	//replace income indicator variable based on new grouping

	if (`qt' == 1) {

		gen group_id = 1
		qui tab group_id, gen(ind)
			
	}
	else {
		
		local lower = 2*`group1' //gpid is income deciles so need to multiply by 2 for quintile conversion
		gen group_id = 1 if gpid <= (`lower')
		
		forval gn=2/`qt' {
			local upper = `lower' + (2*`group`gn'')
			di "lower: `lower' upper: `upper' number of groups: `qt'"
			qui replace group_id = `gn' if gpid <= `upper' & gpid > `lower'
			local lower = `upper'
		}
		
		qui tab group_id, gen(ind)
	}

	global qt `qt'

end


//clean up shop to redefine income group variables 

program define drop_income_dummy_vars

	forval i=1/10 {
		cap drop I`i'* FD_I`i'* 
		cap drop ind`i' 
		cap drop FD_ind`i' ind`i'_lag
	}

	//cap drop Dum*
	cap drop group_id

end

********************************************************************************
*Step 1: Load Data and Clean
********************************************************************************
		
use "`data'/clim`clim_data'_`case'`IF'_`bknum'_`grouping_test'_`model'_`data_type'_regsort.dta", clear
pause
		
//keep specific sector-fuel
		
if ("`bknum'" == "break6") {
	keep if flow=="RESIDENT" | flow == "COMMPUB" | flow=="TOTIND" 
}
else if ("`bknum'" == "break4") {
	keep if flow == "TOTIND" | flow == "TOTOTHER" 
}
else if ("`bknum'" == "break2") {
	keep if flow=="OTHERIND"
}
		
keep if product == "electricity" | product == "other_energy"	
		
//local pooled FE**					
local FE4 = "i.flow_i#i.product_i#i.year#i.subregionid"

//set time
sort region_i year 
xtset region_i year
		
//drop income group vars 
drop_income_dummy_vars

//deal with product and flow groupings
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

//generate decile dummies for controls for all models

qui tab gpid, gen(ind)

//decile inc group lag
	forval lg=1/10 {
		gen ind`lg'_lag=L1.ind`lg'
		gen FD_ind`lg'=ind`lg'-ind`lg'_lag
	}

//income bin dummies
cap drop DumInc*
forval pg=1/2 {
	forval fg=1/`fn' {
		forval lg=1/10 {
			qui gen DumIG`lg'F`fg'P`pg'=`fd'ind`lg'*indf`fg'*indp`pg'
		}
	}
}

//drop income group vars so can create new ones
drop_income_dummy_vars

********************************************************************************
*Step 2: Run Regression for Linear Income Interaction after Cutoff
********************************************************************************

//Create Cutoff dummy

gen group_id = 1 if largegpid == 1
replace group_id = 2 if largegpid > 1
qui tab group_id, gen(ind)
local qt = 2 //number of income groups: above and below cutoff => 2 income groups

//decile inc group lag
forval lg=1/`qt' {
	gen ind`lg'_lag=L1.ind`lg'
	gen FD_ind`lg'=ind`lg'-ind`lg'_lag
}

//Generate income by cutoff control

forval lg=`qt'/`qt' {
	foreach cov in "lgdppc_`ma_inc'" {
		qui gen double I`lg'`cov'=`cov'*ind`lg'
		qui gen double I`lg'`cov'_lag=`cov'_lag*ind`lg'_lag
		qui gen double FD_I`lg'`cov'=I`lg'`cov'-I`lg'`cov'_lag
	}
}

//generate income x temp x cutoff

forval lg=`qt'/`qt' {
	forval i=1/4 {
		
		cap drop lgdppc_`ma_inc'I`lg'temp`i'_`clim_data' 
		cap drop lgdppc_`ma_inc'I`lg'temp`i'_lag_`clim_data'
		cap drop FD_lgdppc_`ma_inc'I`lg'temp`i'_`clim_data'

		qui gen double lgdppc_`ma_inc'I`lg'temp`i'_`clim_data'=lgdppc_`ma_inc'*temp`i'_`clim_data'*ind`lg' 
		qui gen double lgdppc_`ma_inc'I`lg'temp`i'_lag_`clim_data'=lgdppc_`ma_inc'`inclag'*temp`i'_lag_`clim_data'*ind`lg'_lag 
		qui gen double FD_lgdppc_`ma_inc'I`lg'temp`i'_`clim_data'=lgdppc_`ma_inc'I`lg'temp`i'_`clim_data'-lgdppc_`ma_inc'I`lg'temp`i'_lag_`clim_data' 
	}
}

//Generate above and below cuttoff x temp
forval lg=1/`qt' {
	forval i=1/4 {
		gen double I`lg'temp`i'_`clim_data'=temp`i'_`clim_data'*ind`lg'
		gen double I`lg'temp`i'_lag_`clim_data'=temp`i'_lag_`clim_data'*ind`lg'_lag
		gen double FD_I`lg'temp`i'_`clim_data'= I`lg'temp`i'_`clim_data'-I`lg'temp`i'_lag_`clim_data'
		di "I made it here `lg' `i'"
	}
}
			
//interacted temp coef, Beta by above or below cutoff
local tempregressor=""
forval pg=1/2 {
	local tempgroupC`pg'=""
	forval fg=1/`fn' {
		local tempgroupB`fg'=""
		forval lg = 1/`qt' {
			local tempgroupA`lg'=""
			forval k=1/`o' {
				local add="c.indp`pg'#c.indf`fg'#c.FD_I`lg'temp`k'_`clim_data'"
				local tempgroupA`lg'="`tempgroupA`lg'' `add'"
			}
			local tempgroupB`fg'="`tempgroupB`fg'' `tempgroupA`lg''"
		}
		local tempgroupC`pg'="`tempgroupC`pg'' `tempgroupB`fg''"
	}
	local tempregressor="`tempregressor' `tempgroupC`pg''"
}

//interacted temp x income, beta for above cutoff only

local covregressor=""

forval pg=1/2 {
	local covgroupC`pg'=""
	forval fg=1/`fn' {
		local covgroupB`fg'=""
			forval lg = `qt'/`qt' {
				local covgroupA`lg'=""
		
				forval k=1/`o' {
					local add="c.indp`pg'#c.indf`fg'#c.FD_lgdppc_`ma_inc'I`lg'temp`k'_`clim_data'"
					local covgroupA`lg'="`covgroupA`lg'' `add'"
				}
				
				local covgroupB`fg'="`covgroupB`fg'' `covgroupA`lg''"
			}
		local covgroupC`pg'="`covgroupC`pg'' `covgroupB`fg''"
	}
	local covregressor="`covregressor' `covgroupC`pg''"
}

//interacted precip coef, controls, not varying across groups
local precipregressor=""
forval pg=1/2 {
	local precipgroupC`pg'=""
	forval fg=1/`fn' {
		local precipgroupB`fg'=""
		forval k=1/2 {
			local add="c.indp`pg'#c.indf`fg'#c.FD_precip`k'_`clim_data'"
			local precipgroupB`fg'="`precipgroupB`fg'' `add'"
		}
		local precipgroupC`pg'="`precipgroupC`pg'' `precipgroupB`fg''"
	}
	local precipregressor="`precipregressor' `precipgroupC`pg''"
}

preserve //don't want to drop resid for dataset just for regression			
//run first stage regression
reghdfe FD_load_`spe'pc `tempregressor' `covregressor' `precipregressor' DumI*, absorb(`FE4') cluster(region_i) residuals(resid)
estimates save "`ster'/FD/FD_afterCut_income_inter_clim`clim_data'_`case'`IF'_`bknum'_poly`o'_`model'", replace	
			
//calculating weigts for FGLS
drop if resid==.
bysort region_i: egen omega = var(resid)
qui gen weight = 1/omega
				
//run second stage FGLS regression
reghdfe FD_load_`spe'pc `tempregressor' `covregressor' `precipregressor' DumI* [pw=weight], absorb(`FE4') cluster(region_i)
estimates save "`ster'/FD_FGLS/FD_FGLS_afterCut_income_inter_clim`clim_data'_`case'`IF'_`bknum'_poly`o'_`model'", replace
restore
pause

*******************************************************************************************
*Step 3: Run Regression for Income Spline Interaction (knot between income group 1 and 2)
*******************************************************************************************

//Create Cutoff dummy
//drop income group vars so can create new ones
drop_income_dummy_vars

gen group_id = 1 if largegpid == 1
replace group_id = 2 if largegpid > 1
qui tab group_id, gen(ind)
local qt = 2 //number of income groups: above and below cutoff => 2 income groups

//decile inc group lag
forval lg=1/`qt' {
	gen ind`lg'_lag=L1.ind`lg'
	gen FD_ind`lg'=ind`lg'-ind`lg'_lag
}

//generate income x temp x cutoff

forval lg=1/`qt' {
	forval i=1/4 {
		
		cap drop deltacut1_lgdppc_`ma_inc'I`lg'temp`i'
		cap drop deltacut1_lgdppc_`ma_inc'I`lg'temp`i'_lag
		cap drop FD_deltacut1_lgdppc_`ma_inc'I`lg'temp`i'

		qui gen double deltacut1_lgdppc_`ma_inc'I`lg'temp`i'=deltacut1_lgdppc_`ma_inc'*temp`i'_`clim_data'*ind`lg' 
		qui gen double deltacut1_lgdppc_`ma_inc'I`lg'temp`i'_lag=deltacut1_lgdppc_`ma_inc'_lag*temp`i'_lag_`clim_data'*ind`lg'_lag 
		qui gen double FD_deltacut1_lgdppc_`ma_inc'I`lg'temp`i'=deltacut1_lgdppc_`ma_inc'I`lg'temp`i'-deltacut1_lgdppc_`ma_inc'I`lg'temp`i'_lag 
	}
}
			
//interacted temp coef, Beta by above or below cutoff

local tempregressor = ""
forval pg=1/2 {
	local tempgroupC`pg' = ""
	forval fg=1/`fn' {
		local tempgroupB`fg' = ""
		forval k=1/`o' {
			local add="c.indp`pg'#c.indf`fg'#c.FD_temp`k'_`clim_data'"
			local tempgroupB`fg' = "`tempgroupB`fg'' `add'"
		}
		local tempgroupC`pg'="`tempgroupC`pg'' `tempgroupB`fg''"
	}
	local tempregressor="`tempregressor' `tempgroupC`pg''"
}

//interacted temp x income, beta for above cutoff only

local covregressor=""
forval pg=1/2 {
	local covgroupC`pg'=""
	forval fg=1/`fn' {
		local covgroupB`fg'=""
		forval k=1/`o' {
			local add="c.indp`pg'#c.indf`fg'#c.FD_deltacut1_lgdppc_`ma_inc'I2temp`k'"
			local add="`add' c.indp`pg'#c.indf`fg'#c.FD_deltacut1_lgdppc_`ma_inc'I1temp`k'"
			local covgroupB`fg'="`covgroupB`fg'' `add'"
		}					
		local covgroupC`pg'="`covgroupC`pg'' `covgroupB`fg''"
	}
	local covregressor="`covregressor' `covgroupC`pg''"
}

//interacted precip coef, controls, not varying across groups
local precipregressor=""
forval pg=1/2 {
	local precipgroupC`pg'=""
	forval fg=1/`fn' {
		local precipgroupB`fg'=""
		forval k=1/2 {
			local add="c.indp`pg'#c.indf`fg'#c.FD_precip`k'_`clim_data'"
			local precipgroupB`fg'="`precipgroupB`fg'' `add'"
		}
		local precipgroupC`pg'="`precipgroupC`pg'' `precipgroupB`fg''"
	}
	local precipregressor="`precipregressor' `precipgroupC`pg''"
}

preserve //don't want to drop resid for dataset just for regression			
//run first stage regression
reghdfe FD_load_`spe'pc `tempregressor' `covregressor' `precipregressor' DumI*, absorb(`FE4') cluster(region_i) residuals(resid)
estimates save "`ster'/FD/FD_income_spline_inter_clim`clim_data'_`case'`IF'_`bknum'_poly`o'_`model'", replace	
	
//calculating weigts for FGLS
drop if resid==.
bysort region_i: egen omega = var(resid)
qui gen weight = 1/omega
				
//run second stage FGLS regression
reghdfe FD_load_`spe'pc `tempregressor' `covregressor' `precipregressor' DumI* [pw=weight], absorb(`FE4') cluster(region_i)
estimates save "`ster'/FD_FGLS/FD_FGLS_income_spline_inter_clim`clim_data'_`case'`IF'_`bknum'_poly`o'_`model'", replace
restore
pause

********************************************************************************
*Step 4: Run Regression for Pvalue and MSE
********************************************************************************

/*
//Possible groupings: 

"1-1-1-1-1" /// //4 walls
"1-1-1-2" "1-2-1-1" "2-1-1-1" "1-1-2-1" "1-1-3" /// //3 walls
"1-2-2"  "2-1-2" "2-2-1" "1-3-1" "1-1-3" "3-1-1" /// //2 walls
"1-4" "4-1" "3-2" "2-3" /// //1 wall
"5" /// //0 walls
*/

//for decile dummies

foreach grouping in /*"1_1_1_1_1" "1_1_1_2" "1_2_1_1" "2_1_1_1" "1_1_2_1"*/ "1_2_2"  /*"2_1_2" "2_2_1" "1_3_1" "1_1_3"*/ "3_1_1" /*"1_4" "4_1" "3_2" "2_3" "5"*/ {
	
	//drop old variables
	drop_income_dummy_vars

	//reset number of income groups
	global qt 0

	//decifer from grouping string how to break up quintiles and generate income group indicators 
	gen_income_groups, grouping("`grouping'")
		
	if ($qt != 0) {
		local qt $qt
	}
	else {
		di "Warning!!!!!!!!!! gen_income_groups did not return $qt!!!!!!!!!!"
		pause
	}

	di "Review gen_income_groups output and data income grouping based on grouping `grouping'"
	pause	
	
	//decile inc group lag
	forval lg=1/`qt' {
		gen ind`lg'_lag=L1.ind`lg'
		gen FD_ind`lg'=ind`lg'-ind`lg'_lag
	}

	//decile inc groupxtemp
	forval lg=1/`qt' {
		forval i=1/4 {
			gen double I`lg'temp`i'_`clim_data'=temp`i'_`clim_data'*ind`lg'
			gen double I`lg'temp`i'_lag_`clim_data'=temp`i'_lag_`clim_data'*ind`lg'_lag
			gen double FD_I`lg'temp`i'_`clim_data'= I`lg'temp`i'_`clim_data'-I`lg'temp`i'_lag_`clim_data'
		}
	}
			
	//interacted temp coef, Beta by large group
	local tempregressor = ""
	forval pg=1/2 {
		local tempgroupC`pg' = ""
		forval fg=1/`fn' {
			local tempgroupB`fg' = ""
			forval lg = 1/`qt' {
				local tempgroupA`lg' = ""
				forval k=1/`o' {
					local add = "c.indp`pg'#c.indf`fg'#c.FD_I`lg'temp`k'_`clim_data'"
					local tempgroupA`lg' = "`tempgroupA`lg'' `add'"
				}
				local tempgroupB`fg' = "`tempgroupB`fg'' `tempgroupA`lg''"
			}
			local tempgroupC`pg' = "`tempgroupC`pg'' `tempgroupB`fg''"
		}
		local tempregressor = "`tempregressor' `tempgroupC`pg''"
	}

	//interacted precip coef, controls, not varying across groups
	local precipregressor=""
	forval pg=1/2 {
		local precipgroupC`pg'=""
		forval fg=1/`fn' {
			local precipgroupB`fg'=""
			forval k=1/2 {
				local add="c.indp`pg'#c.indf`fg'#c.FD_precip`k'_`clim_data'"
				local precipgroupB`fg'="`precipgroupB`fg'' `add'"
			}
			local precipgroupC`pg'="`precipgroupC`pg'' `precipgroupB`fg''"
		}
		local precipregressor="`precipregressor' `precipgroupC`pg''"
	}

	di "`grouping'"
	pause
	preserve //if looping over need to preserve here or else loose obs with each regression (...it gets ugly fast)		

	//run first stage regression
	reghdfe FD_load_`spe'pc `tempregressor' `precipregressor' DumI*, absorb(`FE4') cluster(region_i) residuals(resid)
	estimates save "`ster'/FD/income_grouping_`grouping'_FD_inter_clim`clim_data'_`case'`IF'_`bknum'_poly`o'_`model'", replace	
				
	pause
	
	//calculating weigts for FGLS
	drop if resid==.
	bysort region_i: egen omega = var(resid)
	qui gen weight = 1/omega
					
	//run second stage FGLS regression
	reghdfe FD_load_`spe'pc `tempregressor' `precipregressor' DumI* [pw=weight], absorb(`FE4') cluster(region_i)
	estimates save "`ster'/FD_FGLS/income_grouping_`grouping'_FD_FGLS_inter_clim`clim_data'_`case'`IF'_`bknum'_poly`o'_`model'", replace

	restore
	
	pause
}		
