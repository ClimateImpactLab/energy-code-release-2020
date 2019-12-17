/*
Creator: Maya Norman
Purpose: Condense Energy Other Energy Products using raw IEA products

We define electricity consumption based on ELECTR variable code, and consumption 
of other fuels is obtained by aggregating over the following variable codes: COAL (Coal and coal products); 
PEAT (Peat and peat products); OILSHALE (Oil shale and oil sands); TOTPRODS (Oil products); 
NATGAS (Natural gas); SOLWIND (Solar/wind/other); GEOTHERM (Geothermal); 
COMRENEW (Biofuels and waste); HEAT (Heat), HEATNS (Heat pro- duction from non-specified combustible fuels).

*/

//Grouping categories using IEA norm
**Coal: coal+peat+oilshale**
generate double coal=COAL+PEAT+OILSHALE
**NG: itself**
generate double natural_gas=NATGAS
**Electricity: itself, not obbeying the IEA grouping and drop heat**
cap generate double electricity=ELECTR
**Heat: to keep the balance work**
cap generate double heat_other=HEAT+HEATNS

**separate out biofuels and oilproduct**
cap generate double biofuels=COMRENEW
generate double oil_products=TOTPRODS
cap generate double solar=SOLWIND+GEOTHERM

//clean up shop
keep country year flow coal natural_gas electricity heat_other biofuels oil_products solar


	