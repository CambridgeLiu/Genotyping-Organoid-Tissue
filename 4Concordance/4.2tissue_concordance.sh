#!/bin/bash
dir_output=/project/onibasu/Josh/glimpse2/4.2concordance_tis_vs_tis
dir_log=/project/onibasu/Josh/glimpse2/4.2concordance_tis_vs_tis_log
dir_scripts=/project/onibasu/Josh/glimpse2/4.2concordance_tis_vs_tis_scripts
tis_vcf=/project/onibasu/Josh/glimpse2/3.6merge_tissue/allSamples.vcf.gz
tis_ids=/project/onibasu/Josh/glimpse2/3.1sampleIDs_run

mkdir -p "$dir_output"
mkdir -p "$dir_log"
mkdir -p "$dir_scripts"

mapfile -t TIS_SAMPLES < <(awk '{print $1}' "$tis_ids")

for i in "${!TIS_SAMPLES[@]}"; do
    for j in "${!TIS_SAMPLES[@]}"; do

        if [ "$i" -ge "$j" ]; then
            continue
        fi

        tis1="${TIS_SAMPLES[$i]}"
        tis2="${TIS_SAMPLES[$j]}"

        gtcheck_file="${dir_output}/${tis1}_vs_${tis2}_gtcheck.txt"

        if [ -f "$gtcheck_file" ] && [ -s "$gtcheck_file" ]; then
            echo "Skipping already done: $tis1 vs $tis2"
            continue
        fi

        echo "Submitting: $tis1 vs $tis2"

        script="${dir_scripts}/${tis1}_vs_${tis2}.sh"

        cat > "$script" << SCRIPT
#!/bin/bash
source ~/.bashrc
conda activate glimpse2_env

# Extract, rename and save as temp bgzipped files
bcftools view -s ${tis1} ${tis_vcf} -Oz | \
    bcftools reheader -s <(printf '${tis1}\t${tis1}_A\n') \
    -o ${dir_output}/${tis1}_vs_${tis2}_A.vcf.gz
bcftools index -t ${dir_output}/${tis1}_vs_${tis2}_A.vcf.gz

bcftools view -s ${tis2} ${tis_vcf} -Oz | \
    bcftools reheader -s <(printf '${tis2}\t${tis2}_B\n') \
    -o ${dir_output}/${tis1}_vs_${tis2}_B.vcf.gz
bcftools index -t ${dir_output}/${tis1}_vs_${tis2}_B.vcf.gz

# Merge
bcftools merge \
    ${dir_output}/${tis1}_vs_${tis2}_A.vcf.gz \
    ${dir_output}/${tis1}_vs_${tis2}_B.vcf.gz \
    -Oz -o ${dir_output}/${tis1}_vs_${tis2}_merged.vcf.gz
bcftools index -t ${dir_output}/${tis1}_vs_${tis2}_merged.vcf.gz

# Run gtcheck
bcftools gtcheck \
    ${dir_output}/${tis1}_vs_${tis2}_merged.vcf.gz \
    > ${dir_output}/${tis1}_vs_${tis2}_gtcheck.txt

# Clean up
rm -f ${dir_output}/${tis1}_vs_${tis2}_A.vcf.gz* \
      ${dir_output}/${tis1}_vs_${tis2}_B.vcf.gz* \
      ${dir_output}/${tis1}_vs_${tis2}_merged.vcf.gz*
SCRIPT

        chmod +x "$script"

        sbatch \
          -J "tis_${tis1}_${tis2}" \
          --output="${dir_log}/${tis1}_vs_${tis2}.out" \
          --error="${dir_log}/${tis1}_vs_${tis2}.err" \
          --time=12:00:00 \
          --partition=onibasu \
          --account=pi-onibasu \
          -c 1 \
          --mem=16G \
          "$script"

    done
done