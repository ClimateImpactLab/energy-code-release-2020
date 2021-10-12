
/* find the income decile of Nigeria */
cilpath
global root "$REPO/energy-code-release-2020"
use "$DATA/regression/break_data_TINV_clim.dta", clear

keep country *gdp* *year* *Inc* 
tab maxInc_gpid

// income deciles calculated from regression data 

/* 
income deciles - use this for all years
maxInc_gpid |      Freq.     Percent        Cum.
------------+-----------------------------------
   7.245799 |        468       10.00       10.00
   7.712954 |        468       10.00       20.01
   8.136098 |        468       10.00       30.01
   8.474984 |        468       10.00       40.02
   8.776416 |        467        9.98       50.00
    9.08701 |        468       10.00       60.00
   9.385431 |        468       10.00       70.01
   9.782986 |        468       10.00       80.01
   10.19807 |        468       10.00       90.02
   12.41379 |        467        9.98      100.00
------------+-----------------------------------
      Total |      4,678      100.00 */

use "$root/data/raw_income_and_pop.dta", clear
 

*use "${root}/data/IEA_Merged_long_GMFD.dta", replace
keep if inlist(country, "ETH","IND","CHN","KOR","BRA","MEX","USA","NGA")
keep year lgdppc_MA15 lgdppc country
keep if year == 1971 | year ==2012
cap drop inc_dec
egen inc_dec = cut(lgdppc), at(0, 7.245799,7.712954,8.136098,8.474984,8.776416,9.08701,9.385431,9.782986,10.19807, 100) icodes
replace inc_dec = inc_dec + 1
// now load future income data

//import delimited using "/mnt/CIL_energy/code_release_data_pixel_interaction/miscellaneous/covariates_FD_FGLS_719_Exclude_all-issues_break2_semi-parametric_TINV_clim.csv", clear
//save "/mnt/CIL_energy/code_release_data_pixel_interaction/miscellaneous/covariates_FD_FGLS_719_Exclude_all-issues_break2_semi-parametric_TINV_clim.dta", replace


use "/mnt/CIL_energy/code_release_data_pixel_interaction/miscellaneous/covariates_FD_FGLS_719_Exclude_all-issues_break2_semi-parametric_TINV_clim.dta", clear

gen country = substr(region,1,3)
keep if inlist(country, "ETH","IND","CHN","KOR","BRA","MEX","USA","NGA")
keep if year == 2099 
bysort country: egen mode_loggdppc = mode(loggdppc)
keep year country mode_loggdppc
duplicates drop
egen inc_dec = cut(mode_loggdppc), at(0, 7.245799,7.712954,8.136098,8.474984,8.776416,9.08701,9.385431,9.782986,10.19807, 100) icodes
replace inc_dec = inc_dec + 1
list country year inc_dec


