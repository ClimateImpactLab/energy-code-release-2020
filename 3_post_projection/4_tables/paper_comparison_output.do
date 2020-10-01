//Paper comparisons for Energy results
//Created by: Yuqi Song, May 2018
//Directly using projection results, single run, base year taking 2010, end of century takes 2010
//Files to run before this one, on Sacagawea: 1) extract_ctn.do (extract country-time series from single projection) 2) CA_comparison.do (extract CA projection) 3) EU_combine.do (extract EU projection)
//The prices files are downloaded under /Yuqi_Codes/Data
//table J1

clear all
set maxvar 3000

cilpath

// path to energy-code-release repo 
local root "$REPO/energy-code-release-2020"
local DATA "`root'/data"

**use file**
local usefile="`DATA'/IEA_Merged_long.dta"

**output file**
clear
qui gen Paper=""
qui save Paper_Ref_Comp, replace

**Davis Gertler, MEX, R-E**
**Take full adapatation**
qui insheet using "MEX-histclim_RESIDENT_electricity_FD_FGLS_FE.csv", comma names clear
rename value sub
tempfile histclim
qui save `histclim', replace

qui insheet using "MEX_RESIDENT_electricity_FD_FGLS_FE.csv", comma names clear
qui merge 1:1 year using `histclim'
assert _merge==3
drop _merge
qui replace value=value-sub
drop sub

**Take the values of 2099 and 2010**
qui keep if year==2099 | year==2010
sort year
local qDG2010=value[1]
local qDG2099=value[2]

**Take the percentage**
qui use "`usefile'", clear
qui keep if flow=="RESIDENT" & product=="electricity" & country=="MEX" & year==2010
local refDG2010=load_pc[1]
local rpopDG2010=pop[1]

**Price using constant pricing**
qui use "/home/yuqisong/GCP_Reanalysis/ENERGY/IEA/Yuqi_Codes/Data/IEA_Price_FIN_Clean_gr0.dta", clear
qui keep if country=="MEX"
local priceDG2010=price_RESIDENT_electricity[1]

**Pop: assume taking end of century pop**
qui use "/home/yuqisong/GCP_Reanalysis/ENERGY/IEA/Yuqi_Codes/Data/population-interpolated-SSP3-byiso.dta", clear
qui keep if iso=="MEX"
qui keep if year==2099 | year==2010
sort year
local popDG2010=pop[1]
local popDG2099=pop[2]

**Obtain Comparison and Scale**
**inflation indicators**'"
import excel using "/home/yuqisong/GCP_Reanalysis/ENERGY/IEA/Yuqi_Codes/Data/API_NY.GDP.DEFL.ZS_DS2_en_excel_v2.xls", sheet("Data") firstrow clear cellrange(A4:BI268)
keep AX BC CountryCode
rename BC y2010
rename AX y2005
keep if CountryCode=="USA"
rename CountryCode country
reshape long y, i(country) j(year)
rename y CPI
sort year
generate ratio=CPI[2]/CPI[1]
local defactor=ratio[1]
display `defactor'

local percDG=(`qDG2099'*`popDG2099'-`qDG2010'*`popDG2010')/(`refDG2010'*`rpopDG2010')*100
local damageDG=`priceDG2010'*(`qDG2099'*`popDG2099'-`qDG2010'*`popDG2010')*`defactor'/10^9 
local percDG_cons=(`qDG2099'*`popDG2010'-`qDG2010'*`popDG2010')/(`refDG2010'*`rpopDG2010')*100
local damageDG_cons=`priceDG2010'*(`qDG2099'*`popDG2010'-`qDG2010'*`popDG2010')*`defactor'/10^9 

**Output**
clear
qui set obs 1
qui gen Paper="Davis & Gertler, 2015" 
qui gen Sector="Residential Electricity"
qui gen Ref_Impact="83%"
qui gen Our_Impact=`percDG'
qui tostring Our_Impact, force replace format(%12.0f)
qui replace Our_Impact=Our_Impact+"%"
qui gen Ref_Price="$90.19 per megawatt hour"
qui gen Our_Price=`priceDG2010'*`defactor'*1000
qui tostring Our_Price, force replace format(%12.2f)
qui replace Our_Price="$"+Our_Price+" per megawatt hour"
qui gen Ref_Damage="3.955 Billion [2010 USD]"
qui gen Our_Damage=`damageDG'
qui tostring Our_Damage, force replace format(%12.3f)
qui replace Our_Damage=Our_Damage+" Billion [2010 USD]"

qui gen Our_Impact_Const_Pop=`percDG_cons'
qui tostring Our_Impact_Const_Pop, force replace format(%12.0f)
qui replace Our_Impact_Const_Pop=Our_Impact_Const_Pop+"%"
qui gen Our_Damage_Const_Pop=`damageDG_cons'
qui tostring Our_Damage_Const_Pop, force replace format(%12.3f)
qui replace Our_Damage_Const_Pop=Our_Damage_Const_Pop+" Billion [2010 USD]"

qui gen Note="Paper Baseline Unclear"

qui append using Paper_Ref_Comp
qui save Paper_Ref_Comp, replace

**Wenz etal, 2017, E**
**Country list: AUT, BEL, BIH, BGR, HRV, CZE, DNK, EST, FIN, FRA, DEU, GBR, GRC, HUN, ISL, IRL, ITA, LVA, LTU, LUX, MKD, MNE, NLD, NOR, POL, PRT, ROU, SRB
**SVK, SVN, ESP, SWE, CHE
local clist="AUT BEL BIH BGR HRV CZE DNK EST FIN FRA DEU GBR GRC HUN ISL IRL ITA LVA LTU LUX MKD MNE NLD NOR POL PRT ROU SRB SVK SVN ESP SWE CHE"

**First part of extraction from Sacagawea  
**Take the difference of 2099 to 2010**
qui use "EU_comparison_rawout.dta", clear
qui drop if rangeclass==2015
drop sub*
qui reshape wide value value_cons_pop, i(country) j(rangeclass)
tempfile valuesave
qui save `valuesave', replace

**Take the percentage [assume we use the IEA data instead of James' projection]**
qui use "`usefile'", clear
qui keep if flow=="COMPILE" & product=="electricity" & year==2010
local ls=0
foreach loc in `clist' {
	local ls=`ls'+1
	preserve
		qui keep if country=="`loc'"
		qui replace load_pc=load_pc/365
		qui replace load=load_pc*pop
		keep country year flow product load
		if `ls'==1 {
			tempfile refsave
			qui save `refsave', replace
		}
		else {
			qui append using `refsave'
			qui save `refsave', replace
		}
	restore
}

**Obtain Comparison**
qui use `valuesave', clear
qui merge 1:1 country using `refsave'
assert _merge==3
drop _merge
foreach var of varlist value* {
	qui replace `var'=`var'/load*100
	qui tostring `var', force replace format(%12.3f)
}
keep country value*
order country value2035 value2055 value2075 value2095 ///
		      value_cons_pop2035 value_cons_pop2055 value_cons_pop2075 value_cons_pop2095 
sort country
qui export excel using "EU_comparison_S3table.xlsx", firstrow(variables) replace

**Output the sum to our table**
qui use `valuesave', clear
qui merge 1:1 country using `refsave'
assert _merge==3
drop _merge
keep country load value*2095
qui collapse (sum) load value2095 value_cons_pop2095
rename *2095 *
foreach pr in "" "_cons_pop" {
	foreach wy in "" {
		qui gen perc`pr'`wy'=value`pr'`wy'/load*100
		local percW`pr'`wy'=perc`pr'`wy'[1]
	}
}
 
clear
qui set obs 1
qui gen Paper="Wenz et al., 2017" 
qui gen Sector="All Electricity"
qui gen Ref_Impact="0%"
qui gen Our_Impact=`percW'
qui tostring Our_Impact, force replace format(%12.0f)
qui replace Our_Impact=Our_Impact+"%"
qui gen Our_Impact_Const_Pop=`percW_cons_pop'
qui tostring Our_Impact_Const_Pop, force replace format(%12.0f)
qui replace Our_Impact_Const_Pop=Our_Impact_Const_Pop+"%"
qui gen Note="Project R,C,I Electricity Separately"
qui append using Paper_Ref_Comp
qui save Paper_Ref_Comp, replace

**Auffhammer, CA, R-E and R-NG**
local factor=293071083333.33
foreach var in "electricity" "other_energy" {
	qui use "CA_comparison_rawout.dta", clear
	qui keep if product=="`var'"
	qui collapse (sum) climadapt*, by(year)
	qui keep if year==2099
	local qA`var'=climadapt[1]/`factor'
	local qA`var'_cons=climadapt_const_pop[1]/`factor'
}

**Take the percentage**
**Take the Paper Reference of EIA 2009**
local refA2010electricity=0.287
local refA2010other_energy=0.439

foreach var in "electricity" "other_energy" {
	local percA`var'=`qA`var''/`refA2010`var''*100
	local percA`var'_cons=`qA`var'_cons'/`refA2010`var''*100

	**Output**
	clear
	qui set obs 1
	qui gen Paper="Auffhammer, 2018" 
	if "`var'"=="electricity" {
		qui gen Sector="Residential Electricity"
		qui gen Ref_Impact="16.9%-17.6%"
	}
	else if "`var'"=="other_energy" {
		qui gen Sector="Residential Natural Gas"
		qui gen Ref_Impact="-20.5%"
	}
	qui gen Our_Impact=`percA`var''
	qui tostring Our_Impact, force replace format(%12.1f)
	qui replace Our_Impact=Our_Impact+"%"
	qui gen Our_Impact_Const_Pop=`percA`var'_cons'
	qui tostring Our_Impact_Const_Pop, force replace format(%12.1f)
	qui replace Our_Impact_Const_Pop=Our_Impact_Const_Pop+"%"
	if "`var'"=="other_energy" {
		qui gen Note="Approximate NG Use by Sum of All Non-Electricity"
	}
	qui append using Paper_Ref_Comp
	qui save Paper_Ref_Comp, replace
}

**Add the total impact**
qui use "CA_comparison_rawout.dta", clear
qui collapse (sum) climadapt*, by(year)
qui keep if year==2099
local qA=climadapt[1]/`factor'
local qA_cons=climadapt_const_pop[1]/`factor'

**Output**
clear
qui set obs 1
qui gen Paper="Auffhammer, 2018" 
qui gen Sector="All Residential"
qui gen Ref_Impact="-0.039 BTU"
qui gen Our_Impact=`qA'
qui tostring Our_Impact, force replace format(%12.3f)
qui replace Our_Impact=Our_Impact+" BTU"
qui gen Our_Impact_Const_Pop=`qA_cons'
qui tostring Our_Impact_Const_Pop, force replace format(%12.3f)
qui replace Our_Impact_Const_Pop=Our_Impact_Const_Pop+" BTU"
qui gen Note="Project Electricity and Non-Electricity Separately"
qui append using Paper_Ref_Comp
qui save Paper_Ref_Comp, replace

**Deschene Greenstone 2011, R-Total, USA**
**Take no adapatation, summ E and NE**
qui insheet using "USA-noadapt_RESIDENT_electricity_FD_FGLS_FE.csv", comma names clear

qui gen flow="RESIDENT"
qui gen product="electricity"

tempfile RE
qui save `RE', replace

qui insheet using "USA-noadapt_RESIDENT_other_energy_FD_FGLS_FE.csv", comma names clear

qui gen flow="RESIDENT"
qui gen product="other_energy"

**Combine**
qui append using `RE'
qui collapse (sum) value, by(year)

**Take the values of 2099 and 2010**
qui keep if year==2099 | year==2010
sort year
local qDeGr2010=value[1]
local qDeGr2099=value[2]

**Take the percentage**
qui use "`usefile'", clear
qui keep if flow=="RESIDENT" & product=="total_energy" & country=="USA" & year==2010
local refDeGr2010=load_pc[1]
local rpopDeGr2010=pop[1]

**Pop: assume taking end of century pop**
qui use "/home/yuqisong/GCP_Reanalysis/ENERGY/IEA/Yuqi_Codes/Data/population-interpolated-SSP3-byiso.dta", clear
qui keep if iso=="USA"
qui keep if year==2099 | year==2010
sort year
local popDeGr2010=pop[1]
local popDeGr2099=pop[2]

local percDeGr=(`qDeGr2099'*`popDeGr2099'-`qDeGr2010'*`popDeGr2010')/(`refDeGr2010'*`rpopDeGr2010')*100
local percDeGr_cons=(`qDeGr2099'*`popDeGr2010'-`qDeGr2010'*`popDeGr2010')/(`refDeGr2010'*`rpopDeGr2010')*100

**Output**
clear
qui set obs 1
qui gen Paper="Deschenes & Greenstone, 2011" 
qui gen Sector="All Residential"
qui gen Ref_Impact="11%"
qui gen Our_Impact=`percDeGr'
qui tostring Our_Impact, force replace format(%12.0f)
qui replace Our_Impact=Our_Impact+"%"
qui gen Our_Impact_Const_Pop=`percDeGr_cons'
qui tostring Our_Impact_Const_Pop, force replace format(%12.0f)
qui replace Our_Impact_Const_Pop=Our_Impact_Const_Pop+"%"
qui gen Note="Project Electricity and Non-Electricity Separately"
qui append using Paper_Ref_Comp
qui save Paper_Ref_Comp, replace

**Outsheet**
qui use Paper_Ref_Comp, clear
sort Paper
order Paper Sector Ref_Impact Our_Impact Our_Impact_Const_Pop Note Ref_Price Our_Price Ref_Damage Our_Damage Our_Damage_Const_Pop
qui export excel using "Paper_Ref_Comp.xlsx", firstrow(variables) replace





