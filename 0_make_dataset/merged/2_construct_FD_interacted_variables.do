/*

Purpose: Transform cleaned data to be regression ready
- construct decade variable for the last decade robustness check
- construct income spline variable
- First Difference and interact terms

*/

// set time
sort region_i year
xtset region_i year

** Generate Decadal dummies**
qui gen decade=.
qui replace decade=1 if (year<=1980 & year>=1971)
qui replace decade=2 if (year<=1990 & year>=1981)
qui replace decade=3 if (year<=2000 & year>=1991)
qui replace decade=4 if (year<=2012 & year>=2001)
qui tab decade, gen(decind)


** Generate income spline variable **

gen dc1_lgdppc_MA15 = .

foreach product in "other_energy" "electricity" {
	summ lgdppc_MA15 if largegpid == 1 & product == "`product'"
	replace dc1_lgdppc_MA15 = lgdppc_MA15 - `r(max)' if product == "`product'"
}

** First difference energy load pc

gen FD_load_pc = load_pc - L1.load_pc

** First difference income group and income x income group 
	
forval lg=1/2 {
	qui gen FD_largeind`lg' = largeind`lg' - L1.largeind`lg'
	qui gen double FD_I`lg'lgdppc_MA15 = ( lgdppc_MA15 * largeind`lg' ) - ( L1.lgdppc_MA15 * L1.largeind`lg' )
}

** First Difference precip **

forval i=1/2 {
	qui gen double FD_precip`i'_GMFD = precip`i'_GMFD - L1.precip`i'_GMFD
}

** First Difference temp, temp x year, temp x year^2, and temp x decade **

// generate a year variable centered around 1971

forval i=1/4 {
	
	// temp
	qui gen double FD_temp`i'_GMFD = temp`i'_GMFD - L1.temp`i'_GMFD
	qui gen double FD_polyBelow`i'_GMFD = polyBelow`i'_GMFD - L1.polyBelow`i'_GMFD
	
	foreach yr in year cyear pyear p80yr {
		// temp x year
		qui gen double FD_`yr'temp`i'_GMFD = (`yr' * temp`i'_GMFD) - (L1.`yr' * L1.temp`i'_GMFD)
		
		// temp x year^2
		qui gen double FD_`yr'2temp`i'_GMFD = (`yr' * `yr' * temp`i'_GMFD) - (L1.`yr' * L1.`yr' * L1.temp`i'_GMFD)
	}
	// temp x decade
	forval dg=1/2 {
		qui gen double FD_D`dg'temp`i'_GMFD = (decind`dg' * temp`i'_GMFD) - (L1.decind`dg' * L1.temp`i'_GMFD)
	}
		
	// polyBelow x year post 1980 for coldsidep80 interaction
	qui gen double FD_p80yr_polyBelow`i'_GMFD = (p80yr * polyBelow`i'_GMFD) - (L1.p80yr * L1.polyBelow`i'_GMFD)
		
	// polyBelow x year  for coldside interaction
	qui gen double FD_year_polyBelow`i'_GMFD = (year * polyBelow`i'_GMFD) - (L1.year * L1.polyBelow`i'_GMFD)

	// polyAbove x year post 1980 for twosidedp80 interaction
	qui gen double FD_p80yr_polyAbove`i'_GMFD = (p80yr * polyAbove`i'_GMFD) - (L1.p80yr * L1.polyAbove`i'_GMFD)

}


** First difference temp x income decile

forval lg = 1/10 {
	forval i=1/4 {
		gen double FD_I`lg'temp`i'_GMFD = ( temp`i'_GMFD * ind`lg' ) - ( L1.temp`i'_GMFD * L1.ind`lg' )
	}
}

** First difference temp x year x income spline 

forval lg=1/2 {
	forval i=1/4 {

		foreach yr in year cyear pyear p80yr {

	 		qui gen double FD_dc1_lgdppc_MA15`yr'I`lg'temp`i' = ///
			( dc1_lgdppc_MA15 * temp`i'_GMFD * largeind`lg' * `yr' ) ///
			- ( L1.dc1_lgdppc_MA15 * L1.temp`i'_GMFD * L1.largeind`lg' * L1.`yr' )
		
		}
		// temp(polyBelow) x year(post 1980) x income spline terms for coldsidep80 interaction
 		qui gen double FD_lgdppc_MA15p80yrI`lg'polyBelow`i' = ///
		( dc1_lgdppc_MA15 * polyBelow`i'_GMFD * largeind`lg' * p80yr ) ///
		- ( L1.dc1_lgdppc_MA15 * L1.polyBelow`i'_GMFD * L1.largeind`lg' * L1.p80yr )

		// temp(polyBelow) x year x income spline terms for coldside interaction
 		qui gen double FD_lgdppc_MA15yearI`lg'polyBelow`i' = ///
		( dc1_lgdppc_MA15 * polyBelow`i'_GMFD * largeind`lg' * year ) ///
		- ( L1.dc1_lgdppc_MA15 * L1.polyBelow`i'_GMFD * L1.largeind`lg' * L1.year )

		// temp(polyAbove) x year(post 1980) x income spline terms for twosidedp80 interaction
 		qui gen double FD_lgdppc_MA15p80yrI`lg'polyAbove`i' = ///
		( dc1_lgdppc_MA15 * polyAbove`i'_GMFD * largeind`lg' * p80yr ) ///
		- ( L1.dc1_lgdppc_MA15 * L1.polyAbove`i'_GMFD * L1.largeind`lg' * L1.p80yr )
	
	}
}		
		
** First difference temp x year^2 x income spline 

forval lg=1/2 {
	forval i=1/4 {
		foreach yr in year cyear pyear p80yr {
			qui gen double FD_dc1_lgdppc_MA15`yr'2I`lg'temp`i' = ///
			( dc1_lgdppc_MA15 * temp`i'_GMFD * largeind`lg' * `yr' * `yr' ) ///
			- ( L1.dc1_lgdppc_MA15 * L1.temp`i'_GMFD * L1.largeind`lg' * L1.`yr' * L1.`yr' )
		}
	}
}		


** First difference income spline x temp

forval lg=1/2 {
	forval i=1/4 {
		qui gen double FD_dc1_lgdppc_MA15I`lg'temp`i' = ///
		( dc1_lgdppc_MA15 * temp`i'_GMFD * largeind`lg' ) - ///
		( L1.dc1_lgdppc_MA15 * L1.temp`i'_GMFD * L1.largeind`lg' )
	}
}

** First difference income spline x temp (polyBelow)

forval lg=1/2 {
	forval i=1/4 {
		qui gen double FD_dc1_lgdppc_MA15I`lg'polyBelow`i' = ///
		( dc1_lgdppc_MA15 * polyBelow`i'_GMFD * largeind`lg' ) - ///
		( L1.dc1_lgdppc_MA15 * L1.polyBelow`i'_GMFD * L1.largeind`lg' )
	}
}



** First difference dd20 x polyBreak ** 

forval i=1/4 {
	
	qui gen double FD_cdd20_TINVtemp`i'_GMFD_old = ///
			( cdd20_TINV_GMFD * polyAbove`i'_GMFD ) - ///
			( cdd20_TINV_GMFD * L1.polyAbove`i'_GMFD )
	
	qui gen double FD_hdd20_TINVtemp`i'_GMFD_old = ///
			( hdd20_TINV_GMFD * polyBelow`i'_GMFD ) - ///
			( hdd20_TINV_GMFD * L1.polyBelow`i'_GMFD )
}


** First difference dd20 x polyBreak at pixel level ** 

forval i=1/4 {
	
	qui gen double FD_cdd20_TINVtemp`i'_GMFD = ///
			polyAbove`i'_x_cdd_GMFD - L1.polyAbove`i'_x_cdd_GMFD
	
	qui gen double FD_hdd20_TINVtemp`i'_GMFD = ///
			polyBelow`i'_x_hdd_GMFD - L1.polyBelow`i'_x_hdd_GMFD
}




