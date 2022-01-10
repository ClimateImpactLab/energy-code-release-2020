#!/bin/bash
# This script run all data construction steps.
# You can also run individual scripts using commands in this script.

mkdir ${LOG}/1_analysis

echo "Running analysis:"
echo "STEP 1 - uninteracted regressions"
stata-se -b do 1_uninteracted_regression.do
echo "STEP 2 - decile regressions"
stata-se -b do 2_decile_regression.do
echo "STEP 3 - interacted regressions"
stata-se -b do 3_interacted_regression.do
