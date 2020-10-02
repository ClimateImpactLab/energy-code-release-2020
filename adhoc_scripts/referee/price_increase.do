
* Calculate price increases for non-US countries for which we have price data.
* take the earliest/latest years available in the data (IEA_price.dta)
global path "/mnt/CIL_energy/IEA_Replication/Data/Projection/prices/1_inter/"
global path "/mnt/CIL_energy/IEA_Replication/Data/Projection/prices/2_final/"

use "${path}/IEA_Price.dta", clear
use "${path}/consumption_shares.dta", clear

biofuels        double  %10.0g                biofuels value
coal            double  %10.0g                coal value
electricity     double  %10.0g                electricity value
heat_other      double  %10.0g                heat_other value
oil_products    double  %10.0g                oil_products value
solar           double  %10.0g                solar value