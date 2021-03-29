clear all
set more off
macro drop _all
pause on
cap ssc install rangestat
cilpath
local root "$REPO/energy-code-release-2020/"
global dataset_construction "`root'/4_misc/referee_comment_replies/continent_regression/"
local DATA "`root'/data"


// clean climate data
do "$dataset_construction/climate/1_clean_climate_data.do"
clean_climate_data, clim("GMFD") programs_path("$dataset_construction/climate/programs")

tempfile climate_data
save `climate_data', replace

// drop variables we don't need
drop *hdd* *cdd* *other* *Below* *Above* 
drop if temp1_GMFD == .


**Clean the region data**
preserve
insheet using "`root'/data/UNSD — Methodology.csv", comma names clear
generate subregionid=.
replace subregionid=1 if regionname=="Oceania" 
replace subregionid=2 if subregionname=="Northern America" 
replace subregionid=3 if subregionname=="Northern Europe" 
replace subregionid=4 if subregionname=="Southern Europe"
replace subregionid=5 if subregionname=="Western Europe"
replace subregionid=6 if subregionname=="Eastern Europe" | subregionname=="Central Asia" 
replace subregionid=7 if subregionname=="Eastern Asia" 
replace subregionid=8 if subregionname=="South-eastern Asia" 
replace subregionid=9 if intermediateregionname=="Caribbean" | intermediateregionname=="Central America"
replace subregionid=10 if intermediateregionname=="South America"
replace subregionid=11 if subregionname=="Sub-Saharan Africa" 
replace subregionid=12 if subregionname=="Northern Africa" | subregionname=="Western Asia" 
replace subregionid=13 if subregionname=="Southern Asia"
drop if subregionid==.
keep isoalpha3code subregionid subregionname regionname regioncode
replace subregionname="Oceania" if subregionid==1
replace subregionname="Caribbean and Central America" if subregionid==9
replace subregionname="South America" if subregionid==10
replace subregionname="Central Asia and Eastern Europe" if subregionid==6
replace subregionname="Western Asia and Northern Africa" if subregionid==12
rename isoalpha3code country 
tempfile subregion
save `subregion', replace
restore

// merge with climate data
merge m:1 country using `subregion'
keep if _merge!=2
drop _merge

replace subregionid = 6 if country=="FSUND"
replace subregionid = 4 if country=="YUGOND"
replace subregionid = 7 if country=="TWN"
replace subregionid = 4 if country=="XKO"
replace subregionname = "Central Asia and Eastern Europe" if country == "FSUND"
replace subregionname = "Southern Europe" if country == "YUGOND"
replace subregionname = "Eastern Asia" if country == "TWN"
replace subregionname = "Southern Europe" if country=="XKO"


// drop some regions without enough years or not assigned a continent
drop if subregionid == .

encode country, gen(countrycode)
bysort countrycode: egen c = count(year)
// drop if we don't have a complete time series
drop if c < 40
xtset countrycode year

// fill in missing continent
replace regioncode = 142 if subregionid == 7
replace regionname = "Asia" if subregionid == 7

//separate south and north americas
replace regionname = "South America" if subregionname == "South America"
replace regionname = "North America" if subregionname == "Caribbean and Central America"
replace regionname = "North America" if subregionname == "Northern America"
drop c countrycode subregionid regioncode

save `climate_data', replace

use `climate_data', clear

// import world bank pop data
import delimited using "`DATA'/worldbank_pop.csv", varnames(4) clear
reshape long v, i(countrycode) j(year)
rename v pop 
replace year = year + 1955
keep countrycode year pop 
rename countrycode country

merge 1:m country year using `climate_data'

keep if _merge == 3
drop _merge

save "`DATA'/continental_regression_dataset.dta", replace

//check if the panel is strongly balanced
//encode country, gen(countrycode)
//xtset countrycode year
