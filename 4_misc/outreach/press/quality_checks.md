Quality checks:

# Check number of directories and files (passed)
- 5 spatial resolutions directories
- 2 rcps directories
- 1 ssp directories
- 2 time resolutions * (2 fuels * 2 units * 6 stats + 1 fuel * 1 unit * 6 stats) = 60 files per directory
## action
Removed a few extra files with wrong names generated during testing

# Check that files have the correct dimension
## year: verify that files with the following filenames have the corresponding columns (passed)
1. "*years_all*" : year_2020 ~ year_2099
1. "*years_averaged*" : years_2020_2039, years_2040_2059, years_2080_2099

## regions: verify that files have correct number of regions (passed)

## check for zeros, NAs, Infs in all files 
1. Found a few non-concerning NAs (small islands with no population), same missingness with mortality press data
1. Florida (USA.10) 2020, missing q50 value in the extracted data
## action
Need to investigate why florida 2020 is missing

## check percentage gdp is always <1
1. I then realized that this is not necessarily true, but did find a few weird q50 files with abnormally large values. this is found to be cause by a bug in the load median package, and fixed now.

# Check that the actual values are extracted and calculated correctly
## Check kwh and gj conversion (passed)
## Compare values with raw projection output (to be done)


# Extraction code and checking code review - Emile (time needed: less than a day)


