//clean deflator data

drop A C D
foreach var of varlist _all {
	qui replace `var'=subinstr(`var'," ","",.)
	local name=`var'[1]
	rename `var' y`name'
}
rename yCountryCode country
rename y* def*
qui keep if country=="USA"
qui reshape long def, i(country) j(year)
qui destring def, force replace
qui gen id=1
preserve
	qui keep if year==2005
	rename def def2005
	tempfile baseyear
	qui save `baseyear', replace
restore
qui merge m:1 country using `baseyear'
assert _merge==3
drop _merge
drop country
sort year
