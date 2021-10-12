
/*

Purpose: Clean Load Data

********************************************************************************
* Data Source: IEA (International Energy Agency), World Balance Table (WBAL)   *
* Access: 1) Log into UChicago Library 2) Search "OECD iLibrary", enter the    *
* website tapping the "full-text" link 3) In OECD iLibrary website, select the *
* tab "Statistics" 4) Abitrarily select one of the OECD dataset, click the     *
* purple button to enter a blue browser spread sheet 5) Do not close the       *
* spreadsheet, click on "IEA World Energy Statistics and Balances" 6) Enter    *
* through cliking the purple Data button into "World energy balances" dataset  *
* 7) Download csv file, or their compiled zip file                             *
********************************************************************************

//Note: the above data extraction progress has to be done under IE/Safari, Chrome is unstable
//Note: Documentation of this dataset is "WORLDBAL_Documentation.pdf" under Docs

*/

*--Load Data Cleaning--*

//This part of the code is to be run under Sacagawea, where raw datafile saved
local RAWDATA "${DATA}/energy/IEA"

// merge raw data files
import delimited using "`RAWDATA'/WBAL_13022019212114578.csv", clear
keep unit country product flow time value flagcodes
replace value=. if flagcodes=="M"
replace value=. if flagcodes=="L"
replace value=. if flagcodes=="C"
tempfile file1
save "`file1'" , replace

import delimited using "`RAWDATA'/WBAL_17102017011114914.csv", clear
keep unit country product flow time value flagcodes
keep if flow == "TFC" | flow == "TOTIND"
replace value=. if flagcodes=="M"
replace value=. if flagcodes=="L"
replace value=. if flagcodes=="C"
tempfile file2
save "`file2'" , replace

import delimited using "`RAWDATA'/WBAL_24102017005034148.csv", clear
keep unit country product flow time value flagcodes
keep if flow == "TOTRANS"
replace value=. if flagcodes=="M"
replace value=. if flagcodes=="L"
replace value=. if flagcodes=="C"
append using "`file1'"
append using "`file2'"

// clean/reshape
keep unit country product flow time value
reshape wide value, i(unit country flow time) j(product) string

// Save/export
ren value* *
ren time year
