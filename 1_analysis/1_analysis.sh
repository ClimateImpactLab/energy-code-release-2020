#!/bin/bash

echo "STEP 1"
stata-mp do 1_uninteracted_regression.do
echo "STEP 2"
stata-mp do 2_decile_regression.do
echo "STEP 3"
stata-mp do 3_interacted_regression.do
