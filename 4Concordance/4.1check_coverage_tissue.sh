#!/bin/bash
# 4.1check_coverage.sh

dir_cellranger=/project/gca/.Joshliu/ATAC_matchtissue/
dir_output=/project/onibasu/Josh/glimpse2/4.1coverage_check_tissue
dir_log=/project/onibasu/Josh/glimpse2/4.1coverage_check_tissue_log
sampleIDs_taskfile=/project/onibasu/Josh/glimpse2/3.1sampleIDs_run

mkdir -p "$dir_output"
mkdir -p "$dir_log"

for sampleID in $(awk '{print $1}' "$sampleIDs_taskfile" | sort | uniq)
do
    if [ "$sampleID" == "HA41AC" ]; then
        bam_path="$dir_cellranger/$sampleID/outs/atac_possorted_bam.bam"
    else
        bam_path="$dir_cellranger/$sampleID/outs/possorted_bam.bam"
    fi

    if [ ! -f "$bam_path" ]; then
        echo "Skipping $sampleID: missing BAM at $bam_path"
        continue
    fi

    sbatch \
      -J "cov_${sampleID}" \
      --output="${dir_log}/${sampleID}_coverage.out" \
      --error="${dir_log}/${sampleID}_coverage.err" \
      --time=2:00:00 \
      --partition=onibasu \
      --account=pi-onibasu \
      -c 1 \
      --mem=8G \
      --wrap="
        source ~/.bashrc && \
        conda activate glimpse2_env && \
        echo '=== flagstat ===' > ${dir_output}/${sampleID}_coverage.txt && \
        samtools flagstat ${bam_path} >> ${dir_output}/${sampleID}_coverage.txt && \
        echo '=== idxstats ===' >> ${dir_output}/${sampleID}_coverage.txt && \
        samtools idxstats ${bam_path} >> ${dir_output}/${sampleID}_coverage.txt && \
        echo '=== mean depth per chrom ===' >> ${dir_output}/${sampleID}_coverage.txt && \
        samtools depth -a ${bam_path} | awk '{depth[\$1]+=\$3; count[\$1]++} END {for (chr in depth) printf \"%s\t%.4f\n\", chr, depth[chr]/count[chr]}' | sort -V >> ${dir_output}/${sampleID}_coverage.txt
      "
done