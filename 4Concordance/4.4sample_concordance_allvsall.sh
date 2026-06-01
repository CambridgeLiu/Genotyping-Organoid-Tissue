#!/bin/bash
dir_output=/project/onibasu/Josh/glimpse2/4.4concordance_allvsall
dir_log=/project/onibasu/Josh/glimpse2/4.4concordance_allvsall_log
org_vcf=/project/onibasu/Josh/glimpse2/2.6merge/allSamples.vcf.gz
tis_vcf=/project/onibasu/Josh/glimpse2/3.6merge_tissue/allSamples.vcf.gz
org_ids=/project/onibasu/Josh/glimpse2/2.1sampleIDs_run
tis_ids=/project/onibasu/Josh/glimpse2/3.1sampleIDs_run

mkdir -p "$dir_output"
mkdir -p "$dir_log"

# Read all sample IDs into arrays
mapfile -t ORG_SAMPLES < <(awk '{print $1}' "$org_ids")
mapfile -t TIS_SAMPLES < <(awk '{print $1}' "$tis_ids")

# Submit one job per organoid-tissue pair (14x14 = 196 jobs)
for org in "${ORG_SAMPLES[@]}"; do
    for tis in "${TIS_SAMPLES[@]}"; do

        gtcheck_file="${dir_output}/${org}_vs_${tis}_gtcheck.txt"

        # Skip if already done
        if [ -f "$gtcheck_file" ] && [ -s "$gtcheck_file" ]; then
            echo "Skipping already done: $org vs $tis"
            continue
        fi

        # Clean up any leftover files
        rm -f ${dir_output}/${org}_tmp.vcf.gz* \
              ${dir_output}/${org}_${tis}_renamed_org.vcf.gz* \
              ${dir_output}/${tis}_${org}_renamed_tis.vcf.gz* \
              ${dir_output}/${org}_vs_${tis}_merged.vcf.gz*

        sbatch \
          -J "${org}_${tis}" \
          --output="${dir_log}/${org}_vs_${tis}.out" \
          --error="${dir_log}/${org}_vs_${tis}.err" \
          --time=36:00:00 \
          --partition=onibasu \
          --account=pi-onibasu \
          -c 1 \
          --mem=16G \
          --wrap="
            source ~/.bashrc && \
            conda activate glimpse2_env && \

            # Write rename files with unique names per pair
            printf '${org}\t${org}_ORG\n' > ${dir_output}/${org}_${tis}_org_rename.txt && \
            printf '${tis}\t${tis}_TIS\n' > ${dir_output}/${org}_${tis}_tis_rename.txt && \

            # Extract and rename organoid sample
            bcftools view -s ${org} ${org_vcf} -Oz \
                -o ${dir_output}/${org}_${tis}_org_tmp.vcf.gz && \
            bcftools index -t ${dir_output}/${org}_${tis}_org_tmp.vcf.gz && \
            bcftools reheader \
                -s ${dir_output}/${org}_${tis}_org_rename.txt \
                ${dir_output}/${org}_${tis}_org_tmp.vcf.gz \
                -o ${dir_output}/${org}_${tis}_org_renamed.vcf.gz && \
            bcftools index -t ${dir_output}/${org}_${tis}_org_renamed.vcf.gz && \

            # Extract and rename tissue sample
            bcftools view -s ${tis} ${tis_vcf} -Oz \
                -o ${dir_output}/${org}_${tis}_tis_tmp.vcf.gz && \
            bcftools index -t ${dir_output}/${org}_${tis}_tis_tmp.vcf.gz && \
            bcftools reheader \
                -s ${dir_output}/${org}_${tis}_tis_rename.txt \
                ${dir_output}/${org}_${tis}_tis_tmp.vcf.gz \
                -o ${dir_output}/${org}_${tis}_tis_renamed.vcf.gz && \
            bcftools index -t ${dir_output}/${org}_${tis}_tis_renamed.vcf.gz && \

            # Merge
            bcftools merge \
                ${dir_output}/${org}_${tis}_org_renamed.vcf.gz \
                ${dir_output}/${org}_${tis}_tis_renamed.vcf.gz \
                -Oz -o ${dir_output}/${org}_vs_${tis}_merged.vcf.gz && \
            bcftools index -t ${dir_output}/${org}_vs_${tis}_merged.vcf.gz && \

            # Run gtcheck
            bcftools gtcheck \
                ${dir_output}/${org}_vs_${tis}_merged.vcf.gz \
                > ${dir_output}/${org}_vs_${tis}_gtcheck.txt && \

            # Clean up tmp files
            rm -f ${dir_output}/${org}_${tis}_org_tmp.vcf.gz* \
                  ${dir_output}/${org}_${tis}_org_renamed.vcf.gz* \
                  ${dir_output}/${org}_${tis}_org_rename.txt \
                  ${dir_output}/${org}_${tis}_tis_tmp.vcf.gz* \
                  ${dir_output}/${org}_${tis}_tis_renamed.vcf.gz* \
                  ${dir_output}/${org}_${tis}_tis_rename.txt \
                  ${dir_output}/${org}_vs_${tis}_merged.vcf.gz*
          "
    done
done