/*
Purpose: SRB_MNE_XKO Shape File Climate Data Clean Function
Note: this file relies on programs in the helper_functions.do script

Primary Function:

Provide geographic issue fixes for the following issues and complete subsequent cleaning steps--

SRB - XKO included in Serbia until 1999
SRB - MNE included in Serbia between 1990 and 2004

*/

program define clean_SRB_MNE_XKO

	**rename**
	replace country = "SRB"

	**kenya fix**
	generate_other

	**generating MA**
	longrun_climate_measures

	**leave gaps for fill**
	* TO-DO: ask Maya why there's tmax*
	foreach var of varlist tavg* prcp* {
		qui replace `var' = . if year > 1999 | year <= 1989
	}

end
 
 