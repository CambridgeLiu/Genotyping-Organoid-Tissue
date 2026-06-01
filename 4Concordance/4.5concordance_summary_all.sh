#!/bin/bash

dir_output=/project/onibasu/Josh/glimpse2/4.4concordance_allvsall
org_ids=/project/onibasu/Josh/glimpse2/2.1sampleIDs_run
tis_ids=/project/onibasu/Josh/glimpse2/3.1sampleIDs_run

mapfile -t ORG_SAMPLES < <(awk '{print $1}' "$org_ids")
mapfile -t TIS_SAMPLES < <(awk '{print $1}' "$tis_ids")

echo "Organoid,Tissue,Concordance" > ${dir_output}/concordance_allvsall.csv

for org in "${ORG_SAMPLES[@]}"; do
    for tis in "${TIS_SAMPLES[@]}"; do
        gtcheck_file="${dir_output}/${org}_vs_${tis}_gtcheck.txt"
        if [ -f "$gtcheck_file" ] && [ -s "$gtcheck_file" ]; then
            line=$(grep "^DCv2" "$gtcheck_file" | head -1)
            nsites=$(echo "$line"     | awk '{print $6}')
            nmatching=$(echo "$line"  | awk '{print $7}')
            concordance=$(awk "BEGIN {printf \"%.6f\", $nmatching/$nsites}")
            echo "${org},${tis},${concordance}" >> ${dir_output}/concordance_allvsall.csv
        else
            echo "${org},${tis},NA" >> ${dir_output}/concordance_allvsall.csv
        fi
    done
done

echo "Done:"
cat ${dir_output}/concordance_allvsall.csv