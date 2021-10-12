/*

Purpose: Make 3 x 3 Arrays and Array Overlays energy temperature response with heterogeneity by climate and by income
for p80elecinter model, 3 curves per cell: 1980 response, 2010 response, main response

*/

set scheme s1color

****** Set Model Specification Locals ******************************************

local model_main = "$model" // What is the main model for this plot?
local var = "$product" // What product's response function are we plotting?
local submodel_ov = "$submodel" // What submodel is gettting overlayed on this plot?

****** Set Plotting Toggles ****************************************************

// plotting color for main specification and overlay


local col_electricity "dknavy"
local col_electricity_ov2099 "maroon"

local col_other_energy "dkorange"
local col_other_energy_ov2099 "gray"

local col_main "`col_`var''"
local col_ov2099 "`col_`var'_ov2099'"

			
********************************************************************************
* Step 1: Load Data and Clean for Plotting
********************************************************************************
		
use "$DATA/regression/GMFD_`model_main'_regsort.dta", clear

//Set up locals for plotting
local obs = 35 + abs(-5) + 1

//clean data for plotting
drop if _n > 0
set obs `obs'

replace temp1_GMFD = _n - 6
// for coldsidep80 and coldside interaction
replace polyBelow1_GMFD = 20 - temp1_GMFD
replace polyBelow1_GMFD = 0 if polyBelow1_GMFD < 0
// for twosidedp80 interaction
replace polyAbove1_GMFD = temp1_GMFD - 20
replace polyAbove1_GMFD = 0 if polyAbove1_GMFD < 0

foreach k of num 1/2 {
	rename temp`k'_GMFD temp`k'
	replace temp`k' = temp1 ^ `k'
	// for coldsidep80 and coldside interaction
	rename polyBelow`k'_GMFD polyBelow`k'
	replace polyBelow`k' = 20 ^ `k' - temp1 ^ `k'
	replace polyBelow`k' = 0 if polyBelow`k' < 0
	// for twosidedp80 interaction
	rename polyAbove`k'_GMFD polyAbove`k'
	replace polyAbove`k' = temp1 ^ `k' - 20 ^ `k'
	replace polyAbove`k' = 0 if polyAbove`k' < 0

}
gen above20 = (temp1 >= 20) //above 20 indicator
gen below20 = (temp1 < 20) //below 20 indicator

********************************************************************************
* Step 2: Set up for plotting by: 
	* a) finding knot location 
	* b) assigning whether to plot an overlay or not
********************************************************************************

* Get Income Spline Knot Location 
	
preserve
use "$DATA/regression/break_data_`model_main'.dta", clear
summ maxInc_largegpid_`var' if largegpid_`var' == 1
local ibar_main = `r(max)'
restore

/* if the underlying dataset differs for a given robustness model, 
the income spline knot location will vary because the income decile
locations are different.*/

local ibar_ov2099 = `ibar_main'

* Set plotting locals and name tags 

local colorGuide " Model Spec: `model_main' (`col_main') "
local plot_title "`model_main'"

// create list of model types to loop over
local type_list " _main "

	
// add to list of model types to loop over
local type_list " _ov2099 `type_list' " 

// create colorguide to help viewer decipher between overlayed spec and non overlayed spec
local colorGuide "`colorGuide' Overlay Spec: `model_main'_`submodel_ov' 2099(`col_ov2099') "

local plot_title "main_model_`plot_title'_overlay_model_`submodel_ov'"

local fig "fig_Appendix-G3B"


********************************************************************************
* Step 3: Plot, Plot, Plot
********************************************************************************

// create locals to populate with sub plots
local graphicM=""
local graphicM_noSE=""

forval lg=3(-1)1 {	//Income tercile
	forval tr=3(-1)1 {	//Tmean tercile
		
		// create cellid for labeling each subplot
		local cellid=`lg'+`tr'*100
		
		// grab income and climate covariates to trace out response for this cell
		preserve
		use "$DATA/regression/break_data_`model_main'.dta", clear
		duplicates drop tpid tgpid, force
		sort tpid tgpid 
		local tr_index = `tr' * 3 
		// create index for grabbing the long run climate to plot in each cell
		local subCDD = avgCDD_tpid[`tr_index']
		local subHDD = avgHDD_tpid[`tr_index']
		local subInc = avgInc_tgpid[`lg']
		restore
			
		// set up plotting locals for sub plot
		loc SE ""
		loc noSE ""
		
		// assign fuel index to trace out proper dose response
		if "`var'"=="electricity" {
			local pg=1
		}
		else if "`var'"=="other_energy" {
			local pg=2
		}

		// loop over plotting models
		foreach type in `type_list' {

			// year to plot temporal trend model:
			local p80yr = 2099 - 1980
			local year = 2099
			local pre80yr = 0


			// assign model to be plotted
			if (strpos("`type'", "ov") > 0) {
				local plot_model = "`model_main'_`submodel_ov'"
			}
			else {
				local plot_model = "`model_main'"
			}
			
			// construct income spline
			local deltacut_subInc = `subInc' - `ibar`type''

			// assign the large income group based on the cell's income covariate
			
			if `subInc' > `ibar`type'' local ig = 2
			else if `subInc' <= `ibar`type'' local ig = 1

			// create dose response function equation

			local line ""
			local add ""
			
			foreach k of num 1/2 {
				
				local line = " `line' `add' _b[c.indp`pg'#c.indf1#c.FD_temp`k'_GMFD] * (temp`k' - 20^`k')"
				local line = "`line' + above20*_b[c.indp`pg'#c.indf1#c.FD_cdd20_TINVtemp`k'_GMFD]*`subCDD' * (temp`k' - 20^`k')"
				local line = "`line' + below20*_b[c.indp`pg'#c.indf1#c.FD_hdd20_TINVtemp`k'_GMFD]*`subHDD' * (20^`k' - temp`k')"
				// if plotting interacted model			
				if (strpos("`type'", "ov") > 0) {
					// low income group
					if (`ig' == 1) {
						local line = "`line' + _b[c.indp`pg'#c.indf1#c.FD_dc1_lgdppc_MA15I`ig'temp`k']*`deltacut_subInc'*(temp`k' - 20^`k')"
					} 
					// high income group
					else if (`ig' == 2) {
						// not always rich case
						if ("`submodel_ov'" == "coldsidehighincsep") {
							local line = "`line' + _b[c.indp`pg'#c.indf1#c.largeind_notallyears#c.FD_dc1_lgdppc_MA15I`ig'temp`k']*`deltacut_subInc'*(temp`k' - 20^`k')"
				
						}
						// always rich case 
						else if ("`submodel_ov'" == "coldsidehighincsep_alwaysrich") {
							if  ("`var'" == "electricity") {
								local line = "`line' + _b[c.indp`pg'#c.indf1#c.largeind_allyears#c.FD_year_polyBelow`k'_GMFD] * (polyBelow`k' - 0)*`year'"
								local line = "`line' + _b[c.indp`pg'#c.indf1#c.largeind_allyears#c.FD_dc1_lgdppc_MA15I`ig'temp`k']*`deltacut_subInc'*(temp`k' - 20^`k')"
								local line = "`line' + _b[c.indp`pg'#c.indf1#c.largeind_allyears#c.FD_lgdppc_MA15yearI`ig'polyBelow`k']*`deltacut_subInc'*`year'*(polyBelow`k' - 0)"
							}
							// for other energy, plot the same as not always case
							else if ("`var'" == "other_energy") {
								local line = "`line' + _b[c.indp`pg'#c.indf1#c.largeind_notallyears#c.FD_dc1_lgdppc_MA15I`ig'temp`k']*`deltacut_subInc'*(temp`k' - 20^`k')"
							}
						}
					}
				} 
				// plotting main model 
				else {
					local line = "`line' + _b[c.indp`pg'#c.indf1#c.FD_dc1_lgdppc_MA15I`ig'temp`k']*`deltacut_subInc'*(temp`k' - 20^`k')"
				}
				local add " + "
			}

			// trace out does response equation and add to local for plotting 
			estimates use "$OUTPUT/sters/FD_FGLS_inter_`plot_model'"
			di  "$OUTPUT/sters/FD_FGLS_inter_`plot_model'"

			predictnl yhat`cellid'`type' = `line', se(se`cellid'`type') ci(lower`cellid'`type' upper`cellid'`type')

			loc SE = "`SE' rarea upper`cellid'`type' lower`cellid'`type' temp1, col(`col`type''%30) || line yhat`cellid'`type' temp1, lc (`col`type'') ||"
			loc noSE = "`noSE' line yhat`cellid'`type' temp1, lc (`col`type'') ||"
			
		}
		
		//plot with no SE for overlay plots
		tw `noSE' , yline(0, lwidth(vthin)) xlabel(-5(10)35, labsize(vsmall)) ///
			ylabel(, labsize(vsmall) nogrid) legend(off) ///
			subtitle("", size(vsmall) color(dkgreen)) ///
			ytitle("", size(vsmall)) xtitle("", size(small)) ///
			plotregion(color(white)) graphregion(color(white)) nodraw ///
			name(Maddgraph`cellid', replace)
			
		//add graphic no SE
		local graphicM="`graphicM' Maddgraph`cellid'"
	}
}


// Plot arrays and save

//combine cells
graph combine `graphicM', imargin(zero) ycomm rows(3) ///
	title("Split Degree Days Poly 2 Interaction Model `var'", size(small)) ///
	subtitle("`colorGuide'", size(vsmall)) ///
	plotregion(color(white)) graphregion(color(white)) name(comb_nose, replace)
graph export "$OUTPUT/figures/`fig'_`var'_interacted_`plot_title'_2099.pdf", replace

graph drop _all	
