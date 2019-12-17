/*
Creator: Yuqi Song
Date last modified: 4/29/19
Last modified by: Maya Norman -- create one loop which all shapefiles go through, complete replication modifications
References for issues addressed in Climate Data Construction: 
historic: 
	https://docs.google.com/spreadsheets/d/1xpwmzk4HVMSBgsiZ6r9JNCQOVxaRNcnAy5wFLAo72Rw/edit?usp=sharing
	https://docs.google.com/spreadsheets/d/10br5G1PtPn20M8KI5_p4iESk7J1BhVT_vbXb6OjqEi8/edit?usp=sharing
replication: 
	https://paper.dropbox.com/doc/Energy-Replication-Data-Extraction-and-Clean--AcW~Qw9B5VVB29k4PJCYL1I3Ag-VAYyKKRjKXNub5MzctYgB

Purpose: Clean/Aggregate Climate data for Energy

	********************************************************************************
	* Data Source: GMFD   														   *
	* Generations: Using the data generation codes of https://bitbucket.org/       *
	* ClimateImpactLab/climate_data_aggregation									   *
	* Input files constructed with 0_Clim_Config_Gen.do		                   	   *
	********************************************************************************

*/


*--Climate Data Cleaning--*

program define clean_climate_data

syntax , clim(string) //note functionality only set up for GMFD currently

	//SET UP RELEVANT PATHS

	if "`c(username)'" == "mayanorman"{

		local ROOT "/Users/`c(username)'"
		local DROPBOX "`ROOT'/Dropbox"
		local GIT "`ROOT'/Documents/Repos/gcp-energy"

	}
	else if "`c(username)'" == "manorman"{
		// This path is for running the code on Sacagawea
		local ROOT "/home/`c(username)'"
		local DROPBOX "/home/`c(username)'"
		local RAWDATA "/shares/gcp/estimation/energy/IEA"
		local GIT "`ROOT'/gcp-energy"
	}

	local programs_path "`GIT'/rationalized/0_make_dataset/climate/programs"

	//Define loop lists

	local climvar_list "tmax_cdd_20C tmax_hdd_20C tavg_poly_1 tavg_poly_2 tavg_poly_3 tavg_poly_4 tavg_polyBelow20_1 tavg_polyBelow20_2 tavg_polyBelow20_3 tavg_polyBelow20_4 tavg_polyAbove20_1 tavg_polyAbove20_2 tavg_polyAbove20_3 tavg_polyAbove20_4 prcp_poly_1 prcp_poly_2"
	local shpfile_list "WORLD WORLDpre SRB_MNE_XKO SRB_MNE MDA_other ITA_SMR_VAT ISR_PSE CUW_BES_ABW FRA_MCO"

	//Note: when generate the climate datas, one must follow the exact folder in this code in order for the cleaning code to be running 

	***************************************************************************************
	*Step 0: Source Programs -- Cleaning and Processing of Aggregated Climate Data Issues
	***************************************************************************************

	do "`programs_path'/helper_functions.do"

	foreach shp in `shpfile_list' {
		do "`programs_path'/clean_`shp'.do"
	}

	****************************************************************
	*Step 1: Generate tempfile with climate data for each shapefile*
	****************************************************************

	//Define shape file paths based on shape file

	foreach shp in `shpfile_list' {

		local `shp'_path = "/shares/gcp/climate/_spatial_data/`shp'/weather_data/"

	}

	local WORLDpre_path = "/shares/gcp/climate/_spatial_data/WORLD/pre1991/weather_data/"


	foreach shp in `shpfile_list' {

		local climvar_counter = 0

		foreach climvar in `climvar_list' {
			
			local climvar_counter = `climvar_counter' + 1
			//Define year chunks given shp file and climate variable

			if ("`shp'" == "WORLD" & inlist("`climvar'", "tmax_cdd_20C", "tmax_hdd_20C", "tavg_poly_1", "tavg_poly_2", "tavg_poly_3", "tavg_poly_4")) | ///
			("`shp'" == "WORLDpre" & inlist("`climvar'", "tmax_cdd_20C", "tavg_poly_1", "tavg_poly_2", "tavg_poly_3", "tavg_poly_4")) {

				local yearspan_list " 1950_1952 1953_1962 1963_1972 1973_1982 1983_1992 1993_2002 2003_2010 "

			}
			else if (("`shp'" == "WORLDpre" & inlist("`climvar'", "tmax_hdd_20C")) | ///
			(inlist("`shp'", "SRB_MNE_XKO", "SRB_MNE", "MDA_other") & ///
			 inlist("`climvar'", "tmax_cdd_20C", "tmax_hdd_20C", "tavg_poly_1", "tavg_poly_2", "tavg_poly_3", "tavg_poly_4"))) {

				local yearspan_list " 1950_1950 1951_1955 1956_1960 1961_1965 1966_1970 1971_1975 1976_1980 1981_1985 1986_1990 1991_1995 1996_2000 2001_2005 2006_2010 "

			} 
			else if ("`shp'" == "WORLD" & inlist("`climvar'", "prcp_poly_1", "prcp_poly_2")) {

				local yearspan_list " 1970_1972 1973_1982 1983_1992 1993_2002 2003_2010 "

			}
			else if ("`shp'" == "WORLD" & inlist("`climvar'", "tavg_polyAbove20_1", "tavg_polyAbove20_2", "tavg_polyAbove20_3", "tavg_polyAbove20_4")) {

				local yearspan_list " 1970_1970 1971_1975 1976_1980 1981_1985 1986_1990 1991_1995 1996_2000 2001_2005 2006_2010"

			}
			else if ( inlist("`shp'", "ITA_SMR_VAT", "ISR_PSE", "CUW_BES_ABW", "FRA_MCO") & !inlist("`climvar'","tmax_cdd_20C","tmax_hdd_20C") ) {

				local yearspan_list " 1968_1972 1973_1977 1978_1982 1983_1987 1988_1992 1993_1997 1998_2002 2003_2007 2008_2010 "

			}
			else if ( inlist("`shp'", "ITA_SMR_VAT", "ISR_PSE", "CUW_BES_ABW", "FRA_MCO") & inlist("`climvar'","tmax_cdd_20C","tmax_hdd_20C") ) {

				local yearspan_list " 1950_1952 1953_1957 1958_1962 1963_1967 1968_1972 1973_1977 1978_1982 1983_1987 1988_1992 1993_1997 1998_2002 2003_2007 2008_2010 "

			}
			else {

				local yearspan_list " 1966_1970 1971_1975 1976_1980 1981_1985 1986_1990 1991_1995 1996_2000 2001_2005 2006_2010 "

			}

			//Define temporal unit of climate data

			if (inlist("`shp'", "WORLD", "WORLDpre")) {

				local temp_unit "monthly"

			}
			else {

				local temp_unit "yearly"

			}

			local yearspan_counter = 0

			foreach yearspan in `yearspan_list' {

				local yearspan_counter = `yearspan_counter' + 1

				qui insheet using "``shp'_path'/csv_`temp_unit'/`clim'/`clim'_`climvar'_v2_`yearspan'_`temp_unit'_popwt.csv", comma names clear

				process_`temp_unit'
				
				rename y `climvar'

				if (`yearspan_counter' == 1 & `climvar_counter' == 1) {
					qui tempfile `shp'
					qui save ``shp'', replace
				} 
				else if (`climvar_counter' == 1 & `yearspan_counter' > 1) {
					qui append using ``shp''
					qui save ``shp'', replace
				}
				else if (`climvar_counter' > 1 & "`temp_unit'" == "monthly") {
					qui merge 1:1 country year month using ``shp''
					assert _merge != 1
					drop _merge
					qui save ``shp'', replace
				}
				else if (`climvar_counter' > 1 & "`temp_unit'" == "yearly") {
					qui merge 1:1 country year using ``shp''
					assert _merge != 1
					drop _merge
					qui save ``shp'', replace
				}

				di "`climvar' `yearspan' `shp'"

			}
		}
	}


	**********************************************************************************************
	*Step 2: Clean shapefile level climate dataset based on Issues and Save into Aggregate Dataset
	**********************************************************************************************

	local shp_counter = 0

	foreach shp in `shpfile_list' {

		local shp_counter = `shp_counter' + 1

		use ``shp'', clear
		clean_`shp'
		save ``shp'', replace
		di "`shp'"
		pause
		
		if (`shp_counter' == 1) {
			tempfile `clim'
			save ``clim'', replace
		}
		else if (`shp_counter' > 1) {
			use ``clim'', clear
			merge 1:1 country year using ``shp'', update
			di "Merged `shp' in!"
			pause
			drop _merge
			save ``clim'', replace
		}

	}


	**drop unwanted years**
	drop if year<1971
	drop if year>2010

	rename tavg_poly_* temp*_`clim'
	rename prcp_poly_* precip*_`clim'
	rename tavg_polyAbove20_* polyAbove*_`clim'
	rename tavg_polyBelow20_* polyBelow*_`clim'
	rename tmax_cdd_20C_* cdd20_*_`clim'
	rename tmax_hdd_20C_* hdd20_*_`clim'
	rename tmax_cdd_20C cdd20_`clim'
	rename tmax_hdd_20C hdd20_`clim'

	sort country year temp* cdd* hdd* polyAbove* polyBelow* precip*

end