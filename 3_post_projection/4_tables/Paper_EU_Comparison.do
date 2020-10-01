//Combining the EU countries projection for Wenz Paper comparison, 33 countries (Northern Ire in GBR, CYP not in)
//Run in Sacagawea
//Created: Yuqi Song, June 2018
cd "/home/yuqisong/Dropbox/GCP_Reanalysis/ENERGY/IEA/Robustness_and_Reference/Paper_Reference"

clear all
cd "/home/yuqisong/Energy_IEA/Projection0618"
set maxvar 3000

**Define list**
local clist="AUT BEL BIH BGR HRV CZE DNK EST FIN FRA DEU GBR GRC HUN ISL IRL ITA LVA LTU LUX MKD MNE NLD NOR POL PRT ROU SRB SVK SVN ESP SWE CHE"

**Loop and compute**
foreach rcp in "rcp85" {

foreach ssp in "ssp3" {

foreach gcm in "ccsm4" {

foreach iam in "high" {

	//Initialization
	clear
	qui gen country=""
	qui save EU_comparison, replace

foreach loc in `clist' {
	
	//Compile separate categories
	foreach tag in "RESIDENT" "COMMPUB" "TOTIND" {
	
	foreach var in "electricity" {
	
	qui insheet using "/shares/gcp/temp_yuqi/Energy_Proj_0618/single-aggregated_energy_rcp85_ccsm4_high_ssp3_`tag'_`var'_FD_FGLS_FE.csv", comma names clear
	qui keep if region=="`loc'"
	qui destring value, force replace
	rename value fulladapt
	tempfile fulladapt
	qui save `fulladapt', replace
	
	//Get the histclim
	qui insheet using "/shares/gcp/temp_yuqi/Energy_Proj_0618/single-aggregated_energy_rcp85_ccsm4_high_ssp3_`tag'_`var'_FD_FGLS_FE-histclim.csv", comma names clear
	qui keep if region=="`loc'"
	qui destring value, force replace
	rename value histclim
	
	//Substract from fulladapt
	qui merge 1:1 region year using `fulladapt'
	assert _merge==3
	drop _merge
	qui replace fulladapt=fulladapt-histclim
	drop histclim
	rename fulladapt value
	rename region country
	qui replace country="`loc'"
	
	//Gen tag
	qui gen flow="`tag'"
		
	//Save
	qui append using EU_comparison
	qui save EU_comparison, replace
	
	}
	
	}

	display "finish-`loc'"
}

	//Compute reference
	//Collapse
	qui use EU_comparison, clear
	qui collapse (sum) value, by(country year)

	//Keep appropriate years (same reference as Table S3, taking average of 5 years, adjust to daily)
	qui replace value=value/365 if mod(year,4)!=0
	qui replace value=value/366 if mod(year,4)==0
	
	//Merge and times pop
	rename country iso
	qui drop if year<2010
	qui merge m:1 iso year using "/home/yuqisong/GCP_Reanalysis/ENERGY/IEA/Yuqi_Codes/Data/population-interpolated-SSP3-byiso.dta"
	assert _merge!=1
	qui keep if _merge==3
	drop _merge
	rename iso country
	qui gen double valuesub=value
	drop value
	qui gen double value=valuesub*pop
	drop pop
	
	//Merge with pop2010
	rename country iso
	preserve
		qui use "/home/yuqisong/GCP_Reanalysis/ENERGY/IEA/Yuqi_Codes/Data/population-interpolated-SSP3-byiso.dta", clear
		qui keep if year==2010
		tempfile pop2010
		qui save `pop2010', replace
	restore
	qui merge m:1 iso using `pop2010'
	assert _merge!=1
	qui keep if _merge==3
	drop _merge
	rename iso country
	qui gen double value_cons_pop=valuesub*pop
	drop pop
	drop valuesub
	
	//Collapse to mean
	qui gen rangeclass=.
	foreach yr of num 2015 2035 2055 2075 2095 {
		local yrd=`yr'+4
		qui replace rangeclass=`yr' if (year<=`yrd' & year>=`yr')
	}
	drop if rangeclass==.
	qui collapse (mean) value value_cons_pop, by(country rangeclass)
	
	//Debase by 2015 values
	preserve
		qui keep if rangeclass==2015
		rename value sub
		rename value_cons_pop sub_cons_pop
		tempfile baseline
		qui save `baseline', replace
	restore
	qui merge m:1 country using `baseline'
	assert _merge==3
	drop _merge
	qui replace value=value-sub
	qui replace value_cons_pop=value_cons_pop-sub_cons_pop
	drop sub

	//Save
	qui save EU_comparison_rawout, replace
	
}
}
}
}

