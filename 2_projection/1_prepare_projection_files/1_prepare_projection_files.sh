#!/bin/bash

echo "STEP 1"
stata-mp -b do 1_generate_csvv.do
echo "STEP 2"
stata-mp -b do 2_decile_regression.do
