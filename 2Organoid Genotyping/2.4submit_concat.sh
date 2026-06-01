#!/bin/bash

dir_concat=/project/onibasu/Josh/glimpse2/2.4concat
dir_eagle=/project/onibasu/Josh/glimpse2/2.3eagle
dir_log=/project/onibasu/Josh/glimpse2/2.4concat_log
sampleIDs_taskfile=/project/onibasu/Josh/glimpse2/2.1sampleIDs_run

mkdir -p "$dir_concat"
mkdir -p "$dir_log"

for sampleID in $(awk '{print $1}' "$sampleIDs_taskfile" | sort | uniq)
do
    eagle_output_cell="$dir_eagle/${sampleID}"
    output_cell="$dir_concat"

    if [ ! -d "$eagle_output_cell" ]; then
        echo "Skipping $sampleID: missing Eagle output directory $eagle_output_cell"
        continue
    fi

    sbatch \
      -J "${sampleID}" \
      --output="${dir_log}/${sampleID}.out" \
      --error="${dir_log}/${sampleID}.err" \
      --time=36:00:00 \
      --partition=onibasu \
      --account=pi-onibasu \
      -c 1 \
      --mem=40G \
      --wrap="source ~/.bashrc && \
conda activate glimpse2_env && \
export LD_LIBRARY_PATH=\"\$CONDA_PREFIX/lib:\$LD_LIBRARY_PATH\" && \
sampleID=\"$sampleID\" && \
output_cell=\"$output_cell\" && \
eagle_output_cell=\"$eagle_output_cell\" && \
xx=\$(ls -1v \"\$eagle_output_cell/\${sampleID}_\"*.vcf.gz 2>/dev/null) && \
if [ -z \"\$xx\" ]; then \
  echo \"No Eagle VCFs found for \${sampleID}\"; \
  exit 1; \
fi && \
bcftools concat -Oz -o \"\$output_cell/\${sampleID}.vcf.gz\" \$xx && \
tabix -p vcf \"\$output_cell/\${sampleID}.vcf.gz\""
done