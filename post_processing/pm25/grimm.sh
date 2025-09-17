#!/bin/bash

cat ${1}.txt | tr -d '\r' | sed 's|  *|,|g' > temp-input.grimm
python3 grimm_aggregate.py
cat temp-aggregated.csv | sed 's|-1||g' > temp-aggregated-clean.csv
python3 grimm_mass.py > ${1}.csv
