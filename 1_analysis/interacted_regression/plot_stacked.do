/*
Creator: Maya Norman
Date last modified: 12/3/19 
Last modified by: Maya

Purpose: Make 3 x 3 Arrays and Array Overlays

This script has a lot of toggles and a somewhat fancy somewhat convalooted way of making overlays. its got some seemingly unneccessary bells and whistles as well. 
I'm sorry. I like having one script to do all my bidding, so when I make a change I only have to make it once. I've tried to provide documentation to explain what's 
going on with all my toggles, but please feel free to improve or ask questions.

Note from Tom - to run locally, I need to specify smaller file names - put this in with toggles at the end 

toggle documentation style --
toggle name: toggle use
options: different values toggles can take on

Plotting toggles:

OV: Decide if you want to overlay
options: "" "_overlay"

num_OV: number of overlayed models -- if you just want two models in your overlayed array num_OV = 1. if `OV' == "" then num_OV is irrelevant
options: [1,3]

at: do you want to plot across time?
options: "" "_acrosstime"

2axis: if you are only overlaying two models you can make a plot with two axis
options: "_2axis" or ""

plot_se: do you not want a plot with SE to pop out?
options: "yes" or "no"

for_appendix: are you tom, and is your computer a useless windows? this option saves the output needed for the appendix with a shorter file name
options: "yes" or anything thats not yes

unit: do you want KWH (default) or gigajoules
options: "GJ", or "KWh"

Model toggles:

data_type: what data did you use to estimate the model?
options: "replicated_data" or "historic_data"

model: general statistical modeling approach
options: TINV_clim, TINV_clim_EX, TINV_both, TINV_clim_income_spline, TINV_clim_ui

submodel: small modification of model
options: income_spline, lininter, decinter, ui

bknum: how many productxflow categories are used to estimate the model?
options: "break2" "break4" "break6"

case: how do you want to treat zeroes in the dataset used to estimate the model?
options: "Exclude" or "Include"

grouping_test: method used to construct the income group breaks
options: "semi-parametric" "iterative-ftest" "visual"

clim_data: what climate data do you want to use to estimate the model?
options: "GMFD" "GMFD_v3" "BEST"

IF: what set of issues do you want to use to clean the dataset used to estimate the model?
options: "second-reading-issues" "revised-first-reading-issues" "matched-issues" "all-issues" "face-value" "first-reading-issues"

FGLS: do you want to plot the model with or without FGLS
options: "_FGLS" ""

var: which product do you want to plot?
options: "electricity" "other_energy"

final_decade_only: should the yearlist just be for 

Overlay model toggles:

Instructions for specifying overlay variables: 
assign model toggle values for your overlay models which are distinct from your main model's toggle values
in this section you should specify at least the same number of parameters as `num_OV'

	for example: if I wanted to overlay the time linear interaction onto the main model I would specify that as follows:

	local submodel_ov1 "lininter"

You should specify your overlay locals in the section labeled: "SPECIFY OVERLAY MODEL TOGGLES"
*/


clear all
set more off
macro drop _all
set scheme s1color
* pause on

//SET UP RELEVANT PATHS

if "`c(username)'" == "mayanorman"{

	local DROPBOX "/Users/`c(username)'/Dropbox"
	local GIT "/Users/`c(username)'/Documents/Repos/gcp-energy/rationalized"

}
else if "`c(username)'" == "manorman"{
	// This path is for running the code on Sacagawea
	local DROPBOX "/home/`c(username)'"
	local RAWDATA "/shares/gcp/estimation/energy/IEA"
	local GIT "/home/`c(username)'/gcp-energy/rationalized"
}

else if "`c(username)'" == "TomBearpark"{
	local DROPBOX "C:/Users/TomBearpark/Dropbox"
	local GIT "C:/Users/TomBearpark/Desktop/gcp-energy/rationalized"
}

else if "`c(username)'" == "tbearpar"{
	// This path is for running the code on Sacagawea
	local DROPBOX "/local/shsiang/Dropbox"
	local RAWDATA "/shares/gcp/estimation/energy/IEA"
	local GIT "/home/tbearpark/repos/gcp-energy/rationalized"
}

******Set Script Toggles********************************************************

** Plotting toggles **

//Decide if you want to overlay:
local OV "_overlay" 

//Do you want to plot across time?
local at = "" 

//specify number of models to overlay
local num_OV 1

//if only one overlay can set two axis
local 2axis "" 

//do you want to make a plot with SE? - a plot w/o SE is def going to come out as well
local plot_se "no"

// Do you want to save with a short file name, since it's one of the plots for the appendix
local for_appendix "yes"

// Do you want to have a unit conversion from KWh into Gigajoules (this just multiplies the yhat by 0.0036)
local unit "GJ"





** Model toggles **

//Model type-- Options: TINV_clim, TINV_both, TINV_clim_EX
local model "TINV_clim_income_spline"

//Set data type ie historic or replicated
local data_type "replicated_data"
		
//Submodel type-- (Default: "")
local submodel ""

//Set zero subset case
//Number of data subsets used to estimate
local bknum "break2"
local case "Exclude" // "Exclude" "Include"

//income grouping test (visual or iterative-ftest)
local grouping_test "semi-parametric"
		
//Climate Data type
local clim_data "GMFD"
		
// What issues do you want to use to clean the dataset used to estimate your model?
local IF "_all-issues" 
	
//FGLS
local FGLS "_FGLS" 

//product
local var "electricity"

// final decade only toggle - for runnign the robustness check using decinter model and only most recent data
loc final_decade_only ""
	

****** Assign Some Locals Based on Toggles********************************************************

//Define if covariates are MA15 or TINV
if ("`model'" != "TINV_both") {
		
	//Climate Var Average type
	local ma_clim "TINV"

	//Income Var Average type
	local ma_inc "MA15"

}
else if ("`model'" == "TINV_both") {

	//Climate Var Average type
	local ma_clim "TINV"

	//Income Var Average type
	local ma_inc "TINV"

	local submodel ""
		
}

// yearlist is for plotting responses overtime

if "`at'" != "" {

	local yearlist "1 2 3 4"

}
else {
	if("`final_decade_only'" == "yes") {
		local yearlist " 4 "
	}
	else { 
		local yearlist " 0 "
	}
}

* Define a local based on the variable name for use in the title of the plots 
if "`var'" == "other_energy" {
	loc stit "Other Energy"
}
if "`var'" == "electricity" {
	loc stit "Electricity"
}


//Set submodel
if (inlist("`model'","TINV_clim","TINV_clim_ui","TINV_clim_lininter", "TINV_clim_decinter", "TINV_clim_income_spline") & "`submodel'" != "") {
	
	local submodel "_`submodel'"

}

****** Set Parameters for Overlayed Model **************************************

if ( "`OV'" == "_overlay" ) {

	assert (`num_OV' < 4) //currently not set up to plot more than 3 alternate models (need to add colors)
	local parameter_list " model submodel IF FGLS grouping_test bknum case clim_data var "

	//Note: unless tweaked below the overlayed model will plot the main model

	//set all overlay model parameters equal to the main model
	foreach parameter in `parameter_list' {
		forval i=1/`num_OV' {
			local `parameter'_ov`i' = "``parameter''"
		}
	}


	************** SPECIFY OVERLAY MODEL TOGLES ***************************

	local submodel_ov1 "_lininter"

	* specify the year you want to look at the response function for
	loc year_4_lininter = 2099


	************************************************************************

	forval i=1/`num_OV' {
		//Define if covariates are MA15 or TINV
		if ("`model_ov`i''" != "TINV_both") {
				
			//Climate Var Average type
			local ma_clim_ov`i' "TINV"

			//Income Var Average type
			local ma_inc_ov`i' "MA15"

		}
		else if ("`model_ov`i''" == "TINV_both") {

			//Climate Var Average type
			local ma_clim_ov`i' "TINV"

			//Income Var Average type
			local ma_inc_ov`i' "TINV"
			
		}
	}
}

*************** Set Paths, Load Data, Load Programs **********************************************

// load necessary programs

do `GIT'/1_analysis/get_line.do

// setting path shortcuts

local IFtt = subinstr("`IF'", "_","",.)
local data "`DROPBOX'/GCP_Reanalysis/ENERGY/IEA_Replication/Data/Analysis"	
local output "`DROPBOX'/GCP_Reanalysis/ENERGY/IEA_Replication/Analysis/`clim_data'/rationalized_code/`data_type'/figures/arrays/"
local output_dir "`output'/OTHERIND_`var'/`grouping_test'/`IFtt'"

if ("`data_type'"=="historic_data") {
	local DATA "`DROPBOX'/GCP_Reanalysis/ENERGY/IEA/Yuqi_Codes/Data"
}
else if ("`data_type'"=="replicated_data") {
	local DATA "`DROPBOX'/GCP_Reanalysis/ENERGY/IEA_Replication/Data"
}

// load data and set up plotting colors and overlays

if (inlist("`model'","TINV_clim","TINV_clim_ui","TINV_clim_lininter", "TINV_clim_decinter", "TINV_clim_income_spline")) {
	use "`data'/`clim_data'/rationalized_code/`data_type'/data/clim`clim_data'_`case'`IF'_`bknum'_`grouping_test'_TINV_clim_`data_type'_regsort.dta", clear
}
else {
	use "`data'/`clim_data'/rationalized_code/`data_type'/data/clim`clim_data'_`case'`IF'_`bknum'_`grouping_test'_`model'_`data_type'_regsort.dta", clear
}

*************** Set plotting locals and name tags **********************************************

local col "black"
local col_ov1 "red"
local col_ov2 "midgreen"
local col_ov3 "purple"

local colorGuide " Main Spec: `col' "
local type_list " "" "

//create model and overlay specification titles
if ("`OV'" == "_overlay") {
	
	forval i=1/`num_OV' {
		local type_list " `type_list' _ov`i' "
	}

	//retrieve overlay axis of variance
	local OVtag = ""

	forval i=1/`num_OV' {
		local OVtag = "`OVtag'_ov`i'"
		
		foreach parameter in `parameter_list' {

			if ("``parameter'_ov`i''" != "``parameter''") {
				if strpos("``parameter'_ov`i''", "_") == 1 {
					local add = substr("``parameter'_ov`i''",2,.)
				}
				else {
					local add = "``parameter'_ov`i''"
				}
				local tag_ov`i' = "`tag_ov`i'' `add'"
				local OVtag = "`OVtag'_`add'"
			}
		}

		local colorGuide = "`colorGuide' `tag_ov`i'': `col_ov`i''"
	}

}
		
// temperature locals for plotting response
local min = -5
local max = 35
local omit = 20
local obs = `max' + abs(`min') + 1
local midcut=20


*************** Clean Data for plotting **********************************************

drop if _n > 0
set obs `obs'
replace temp1_`clim_data' = _n + `min' -1
gen above`midcut'=(temp1_`clim_data'>=`midcut') //above 20 indicator
gen below`midcut'=(temp1_`clim_data'<`midcut') //below 20 indicator

foreach k of num 1/2 {
	rename temp`k'_`clim_data' temp`k'	
	replace temp`k' = temp1^`k'
}							

*************** Get Income Spline Knot Location **********************************************

foreach type in `type_list' {
	di "`type'"
	local break_data "`data'/`clim_data`type''/rationalized_code/`data_type'/data"
	
	if inlist("`model`type''", "TINV_both","TINV_clim_EX") {
		local break_model "`model`type''"
	}
	else {
		local break_model "TINV_clim"
	}
	
	preserve
	use "`break_data'/break10_clim`clim_data`type''_`case`type''`IF`type''_`bknum`type''_`grouping_test`type''_`break_model'_`data_type'.dta", clear
	summ maxInc_largegpid_`var`type'' if largegpid_`var`type'' == 1
	local ibar`type' = `r(max)'
	restore

}

**********************--Plot--*******************************

local graphicM=""
local graphicM_noSE=""

forval lg=3(-1)1 {	//Income tercile
	
	local real_lg = `lg'
	
	if `lg'==1 {
		local ltit="Poor"
	}
	else if (`lg'==2) {
		local ltit="Middle"
	}
	else if `lg'==3 {
		local ltit="Rich"
	}

	forval tr=3(-1)1 {	//Tmean tercile

		if `tr'==1 {
			local ttit="Hot" 
		}
		else if `tr'==2 {
			local ttit="Medium" 
		}
		else if `tr'==3 {
			local ttit="Cold" 
		}

		local cellid=`real_lg'+`tr'*100
		local tr_index = `tr' * 3
		local xs = 0
		
		//extract info for plotting
		preserve
		
		if (inlist("`model'","TINV_clim","TINV_clim_ui","TINV_clim_lininter", "TINV_clim_decinter","TINV_clim_income_spline") ///
			& inlist("`grouping_test'", "visual", "semi-parametric")) {
			di "Using visual TINV_clim breaks."
			use "`break_data'/break10_clim`clim_data'_`case'`IF'_`bknum'_visual_TINV_clim_`data_type'.dta", clear
		}
		else {
			di "Using main spec breaks."
			use "`break_data'/break10_clim`clim_data'_`case'`IF'_`bknum'_`grouping_test'_`model'_`data_type'.dta", clear
		}
	
		duplicates drop tpid tgpid, force
		sort tpid tgpid 

		local subCDD = avgCDD_tpid[`tr_index']
		local subHDD = avgHDD_tpid[`tr_index']
		local subInc = avgInc_tgpid[`lg']

		foreach note in "avgCDD" "avgHDD" "avgInc" {
			if strpos("`note'","Inc") > 0 {
				local index = `lg'
				local id = "tgpid"
			}
			else {
				local index = `tr_index'
				local id = "tpid"
			}
			replace `note'_`id'=round(`note'_`id',0.1)
			tostring `note'_`id', force replace format(%12.1f)
			local `note'_`var'=`note'_`id'[`index']
		}
		restore

		di " YEAR LIST: `yearlist'"
		if "`at'" != "" {
			local graphicM=""
			local graphicM_noSE=""
		}

		foreach dd of num `yearlist' {
			
			//set up graphing code
			loc SE ""
			loc noSE ""
			loc info ""
			local counter = 1
			local dtit ""

			//plotting time
			foreach type in `type_list' {
				local D ""
				local myyear 2010

				if ("`submodel`type''" == "decinter") {
					local D "D`dd'"
					if `dd'==1 {
						local dtit="1971-1980"
					}
					else if `dd'==2 {
						local dtit="1981-1990"
					}
					else if `dd'==3 {
						local dtit="1991-2000"
					}
					else if `dd'==4 {
						local dtit="2001-2012"
					}
				}
				else if ("`submodel`type''" == "_lininter") {
					if `dd' == 0 {
						local myyear = `year_4_lininter'
					} 
					else {
						local myyear = 1961 + `dd'*10
						local dtit "Year `myyear'"
					}
				}
				di "`submodel'"
				di "`myyear'"
				
				local deltacut_subInc = `subInc' - `ibar`type''

				if ((inlist("`submodel`type''", "_ui", "_income_spline") ///
				| inlist("`model`type''","TINV_clim_ui","TINV_clim_income_spline")) ///
				& "`grouping_test`type''" == "semi-parametric") { 
					if `subInc' > `ibar`type'' local ig = 2
					else if `subInc' <= `ibar`type'' local ig = 1
				}
				else {
					di "model income grouping needs to be coded up."
					pause
				}

				local ster "FD`FGLS`type''_inter_clim`clim_data`type''_`case`type''`IF`type''_`bknum`type''_`grouping_test`type''_poly2_`model`type''`submodel`type''"
				
				//get_interacted_response program only set up for break2_Exclude spec
				assert strpos("`ster'", "break2") > 0
				assert strpos("`ster'", "Exclude") > 0

				if strpos("`ster'", "lininter") > 0 {
					local myyear_tit "_`myyear'"
				}
				
				get_interacted_response , model("`ster'") product("`var`type''") income_group(`ig') n_income_group(3) ///
				subInc(`subInc') subCDD(`subCDD') subHDD(`subHDD') deltacut_subInc(`deltacut_subInc') myyear(`myyear') decade(`dd')

				local line `s(interacted_response_line)'
				
				di "type: `type'"
				di "ster:`data'/`clim_data`type''/rationalized_code/`data_type'/sters/FD`FGLS`type''/`ster'"
				di "`line'"
				
				estimates use "`data'/`clim_data`type''/rationalized_code/`data_type'/sters/FD`FGLS`type''/`ster'"
				//ereturn display
				//pause

				predictnl yhat`type' = `line', se(se`type') ci(lower`type' upper`type')
				
				* convert yhat into gigajoules hours...
				if("`unit'" == "GJ") {
					replace yhat`type' = yhat`type' * 0.0036
				}

				if "`var`type''" == "other_energy" & "`2axis'" != "" {
					replace yhat`type' = yhat`type'/5
				}

				if "`2axis'" != "" {
					local yaxis "yaxis(1 2)"
				}

				loc SE = "`SE' rarea upper`type' lower`type' temp1, col(`col`type''%30) || line yhat`type' temp1, lc (`col`type'') ||"
				loc noSE = "`noSE' line yhat`type' temp1, lc (`col`type'') `yaxis' ||"
				local counter = `counter' + 1
				
			}
			
			local info "CDD: `avgCDD_`var'' HDD: `avgHDD_`var'' Inc: `avgInc_`var''"
			di "`info'"
			di "plotting info: cdd: `subCDD' hdd: `subHDD' inc: `subInc'"

			if ("`OV'" == "") {
				preserve
					keep temp1 yhat upper* lower* se*
					outsheet using "`data'/`clim_data'/rationalized_code/$data_type/plotting_responses/clim`ttit'_inc`ltit'_FD`FGLS'_inter_poly2_`model'`submodel'_`var'_clim`clim_data'_`case'`IF'_`bknum'_`grouping_test'`myyear_tit'`OV'`OVtag'.csv", comma replace
				restore
			}

			if ("`plot_se'" == "yes") {
				//plot with SE
				tw `SE' , yline(0, lwidth(vthin)) xlabel(`min'(10)`max', labsize(vsmall)) ///
				ylabel(, labsize(vsmall) nogrid) legend(off) ///
				subtitle("`info'", size(vsmall) color(dkgreen)) ///
				ytitle("`dtit'", size(vsmall)) xtitle("", size(small)) ///
				plotregion(color(white)) graphregion(color(white)) nodraw  ///
				name(M`dd'addgraph`cellid', replace)

				//add graphic with SE
				local graphicM = "`graphicM' M`dd'addgraph`cellid'"
			}

			if "`2axis'" != "" local yaxis_formatting ylabel(, labsize(vsmall) nogrid axis(2)) ytitle("", size(small) axis(2)) 

			//plot with no SE
			tw `noSE' , yline(0, lwidth(vthin)) xlabel(`min'(10)`max', labsize(vsmall)) ///
			ylabel(, labsize(vsmall) nogrid) `yaxis_formatting' legend(off) ///
			subtitle("`info'", size(vsmall) color(dkgreen)) ///
			ytitle("`dtit'", size(vsmall)) xtitle("", size(small)) ///
			plotregion(color(white)) graphregion(color(white)) nodraw ///
			name(M`dd'addgraph`cellid'_noSE, replace)			

			//add graphic no SE
			local graphicM_noSE="`graphicM_noSE' M`dd'addgraph`cellid'_noSE"


			drop yhat* se* lower* upper*
			local xs = `xs' + 1
		}

		if "`at'" != "" {

			local xs=2*`xs'
		
			//combine cells with SE
			graph combine `graphicM', imargin(zero) ycomm rows(1) ysize(3) xsize(`xs') ///
			title("Split Degree Days Poly 2 Interaction Model for Total `stit' Consumption `ttit' Climate `ltit' Income", size(small)) ///
			subtitle("", size(small)) ///
			plotregion(color(white)) graphregion(color(white)) name(comb`i', replace)
			graph export "`output_dir'/FD`FGLS'_inter_poly2_`model'`submodel'_`var'_clim`clim_data'_`case'`IF'_`bknum'_`grouping_test'`myyear_tit'`OV'`OVtag'_`ttit'_`ltit'.pdf", replace

			//combine cells no SE
			graph combine `graphicM_noSE', imargin(zero) ycomm rows(1) ysize(3) xsize(`xs') ///
			title("Split Degree Days Poly 2 Interaction Model for Total `stit' Consumption `ttit' Climate `ltit' Income", size(small)) ///
			subtitle("", size(small)) ///
			plotregion(color(white)) graphregion(color(white)) name(comb`i', replace)
			graph export "`output_dir'/FD`FGLS'_inter_poly2_`model'`submodel'_`var'_clim`clim_data'_`case'`IF'_`bknum'_`grouping_test'`myyear_tit'`OV'`OVtag'`2axis'_`ttit'_`ltit'_noSE.pdf", replace
		
			graph drop _all
		}

	}
}

//For each parameter check if parameter differs between base and overlay, if it does include it in a specification for title

if ("`at'" == "") {
	if ("`plot_se'" == "yes") {
		//combine cells with SE
		graph combine `graphicM', imargin(zero) ycomm rows(3) ///
		title("Split Degree Days Poly 2 Interaction Model for `stit' Consumption (`model')", size(small)) ///
		subtitle("`colorGuide'", size(vsmall)) ///
		plotregion(color(white)) graphregion(color(white)) name(comb`i', replace)

		graph export "`output_dir'/FD`FGLS'_inter_poly2_`model'`submodel'_`var'_clim`clim_data'_`case'`IF'_`bknum'_`grouping_test'`myyear_tit'`OV'`OVtag'.pdf", replace
	}

	//combine cells no SE
	graph combine `graphicM_noSE', imargin(zero) ycomm rows(3) ///
	title("Split Degree Days Poly 2 Interaction Model for `stit' Consumption (`model')", size(small)) ///
	subtitle("`colorGuide'", size(vsmall)) ///
	plotregion(color(white)) graphregion(color(white)) name(comb`i', replace)
	di "`output_dir'/FD`FGLS'_inter_poly2_`model'`submodel'_`var'_clim`clim_data'_`case'`IF'_`bknum'_`grouping_test'`myyear_tit'`OV'`OVtag'`2axis'_noSE.pdf"
	
	if("`for_appendix'" == "yes") {
		* cut out some of the locals from the name, so it saves on my computer
		graph export "`output_dir'/`model'`submodel'`myyear_tit'`OV'`OVtag'`2axis'_noSE.pdf", replace
	}
	else{
		graph export "`output_dir'/FD`FGLS'_inter_poly2_`model'`submodel'_`var'_clim`clim_data'_`case'`IF'_`bknum'_`grouping_test'`myyear_tit'`OV'`OVtag'`2axis'_noSE.pdf", replace
	}
	* graph drop _all
}
		

