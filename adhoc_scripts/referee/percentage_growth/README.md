# Codes for cleaning and extrapolating IEA energy prices for other energy and electricity 

## Overall summary


Total of 18 scripts in this process. They are run using two master scripts:
1. 0_clean.do
    * This cleans up the data needed for 1_extrapolate
    * Inputs: OECD and Non-OECD price data, GDP deflator data, consumption data
    * Outputs: 
        * IEA_price.dta – country-year level prices for fuels and sub-fuels
        * Consumption_shares.dta - country level consumption values for subfuels

2. 1_extrapolate.do
    * This does two types of extrapolation
        * Extrapolates in sample data to get one tax free observation for each country, flow, product 
            * Extrapolation is necessary because most combinations of country - flow - product - year are not in the IEA raw data
        * Extrapolates forward in time using a different price growth scenarios 
    * Inputs: UNSD — Methodology.csv, to assign subregionids to countries, 2010 population data from IEA_Merged_long_GMFD.dta, GDP deflator, outputs of 0_clean
    * (final) output: IEA_Price_FIN_Clean_gr*_GLOBAL_COMPILE.dta, where * is for each price growth scenario 


For a detailed summary of the steps taken in this process, see this document: [https://www.dropbox.com/s/2ehfrq04wk6eql2/price_replication_notes.docx?dl=0](https://www.dropbox.com/s/2ehfrq04wk6eql2/price_replication_notes.docx?dl=0)


`````````````
