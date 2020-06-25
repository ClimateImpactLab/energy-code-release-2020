'''
--------------------------------------------------------------------------
## RCPs

We can run FAIR with the CO$_2$ emissions and non-CO$_2$ forcing from the four
representative concentration pathway scenarios. To use the emissions-based
version specify ```useMultigas=True``` in the call to ```fair_scm()```.

By default in multi-gas mode, volcanic and solar forcing plus natural emissions
of methane and nitrous oxide are switched on.

We can compute the SCC by adding an additional pulse in CO2 emissions to the
RCP trajectory.

This study uses a 1 Gt C emissions pulse. You can change the pulse amount by
modifying the PULSE_AMT variable. 

--------------------------------------------------------------------------
'''
import fair
import numpy as np
import pandas as pd
import xarray as xr
from fair.RCPs import rcp3pd, rcp45, rcp6, rcp85
import matplotlib
from matplotlib import pyplot as plt
from matplotlib import cm
import seaborn as sns
import sys
import load_parameters
import copy


# IMPORTANT!!!!!!!!!!!!!!!!!!!!!!!!!!!!! 
# Unless the climate team recommends a cross-project version bump, the FAIR package should be as specified below.

project_fair_vers = '1.3.2'

assert fair.__version__ == project_fair_vers, (
    "system FAIR version has changed. Install with `pip install fair=={}`".format(project_fair_vers))

def temperatures_anomaly(PULSE_YEAR, 
	PULSE_AMT, 
	output = None, 
	make_plots = False,
	plot_all_scenarios = False
	):

	"""
	Parameters:
	PULSE_YEAR (int): year in which pulse will be emitted
	PULSE_AMT (double): quantity of pulse emitted in Gt C = 1e9 ton C
	output (string): path to where plots should be saved
	make_plots (boolean): if true -> make plots visualizing fair
	plot_all_scenarios (boolean): if true -> make fair visualization plots for both rcp45 and rcp85 as well as rcp45, 85, 6, and 3pd
	
	Returns:
	DataArray: temperature projections under different emission scenarios with PULSE_AMT emitted in PULSE_YEAR

	"""

	# confirm, if plotting, place to save is specified
	if make_plots :
		assert output != None


	# load median FAIR parameters

	# version control here is defined by the climate team
	# you should coordinate with the climate team to ensure you are using the right version

	CLIMATE_V1 = False # refers to the parameter set used. This is summer 2018 paper version
	CLIMATE_V2 = False # This is 2019 paper version w/ pulse year = 2015
	CLIMATE_V2p1 = True # this is 2019 paper version w/ pulse year = 2020

	# ensure version aligns with PULSE_YEAR
	if CLIMATE_V1 or CLIMATE_V2:
	    PULSE_YEAR = 2015
	elif CLIMATE_V2p1:
	    PULSE_YEAR = 2020
	else:
	    raise NotImplementedError
	
	tcr, ecs, d2, tau4 = load_parameters.get_median_climate_params(CLIMATE_V1 = CLIMATE_V1, 
		CLIMATE_V2 = CLIMATE_V2, 
		CLIMATE_V2p1 = CLIMATE_V2p1).values

	# Run the RCP emissions scenarios
	C26, F26, T26 = fair.forward.fair_scm(emissions=rcp3pd.Emissions.emissions,tcrecs=np.array([tcr,ecs]),
	            tau=np.array([1000000, 394.4, 36.54, tau4]),
	            d=np.array([239.0, d2]))
	C45, F45, T45 = fair.forward.fair_scm(emissions=rcp45.Emissions.emissions,tcrecs=np.array([tcr,ecs]),
	            tau=np.array([1000000, 394.4, 36.54, tau4]),
	            d=np.array([239.0, d2]))
	C60, F60, T60 = fair.forward.fair_scm(emissions=rcp6.Emissions.emissions,tcrecs=np.array([tcr,ecs]),
	            tau=np.array([1000000, 394.4, 36.54, tau4]),
	            d=np.array([239.0, d2]))
	C85, F85, T85 = fair.forward.fair_scm(emissions=rcp85.Emissions.emissions,tcrecs=np.array([tcr,ecs]),
	            tau=np.array([1000000, 394.4, 36.54, tau4]),
	            d=np.array([239.0, d2]))

	if make_plots:
		
		fig = plt.figure()
		ax1 = fig.add_subplot(221)
		ax2 = fig.add_subplot(222)
		ax3 = fig.add_subplot(223)
		ax4 = fig.add_subplot(224)

		ax1.set_ylabel('Fossil CO$_2$ Emissions (GtC)')
		ax2.set_ylabel('CO$_2$ concentrations (ppm)')
		ax3.set_ylabel('Total radiative forcing (W.m$^{-2}$)')
		ax4.set_ylabel('Temperature anomaly (K)');

		#rcp45
		ax1.plot(rcp45.Emissions.year, rcp45.Emissions.co2_fossil, color='blue', label='RCP4.5')
		ax2.plot(rcp45.Emissions.year, C45[:, 0], color='blue')
		ax3.plot(rcp45.Emissions.year, np.sum(F45, axis=1), color='blue')
		ax4.plot(rcp45.Emissions.year, T45, color='blue')

		#rcp85
		ax1.plot(rcp85.Emissions.year, rcp85.Emissions.co2_fossil, color='black', label='RCP8.5')
		ax2.plot(rcp85.Emissions.year, C85[:, 0], color='black')
		ax3.plot(rcp85.Emissions.year, np.sum(F85, axis=1), color='black')
		ax4.plot(rcp85.Emissions.year, T85, color='black')

		sns.despine()
		ax1.legend()
		fig.savefig('{}/fair_control_scenarios.pdf'.format(output))

		if plot_all_scenarios:
			#rcp3
			ax1.plot(rcp3pd.Emissions.year, rcp3pd.Emissions.co2_fossil, color='green', label='RCP3PD')
			ax2.plot(rcp3pd.Emissions.year, C26[:, 0], color='green')
			ax3.plot(rcp3pd.Emissions.year, np.sum(F26, axis=1), color='green')
			ax4.plot(rcp3pd.Emissions.year, T26, color='green')

			#rcp6
			ax1.plot(rcp6.Emissions.year, rcp6.Emissions.co2_fossil, color='red', label='RCP6')
			ax2.plot(rcp6.Emissions.year, C60[:, 0], color='red')
			ax3.plot(rcp6.Emissions.year, np.sum(F60, axis=1), color='red')
			ax4.plot(rcp6.Emissions.year, T60, color='red')


			ax1.legend()
			sns.despine()
			fig.savefig('{}/fair_control_all_scenarios.pdf'.format(output))

	# Create new emissions scenarios corresponding to each RCP with the additional pulse
	for scen in [rcp3pd, rcp45, rcp6, rcp85]:
	    # copy the emissions object
	    scen.Plus = copy.deepcopy(scen.Emissions)
	    # add an additional impulse of fossil CO2
	    scen.Plus.co2_fossil = (
	        scen.Plus.co2_fossil + np.where(scen.Plus.year == PULSE_YEAR, PULSE_AMT, 0))
	    # update the emissions accounting throughout the data object to reflect the change
	    # Second line sums over fossil and land use CO2.
	    scen.Plus.emissions[:,1] = scen.Plus.co2_fossil
	    scen.Plus.co2 = np.sum(scen.Plus.emissions[:,1:3],axis=1)

	# Run FAIR for each of these new scenarios
	C26p, F26p, T26p = fair.forward.fair_scm(emissions=rcp3pd.Plus.emissions,tcrecs=np.array([tcr,ecs]),
	            tau=np.array([1000000, 394.4, 36.54, tau4]),
	            d=np.array([239.0, d2]))
	C45p, F45p, T45p = fair.forward.fair_scm(emissions=rcp45.Plus.emissions,tcrecs=np.array([tcr,ecs]),
	            tau=np.array([1000000, 394.4, 36.54, tau4]),
	            d=np.array([239.0, d2]))
	C60p, F60p, T60p = fair.forward.fair_scm(emissions=rcp6.Plus.emissions,tcrecs=np.array([tcr,ecs]),
	            tau=np.array([1000000, 394.4, 36.54, tau4]),
	            d=np.array([239.0, d2]))
	C85p, F85p, T85p = fair.forward.fair_scm(emissions=rcp85.Plus.emissions,tcrecs=np.array([tcr,ecs]),
	            tau=np.array([1000000, 394.4, 36.54, tau4]),
	            d=np.array([239.0, d2]))

	# plot difference between RCP and RCP+ scenarios
	if make_plots:
		
		fig = plt.figure()
		ax1 = fig.add_subplot(221)
		ax2 = fig.add_subplot(222)
		ax3 = fig.add_subplot(223)
		ax4 = fig.add_subplot(224)

		fig.suptitle('Marginal effect of CO2 pulse by scenario', size=18)
		ax1.set_ylabel('Fossil CO$_2$ Emissions (GtC)')
		ax2.set_ylabel('CO$_2$ concentrations (ppm)')
		ax3.set_ylabel('Total radiative forcing (W.m$^{-2}$)')
		ax4.set_ylabel('Temperature anomaly (K)');

		ax1.plot(rcp45.Plus.year, (rcp45.Plus.co2_fossil - rcp45.Emissions.co2_fossil), color='blue', label='RCP4.5')
		ax2.plot(rcp45.Plus.year, (C45p[:, 0] - C45[:, 0]), color='blue')
		ax3.plot(rcp45.Plus.year, np.sum((F45p-F45), axis=1), color='blue')
		ax4.plot(rcp45.Plus.year, (T45p-T45), color='blue')

		ax1.plot(rcp85.Plus.year, (rcp85.Plus.co2_fossil - rcp85.Emissions.co2_fossil), color='black', label='RCP8.5')
		ax2.plot(rcp85.Plus.year, (C85p[:, 0] - C85[:, 0]), color='black')
		ax3.plot(rcp85.Plus.year, np.sum((F85p-F85), axis=1), color='black')
		ax4.plot(rcp85.Plus.year, (T85p-T85), color='black')

		ax1.legend()
		sns.despine()
		fig.savefig('{}/fair_response_to_impulse_scenarios.pdf'.format(output))

		if plot_all_scenarios:
			ax1.plot(rcp3pd.Plus.year, (rcp3pd.Plus.co2_fossil - rcp3pd.Emissions.co2_fossil), color='green', label='RCP3PD')
			ax2.plot(rcp3pd.Plus.year, (C26p[:, 0] - C26[:, 0]), color='green')
			ax3.plot(rcp3pd.Plus.year, np.sum((F26p-F26), axis=1), color='green')
			ax4.plot(rcp3pd.Plus.year, (T26p-T26), color='green')

			ax1.plot(rcp6.Plus.year, (rcp6.Plus.co2_fossil - rcp6.Emissions.co2_fossil), color='red', label='RCP6')
			ax2.plot(rcp6.Plus.year, (C60p[:, 0] - C60[:, 0]), color='red')
			ax3.plot(rcp6.Plus.year, np.sum((F60p-F60), axis=1), color='red')
			ax4.plot(rcp6.Plus.year, (T60p-T60), color='red')

			ax1.legend()
			sns.despine()
			fig.savefig('{}/fair_response_to_impulse_all_scenarios.pdf'.format(output))

	# Move temperature projections into xarray
	fair_temperatures = xr.DataArray(
	    np.stack([
	        np.stack([T26, T45, T60, T85]),
	        np.stack([T26p, T45p, T60p, T85p])]),
	    dims=['pulse', 'rcp', 'year'],
	    coords=[['rcp', 'pulse'], ['rcp26', 'rcp45', 'rcp60', 'rcp85'], rcp85.Emissions.year])

	#Plot global mean temperatures by scenario
	if make_plots:
		fig, ax = plt.subplots(1, 1)
		colors = ['green', 'blue', 'red', 'black']
		styles = ['solid', 'dashed']

		lines = []
		labels = []
		for r, rcp in enumerate(fair_temperatures.rcp.values):
		    for p, pulse in enumerate(fair_temperatures.pulse):
		        labels.append('{}{}'.format(rcp, ['', '+'][p]))
		        lines.append(
		            ax.plot(
		                fair_temperatures.year,
		                fair_temperatures.sel(rcp=rcp, pulse=pulse),
		                color=colors[r],
		                linestyle=styles[p])[0])
		        
		plt.legend(lines, labels)
		ax.set_title('Global mean surface temperature by scenario')
		sns.despine()
		fig.savefig('{}/gmst_by_scenarios.pdf'.format(output))

	# Calculate temperature anomalies
	fair_temperatures_anomaly = (
	    fair_temperatures
	    - fair_temperatures.sel(year=slice(2001, 2011)).mean(dim='year'))

	print('Finished loading FAIR')

	return fair_temperatures_anomaly
