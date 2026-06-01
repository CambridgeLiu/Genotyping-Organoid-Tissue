#!/bin/bash

dir_output=/project/onibasu/Josh/glimpse2/3.2ligate_tissue
dir_phase=/project/onibasu/Josh/glimpse2/3.1phase_tissue
dir_log=/project/onibasu/Josh/glimpse2/3.2ligate_tissue_log
sampleIDs_taskfile=/project/onibasu/Josh/glimpse2/3.1sampleIDs_run

mkdir -p "$dir_output"
mkdir -p "$dir_log"

for sampleID in $(awk '{print $1}' "$sampleIDs_taskfile" | sort | uniq)
do
    output_cell="$dir_output/${sampleID}"
    mkdir -p "$output_cell"

    phase_output_cell="$dir_phase/${sampleID}"

    for chrom in {1..22} X
    do
        sbatch \
          -J "${sampleID}_${chrom}" \
          --output="${dir_log}/${sampleID}_${chrom}.out" \
          --error="${dir_log}/${sampleID}_${chrom}.err" \
          --time=36:00:00 \
          --partition=onibasu \
          --account=pi-onibasu \
          -c 1 \
          --mem=20G \
          --wrap="source ~/.bashrc && \
conda activate glimpse2_env && \
export LD_LIBRARY_PATH=\"\$CONDA_PREFIX/lib:\$LD_LIBRARY_PATH\" && \
sampleID=\"$sampleID\" && \
chrom=\"$chrom\" && \
output_cell=\"$output_cell\" && \
phase_output_cell=\"$phase_output_cell\" && \
ls -1v \${phase_output_cell}/\${sampleID}_imputed_chr\${chrom}_*.bcf > \${output_cell}/list.chr\${chrom}.txt && \
GLIMPSE2_ligate --input \${output_cell}/list.chr\${chrom}.txt --output \${output_cell}/\${sampleID}_chr\${chrom}_ligated.bcf"
    done
done