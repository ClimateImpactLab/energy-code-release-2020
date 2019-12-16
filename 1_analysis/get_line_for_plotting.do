/*

//note function assumes: break2, exclude

Program purpose: Return string with energy interacted response function to be used with a ster file and predictnl

Parameters:

	model: income grouping specificition (`grouping_test'), model, submodel, and climate data (`clim_data') (order doesn't matter but spelling does)
	product: other_energy or electricity
	income_group: 1,2 or 3
	n_income_group: 2 or 3 depending on spec
	subInc, subCDD, subHDD, deltacut_subInc values user wants for response function construction
		* subInc - income
		* subCDD - CDD
		* subHDD - HDD
		* deltacut_subInc - subInc - Ibar (top income group)
	myyear : year for plotting if lininter in model

To do:

	* improve assert statements
	* make myyear parameter optional, so only have to feed through for lininter

*/


program define get_interacted_response, sclass

syntax , model(string) product(string) income_group(integer) n_income_group(integer) ///
subInc(real) subCDD(real) subHDD(real) deltacut_subInc(real) myyear(integer) [decade(integer 1)]
	

	******************************************************************************************
	* Part 1: Assert statements verifying specificition within scope of program functionality
	******************************************************************************************
	
	di "i made it here!"
	//this section is incomplete... continue to populate

	if (strpos("`model'", "income_spline") > 0) {
		assert strpos("`model'", "semi-parametric") > 0
	}

	if (strpos("`model'", "decinter") > 0) {
		assert strpos("`model'", "ui") == 0
	}

	if (strpos("`model'", "lininter") > 0) {
		assert strpos("`model'", "ui") == 0
		assert "`myyear'" != ""
	}

	//ensure product is spelled correctly
	assert inlist("`product'", "other_energy", "electricity")

	//ensure not more than one grouping_test fed in
	if strpos("`model'", "semi-parametric") > 0 {
		assert strpos("`model'", "visual") == 0
	}

	//ensure not both TINV_both and TINV_clim are specified at the same time
	if strpos("`model'", "TINV_clim") > 0 {
		assert strpos("`model'", "TINV_both") == 0
	}

	//ensure income group for line does not exceed number of income groups possible for product/model/grouping_test
	assert `income_group' <= `n_income_group'
	
	******************************************************************************************
	* Part 2: Assign necessary within program locals based on program parameters
	******************************************************************************************

	//assign product index
	if "`product'"=="electricity" {
		local pg=1
	}
	else if "`product'"=="other_energy" {
		local pg=2
	}

	//only one flow (OTHERIND)
	local fg = 1

	//assign if temp and climate response are income group specific based on model
	if (strpos("`model'", "income_spline") > 0) {
		//temp response
		local tt = ""
		//climate response
		local ct = ""
	}
	else {
		//temp response
		local tt = "I`income_group'"
		//climate response
		local ct = "`tt'"
	}

	//if decadal interaction model -- plot decade 4
	if (strpos("`model'", "decinter") > 0) {
		assert `decade' > 0 & `decade' < 5
		local D "D`decade'"
	}
	else {
		local D ""
	}

	// assign moving average values
	if (strpos("`model'", "TINV_both") > 0) {
		local ma_clim "TINV"
		local ma_inc "TINV"
	}
	else if (strpos("`model'", "TINV_clim") > 0) {
		local ma_clim "TINV"
		local ma_inc "MA15"
	}

	//assign climate data based on model

	if strpos("`model'", "GMFD_v3") > 0 {
		local clim_data "GMFD_v3"
	}
	else if (strpos("`model'", "GMFD") > 0) {
		local clim_data "GMFD"
	}
	else if (strpos("`model'", "BEST") > 0) {
		local clim_data "BEST"
	}

	******************************************************************************************
	* Part 3: Create line and return to calling do file
	******************************************************************************************

	//reset everything			
	local line ""

	foreach k of num 1/2 {
		
		//add plus sign in front of first term only if not first term in loop
		if `k' > 1 local add "+"
		if `k' == 1 local add ""

		* loop over the polynomials' degree and save the predict command in the local `line'
		local line = " `line' `add' _b[c.indp`pg'#c.indf`fg'#c.FD_`D'`tt'temp`k'_`clim_data'] * (temp`k' - 20^`k')"
		local line = "`line' + above`midcut'*_b[c.indp`pg'#c.indf`fg'#c.FD_cdd20_`ma_clim'`ct'temp`k'_`clim_data']*`subCDD' * (temp`k' - 20^`k')"
		local line = "`line' + below`midcut'*_b[c.indp`pg'#c.indf`fg'#c.FD_hdd20_`ma_clim'`ct'temp`k'_`clim_data']*`subHDD' * (20^`k' - temp`k')"
		
		if ((strpos("`model'", "ui") > 0) & ((`income_group' == `n_income_group') | ((`income_group' == `n_income_group'-1) & strpos("`model'", "semi-parametric")>0))) {
			local line = "`line' + _b[c.indp`pg'#c.indf`fg'#c.FD_lgdppc_`ma_inc'I`income_group'temp`k'_`clim_data']*`subInc' * (temp`k' - 20^`k')"
		} 
		if (strpos("`model'", "lininter") > 0) {
			local line = "`line' + _b[c.indp`pg'#c.indf`fg'#c.FD_year`tt'temp`k'_`clim_data'] * (temp`k' - 20^`k')*`myyear'"
		}
		
		if ((strpos("`model'", "income_spline") > 0)  & (strpos("`model'", "semi-parametric") > 0)) {
			local line = "`line' + _b[c.indp`pg'#c.indf`fg'#c.FD_dc1_lgdppc_`ma_inc'I`income_group'temp`k']*`deltacut_subInc'*(temp`k' - 20^`k')"
			if (strpos("`model'", "lininter") > 0) {
				local line = "`line' + _b[c.indp`pg'#c.indf`fg'#c.FD_dc1_lgdppc_`ma_inc'yearI`income_group'temp`k']*`deltacut_subInc'*`myyear'*(temp`k' - 20^`k')"
			}
		}

	}

	sreturn local interacted_response_line "`line'"

end
