#!/bin/bash

dir_cellranger=/project/gca/.Joshliu/ATAC_matchtissue/
dir_glimpse=/project/onibasu/Josh/glimpse2
dir_output=/project/onibasu/Josh/glimpse2/3.1phase_tissue
dir_log=/project/onibasu/Josh/glimpse2/3.1phase_tissue_log
sampleIDs_taskfile=/project/onibasu/Josh/glimpse2/3.1sampleIDs_run

mkdir -p "$dir_output"
mkdir -p "$dir_log"

for sampleID in $(awk '{print $1}' "$sampleIDs_taskfile" | sort | uniq)
do
    output_cell="$dir_output/${sampleID}"
    mkdir -p "$output_cell"

    if [ "$sampleID" == "HA41AC" ]; then
        bam_path="$dir_cellranger/$sampleID/outs/atac_possorted_bam.bam"
    else
        bam_path="$dir_cellranger/$sampleID/outs/possorted_bam.bam"
    fi
    if [ ! -f "$bam_path" ]; then
        echo "Skipping $sampleID: missing BAM at $bam_path"
    continue
    fi

    for chrom in {1..22} X
    do
        chunk_file="$dir_glimpse/chunks/chunks.chr${chrom}.txt"
        map_file="$dir_glimpse/github/maps/genetic_maps.b38/chr${chrom}.b38.gmap.gz"

        if [ ! -f "$chunk_file" ]; then
            echo "Skipping $sampleID chr${chrom}: missing chunk file $chunk_file"
            continue
        fi

        if [ ! -f "$map_file" ]; then
            echo "Skipping $sampleID chr${chrom}: missing map file $map_file"
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
          --mem=30G \
          --wrap="cd \"$dir_glimpse\" && \
source ~/.bashrc && \
conda activate glimpse2_env && \
export LD_LIBRARY_PATH=\"\$CONDA_PREFIX/lib:\$LD_LIBRARY_PATH\" && \
REF=\"$dir_glimpse/ref_panel/split/1000GP.chr${chrom}\" && \
BAM=\"$bam_path\" && \
OUT=\"$output_cell/${sampleID}_imputed\" && \
while IFS= read -r LINE || [ -n \"\$LINE\" ]; do \
    ID=\$(echo \"\$LINE\" | awk '{printf \"%02d\", \$1}'); \
    CHR=\$(echo \"\$LINE\" | awk '{print \$2}'); \
    IRG=\$(echo \"\$LINE\" | awk '{print \$3}'); \
    ORG=\$(echo \"\$LINE\" | awk '{print \$4}'); \
    REGS=\$(echo \"\$IRG\" | awk -F'[:-]' '{print \$2}'); \
    REGE=\$(echo \"\$IRG\" | awk -F'[:-]' '{print \$3}'); \
    GLIMPSE2_phase \
      --bam-file \"\$BAM\" \
      --reference \"\${REF}.\${ID}_\${CHR}_\${REGS}_\${REGE}.bin\" \
      --output \"\${OUT}_\${CHR}_\${REGS}_\${REGE}.bcf\" \
      </dev/null; \
done < \"$dir_glimpse/chunks/chunks.chr${chrom}.txt\""
    done
done