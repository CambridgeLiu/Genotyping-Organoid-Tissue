#!/bin/bash

dir_output=/project/onibasu/Josh/glimpse2/3.6merge_tissue
sampleIDs_taskfile=/project/onibasu/Josh/glimpse2/3.1sampleIDs_run
prefix="/project/onibasu/Josh/glimpse2/3.5reheader_tissue/"
suffix=".vcf.gz"
vcf_list="$dir_output/tmp.txt"
samples_list="$dir_output/samples.txt"

mkdir -p "$dir_output"

rm -f "$vcf_list"
rm -f "$samples_list"

for sampleID in $(awk '{print $1}' "$sampleIDs_taskfile" | sort -V | uniq)
do
  tmp="${prefix}${sampleID}${suffix}"
  if [ ! -f "$tmp" ]; then
    echo "Missing VCF for $sampleID: $tmp"
    continue
  fi
  echo "$tmp" >> "$vcf_list"
  echo "$sampleID" >> "$samples_list"
done

if [ ! -s "$vcf_list" ]; then
  echo "No input VCFs found. Exiting."
  exit 1
fi

cmd="source ~/.bashrc && \
conda activate glimpse2_env && \
export LD_LIBRARY_PATH=\"\$CONDA_PREFIX/lib:\$LD_LIBRARY_PATH\" && \
bcftools merge -m none -Oz -o $dir_output/allSamples.vcf.gz -l $vcf_list && \
bcftools index -f $dir_output/allSamples.vcf.gz"

sbatch \
  --time=36:00:00 \
  --mem=50G \
  --output=$dir_output/merge.out \
  --error=$dir_output/merge.err \
  --account=pi-onibasu \
  -p onibasu \
  -c 1 \
  --wrap="$cmd"