/*

Sub script purpose: Using the observations that pass the criteria outlined below, 
find global average consumption share for households and industry for products we have price data for.

Bigger Picture Purpose: get shares for price aggregation across sectors

*/


/*
# Criteria for country getting included in global average: 
#	a) drop country if non-specified is non-zero for any product
#   b) drop country if zero for all products for either industrial 
#      (totind) or totother (all sectors besides industrial)
*/

//check criteria a:

preserve

keep if flow == "ononspec"
collapse(max) value, by(country)
keep if value == 0
keep country
tempfile criteriaA
save `criteriaA', replace

restore

//check criteria b:

preserve

keep if inlist(flow,"totind", "totother")
collapse(max) value, by(country flow)
collapse(min) value, by(country)
drop if value == 0
keep country
tempfile criteriaB
save `criteriaB', replace

restore

//eliminate countries that do not meet the criteria

foreach criteria in "A" "B" {
	merge m:1 country using `criteria`criteria'', keep(3) nogen
}

//construct sector weights for prices
keep if inlist(flow, "industrial","resident")
reshape wide value, i(country product) j(flow) string
gen sum = valueindustrial + valueresident
foreach sector in "industrial" "resident" {
	gen share_`sector' = value`sector'/sum
}

collapse(mean) share_industrial share_resident, by (product)
rename (share_resident share_industrial) (share_households share_industry)
replace product = lower(product)