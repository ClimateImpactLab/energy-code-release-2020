/*
Purpose: SRB_MNE Shape File Climate Data Clean Function
Note: this file relies on programs in the helper_functions.do script

Primary Function:

Provide geographic issue fixes for the following issues and complete subsequent cleaning steps--

SRB - XKO included in Serbia until 1999
SRB - MNE included in Serbia between 1990 and 2004

*/


program define clean_SRB_MNE

	replace country="SRB"

	**kenya fix**
	generate_other

	**generating MA**
	longrun_climate_measures

	**leave gaps**
	foreach var of varlist tmax* tavg* prcp* {
		qui replace `var'=. if year > 2004 | year <= 1999
	}

end
