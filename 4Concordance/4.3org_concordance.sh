#!/bin/bash
dir_output=/project/onibasu/Josh/glimpse2/4.3concordance_org_vs_org
dir_log=/project/onibasu/Josh/glimpse2/4.3concordance_org_vs_org_log
dir_scripts=/project/onibasu/Josh/glimpse2/4.3concordance_org_vs_org_scripts
org_vcf=/project/onibasu/Josh/glimpse2/2.6merge/allSamples.vcf.gz
org_ids=/project/onibasu/Josh/glimpse2/2.1sampleIDs_run

mkdir -p "$dir_output"
mkdir -p "$dir_log"
mkdir -p "$dir_scripts"

mapfile -t ORG_SAMPLES < <(awk '{print $1}' "$org_ids")

for i in "${!ORG_SAMPLES[@]}"; do
    for j in "${!ORG_SAMPLES[@]}"; do

        if [ "$i" -ge "$j" ]; then
            continue
        fi

        org1="${ORG_SAMPLES[$i]}"
        org2="${ORG_SAMPLES[$j]}"

        gtcheck_file="${dir_output}/${org1}_vs_${org2}_gtcheck.txt"

        if [ -f "$gtcheck_file" ] && [ -s "$gtcheck_file" ]; then
            echo "Skipping already done: $org1 vs $org2"
            continue
        fi

        echo "Submitting: $org1 vs $org2"

        script="${dir_scripts}/${org1}_vs_${org2}.sh"

        cat > "$script" << SCRIPT
#!/bin/bash
source ~/.bashrc
conda activate glimpse2_env

# Extract, rename, save as bgzipped temp files
bcftools view -s ${org1} ${org_vcf} -Oz | \
    bcftools reheader -s <(printf '${org1}\t${org1}_A\n') \
    -o ${dir_output}/${org1}_vs_${org2}_A.vcf.gz
bcftools index -t ${dir_output}/${org1}_vs_${org2}_A.vcf.gz

bcftools view -s ${org2} ${org_vcf} -Oz | \
    bcftools reheader -s <(printf '${org2}\t${org2}_B\n') \
    -o ${dir_output}/${org1}_vs_${org2}_B.vcf.gz
bcftools index -t ${dir_output}/${org1}_vs_${org2}_B.vcf.gz

# Merge
bcftools merge \
    ${dir_output}/${org1}_vs_${org2}_A.vcf.gz \
    ${dir_output}/${org1}_vs_${org2}_B.vcf.gz \
    -Oz -o ${dir_output}/${org1}_vs_${org2}_merged.vcf.gz
bcftools index -t ${dir_output}/${org1}_vs_${org2}_merged.vcf.gz

# Run gtcheck
bcftools gtcheck \
    ${dir_output}/${org1}_vs_${org2}_merged.vcf.gz \
    > ${dir_output}/${org1}_vs_${org2}_gtcheck.txt

# Clean up
rm -f ${dir_output}/${org1}_vs_${org2}_A.vcf.gz* \
      ${dir_output}/${org1}_vs_${org2}_B.vcf.gz* \
      ${dir_output}/${org1}_vs_${org2}_merged.vcf.gz*
SCRIPT

        chmod +x "$script"

        sbatch \
          -J "org_${org1}_${org2}" \
          --output="${dir_log}/${org1}_vs_${org2}.out" \
          --error="${dir_log}/${org1}_vs_${org2}.err" \
          --time=15:00:00 \
          --partition=onibasu \
          --account=pi-onibasu \
          -c 1 \
          --mem=16G \
          "$script"

    done
done