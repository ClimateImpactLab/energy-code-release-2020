# The Social Cost of Global Energy Consumption Due to Climate Change -- Dataset Construction and Analysis Code

The code in this repository allows users to generate the dataset and figures in the main text of ***Social Cost of Global Energy Consumption Due to Climate Change*** Paper figures may differ aesthetically due to post-processing.

## Description of folders

## Instructions for Constructing the Analysis Dataset

1. Run [0_construct_dataset_from_raw_inputs.do]() to construct a country x year x fuel panel dataset with climate, energy load, population and income data.
2. Run [1_construct_regression_ready_data.do]() to construct a dataset ready for regressions. This script completes the following tasks:
	1. Construct fixed effect regimes based off coded issues (fill out based on paper)
	2. Pair climate data