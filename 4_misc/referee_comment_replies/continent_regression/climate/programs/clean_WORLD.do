/*
Purpose: WORLD Shape File Climate Data Clean Function
Note: this file relies on programs in the helper_functions.do script

Function Properties:
1) Construct Fiscal Years based on the following issues:

JPN: From 1990, data are reported on a fiscal year basis (e.g. April 2015 to March 2016 for 2015).
AUS: All data refer to the fiscal year (e.g. July 2014 to June 2015 for 2015)
BGD: Data are reported on a fiscal year basis, beginning on 1 July and ending on 30 June of the subsequent year.
EGY: Data are reported on a fiscal year basis. Data for 2015 correspond to 1 July 2015-30 June 2016
ETH: Data are reported according to the Ethiopian financial year, which runs from 1 July to 30 June of the next year
IND: Data are reported on a fiscal year basis. Data for 2015 correspond to 1 April 2015 – 30 March 2016
IRN: Data for 2015 correspond to 20 March 2015 19 March 2016, which is Iranian year 1394
NPL: Data are reported on a fiscal year basis, beginning on 1 July and ending on 30 June of the subsequent year 2015/16 is treated as 2015
NZL: Prior to 1994, data refer to fiscal year (April 1993 to March 1994 for 1993). From 1994, data refer to calendar year.
KEN: As of 2001, electricity data are reported on a fiscal year basis, beginning on 1 July and ending on 30 June of the subsequent year

2) Using collapse_monthly_to_yearly collapse monthly time units to yearly

3) Drop final year for countries we don't have climate data for due to fiscal years

4) Construct long run climate measures using longrun_climate_measures

5) Construct gaps in climate data, so holes can be filled by different shapefile climate data to reflect the following issues:

//Both Electricity and Other Energy
ETH: Prior to 1992, ERI included in Ethiopia
ERI: Prior to 1992, ERI included in Ethiopia
SRB: XKO included in Serbia until 1999, MNE included in Serbia between 1990 and 2004
SDN: Data for South Sudan are available from 2012. Prior to 2012, they are included in Sudan
SSD: Data for South Sudan are available from 2012. Prior to 2012, they are included in Sudan
CUW: From 2012 onwards, data now account for the energy statistics of Curaçao Island only. 
Prior to 2012, data remain unchanged and still cover the entire territory of the former Netherland Antilles
FRA: Includes Monaco
ISR: The statistical data for Israel are supplied by and under the responsibility of the relevant 
Israeli authorities. The use of such data by the OECD is without prejudice to the status of the Golan Heights, 
East Jerusalem and Israeli settlements in the West Bank under the terms of international law.
ITA: Includes San Marino and the Holy See
MMR: Some data are reported on a fiscal year basis, beginning on 1 April and ending on 31 March of the subsequent year
XKO: XKO included in Serbia until 1999
MNE: MNE included in Serbia between 1990 and 2004

//Just other energy
MDA: Official figures on natural gas imports, natural gas inputs to power plants, electricity production and consumption 
are modified by the IEA Secretariat to include estimates for supply and demand for the autonomous region of Stînga Nistrului 
(also known as the Pridnestrovian Moldavian Republic or Transnistria). Other energy production or consumption from this region is not included in the Moldovan data.
TZA: Some of oil data (EWURA) are reported on a fiscal year basis. Data for 2015 correspond to 1 July 2015 30 June 2016
GRL: “Excludes Greenland and the Faroe Islands, except prior to 1990, where data on oil for Greenland were included with the Danish statistics. The Administration is planning to revise the series back to 1974 to exclude these amounts.” 
DNK: “Excludes Greenland and the Faroe Islands, except prior to 1990, where data on oil for Greenland were included with the Danish statistics. The Administration is planning to revise the series back to 1974 to exclude these amounts.” 
CHE: Includes Liechtenstein for the oil data. Data for other fuels do not include Liechtenstein
LIE: Includes Liechtenstein for the oil data. Data for other fuels do not include Liechtenstein


*/

program define clean_WORLD

	*Step 1: fix fiscal years according to Azhar's code**
	sort country year month
	egen id = group(year month)
	encode country, gen(cnt)
	tset cnt id
	
	foreach var of varlist tmax* tavg* prcp* {
		
		**creating fiscal years
		qui generate double `var'_N=`var'
		qui replace `var'_N = F3.`var' if country == "JPN" & year>=1990
		qui replace `var'_N = L6.`var' if country == "AUS"
		qui replace `var'_N = F6.`var' if country == "BGD"
		qui replace `var'_N = F6.`var' if country == "EGY"
		qui replace `var'_N = F6.`var' if country == "ETH"
		qui replace `var'_N = F3.`var' if country == "IND"
		qui replace `var'_N = F3.`var' if country == "IRN"
		qui replace `var'_N = F6.`var' if country == "NPL"
		qui replace `var'_N = F3.`var' if country == "NZL" & year<=1993
	
	}

	keep *_N country year month cnt id
	rename *_N *

	**fix kenya fiscal years for electricity only**
	foreach var of varlist tmax* tavg* prcp* {
		
		qui generate double `var'_other=`var'
		qui generate double `var'_N=`var'
		qui replace `var'_N = F6.`var' if country == "KEN" & year >= 2001

	}

	keep *_N *_other country year month
	
	**Step 2: Go from monthly to yearly data
	collapse_monthly_to_yearly

	**Step 3: Drop final year because do not have climate data for fiscal year

	rename *_N *

	**Step 4: generating MA and TINV**

	longrun_climate_measures

	**Step 5: Construct Gaps to Update with Other Shapefile Climate Data**
	
	//fixes for both other energy and electricity
	foreach var of varlist tmax* tavg* prcp* {
		
		qui replace `var'=. if country == "ETH" & year <= 1991
		qui replace `var'=. if country == "SRB" & year <= 2004
		qui replace `var'=. if country == "SDN" & year <= 2011
		qui replace `var'=. if country == "CUW" & year < 2012
		qui replace `var'=. if country == "FRA"
		qui replace `var'=. if country == "ISR"
		qui replace `var'=. if country == "ITA"
		qui replace `var'=. if country == "SSD" & year < 2012
		qui replace `var'=. if country == "MMR"
		qui replace `var'=. if country == "ERI" & year < 1992
		qui replace `var'=. if country == "XKO" & year <= 1999
		qui replace `var'=. if country == "MNE" & year <= 2004
	}

	**fixes for just other energy MDA, TZA, GRL and DNK**
	
	foreach var of varlist *_other {
		
		qui replace `var' = . if country=="MDA"
		qui replace `var' = . if country=="TZA"
		qui replace `var' = . if (country=="GRL" | country=="DNK") & year < 1990
		qui replace `var'=. if country == "CHE" 
		qui replace `var'=. if country == "LIE"

	}

end

