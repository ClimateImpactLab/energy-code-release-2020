//Purpose of subfunction: Create subregioniod based on UN subregions

generate subregionid=.
replace subregionid=1 if regionname=="Oceania" 
replace subregionid=2 if subregionname=="Northern America" 
replace subregionid=3 if subregionname=="Northern Europe" 
replace subregionid=4 if subregionname=="Southern Europe"
replace subregionid=5 if subregionname=="Western Europe"
replace subregionid=6 if subregionname=="Eastern Europe" | subregionname=="Central Asia" 
replace subregionid=7 if subregionname=="Eastern Asia" 
replace subregionid=8 if subregionname=="South-eastern Asia" 
replace subregionid=9 if intermediateregionname=="Caribbean" | intermediateregionname=="Central America"
replace subregionid=10 if intermediateregionname=="South America"
replace subregionid=11 if subregionname=="Sub-Saharan Africa" 
replace subregionid=12 if subregionname=="Northern Africa" | subregionname=="Western Asia" 
replace subregionid=13 if subregionname=="Southern Asia"
drop if subregionid==.
keep isoalpha3code subregionid
rename isoalpha3code country
