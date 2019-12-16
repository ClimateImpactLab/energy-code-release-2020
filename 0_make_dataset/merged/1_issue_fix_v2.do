/*
Creator: Yuqi Song
Date last modified: 2/13/19 
Last modified by: Maya Norman

Purpose: Apply Coded Issues

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

// set data type ie historic or replicated
local data_type $data_type


// set coded issue type

local issue_type $issue_type


// toggle for dropping exclusively estimated data

local model $model

******Set Model Parameters******************************************************

//Climate Data type
local clim_data $clim_data
	
//Zero Subset Case
local case $case 
	
//flow product breakdown

local bknum $bknum
		
if "`bknum'" == "break2" {
	
	local flowlist "COMPILE"
	local productlist "other_energy electricity"

}

else if "`bknum'" == "break4" {
	
	local flowlist "TOTOTHER TOTIND"
	local productlist "other_energy electricity"

}

else if "`bknum'" == "break6" {
	
	local flowlist "RESIDENT TOTIND COMMPUB"
	local productlist "other_energy electricity"

}
	
********************************************************************************

//Setting path shortcuts

local DATA "`DROPBOX'/GCP_Reanalysis/ENERGY/IEA/Yuqi_Codes/Data"
local replicated_data "`DROPBOX'/GCP_Reanalysis/ENERGY/IEA_Replication/Data"


********************************************************************************
*Step 1: Load Energy Data and Coded Issues to Apply to Energy Dataset
********************************************************************************

//Part A: Make Energy Dataset Tempfile and retrieve Country List for looping
use "`replicated_data'/Analysis/`clim_data'/rationalized_code/`data_type'/data/IEA_Merged_long_`clim_data'.dta", clear
drop countryid
keep if year>=1971 & year<=2012
generate FEtag="G"
tempfile energy_long
save `energy_long', replace
keep if temp1_`clim_data' !=.
duplicates drop country, force
levelsof country, local(countrylist)

//Part B: Load Coded Issues - type/set of coded issues specified with toggle at top of code

if ("`issue_type'" == "first-reading-issues") {
	use "`DATA'/issue_coding_3sectors_fix.dta", clear
	local type_of_issues "oldies"
}
else {
	di "`replicated_data'/Cleaning/cleaned_coded_issues.csv"
	insheet using "`replicated_data'/Cleaning/cleaned_coded_issues.csv", comma names clear
	pause
	foreach variable in "grey" "tot_drop" "flag_drop" "fuel_keep" {
		replace `variable' = 0 if `variable' == .
	}
	
	if ("`issue_type'" == "second-reading-issues") {
		keep if no_match == 2 | no_match == 0
		local type_of_issues "seconds"
	} 
	else if ("`issue_type'" == "revised-first-reading-issues") {
		keep if no_match == 1 | no_match == 0
		local type_of_issues "oldies revised"
	}
	else if ("`issue_type'" == "matched-issues") {
		keep if no_match == 0
		local type_of_issues "matchy matchy"
	}
}

di "Issue subset: `type_of_issues'"

di "Did we set up exclusively estimated data to be dropped?"
//Part C: Set up Exclusively Estimated Observations to be Dropped if drop_ex_est toggle set
if ("`model'" == "TINV_clim_EX" ) {
	replace grey = 9 if ex_ex == 1 
	di "Set up exclusively estimated data to be dropped."
}
else {
	di "No"
}

pause
********************************************************************************
*Step 2: Clean Coded Issues and Save in Issue Type Specific Datasets
********************************************************************************

**replace to match the main file**
keep country sector fuel issue_code year_start year_end oecd flag_drop grey tot_drop fuel_keep

foreach var in fuel sector {
	qui replace `var'="" if `var' == "." | `var'==""
}

rename sector flow
rename fuel product

replace product="biofuels" if product=="biofuels and waste" | product == "biofuelsandwaste"
replace product="heat_other" if product=="heat"
replace product="natural_gas" if product=="natural gas" | product=="naturalgas"
replace product="oil_products" if product=="oil"
replace product="solar" if product=="solar and geothermal"
replace product="all" if product==""

**sort the double counting for LVA**
replace oecd=1 if country=="LVA"

**save FEcut and dropped files individually**
preserve
	keep if flag_drop==0 & grey==0
	drop flag_drop grey
	tempfile fixed_effects
	save `fixed_effects', replace
restore
preserve
	keep if flag_drop==1
	drop flag_drop grey
	tempfile flag_drop_issues
	save `flag_drop_issues', replace
restore
preserve
	keep if grey==1
	drop flag_drop grey
	tempfile grey_one_issues
	save `grey_one_issues', replace
restore
preserve
	keep if grey==9
	drop flag_drop grey
	tempfile grey_nine_issues
	save `grey_nine_issues', replace
restore

**Make temp files for saving future data

preserve
	drop if _n>0
	tempfile fixed_effects_file
	save `fixed_effects_file', replace
	tempfile flag_drop_issues_file
	save `flag_drop_issues_file', replace
	tempfile grey_one_issues_file
	save `grey_one_issues_file', replace
	tempfile grey_nine_issues_file
	save `grey_nine_issues_file', replace
restore

********************************************************************************
*Step 3: Write Programs To Use In Country Flow Product Loop
********************************************************************************

//Issue Data Cleaning and Reshaping Programs

program define clean_issues

syntax , country(string) flow(string) product(string)

	//di "country: `country' flow: `flow' product: `product'"

	//country
	qui keep if country=="`country'"
				
	//flow

	qui replace flow="`flow'"

	//product
	if ("`product'"=="other_energy") {
		qui keep if product!="electricity"
	}
	else if ("`product'"== "electricity") {
		qui keep if product=="`product'" | product=="all" | product=="all but biofuels" | product == "allbutbiofuels"
	}
				
	qui replace product="`product'"

end

program define restructure_issues

	**duplicates drop**
	qui duplicates drop year_start year_end, force
					
	**sort and generate tag**
	sort year_start
	qui drop if country==""
	qui generate idn=_n
					
	**local parameters**
	qui summ idn
	global mt=r(N)
					
	**invert to obtain year segments**
	qui drop issue_code //drop disturbing factors for now
	qui reshape wide year_start year_end, i(country flow product) j(idn)

end


//Programs specific to each particular type of issue

program define fixed_effects //pass in number of observations to apply
	
	**assign flags to different years, Greg's algorithm of adding on**
	forval i=1/`1' {
		qui replace FEtag=FEtag+"1" if year>=year_start`i' & year<=year_end`i' 
		qui replace FEtag=FEtag+"0" if year<year_start`i' | year>year_end`i' 
	}

end

program define flag_drop_issues //pass in number of observations to apply

	forval i=1/`1' {
		qui drop if year>=year_start`i' & year<=year_end`i' 
	}

end

program define grey_one_issues //pass in number of observations to apply

	forval i=1/`1' {
		qui drop if year<year_start`i' | year>year_end`i' 
	}

end

program define grey_nine_issues //pass in number of observations to apply

	forval i=1/`1' {
		qui drop if year>=year_start`i' & year<=year_end`i' 
	}


end

********************************************************************************
*Step 4: Apply Issues Selected via Toggles at Top and Save Issue Fixed Data
********************************************************************************

if ("`issue_type'" != "face-value") { //if want face-value energy dataset no need to run code

	**loop through fuels**
	foreach var in `productlist' {
		**loop through sectors**
		foreach tag in `flowlist' {
			**loop through countries**
			foreach loc in `countrylist' {
			
				timer on 1
				
				local merge_file "energy_long"
				
				foreach it in "fixed_effects" "flag_drop_issues" "grey_one_issues" "grey_nine_issues" { //note order issues are applied matters
					
					//load in and clean issues
					qui use ``it'', clear
					
					clean_issues, country("`loc'") flow("`tag'") product("`var'")
					
					qui count 
					local ct=r(N)
					local zt=1
					
					drop oecd tot_drop fuel_keep
					
					**proceed only when the issue exists**
					if `ct'!=0 & `zt'==1 {
						
						//compress issues so no time segements overlap, clean, and reshape
						restructure_issues
						//di "MT: $mt"
						
						**merge back to IEA datas**
						qui merge 1:m country flow product using ``merge_file''
						
						//Datasets only have to match if no data points have been dropped
						if ("`it'" == "fixed_effects" | "`it'" == "flag_drop_issues" ) {
							assert _merge != 1
						}
						
						qui keep if _merge == 3
						drop _merge
						
						//run issue type specific program to clean data
						`it' $mt
				
						**save and tempfile**
						drop year_start* year_end*
						tempfile file`loc'
						qui save `file`loc'', replace
						
					}
					
					else if `ct'==0 & `zt'==1 {
						
						**keep the original data**
						qui use ``merge_file'', clear
						qui keep if country=="`loc'"
						qui keep if flow=="`tag'"
						qui keep if product=="`var'"
						
						**save and tempfile**
						tempfile file`loc'
						qui save `file`loc'', replace
					
					}
					
					else if `zt'==0 {
					
						**keep the original data**
						qui use ``merge_file'', clear
						qui drop if _n>0
						
						**save and tempfile**
						tempfile file`loc'
						qui save `file`loc'', replace	
						
					}
					local merge_file = "`it'_file"
					**appending back to the long data**
					qui use ``merge_file'', clear
					append using `file`loc''
					qui save ``merge_file'', replace
				}
				
				timer off 1
				qui timer list 1
				local tim=r(t1)
				timer clear
				
				**keep time track**
				display "`var' `tag' `loc'-`tim's"
			
			}
		}
	}
	
	use `grey_nine_issues_file', clear
}
else {
	use `energy_long', clear
	local type_of_issues "no issues used"
}

//Clean
drop issue_code year_start year_end flag_drop tot_drop fuel_keep grey oecd
sort flow product country year flow

//save "`DATA'/IEA_Merged_long_`issue_type'_`clim_data'_`bknum'`drop_ex_est'.dta", replace
di "Issue Types Applied: `type_of_issues'"
pause
