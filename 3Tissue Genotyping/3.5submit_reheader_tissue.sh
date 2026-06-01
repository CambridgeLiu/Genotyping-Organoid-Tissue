#!/bin/bash

sampleIDs_taskfile=/project/onibasu/Josh/glimpse2/3.1sampleIDs_run
input_cell=/project/onibasu/Josh/glimpse2/3.4concat_tissue
output_cell=/project/onibasu/Josh/glimpse2/3.5reheader_tissue

mkdir -p "$output_cell"

tmp="/project/onibasu/Josh/glimpse2/3.5reheader_tissue/tmp.txt"
source activate glimpse2_env
for sampleID in $(awk '{print $1}' "$sampleIDs_taskfile" | sort -V | uniq)
do
    echo "$sampleID" > "$tmp"

    bcftools reheader \
        "$input_cell/${sampleID}.vcf.gz" \
        -s "$tmp" \
        -o "$output_cell/${sampleID}.vcf.gz"

    tabix -p vcf "$output_cell/${sampleID}.vcf.gz"
done

rm -f "$tmp"