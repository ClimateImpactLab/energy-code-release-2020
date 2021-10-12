#!/bin/bash

mkdir ${LOG}/1_analysis

echo "STEP 1"
stata-se -b do 1_uninteracted_regression.do
echo "STEP 2"
stata-se -b do 2_decile_regression.do
echo "STEP 3"
stata-se -b do 3_interacted_regression.do
