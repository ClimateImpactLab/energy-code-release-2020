/*

Purpose: Clean Load Data for Analysis For the break 2 spec

* Break 2 Specification: 

Flow: Compile = TOTOTHER + TOTIND

**For future notes: 
*TOTIND is all subsectors of industrial
*TOTOTHER includes RESIDENT, COMMPUB, AGRICULT, FISHING, ONONSPEC (non specified)

Products: other energy and electricity

We define electricity consumption based on ELECTR variable code, and consumption 
of other fuels is obtained by aggregating over the following variable codes: COAL (Coal and coal products); 
PEAT (Peat and peat products); OILSHALE (Oil shale and oil sands); TOTPRODS (Oil products); 
NATGAS (Natural gas); SOLWIND (Solar/wind/other); GEOTHERM (Geothermal); 
COMRENEW (Biofuels and waste); HEAT (Heat), HEATNS (Heat pro- duction from non-specified combustible fuels).

*/

local flowlist " TOTIND TOTOTHER "
local productlist " other_energy electricity "

**add other energy**
foreach flow in `flowlist' {
	qui generate double other_energy`flow'=coal`flow'+oil_products`flow'+natural_gas`flow'+biofuels`flow'+solar`flow'+heat_other`flow'
	qui gen double other_energy`flow'_pc = other_energy`flow' / pop
	qui gen double other_energy`flow'_log_pc = log(other_energy`flow'_pc)
}

drop coal* oil* nat* heat* bio* solar*

**Add COMPILE

foreach product in `productlist' {

	qui generate double `product'COMPILE= `product'TOTOTHER + `product'TOTIND
	if (inlist("`product'", "other_energy", "electricity")) {
		// if other_energy or electricity is zero or missing for either TOTIND or TOTOTHER we deam the observation untrustworthy and drop it downstream of this code
		replace `product'COMPILE = 0 if ((`product'TOTOTHER == 0 | `product'TOTOTHER == .) | (`product'TOTIND == 0 | `product'TOTIND == .))  
	}
	qui gen double `product'COMPILE_pc = `product'COMPILE / pop
	qui gen double `product'COMPILE_log_pc = log(`product'COMPILE_pc)

}

**Reshape long**
local reshapelist=""
foreach var in `productlist' {
	foreach flow in "TOTIND" "TOTOTHER" "COMPILE" {
		rename `var'`flow' load`var'`flow'
		rename `var'`flow'_pc load_pc`var'`flow'
		rename `var'`flow'_log_pc log_pc`var'`flow'
	}
	local reshapelist="`reshapelist' load`var' load_pc`var' log_pc`var'"
}

reshape long `reshapelist', i(country year) j(flow) string
reshape long load load_pc log_pc, i(country year flow) j(product) string
sort country year flow product
rename log_pc load_log_pc

keep if flow == "COMPILE"
keep if inlist(product, "other_energy", "electricity")

