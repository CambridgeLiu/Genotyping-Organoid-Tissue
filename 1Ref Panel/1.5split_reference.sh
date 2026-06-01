#!/bin/bash

cd /project/onibasu/Josh/glimpse2

mkdir -p ref_panel/split
mkdir -p 1.5split_log

for chr in {1..22} X
do
  sbatch \
    --job-name="1.5_${chr}" \
    --output="1.5split_log/1.5_${chr}.out" \
    --error="1.5split_log/1.5_${chr}.err" \
    --time=36:00:00 \
    --partition=onibasu \
    --account=pi-onibasu \
    -c 1 \
    --mem=10G \
    --wrap="source ~/.bashrc && \
conda activate glimpse2_env && \
export LD_LIBRARY_PATH=\"\$CONDA_PREFIX/lib:\$LD_LIBRARY_PATH\" && \
REF=ref_panel/1000GP.chr${chr}.bcf && \
MAP=github/maps/genetic_maps.b38/chr${chr}.b38.gmap.gz && \
while IFS= read -r LINE || [ -n \"\$LINE\" ]; do \
  ID=\$(echo \"\$LINE\" | awk '{printf \"%02d\", \$1}'); \
  IRG=\$(echo \"\$LINE\" | awk '{print \$3}'); \
  ORG=\$(echo \"\$LINE\" | awk '{print \$4}'); \
  GLIMPSE2_split_reference \
    --reference \"\$REF\" \
    --map \"\$MAP\" \
    --input-region \"\$IRG\" \
    --output-region \"\$ORG\" \
    --output \"ref_panel/split/1000GP.chr${chr}.\$ID\" \
    </dev/null; \
done < chunks/chunks.chr${chr}.txt"
done