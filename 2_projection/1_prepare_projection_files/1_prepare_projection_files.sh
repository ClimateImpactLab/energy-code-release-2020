#!/bin/bash

mkdir ${LOG}/2_projection
mkdir ${LOG}/2_projection/1_prepare_projection_files

echo "STEP 1"
stata-se -b do 1_generate_csvv.do
echo "STEP 2"
stata-se -b do 2_generate_projection_configs.do
