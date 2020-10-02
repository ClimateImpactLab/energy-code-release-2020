// clean raw price data and deflate

keep country time flagcodes product flow value sector
replace value=. if flagcodes=="M"
replace value=. if flagcodes=="L"
replace value=. if flagcodes=="C"
drop flagcodes
rename time year

**keep the yearly measure**
generate pos=strpos(year,"Q")
drop if pos!=0
drop pos
destring year, force replace

**keep the end-use sector**
drop if sector=="ELECGEN"

******************
if $oecd==0{
	* This step is required for a few (non-oecd) countries that have tax data available in their natural currency, 
	* but not in USD. Here, we convert them so we can use them later.
	reshape wide value, i(country product sector year) j(flow) string

	bysort country year: gen ratio = valueNCPRICE_TOE / valueUSDPRICE_TOE
	bysort country year: egen mean_ratio = mean(ratio)
	replace valueUSDTAX_TOE = valueNCEXTAX_TOE / mean_ratio if valueNCEXTAX_TOE !=. & valueUSDTAX_TOE ==.
	drop ratio mean_ratio ratio

	reshape long value, i(country product sector year) j(flow) string
}

******************

**rename flow**
replace flow="price" if flow=="USDPRICE_TOE"
replace flow="tax" if flow=="USDTAX_TOE"
keep if flow=="price" | flow=="tax"

//import income deflator data
preserve
import excel using "$cleaning_data/API_NY.GDP.DEFL.ZS_DS2_en_excel_v2.xls", sheet("Data") firstrow clear cellrange(A3:BI268)
do $sub_script_path/price_data/sub_scripts/prices/clean/clean_deflator_data
tempfile deflat_usa
save `deflat_usa'
restore

**deflate**
merge m:1 year using `deflat_usa' 
assert _merge!=1
drop _merge
replace value = value * def2005/def
drop def def2005

**drop if all years are missings**
sort country year
generate tag=(value!=.)
bysort country flow sector product: gen tagsum=sum(tag)
drop if tagsum==0
drop tag tagsum

**reshape**
qui replace product=lower(product)
reshape wide value, i(country year flow sector) j(product) string
rename value* *
reshape wide bitcoal cokcoal diesel electr hsfo leadprem leadreg lfo lpg lsfo natgas ///
			 unprem95 unprem98 unreg, i(country year flow) j(sector) string
rename *HOUSEHOLDS *HOUSEHOLDS_	
rename *INDUSTRY *INDUSTRY_
reshape wide bitcoal* cokcoal* diesel* electr* hsfo* leadprem* leadreg* lfo* lpg* lsfo* natgas* ///
			 unprem95* unprem98* unreg*, i(country year) j(flow) string
