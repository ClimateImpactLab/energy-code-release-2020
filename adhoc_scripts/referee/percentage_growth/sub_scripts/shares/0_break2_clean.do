
/*
Sub-script purpose: Clean raw load data in order to constuct consumption shares for other energy price consturction 
*/

**Keep relevant flows for the break2 spec
//keep if inlist(flow, "TOTIND", "TOTOTHER")
keep if inlist(flow,"RESIDENT","COMMPUB","ONONSPEC","AGRICULT","FISHING","TOTIND", "TOTOTHER")
**Keep relevant coal and oil products 

**Coal**
**Items: (kt) Anthracite, Coking coal, other bituminous coal, sub-bituminous coal, lignite
**Patent fuel, coke oven coke, gas coke, goal tar, bkb, peat, peat products, oil shale and oil sands
**(TJ): gas works gas, coke oven gas, blast furnace gas, other recovered gas
**Category from given: hard coal(kt), brown coal(kt), Anthracite(kt), Coking coal(kt), other bituminous coal(kt), sub-bituminous coal(kt)
**lignite(kt), peat(kt), patent fuel(kt), coke oven coke(kt), gas coke(kt), goal tar(kt), bkb(kt)
**gas works gas(TJ), coke oven gas(TJ), blast furnace gas(TJ), other recovered gas(TJ)
**peat products(kt), oil shale and oil sands(kt)

**Oil**
**Items: crude oil, natural gas liquid, refinery feedstocks, naphtha, liquified petroleum gases, motor, unit kts
**gasoline, aviation gasoline, jet kerosene, other kerosene, gas/diesel, fuel oil
**Category from given (kt): feedstock, crude oil, NGL, refinery stocks, Additive/blending component, 
**other hydrocarbons, refinary gas, ethane, liquified petroleum gas, aviation gasoline, jet kerosene, other kerosene
**fuel oil, naphtha, white spirit, lubric, bitumen, paraffin waxes, petroleum coke, other oil product, 
**gas/diesel no bio, kerosene no bio, motor gasoline no bio


keep if product=="HARDCOAL" | product=="BROWN" | product=="ANTCOAL" | product=="COKCOAL" | ///
		product=="BITCOAL" | product=="SUBCOAL" | product=="LIGNITE" | product=="PEAT" | ///
		product=="PATFUEL" | product=="OVENCOKE" | product=="GASCOKE" | product=="COALTAR"| ///
		product=="BKB" | product=="GASWKSGS" | product=="COKEOVGS" | product=="BLFURGS" | ///
		product=="PEATPROD" | product=="OGASES" | product=="OILSHALE" | ///
		product=="CRNGFEED" | product=="CRUDEOIL" | product=="NGL" | product=="REFFEEDS" | ///
		product=="ADDITIVE" | product=="NONCRUDE" | product=="REFINGAS" | product=="ETHANE" | ///
		product=="LPG" | product=="AVGAS" | product=="JETGAS" | product=="OTHKERO"| ///
		product=="RESFUEL" | product=="NAPHTHA" | product=="WHITESP" | product=="LUBRIC" | ///
		product=="BITUMEN" | product=="PARWAX" | product=="PETCOKE" | product=="ONONSPEC" |  ///
		product=="NONBIODIES" | product=="NONBIOJETK" | product=="NONBIOGASO" | product == "NATGAS" 


		