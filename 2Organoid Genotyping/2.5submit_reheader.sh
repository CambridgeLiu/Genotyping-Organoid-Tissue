#!/bin/bash

sampleIDs_taskfile=/project/onibasu/Josh/glimpse2/2.1sampleIDs_run
input_cell=/project/onibasu/Josh/glimpse2/2.4concat
output_cell=/project/onibasu/Josh/glimpse2/2.5reheader

mkdir -p "$output_cell"

tmp="/project/onibasu/Josh/glimpse2/2.5reheader/tmp.txt"

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