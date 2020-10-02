//create OECD label dataset

preserve
keep country v2
duplicates drop country, force
rename country variable_name
rename v2 full_name
generate var="country"
tempfile crossover
save `crossover', replace
restore

preserve
keep product v4
duplicates drop product, force
rename product variable_name
rename v4 full_name
generate var="product"
append using `crossover'
save `crossover', replace
restore

preserve
keep sector v6
duplicates drop sector, force
rename sector variable_name
rename v6 full_name
generate var="sector"
append using `crossover'
save `crossover', replace
restore

preserve
keep flow v8
duplicates drop flow, force
rename flow variable_name
rename v8 full_name
generate var="flow"
append using `crossover'
save "$RAWDATA/IEA_labels_OECD.dta", replace
outsheet using "$DATA/IEA_labels_OECD.csv", comma replace
restore
