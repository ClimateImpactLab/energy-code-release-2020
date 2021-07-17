Prepared by: Ruixue Li, liruixue@uchicago.edu
             Climate Impact Lab

Version:     2021-Jun-18


The files in this folder contain projected energy-related outputs, for various combinations of the following parameters : quantiles of the output, units of output, geographical level, temporal level, emission scenario, economic scenario.

Units:
 
1. impacts_gj: per capita change in energy consumption in Gigajoules.
2. impacts_kwh: per capita change in energy consumption in kilowatt-hour (kWh).
3. impacts_pct_gdp : change in energy expenditures as percentage of projected future GDP (measured in percent)

 
Geographical levels :

1. Impact regions
2. Impact regions (cities with >500k population)
3. State (USA)
4. Country (ISO code, can be matched to any standard country-level shapefile)
5. Global

Temporal levels :

1. All : Individual years 2020-2099
2. Averaged : Two-decades averages (2020-2039, 2040-2059, 2080-2099)

RCP, IAM and SSP (see details below):

1. RCP 4.5, RCP 8.5
2. SSP3
3. IAM: IIASA (low)

Summary statistic : 
1. Quantiles [0.05,0.17,0.50,0.83,0.95]
2. Mean

Folder structure : impacts-outreach - geographical level - emission scenario - socioeconomic pathway 

File title : unit_{fuel}_{unit}_geography_{geographic level}_years_{temporal  level}_{rcp}_{ssp}_quantiles_{summary statistic}.csv


Details about the units : 

1. Change in energy consumption (units: Gigajoules or kWh): Projected per capita change in electricity or other fuels consumed due to climate change. These values are based upon emissions scenario RCP 4.5 or RCP 8.5, socioeconomic scenario SSP3 (from the IIASA Shared Socioeconomic Pathways database), and are climate model-weighted means over 33 climate models. Quantiles are calculated using the delta method along with Newton's method. Impacts aggregated at a higher geographical level than impact region are population-weighted averages of the corresponding impact region-level estimates (there are 24,378 impact regions across the globe).

2. Change in energy expenditures as % GDP (units: percent): Projected change in energy expenditures (both electricity and other fuels) due to climate change as a percentage of projected global GDP. Future prices are assumed to grow at 1.4% per year. These values are based upon emissions scenario RCP 4.5 or RCP 8.5, socioeconomic scenario SSP3 (from the IIASA Shared Socioeconomic Pathways database), and are climate model-weighted mean estimates over 33 climate models. Quantiles are calculated using the delta method along with Newton's method. Expenditure changes and GDP used to construct percentages are aggregated to higher geographical levels as totals of the corresponding impact region-level estimates (there are 24,378 impact regions across the globe). 


