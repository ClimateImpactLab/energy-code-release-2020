# The Social Cost of Global Energy Consumption Due to Climate Change -- Dataset Construction and Analysis Code

The code in this repository allows users to generate the dataset and figures related to pre-projection analysis in the main text of ***Social Cost of Global Energy Consumption Due to Climate Change*** Paper figures may differ aesthetically due to post-processing.

## Description of folders

## Instructions for Constructing the Analysis Dataset

1. Run [0_construct_dataset_from_raw_inputs.do]() to construct a country x year x fuel panel dataset with climate, energy load, population and income data. SEE pg. 14
2. Run [1_construct_regression_ready_data.do]() to construct a dataset ready for regressions. This script completes the following tasks:
	1. Construct fixed effect regimes and drop data based off coded issues (fill out based on paper) SEE pg. 36 of paper
	2. Pair climate data
	3. Income group construction SEE pg. 10 for deciles, pg. 40 for large income groups
	4. Final cleaning steps SEE pg. 16 for UN region FEs
	5. Construct FD variables SEE pg. 36

## Instructions for Running Regressions
1. Run
    1. FGLS 
    2. Global regression SEE pg. 16, 38
	3. Income decile regression SEE pg. 16
	4. Income/Climate interacted regression SEE pg. 17, 41
	5. Robustness- Excl. imputed data SEE pg. 60
	6. Robustness- Last decade SEE pg. 61
	7. Tech trends SEE pg. 63-64

## Instructions for producing analysis related figures
1. Run
    1. Global regression SEE Figure A.5 on pg. 39
	2. Income decile regression SEE Figure 1A on pg. 10
	3. Income/Climate interacted regression SEE Figure 1B on pg. 10; description on pg. 5, 42
	4. Robustness- Excl. imputed data SEE Figure A.13 on pg. 61
	5. Robustness- Last decade SEE Figure A.14 on pg. 64
	6. Tech trends SEE Figure A.15 on pg. 65