#!/bin/bash

dir_glimpse=/project/onibasu/Josh/glimpse2
dir_output=/project/onibasu/Josh/glimpse2/3.3eagle_tissue
dir_ligate=/project/onibasu/Josh/glimpse2/3.2ligate_tissue
dir_log=/project/onibasu/Josh/glimpse2/3.3eagle_tissue_log
sampleIDs_taskfile=/project/onibasu/Josh/glimpse2/3.1sampleIDs_run

gmap=/home/ljq/software/eagle/Eagle_v2.4.1/tables/genetic_map_hg38_withX.txt.gz
eagle_bin=/home/ljq/software/eagle/Eagle_v2.4.1/eagle

mkdir -p "$dir_output"
mkdir -p "$dir_log"

for sampleID in $(awk '{print $1}' "$sampleIDs_taskfile" | sort | uniq)
do
    ligate_output_cell="$dir_ligate/${sampleID}"
    output_cell="$dir_output/${sampleID}"
    mkdir -p "$output_cell"

    for chrom in {1..22} X
    do
        inputFile="$ligate_output_cell/${sampleID}_chr${chrom}_ligated.bcf"
        ref="$dir_glimpse/ref_panel/1000GP.chr${chrom}.bcf"

        if [ ! -f "$inputFile" ]; then
            echo "Skipping $sampleID chr${chrom}: missing ligated input $inputFile"
            continue
        fi

        if [ ! -f "$ref" ]; then
            echo "Skipping $sampleID chr${chrom}: missing reference $ref"
            continue
        fi

        if [ ! -f "$gmap" ]; then
            echo "Skipping $sampleID chr${chrom}: missing Eagle genetic map $gmap"
            continue
        fi

        if [ ! -x "$eagle_bin" ]; then
            echo "Skipping $sampleID chr${chrom}: missing Eagle executable $eagle_bin"
            continue
        fi

        sbatch \
          -J "${sampleID}_${chrom}" \
          --output="${dir_log}/${sampleID}_${chrom}.out" \
          --error="${dir_log}/${sampleID}_${chrom}.err" \
          --time=36:00:00 \
          --partition=onibasu \
          --account=pi-onibasu \
          -c 1 \
          --mem=40G \
          --wrap="source ~/.bashrc && \
conda activate glimpse2_env && \
export LD_LIBRARY_PATH=\"\$CONDA_PREFIX/lib:\$LD_LIBRARY_PATH\" && \
sampleID=\"$sampleID\" && \
chrom=\"$chrom\" && \
output_cell=\"$output_cell\" && \
ligate_output_cell=\"$ligate_output_cell\" && \
gmap=\"$gmap\" && \
eagle_bin=\"$eagle_bin\" && \
ref=\"$dir_glimpse/ref_panel/1000GP.chr${chrom}.bcf\" && \
outputFile=\"\$output_cell/\${sampleID}_chr\${chrom}.vcf.gz\" && \
inputFile=\"\$ligate_output_cell/\${sampleID}_chr\${chrom}_ligated.bcf\" && \
bcftools index -f \"\$inputFile\" && \
\"\$eagle_bin\" \
  --geneticMapFile \"\$gmap\" \
  --vcfRef \"\$ref\" \
  --vcfTarget \"\$inputFile\" \
  --outPrefix \"\$output_cell/\${sampleID}_chr\${chrom}\" \
  --vcfOutFormat z && \
bcftools index -f \"\$outputFile\""
    done
done