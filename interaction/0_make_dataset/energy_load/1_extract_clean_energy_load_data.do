/*
Sub-script purpose: Load and clean energy load data
*/

// raw to semi clean
do "$dataset_construction/energy_load/a_extract_data.do"

// only want data in TJ units
keep if unit=="TJ"

// condense products that have multiple sub products (reference do file for documentation)
do "$dataset_construction/energy_load/b_construct_intermediate_products.do"

// reduce number of flow in dataset for reshape wide

keep if inlist(flow, "TOTIND","TOTOTHER") 

reshape wide coal natural_gas electricity heat_other biofuels oil_products solar, i(year country) j(flow) string

order country year
sort country year

//correct coutry names for merge
replace country="XKO" if country=="KOSOVO" 
replace country="GRL" if country=="GREENLAND" 
replace country="MLI" if country=="MALI"
replace country="MUS" if country=="MAURITIUS"

//Converting to GJ because plotting scale is more familiar
local factor=1000
foreach var of varlist coal* oil* natural_gas* electricity* heat_other* biofuels* solar* {
	qui replace `var'=`var'*`factor'
}
