/*

Creator: Maya Norman
Last Modified: 6/16/19
 
Plot the following sters overlayed for all income deciles:
decile_inter : income decile interacted model (quantile_regression/stacked.do)
income_inter : linear income interaction in top two income groups, low income (large group 1) (income_heterogeneity/1_generate_sters.do)
non-parametrically modeled and high income (large group 2 and 3) parametrically modeled (income_heterogeneity/1_generate_sters.do)
visual_grouping_inter : interacted with climate non-parametric income, visually grouped based on decile (interacted_regression/generate_ster/stacked.do)
visual_grouping : uninteracted with climate non-parametric income, visually grouped based on decile (income_heterogeneity/1_generate_sters.do)
income_spline : interacted with income spline (knot at top of bottom income group) (income_heterogeneity/1_generate_sters.do)
income_spline_inter : interacted with climate and income spline (knot a top of bottom income group)

This script is dependent on income_heterogeneity/1_generate_sters.do and quantile_regression/stacked.do 
and interacted_regression/generate_ster/stacked.do for ster generation.

Additionally, this script is dependent on 0_make_dataset.do for break and main dataset generation.

*/

clear all
set more off
macro drop _all
pause on

//SET UP RELEVANT PATHS

if "`c(username)'" == "mayanorman"{

	local DROPBOX "/Users/`c(username)'/Dropbox"

}
else if "`c(username)'" == "manorman"{
	// This path is for running the code on Sacagawea
	local DROPBOX "/home/`c(username)'"
	local RAWDATA "/shares/gcp/estimation/energy/IEA"

}

******Set Script Toggles********************************************************

//Set data type ie historic or replicated
global data_type "replicated_data"
local data_type $data_type

//set up ZeroSubset toggle

local case "Exclude" // "Exclude" "Include"

//Number of data subsets used to estimate
local bknum "break2"

//income grouping test (visual or iterative-ftest
global grouping_test "visual"
local grouping_test $grouping_test


//Issue Fix
local IF "_all-issues" //second-reading-issues revised-first-reading-issues matched-issues all-issues face-value first-reading-issues

******Set Model Parameters******************************************************


	//Model type-- Options: TINV_clim, TINV_both, TINV_clim_EX
		global model "TINV_clim"
		local model $model
						
	//Specification:
	
		//First Difference
			global FD "FD" // FD vs noFD
			local FD $FD
			
			if ("`FD'" == "noFD") {

				local fd ""
		
			}
			else {

				local fd "FD_"

			}
			
		//FGLS
			local FGLS "_FGLS" // "_FGLS" ""
	
		//Issue Fix
			local IF "_all-issues" //second-reading-issues revised-first-reading-issues matched-issues all-issues face-value first-reading-issues
			
		//Poly
			local o 2 //order of polynomial options: 2,3,4
		
	//Submodel type-- (Default: "")
		global submodel ""
		local submodel ""
	
	//Climate Data type
		global clim_data "GMFD"
		local clim_data $clim_data
	
		
	//Flow product type

		local product_list "other_energy electricity"
		
		local flow_list "OTHERIND" //"COMMPUB TOTIND RESIDENT"
	
	
	//Define if covariates are MA15 or TINV
	if ("$model" != "TINV_both") {
		//Climate Var Average type
		local ma_clim "TINV"

		//Income Var Average type
		local ma_inc "MA15"
		

	}
	else if ("$model" == "TINV_both") {
	
		//Climate Var Average type
		local ma_clim "TINV"

		//Income Var Average type
		local ma_inc "TINV"

		
	}
	
	//Set submodel
	if ("$model" == "TINV_clim") {
		
		local submodel "$submodel"

	}
********************************************************************************

//Setting path shortcuts

local data "`DROPBOX'/GCP_Reanalysis/ENERGY/IEA_Replication/Data/Analysis/"	
local ster "`DROPBOX'/GCP_Reanalysis/ENERGY/IEA_Replication/Data/Analysis/"	
local output "`DROPBOX'/GCP_Reanalysis/ENERGY/IEA_Replication/Analysis/Output/`clim_data'/rationalized_code/$data_type/figures"	

//Assign ster names for different regressions (note: visual grouping ster is product dependent so name assigned within product loop)

local decile_inter_ster "`ster'/`clim_data'/rationalized_code/$data_type/sters/`FD'`FGLS'/quantI10_`FD'`FGLS'_inter_clim`clim_data'_`case'`IF'_`bknum'_poly`o'_`model'.ster"
local income_inter_ster "`ster'/`clim_data'/rationalized_code/$data_type/sters/`FD'`FGLS'/`FD'`FGLS'_afterCut_income_inter_clim`clim_data'_`case'`IF'_`bknum'_poly`o'_`model'.ster"
local income_spline_ster "`ster'/`clim_data'/rationalized_code/$data_type/sters/`FD'`FGLS'/`FD'`FGLS'_income_spline_inter_clim`clim_data'_`case'`IF'_`bknum'_poly`o'_`model'.ster"
local income_spline_inter_ster "`ster'/`clim_data'/rationalized_code/$data_type/sters/`FD'`FGLS'/`FD'`FGLS'_inter_clim`clim_data'_`case'`IF'_`bknum'_semi-parametric_poly2_`model'_income_spline.ster"
local income_spline_internp_ster "`ster'/`clim_data'/rationalized_code/$data_type/sters/`FD'`FGLS'/`FD'`FGLS'_inter_nonpooled_climinter_clim`clim_data'_`case'`IF'_`bknum'_semi-parametric_poly2_`model'_income_spline.ster"
local income_inter_wclim_ster "`ster'/`clim_data'/rationalized_code/$data_type/sters/`FD'`FGLS'/`FD'`FGLS'_inter_clim`clim_data'_`case'`IF'_`bknum'_semi-parametric_poly2_TINV_clim_ui.ster"
local visual_grouping_inter_ster "`ster'/`clim_data'/rationalized_code/$data_type/sters/`FD'`FGLS'/`FD'`FGLS'_inter_clim`clim_data'_`case'`IF'_`bknum'_`grouping_test'_poly2_`model'.ster"

//Assign regression specific colors for plotting

local decile_inter_color "dknavy"
local income_inter_color "midgreen"
local income_inter_wclim_color "lavender"
local income_spline_color "eltblue"
local income_spline_inter_color "purple"
local income_spline_internp_color "pink"
local visual_grouping_color "red"
local visual_grouping_inter_color "dkorange"

//Set up temperature related locals for plotting
	
local min = -5
local max = 35
local omit = 20
local obs = `max' + abs(`min') + 1
local midcut=20

//load data
	
use "`data'/`clim_data'/rationalized_code/$data_type/data/clim`clim_data'_`case'`IF'_`bknum'_`grouping_test'_`model'_`data_type'_regsort.dta", clear
	
//clean data for plotting
drop if _n > 0
set obs `obs'
replace temp1_`clim_data' = _n + `min' -1
gen above`midcut'=(temp1_`clim_data'>=`midcut') //above 20 indicator
gen below`midcut'=(temp1_`clim_data'<`midcut') //below 20 indicator

foreach k of num 1/4 {
	rename temp`k'_`clim_data' temp`k'
	replace temp`k' = temp1 ^ `k'
}

//plotting time

foreach var in "electricity" "other_energy" {

	if "`var'"=="electricity" {
		local stit="Electricity"
		local pg=1
		local grouping "3_1_1" //subject to change depending on visual test
	}
	else if "`var'"=="other_energy" {
		local stit="Non-Electricity"
		local pg=2
		local grouping "1_2_2" //subject to change depending on visual test
	}

	//assign visual grouping ster
	local visual_grouping_ster "`ster'/`clim_data'/rationalized_code/$data_type/sters/`FD'`FGLS'/income_grouping_`grouping'_`FD'`FGLS'_inter_clim`clim_data'_`case'`IF'_`bknum'_poly`o'_`model'.ster"

	foreach tag in "OTHERIND" {

		local fg = 1
		local tit "All Flows"

		//set up graphing locals for graph combined
		local graphic=""
		local graphic_noSE=""

		forval lg=1/10 { //income group

			local cellid=`lg'
			di "Plotting decile: `lg'"
			
			/*
			Extract the following information for plotting:
			 * (subInc) income for income linear interaction model 
			 * (large_group) large group for visual_grouping 
			 * (cut) above cut for semi-parametric models
			 * (subCDD and subHDD) long run climate for fully interacted models
			 * (ibar) income at cut for constructing distance between cut and income
			 * (delta_cut) distance from cut for plotting income spline models
			*/

			preserve
				
				//load break data
				local break_data "`data'/`clim_data'/rationalized_code/$data_type/data"
				use "`break_data'/break10_clim`clim_data'_`case'`IF'_`bknum'_`grouping_test'_`model'_`data_type'.dta", clear
				
				//extract ibar (income at cut off)
				qui summ maxInc_largegpid_`var' if largegpid_`var' == 1
				local ibar = `r(max)'

				//only keep observations in plotting decile, so extract info for decile
				keep if gpid == `cellid'
				
				//get decile large income group
				summ largegpid_`var'
				local large_group = `r(max)'

				//define income group for semi parametric models cut = 1 => low income group & cut = 2 => high income group
				if `large_group' > 1 local cut = 2 
				if `large_group' == 1 local cut = 1

				//get average climate, income, and distance from cut for plotting
				duplicates drop gpid, force
				local subInc = avgInc_gpid[1]
				local delta_cut = abs(`subInc' - `ibar')
				local subCDD = avgCDD_gpid[1]
				local subHDD = avgHDD_gpid[1]

				//Save CDD and HDD rounded value locals for display (all this fanciness is so can display rounded values)
				foreach note in "avgCDD" "avgHDD" {
					replace `note'_gpid=round(`note'_gpid,0.1)
					tostring `note'_gpid, force replace format(%12.1f)
					local `note'_note=`note'_gpid[1]
				}
			restore
		
			//set up graphing code
			loc SE ""
			loc nonSE ""
			
			foreach reg_type in "decile_inter" /*"visual_grouping" "income_spline" "income_inter" */ "income_spline_internp" "income_inter_wclim" "visual_grouping_inter" "income_spline_inter" {

				//change income group plotted based on decile and reg_type
				if (inlist("`reg_type'","visual_grouping", "visual_grouping_inter")) local lg = `large_group'
				if (inlist("`reg_type'","income_inter", "income_inter_wclim", "income_spline", "income_spline_inter", "income_spline_internp")) local lg = `cut'

				*loop over the polynomials' degree and save the predict command in the local `line'
				foreach k of num 1/`o' {
					
					//for the first term in the local line don't need plus... then sedond time around turn on plus
					if `k' > 1 local add " + "
					else if `k' == 1 local add ""
					
					//assign whether base temp interaction is income group specific
					if !inlist("`reg_type'", "income_spline", "income_spline_inter", "income_spline_internp") {
						local tt = "I`lg'"
					}
					else if inlist("`reg_type'", "income_spline", "income_spline_inter", "income_spline_internp") {
						local tt ""
					}
					
					//assign whether climate interaction is income group specific
					if !inlist("`reg_type'", "income_spline", "income_spline_inter") {
						local ct = "I`lg'"
					}
					else if inlist("`reg_type'", "income_spline", "income_spline_inter") {
						local ct ""
					}

					//add temperature response (either interacted with income group or not depending on value of `tt')
					local line = "`line' `add' _b[c.indp`pg'#c.indf`fg'#c.`fd'`tt'temp`k'] * (temp`k' - (`omit')^`k')"
					
					//add in linear income interaction for only income group 2
					if (`cut' == 2 & inlist("`reg_type'", "income_inter", "income_inter_wclim")) {
						local line = "`line' + _b[c.indp`pg'#c.indf`fg'#c.`fd'lgdppc_`ma_inc'I`lg'temp`k'_`clim_data']*(`subInc')*(temp`k' - (`omit')^`k')"
					}
					
					//add income spline interaction for both income groups (1,2 for the semi-parametric spline model) 
					if (inlist("`reg_type'", "income_spline","income_spline_inter", "income_spline_internp")) {
						local line = "`line' + _b[c.indp`pg'#c.indf`fg'#c.`fd'deltacut1_lgdppc_`ma_inc'I`lg'temp`k']*(`delta_cut')*(temp`k' - (`omit')^`k')"
					}
			
					//add climate interaction for fully interacted models (interacted with income group or not depending on value of `ct')
					if (inlist("`reg_type'", "visual_grouping_inter", "income_spline_inter", "income_spline_internp", "income_inter_wclim")) {
						local line = "`line' + above`midcut' * _b[c.indp`pg'#c.indf`fg'#c.`fd'cdd20_`ma_clim'`ct'temp`k'_`clim_data'] * `subCDD' * (temp`k' - (`omit')^`k')"
						local line = "`line' + below`midcut' * _b[c.indp`pg'#c.indf`fg'#c.`fd'hdd20_`ma_clim'`ct'temp`k'_`clim_data'] * `subHDD' * ((`omit')^`k' - temp`k')"
					} 
				}

				//load ster and perform checks
				di "``reg_type'_ster'"
				estimates use "``reg_type'_ster'"
				ereturn display
				di "`line'"
				pause

				//predict response for ster and `line'
				predictnl yhat_`reg_type' = `line', se(se_`reg_type') ci(lower_`reg_type' upper_`reg_type')
				local line ""
				
				//plot dashed "truth" line so stands out more
				if "`reg_type'" == "decile_inter" local dashes "lpattern(shortdash)"
				else local dashes ""
				
				loc SE = "`SE' rarea upper_`reg_type' lower_`reg_type' temp1, col(``reg_type'_color'%30) || line yhat_`reg_type' temp1, lc (``reg_type'_color') ||"
				loc noSE "`noSE' line yhat_`reg_type' temp1, lc (``reg_type'_color') `dashes' ||"

			}
			
			//include average CDDs and HDDs for decile that are using for plotting
			local info "cdd: `avgCDD_note' hdd: `avgHDD_note'"

			//plot with SE
			tw `SE' , ///
			yline(0, lwidth(vthin)) xlabel(`min'(10)`max', labsize(vsmall)) ///
			ylabel(, labsize(vsmall) nogrid) legend(off) ///
			subtitle("`info'", size(small) color(dkgreen)) ///
			ytitle("", size(small)) xtitle("", size(small)) ///
			plotregion(color(white)) graphregion(color(white)) nodraw ///
			name(addgraph`cellid', replace)

			//plot with no SE
			tw `noSE' , ///
			yline(0, lwidth(vthin)) xlabel(`min'(10)`max', labsize(vsmall)) ///
			ylabel(, labsize(vsmall) nogrid) legend(off) ///
			subtitle("`info'", size(small) color(dkgreen)) ///
			ytitle("", size(small)) xtitle("", size(small)) ///
			plotregion(color(white)) graphregion(color(white)) nodraw ///
			name(addgraph`cellid'_noSE, replace)
							
		//add graphic to local for combine command below
		local graphic="`graphic' addgraph`cellid'"
		local graphic_noSE="`graphic_noSE' addgraph`cellid'_noSE"

		//drop predicted responses so can repeat process for next decile
		drop `yhat_'* se_* lower_* upper_*
	}				
					
	local xs = 20
	
	//depending on whats being plotted change color guide		
	//local colorGuide "Decile Interaction (`decile_inter_color') Linear Income Spline Interaction (`income_spline_color') Linear Income Spline Full Interaction (`income_spline_inter_color') Linear Income Interaction (`income_inter_color') Visual Income Decile Grouping (`visual_grouping_color') Visual Income Grouping Full Interaction (`visual_grouping_inter_color')"
	local colorGuide "Decile Interaction (`decile_inter_color') Linear Income Full Interaction (`income_inter_wclim_color') Linear Income Spline Full Interaction (`income_spline_inter_color') Linear Income Spline Full Interaction Non-Pooled Climate (`income_spline_internp_color') Visual Income Grouping Full Interaction (`visual_grouping_inter_color')"

	//combine cells with SE
	graph combine `graphic', imargin(zero) ycomm rows(1) xsize(`xs') ysize(3) ///
	title("Poly `o' Model for `tit' `stit' (`model')", size(small)) ///
	subtitle("`colorGuide'", size(small)) ///
	plotregion(color(white)) graphregion(color(white)) name(comb, replace)
	graph export "`output'/quantile_plots/`tag'_`var'/income_heterogeneity_overlay_`FD'`FGLS'_inter_poly`o'_`model'_`tag'_`var'_clim`clim_data'_`case'`IF'_`bknum'_common_controls_revised.pdf", replace

	//combine cells no SE
	graph combine `graphic_noSE', imargin(zero) ycomm rows(1) xsize(`xs') ysize(3) ///
	title("Poly `o' Model for `tit' `stit' (`model')", size(small)) ///
	subtitle("`colorGuide'", size(small)) ///
	plotregion(color(white)) graphregion(color(white)) name(comb_noSE, replace)
	graph export "`output'/quantile_plots/`tag'_`var'/income_heterogeneity_overlay_`FD'`FGLS'_inter_poly`o'_`model'_`tag'_`var'_clim`clim_data'_`case'`IF'_`bknum'_common_controls_revised_noSE.pdf", replace
			
	graph drop _all
				
	}

}
