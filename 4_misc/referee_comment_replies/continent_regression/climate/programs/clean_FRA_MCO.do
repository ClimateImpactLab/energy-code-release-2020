/*
Purpose: FRA_MCO Shape File Climate Data Clean Function
Note: this file relies on programs in the helper_functions.do script

Primary Function:

Provide geographic issue fixes for the following issues and complete subsequent cleaning steps--

FRA- Includes Monaco 

*/

program define clean_FRA_MCO

	replace country="FRA"

	**kenya fix**
	generate_other

	**generating MA**
	longrun_climate_measures

end
