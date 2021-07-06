clear all
set more off, perm
set scheme s1mono

* Sector

global DB = "/mnt/"
glob coefs_dir = "$DB/CIL_energy/code_release_data_pixel_interaction/projection_system_outputs/damage_function_estimation/coefficients"

glob output = "$DB/CIL_energy/code_release_data_pixel_interaction/referee_comments/crayola"

* truth and nonparametric extrapolation comparisons 

* Import damage function coefficients 
import delimited "$coefs_dir/df_mean_output_SSP3.csv", varnames(1) clear

* Subset to data of interest 
loc upper = 2300
loc lower = 2085
* Just keep data we use in our extrapolation
keep if year >= `lower' & year <= `upper'
keep if growth_rate == "price014"

* Expand to get obs every quarter degree
loc expa = (9.25-.75)/.5+1
expand `expa', gen(newobs)
bysort year: gen anomaly = .75 + .5*(_n-1)

* Predict damage funciton level at each anomaly
gen yh = beta2*anomaly^2 + beta1*anomaly + cons

* Save information on pre 2100 levels for later use 
preserve 
	keep if year < 2100
	keep year anomaly yh
	ren anomaly avrg
	tempfile derivdata
	save "`derivdata'", replace
restore

* Initialise a file for saving trend information
tempfile dtrend
postfile dtrend str12(model) avrg beta cons se using "`dtrend'"


* Run regressions of the level of the damage funciton in each bin on time, to see trends 
* Do this for "truth" - ie pre 2100 when we have data, and "nonpar", which is when we extrapolate 
levelsof anomaly, l(bins) 
gen t = year-2010
foreach bin in `bins' {
	reg yh t if year <=2099 & anomaly == `bin'
	post dtrend ("truth") (`bin') (_b[t]) (_b[_cons])  (_se[t])
}
foreach bin in `bins' {
	reg yh t if year > 2099 & anomaly == `bin'
	post dtrend ("nonpar") (`bin') (_b[t]) (_b[_cons]) (_se[t])
}

* Save bin level trends as a csv 
postclose dtrend
use "`dtrend'", clear
export delimited using "$output/level_trend_v2.csv", replace

loc expa2 = 2110 - 2085 + 1
expand `expa2', gen(newobs)
bysort model avrg: gen year = 2085 + (_n-1)
gen t = year-2010

* Predict for each year
gen yhat = beta*t + cons


* Append information on "yh", which is the actual level of the df in each bin for 2085 to 2100
append using "`derivdata'"
export delimited using "$output/crayola_level_v3.csv", replace	
