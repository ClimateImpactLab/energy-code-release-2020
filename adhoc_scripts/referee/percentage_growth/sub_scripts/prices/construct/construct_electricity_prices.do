//construct electricity prices



**Electricity: read over WEO graphics, 2016**
qui gen double electricitycompile_atprice=.
qui replace electricitycompile_atprice=128/1000 if country=="JPN"
qui replace electricitycompile_atprice=77/1000 if country=="KOR"
qui replace electricitycompile_atprice=74/1000 if country=="BRA"
qui replace electricitycompile_atprice=71/1000 if country=="AUS"
qui replace electricitycompile_atprice=70/1000 if country=="MEX"
qui replace electricitycompile_atprice=60/1000 if country=="IND"
qui replace electricitycompile_atprice=57/1000 if country=="USA"
qui replace electricitycompile_atprice=53/1000 if country=="CHN"
qui replace electricitycompile_atprice=51/1000 if country=="CAN"
qui replace electricitycompile_atprice=29/1000 if country=="RUS"
**Replacing**
**WSN Europe**
qui replace electricitycompile_atprice=82/1000 if subregionid==3 | subregionid==4 | subregionid==5
**E Asia**
preserve
	qui keep if country=="CHN" | country=="JPN" | country=="KOR" 
	qui collapse (mean) electricitycompile_atprice [fw=pop]
	local priceASIA=electricitycompile_atprice[1]
restore
qui replace electricitycompile_atprice=`priceASIA' if subregionid==7 & electricitycompile_atprice==.
**SE Asia**
qui replace electricitycompile_atprice=70/1000 if subregionid==8 
**S America by BRA**
qui replace electricitycompile_atprice=74/1000 if subregionid==10 & electricitycompile_atprice==.
**C America by MEX**
qui replace electricitycompile_atprice=70/1000 if subregionid==9 & electricitycompile_atprice==.
**N America**
preserve
	qui keep if country=="CAN" | country=="USA" 
	qui collapse (mean) electricitycompile_atprice [fw=pop]
	local priceNA=electricitycompile_atprice[1]
restore
qui replace electricitycompile_atprice=`priceNA' if subregionid==2 & electricitycompile_atprice==.
**S Asia by IND**
qui replace electricitycompile_atprice=60/1000 if subregionid==13 & electricitycompile_atprice==.
**Oceania by AUS**
qui replace electricitycompile_atprice=71/1000 if subregionid==1 & electricitycompile_atprice==.
**USSR former by RUS**
qui replace electricitycompile_atprice=29/1000 if subregionid==6 & electricitycompile_atprice==.
**SSA**
qui replace electricitycompile_atprice=59/1000 if subregionid==11
**ME**
qui replace electricitycompile_atprice=65/1000 if subregionid==12

**Electricity Peak Plant price**
qui gen double electricitycompile_peakprice=36/100
