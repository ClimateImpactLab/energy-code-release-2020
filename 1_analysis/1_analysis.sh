#!/bin/bash

echo "STEP 1"
stata-mp -b do 1_uninteracted_regression.do
echo "STEP 2"
stata-mp -b do 2_decile_regression.do
echo "STEP 3"
stata-mp -b do 3_interacted_regression.do
