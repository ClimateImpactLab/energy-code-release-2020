/*
Creator: Maya Norman
Date last modified: 12/13/19
Last modified by: Maya Norman

Purpose: Transform cleaned data to be regression ready
- First Difference
- Interact Terms

*/


******Set Model Parameters******************************************************

// income modelling specification

local grouping_test $grouping_test

//Model type-- Options: TINV_clim, TINV_both, TINV_clim_EX
	local model $model

//Climate Data type
	local clim_data $clim_data

//Define if covariates are MA15 or TINV
if ("$model" == "TINV_clim" | "$model" == "TINV_clim_EX") {

	//Climate Var Average type
	local ma_clim "TINV"
	local climlag ""

	//Income Var Average type
	local ma_inc "MA15"
	local inclag "_lag"
	
}
else if ("$model" == "TINV_both") {

	//Climate Var Average type
	local ma_clim "TINV"
	local climlag ""

	//Income Var Average type
	local ma_inc "TINV"
	local inclag ""

	
}

***************************************************************
*Step 1: Create non-Temp data related regression variables
***************************************************************

//identify number of income groups
sum largegpid
local IG = `r(max)'

sort region_i year
xtset region_i year

gen yearlag=L1.year

**Decadal dummies**
qui gen decade=.
qui replace decade=1 if (year<=1980 & year>=1971)
qui replace decade=2 if (year<=1990 & year>=1981)
qui replace decade=3 if (year<=2000 & year>=1991)
qui replace decade=4 if (year<=2012 & year>=2001)
qui tab decade, gen(decind)

**decade group lag**
forval dg=1/4 {
	qui gen decind`dg'_lag=L1.decind`dg'
	qui gen FD_decind`dg'=decind`dg'-decind`dg'_lag
}

**income spline terms**
gen dc1_lgdppc_`ma_inc' = .
gen dc2_lgdppc_`ma_inc' = .
gen delta_cut1cut2 = .

foreach product in "other_energy" "electricity" {
	forval lg=1/2 {
		summ lgdppc_`ma_inc' if largegpid == `lg' & product == "`product'"
		scalar ibar`lg'_`product' = r(max)
		replace dc`lg'_lgdppc_`ma_inc' = lgdppc_`ma_inc' - ibar`lg'_`product' if product == "`product'"
	}
	replace delta_cut1cut2 = ibar2_`product' - ibar1_`product'
}

** first difference income control and income spline variables **
foreach cov in "lgdppc_`ma_inc'" "dc1_lgdppc_`ma_inc'" "dc2_lgdppc_`ma_inc'" "delta_cut1cut2" {	
	qui gen double `cov'_lag=L1.`cov'
	qui gen double FD_`cov'=`cov'-`cov'_lag
}

**inc group lag**
forval lg=1/`IG' {
	qui gen largeind`lg'_lag=L1.largeind`lg'
	qui gen FD_largeind`lg'=largeind`lg'-largeind`lg'_lag
}
		
**clim quintile lag**
forval qg=1/5 {
	qui gen climind`qg'_lag=L1.climind`qg'
	qui gen FD_climind`qg'=climind`qg'-climind`qg'_lag
}
	

**income binxdecade range dummy**
forval dg=1/4 {
	forval lg=1/`IG' {
		qui gen DumInc`lg'Dec`dg'=decind`dg'*largeind`lg'
		qui gen DumInc`lg'Dec`dg'_lag=decind`dg'_lag*largeind`lg'_lag
		qui gen FD_DumInc`lg'Dec`dg'=DumInc`lg'Dec`dg'-DumInc`lg'Dec`dg'_lag
	}
}

drop DumInc*

**income bin dummies**
forval lg=1/`IG' {
		qui gen DumIncG`lg'=FD_largeind`lg'
}
	
**income bin by climate quintile dummies 
forval qg=1/5 {
	forval lg=1/`IG' {
		qui gen DumClim`qg'Inc`lg'=climind`qg'*largeind`lg'
		qui gen DumClim`qg'Inc`lg'_lag=climind`qg'_lag*largeind`lg'_lag
		qui gen FD_DumClim`qg'Inc`lg'=DumClim`qg'Inc`lg'-DumClim`qg'Inc`lg'_lag
	}
}
	
	
forval lg=1/`IG' {
	foreach cov in "lgdppc_`ma_inc'" {
		qui gen double I`lg'`cov'=`cov'*largeind`lg'
		qui gen double I`lg'`cov'_lag=`cov'_lag*largeind`lg'_lag
		qui gen double FD_I`lg'`cov'=I`lg'`cov'-I`lg'`cov'_lag
	}
}

**precip**

forval i=1/2 {
	qui gen double precip`i'_lag_`clim_data'=L1.precip`i'_`clim_data'
	qui gen double FD_precip`i'_`clim_data'=precip`i'_`clim_data'-precip`i'_lag_`clim_data'
}

***************************************************************
*Step 2: Generate Temp Related Regression variables 
***************************************************************
	
**temp**
forval i=1/4 {
	qui gen double temp`i'_lag_`clim_data'=L1.temp`i'_`clim_data'
	qui gen double FD_temp`i'_`clim_data'=temp`i'_`clim_data'-temp`i'_lag_`clim_data'
	//for income_spline_lininter
	qui gen double FD_yeartemp`i'_`clim_data'= year*temp`i'_`clim_data' - yearlag*temp`i'_lag_`clim_data'
	//for income_spline_decinter
	forval dg=1/4 {
		qui gen double FD_D`dg'temp`i'_`clim_data' = decind`dg'*temp`i'_`clim_data' - decind`dg'_lag*temp`i'_lag_`clim_data'
	}
}
order FD_temp1_`clim_data' FD_temp2_`clim_data' FD_temp3_`clim_data' FD_temp4_`clim_data'
						
**polyBreaks**
foreach lk in "Above" "Below" {
	forval i=1/4 {
		qui gen double poly`lk'`i'_lag_`clim_data'=L1.poly`lk'`i'_`clim_data'
		qui gen double FD_poly`lk'`i'_`clim_data'=poly`lk'`i'_`clim_data'-poly`lk'`i'_lag_`clim_data'
	}
}	

**controls, by large group**
foreach cov in "cdd20_`ma_clim'" "hdd20_`ma_clim'" /*"Tmean_`ma_clim'"*/ {
	qui gen double `cov'_lag_`clim_data'=L1.`cov'_`clim_data'
	qui gen double FD_`cov'_`clim_data'=`cov'_`clim_data'-`cov'`climlag'_`clim_data'
}
	
**dd20xpolyBreak** //for climate interaction without income interaction (can possibly delete soon)

forval i=1/4 {
	qui gen double cdd20_`ma_clim'temp`i'_`clim_data'=cdd20_`ma_clim'_`clim_data'*polyAbove`i'_`clim_data'
	qui gen double cdd20_`ma_clim'temp`i'_lag_`clim_data'=cdd20_`ma_clim'`climlag'_`clim_data'*polyAbove`i'_lag_`clim_data'
	qui gen double FD_cdd20_`ma_clim'temp`i'_`clim_data'=cdd20_`ma_clim'temp`i'_`clim_data'-cdd20_`ma_clim'temp`i'_lag_`clim_data'
								
	qui gen double hdd20_`ma_clim'temp`i'_`clim_data'=hdd20_`ma_clim'_`clim_data'*polyBelow`i'_`clim_data'
	qui gen double hdd20_`ma_clim'temp`i'_lag_`clim_data'=hdd20_`ma_clim'`climlag'_`clim_data'*polyBelow`i'_lag_`clim_data'
	qui gen double FD_hdd20_`ma_clim'temp`i'_`clim_data'=hdd20_`ma_clim'temp`i'_`clim_data'-hdd20_`ma_clim'temp`i'_lag_`clim_data'
}
	
**inc groupxtemp**
forval lg=1/`IG' {
	forval i=1/4 {
		qui gen double I`lg'temp`i'_`clim_data'=temp`i'_`clim_data'*largeind`lg'
		qui gen double I`lg'temp`i'_lag_`clim_data'=temp`i'_lag_`clim_data'*largeind`lg'_lag
		qui gen double FD_I`lg'temp`i'_`clim_data'=I`lg'temp`i'_`clim_data'-I`lg'temp`i'_lag_`clim_data'
	}
}
		
**inc groupxtempxclimate quintile**
forval qg= 1/5 {
	forval lg=1/`IG' {
		forval i=1/4 {
			qui gen double C`qg'I`lg'temp`i'_`clim_data'=temp`i'_`clim_data'*largeind`lg'*climind`qg'
			qui gen double C`qg'I`lg'temp`i'_lag_`clim_data'=temp`i'_lag_`clim_data'*largeind`lg'_lag*climind`qg'_lag
			qui gen double FD_C`qg'I`lg'temp`i'_`clim_data'=C`qg'I`lg'temp`i'_`clim_data'-C`qg'I`lg'temp`i'_lag_`clim_data'
		}
	}
}
		
**inc group x temp x year for TINV_clim_lininter**

forval lg=1/`IG' {
	forval i=1/4 {
		qui gen double yearI`lg'temp`i'_`clim_data'=temp`i'_`clim_data'*largeind`lg'*year
		qui gen double yearI`lg'temp`i'_lag_`clim_data'=temp`i'_lag_`clim_data'*largeind`lg'_lag*yearlag
		qui gen double FD_yearI`lg'temp`i'_`clim_data'=yearI`lg'temp`i'_`clim_data'-yearI`lg'temp`i'_lag_`clim_data'
	}
}

** temp x year x (income spline OR income) for TINV_clim_income_spline_lininter and TINV_clim_ui_lininter

foreach inc_cov in "dc1_lgdppc_`ma_inc'" "dc2_lgdppc_`ma_inc'" "lgdppc_`ma_inc'" {
	forval lg=1/`IG' {
		forval i=1/4 {
			qui gen double `inc_cov'yearI`lg'temp`i'=`inc_cov'*temp`i'_`clim_data'*largeind`lg'*year 
			qui gen double `inc_cov'yearI`lg'temp`i'_lag=`inc_cov'`inclag'*temp`i'_lag_`clim_data'*largeind`lg'_lag*yearlag
			qui gen double FD_`inc_cov'yearI`lg'temp`i'=`inc_cov'yearI`lg'temp`i'-`inc_cov'yearI`lg'temp`i'_lag
		}
	}
}
		
**dd20 x polyBreak or temp x inc group**
						
forval lg=1/`IG' {
	forval i=1/4 {
		qui gen double cdd20_`ma_clim'I`lg'temp`i'_`clim_data'`climlag'=cdd20_`ma_clim'_`clim_data'*polyAbove`i'_`clim_data'*largeind`lg'
		qui gen double cdd20_`ma_clim'I`lg'temp`i'_lag_`clim_data'`climlag'=cdd20_`ma_clim'`climlag'_`clim_data'*polyAbove`i'_lag_`clim_data'*largeind`lg'_lag
		qui gen double FD_cdd20_`ma_clim'I`lg'temp`i'_`clim_data'`climlag'=cdd20_`ma_clim'I`lg'temp`i'_`clim_data'-cdd20_`ma_clim'I`lg'temp`i'_lag_`clim_data'
					
		qui gen double hdd20_`ma_clim'I`lg'temp`i'_`clim_data'`climlag'=hdd20_`ma_clim'_`clim_data'*polyBelow`i'_`clim_data'*largeind`lg'
		qui gen double hdd20_`ma_clim'I`lg'temp`i'_lag_`clim_data'`climlag'=hdd20_`ma_clim'`climlag'_`clim_data'*polyBelow`i'_lag_`clim_data'*largeind`lg'_lag
		qui gen double FD_hdd20_`ma_clim'I`lg'temp`i'_`clim_data'`climlag'=hdd20_`ma_clim'I`lg'temp`i'_`clim_data'-hdd20_`ma_clim'I`lg'temp`i'_lag_`clim_data'
	}
}		
		
**lgdppcxtempxinc group for TINV_clim_ui and TINV_clim_income_spline **

foreach inc_cov in "dc1_lgdppc_`ma_inc'" "dc2_lgdppc_`ma_inc'" "lgdppc_`ma_inc'" {
	forval lg=1/`IG' {
		forval i=1/4 {
			qui gen double `inc_cov'I`lg'temp`i' = `inc_cov' * temp`i'_`clim_data' * largeind`lg' 
			qui gen double `inc_cov'I`lg'temp`i'_lag = `inc_cov'`inclag' * temp`i'_lag_`clim_data' * largeind`lg'_lag 
			qui gen double FD_`inc_cov'I`lg'temp`i'=`inc_cov'I`lg'temp`i'-`inc_cov'I`lg'temp`i'_lag
		}
	}
}

if (`IG' > 2) {
	forval i=1/4 {
		qui gen double spline2temp`i' = temp`i'_`clim_data'*(dc1_lgdppc_`ma_inc'*largeind2 + delta_cut1cut2*largeind3)
		qui gen double spline2temp`i'_lag = temp`i'_lag_`clim_data'*(dc1_lgdppc_`ma_inc'_lag*largeind2_lag + delta_cut1cut2_lag*largeind3_lag)
		qui gen double FD_spline2temp`i' = spline2temp`i' - spline2temp`i'_lag
	}
}
			
**inc groupxtemp*dec** for TINV_clim_decinter

forval dg=1/4 {
	forval lg=1/`IG' {
		forval i=1/4 {
			qui gen double D`dg'I`lg'temp`i'_`clim_data'=temp`i'_`clim_data'*largeind`lg'*decind`dg'
			qui gen double D`dg'I`lg'temp`i'_lag_`clim_data'=temp`i'_lag_`clim_data'*largeind`lg'_lag*decind`dg'_lag
			qui gen double FD_D`dg'I`lg'temp`i'_`clim_data'=D`dg'I`lg'temp`i'_`clim_data'-D`dg'I`lg'temp`i'_lag_`clim_data'
		}
	}
}
