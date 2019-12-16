/*
Creator: Yuqi Song
Date last modified: 3/12/19 
Last modified by: Maya Norman

Purpose: Generate Climate Data Aggregation Configuratin Files to be used with 
climate_data_aggregation/aggregation/merge_transform_average.py

//The following notation is only used in this config generation do-file: 
* temp-poly: tavg poly 1-4
* precip-poly: prcp poly 1-2
* temp-above-poly: polyAbove 20C 1-4
* temp-below-poly: polyBelow 20C 1-4
* hdd: hdd 20C
* cdd: cdd 20C

*/


clear all
set more off
macro drop _all


//SET UP RELEVANT PATHS

if "`c(username)'" == "mayanorman"{

	local DROPBOX "/Users/`c(username)'/Dropbox"
	local GIT "/Users/`c(username)'/Documents/Repos/gcp-energy"

}
else if "`c(username)'" == "manorman"{
	// This path is for running the code on Sacagawea
	local DROPBOX "/home/`c(username)'"
	local RAWDATA "/shares/gcp/estimation/energy/IEA"
	local GIT "/home/manorman/gcp-energy"

}


**Set parameters [change accordingly]
local sys="sacagawea" //running system
local path="/shares/gcp/climate/_spatial_data" //path of the shapefiles
local clim="GMFD" //default climate dataset for Energy
local gap=5 //For BEST, generating 10-years data per output file is OK for the Sacagawea system, but for smaller grid GMFD data aggregation, take gap=5. 


**store the files**
cd "`GIT'/rationalized_code/0_make_dataset/climate_data/climate_configs"

foreach mod in "aggregation" "gis" { //gis input or aggregation output step - note gis input step only need to be done once for each clim dataset, and for Energy they've already been completed for BEST+UDEL+GMFD

foreach shp in "WORLD" "WORLDpre" "SRB_MNE_XKO" "SRB_MNE" "MDA_other" "DNK_GRL" "ITA_SMR_VAT" "ISR_PSE" "CUW_BES_ABW" "FRA_MCO" {
	
	**Write configs**
	
	**GIS input config file generations**
	if "`mod'"=="gis" {
	
		file open txt using "`mod'_input_`shp'.txt", write replace

	
		file write txt "{" _n
		file write txt "    'run_location': '`sys''," _n
		file write txt "    'n_jobs': 0," _n
		file write txt "    'verbose': 2," _n
		
		//Specify clim dataset
		file write txt "    'clim': '`clim''," _n
		
		//Location of the shapefile under directory "path" 
		if ("`shp'"!="WORLDpre") {
			file write txt "    'shapefile_location': '`path'/`shp''," _n
		}
		else if "`shp'"=="WORLDpre" {
			file write txt "    'shapefile_location': `path'/WORLD'," _n
		}

		
		//Name of the shapefile
		if "`shp'"!="WORLD" & "`shp'"!="WORLDpre" & "`shp'"!="MDA_other" {
			file write txt "    'shapefile_name': '`shp'_adm0'," _n
			file write txt "    'shp_id': '`shp'_adm0'," _n
		}
		else if "`shp'"=="WORLD" {
			file write txt "    'shapefile_name': 'gadm28_adm0'," _n
			file write txt "    'shp_id': 'gadm28_adm0'," _n
		}
		else if "`shp'"=="MDA_other" {
			file write txt "    'shapefile_name': '`shp''," _n
			file write txt "    'shp_id': '`shp''," _n
		}
		else if "`shp'"=="WORLDpre" {
			file write txt "    'shapefile_name': 'gadm28_adm0_pre1991'," _n
			file write txt "    'shp_id': 'gadm28_adm0_pre1991'," _n
		}
		
		file write txt "    'numeric_id_fields': []," _n
		file write txt "    'string_id_fields': ['ISO']," _n
		
		//Pop weighted
        file write txt "    'weightlist': ['pop']," _n
		file write txt "    'use_existing_segment_shp': False," _n
		file write txt "    'filter_ocean_pixels': False," _n
        file write txt "    'keep_features': None," _n
        file write txt "    'drop_features': None" _n
		
		file write txt "}" _n
		file close txt
	
	}
	
	**climate data aggregation config file generations**
	else if "`mod'"=="aggregation" {
	
		foreach climvar in "temp-poly" "precip-poly" "temp-above-poly" "temp-below-poly" "hdd" "cdd" {
		
			file open txt using "`mod'_input_`shp'_`climvar'.txt", write replace

	
			if ("`climvar'" == "temp-poly" | "`climvar'" == "hdd" | "`climvar'" == "cdd") {
				local y0 = 1968
				local y1 = 2012
			}
			else {
				local y0 = 1968
				local y1 = 2012
			}
	
			file write txt "{" _n
			file write txt "    'run_location': '`sys''," _n
			
			//Input file from the GIS step and output directory of the final csv 
			if "`shp'"!="WORLD" & "`shp'"!="WORLDpre" & "`shp'"!="MDA_other" {
				file write txt "    'input_file': '`path'/`shp'/segment_weights/`shp'_adm0_{}_grid_segment_weights_area_pop.csv'," _n 
				file write txt "    'output_dir': '`path'/`shp''," _n
			}
			else if "`shp'"=="WORLD" {
				file write txt "    'input_file': '`path'/WORLD/segment_weights/gadm28_adm0_{}_grid_segment_weights_area_pop.csv'," _n 
				file write txt "    'output_dir': '`path'/WORLD_mn'," _n
			}
			else if "`shp'"=="MDA_other" {
				file write txt "    'input_file': '`path'/`shp'/segment_weights/`shp'_{}_grid_segment_weights_area_pop.csv'," _n 
				file write txt "    'output_dir': '`path'/`shp''," _n
			}
			else if "`shp'"=="WORLDpre" {
				file write txt "    'input_file': '`path'/WORLD/segment_weights/gadm28_adm0_pre1991_{}_grid_segment_weights_area_pop.csv'," _n 
				file write txt "    'output_dir': '`path'/WORLD/pre1991_mn'," _n
			}
			
			file write txt "    'region_columns': ['ISO']," _n
			file write txt "    'group_by_column': None," _n
			file write txt "    'weight_columns': ['popwt']," _n
			file write txt "    'climate_source': ['`clim'']," _n
			
			//variable specific specifications
			if "`climvar'"=="temp-poly" {
				file write txt "    'parameters': ['tavg']," _n
				file write txt "    'transforms': {'poly': 4}," _n
				file write txt "    'collapse_as': 'sum'," _n
			}
			else if "`climvar'"=="precip-poly" {
				file write txt "    'parameters': ['prcp']," _n
				file write txt "    'transforms': {'poly': 2}," _n
				file write txt "    'collapse_as': 'sum'," _n
			}
			else if "`climvar'"=="temp-above-poly" {
				file write txt "    'parameters': ['tavg']," _n
				file write txt "    'transforms': {'polyAbove': [4,20]}," _n
				file write txt "    'collapse_as': 'sum'," _n
			}
			else if "`climvar'"=="temp-below-poly" {
				file write txt "    'parameters': ['tavg']," _n
				file write txt "    'transforms': {'polyBelow': [4,20]}," _n
				file write txt "    'collapse_as': 'sum'," _n
			}
			else if "`climvar'"=="hdd" {
				file write txt "    'parameters': ['tavg']," _n
				file write txt "    'transforms': {'hdd': [20,20,1]}," _n
				file write txt "    'collapse_as': 'sum'," _n
			}
			else if "`climvar'"=="cdd" {
				file write txt "    'parameters': ['tavg']," _n
				file write txt "    'transforms': {'cdd': [20,20,1]}," _n
				file write txt "    'collapse_as': 'sum'," _n
			}
			else if "`climvar'"=="bin-above" {
				file write txt "    'parameters': ['tavg']," _n
				file write txt "    'transforms': {'binAbove': 20}," _n
				file write txt "    'collapse_as': 'sum'," _n
			}
			else if "`climvar'"=="bin-below" {
				file write txt "    'parameters': ['tavg']," _n
				file write txt "    'transforms': {'binBelow': 20}," _n
				file write txt "    'collapse_as': 'sum'," _n
			}
			else if "`climvar'"=="NAN" {
				file write txt "    'parameters': ['tavg']," _n
				file write txt "    'transforms': {'nan': 20}," _n
				file write txt "    'collapse_as': 'avg'," _n
			}

			//year frame specification: month for fiscal year fixes shapefiles WORLD and WORLDpre, year for other
			if "`shp'"!="WORLD" & "`shp'"!="WORLDpre" {
				file write txt "    'collapse_to': 'year'," _n
			}
			else if "`shp'"=="WORLD" | "`shp'"=="WORLDpre" {
				file write txt "    'collapse_to': 'month'," _n
			}
			
			file write txt "    'year_block_size': `gap'," _n
			file write txt "    'first_year': `y0'," _n
			file write txt "    'last_year': `y1'" _n
			
			file write txt "}" _n
			file close txt
		}
	}

}
	
}


