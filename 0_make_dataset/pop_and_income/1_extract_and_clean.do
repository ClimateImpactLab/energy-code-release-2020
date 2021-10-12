/*

Purpose: Clean Pop and Income Data

*/

********************************************************************************
* Data Source: IEA (International Energy Agency), World Indicators (WIND)      *
* Access: 1) Log into UChicago Library 2) Search "OECD iLibrary", enter the    *
* website tapping the "full-text" link 3) In OECD iLibrary website, select the *
* tab "Statistics" 4) Abitrarily select one of the OECD dataset, click the     *
* purple button to enter a blue browser spread sheet 5) Do not close the       *
* spreadsheet, click on "IEA World Energy Statistics and Balances" 6) Enter    *						              *
* through cliking the purple Data button into "World indicators" dataset       *
* 7) Download csv file, or their compiled zip file                             *
********************************************************************************

//Note: the above data extraction progress has to be done under IE/Safari, Chrome is unstable
//Note: we convert to 2005 GDP PPP USD using WB values https://data.worldbank.org/indicator/NY.GDP.MKTP.PP.CD, using the real growth rate of IEA measure of GDP
//Note: for SSD and TWN the WB data does not exist, so we scale GDPPPP from IEA (their scaling with 2010 PPP) to 2005 at https://data.worldbank.org/indicator/FP.CPI.TOTL
//Note: for former USSR and Yugoslavia we have no 2005 GDP (WB or IEA), so we sum the values for all breakdown countries to form their 2005 measures. 
//Note: GRL GDP is not in the dataset due to no WB data for GDP PPP 

//This part of the code is to be run under Sacagawea, where raw datafile saved
local RAWDATA "${DATA}/energy/IEA"

**********************************************************************************************
** Clean Income/Pop Data 
**********************************************************************************************

*** Calculate dollar-year adjustment ***

import excel using "`RAWDATA'/API_NY.GDP.DEFL.ZS_DS2_en_excel_v2.xls", cellra(A4) first clear
local y 1960
foreach v of varlist E-BJ {
	rename `v' yr_`y'
	local y = `y'+1
}
gen adj = yr_2005 / yr_2010
gen adj_MLI = yr_2005 / yr_2011
keep if CountryCode == "USA"
loc adj = adj[1]
loc adj_MLI = adj_MLI[1]

*** Clean Mali ***

// GDP
import excel using "`RAWDATA'/API_NY.GDP.MKTP.PP.KD_DS2_en_excel_v2_9909293.xls", cellra(A4) first clear
local y 1960
foreach v of varlist E-BJ {
	rename `v' yr_`y'
	local y = `y'+1
}
keep if CountryCode == "MLI"
keep CountryCode yr_*
reshape long yr_, i(CountryCode) j(year)
ren yr_ gdp
tempfile MLI_gdp
save "`MLI_gdp'", replace

// POP
import excel using "`RAWDATA'/API_SP.POP.TOTL_DS2_en_excel_v2.xls", cellra(A4) first clear
local y 1960
foreach v of varlist E-BJ {
	rename `v' yr_`y'
	local y = `y'+1
}
keep if CountryCode == "MLI"
keep CountryCode yr_*
reshape long yr_, i(CountryCode) j(year)
ren yr_ pop

merge 1:1 CountryCode year using "`MLI_gdp'", nogen
drop if year > 2015
ren CountryCode country
tempfile mali 
save "`mali'", replace

*** Clean main gdp/pop data ***

import delimited using "`RAWDATA'/WIND_24072017220413920.csv", clear asdoub
keep ïcountry flow time value
ren ïcountry country

keep if flow == "GDPPPP" | flow == "POP"

reshape wide value, i(country time) j(flow) string

ren valueGDPPPP gdp
ren valuePOP pop
ren time year

replace gdp = gdp*1e9
replace pop = pop*1e6

// Append Mali
append using "`mali'"
drop if country == "WORLDAV"
drop if country == "WORLDMAR"

// Fix Australia (shift gdp time series forward one year)
en country, g(countryid)
tsset countryid year
gen newgdp = .
replace newgdp = L1.gdp if country == "AUS"
replace gdp = newgdp if country == "AUS"
drop if country == "AUS" & year == 1960
drop newgdp

replace country = "GRL" if country == "GREENLAND" 
replace country = "XKO" if country == "KOSOVO"
replace country = "MLI" if country ==  "MALI" 
replace country = "MUS" if country == "MAURITIUS"


****************************************************************************************************
** Step 2: Adjust Dollar-years / Calculate Moving Average 
****************************************************************************************************

// expand data set for backward extrapolation
preserve
	drop if year > 0
	set obs 1
	replace countryid = 9
	replace year = 1956
	tempfile fillts
	save "`fillts'", replace
restore

append using "`fillts'"
tsfill, full
bysort countryid: replace country = country[_N]

// Adjust dollar-years -- $2010->$2005 for all but Mali (which is $2011->$2005) -- & calc log
gen double gdp2005 = gdp * `adj'
replace gdp2005 = gdp * `adj_MLI' if country == "MLI"
gen double gdppc = gdp2005 / pop
gen double lgdppc = log(gdppc)

// extrapolate and calculate 15yr MA
ipolate lgdppc year, g(lgdppc_i) by(country) epolate
tssmooth ma double lgdppc_MA = lgdppc_i, window(15 0 0) 

drop lgdppc
ren lgdppc_i lgdppc
ren lgdppc_MA lgdppc_MA15
drop if year >= 2015
 