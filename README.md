# Genotyping using scATAC-seq data from patien-matched epithelial organoids and tissues


## Overview

This workflow performs genotype imputation from single-cell ATAC-seq data using GLIMPSE2. 
It is designed to compare genetic concordance between patient-matched tissue and organoid samples.

The pipeline includes:
- Reference panel preparation
- Genotype likelihood generation from scATAC-seq BAM files
- Phasing and imputation using GLIMPSE2
- Post-processing and merging of VCFs
- Sample concordance analysis

## Caveats

-Coverage of scATAC-seq data and Markovian approximation. Genotype imputation from scATAC-seq data is inherently limited by sparse and uneven genomic coverage, as accessible chromatin regions represent only a small fraction of the genome (~2-3% of total DNA that captures >90% TF-bound regions). This results in incomplete and biased genotype likelihoods compared to bulk whole-genome sequencing. Additionally, GLIMPSE2 relies on a Markovian approximation of haplotype structure (Li–Stephens model), which assumes that local haplotypes can be represented as mosaic combination of reference haplotypes. While efficient, this approximation may be less accurate in regions with limited observed data (as in scATAC-seq) or in populations that are underrepresented in the reference panel.

-Genome chunking and buffer region selection. GLIMPSE2 performs haplotype phasing and genotype imputation on discrete genomic chunks rather than chromosomes as a whole. At chunk boundaries, variants on one side have no flanking data on the other side within the same chunk. The buffer region compensates for this by extending the haplotype context available to the model, effectively allowing the exponential decay to accumulate sufficient information before reaching the true boundary of the input region. The choice of buffer size therefore involves a trade-off: if too small, there will be insufficient haplotype context at chunk boundaries, particularly for rare variants where long-range linkage disequilibrium is critical; if too large, increased computational cost per chunk with diminishing returns in accuracy, since the exponential decay ensures that variants beyond some distance contribute negligible additional information regardless. In this workflow, buffer regions were set to the GLIMPSE2 default, which has been shown to provide stable imputation accuracy across common and low-frequency variants for reference panels of the size used here. However, we do encourge other researchers to to evaluate the sensitivity of their results to buffer size.

-Cellular compartment heterogeneity of organoid and tissue. Human intestinal tissue contains a complex mixture of cell types spanning multiple compartments, including epithelial, stromal, immune, and rarely neural populations, whereas intestinal organoids are predominantly composed of epithelial lineages derived from intestinal stem cells. In scATAC-seq data, chromatin accessibility reflects the regulatory landscape of each individual cell type. As a consequence, the fragments from organoid data may not fully represent the accessible regions present in non-epithelial cell populations in tissue, and vice versa. This compartment mismatch can affect the depth and distribution of sequencing reads available for genotyping, particularly in regulatory regions that are selectively open in stromal or immune cells.

## References
-Klemm, S.L., Shipony, Z. & Greenleaf, W.J. Chromatin accessibility and the regulatory epigenome. Nat Rev Genet 20, 207–220 (2019). https://doi.org/10.1038/s41576-018-0089-8

-Rubinacci, S., Hofmeister, R.J., Sousa da Mota, B. et al. Imputation of low-coverage sequencing data from 150,119 UK Biobank genomes. Nat Genet 55, 1088–1090 (2023). https://doi.org/10.1038/s41588-023-01438-3

-Li N, Stephens M. Modeling linkage disequilibrium and identifying recombination hotspots using single-nucleotide polymorphism data. Genetics. 2003 Dec;165(4):2213-33. doi: 10.1093/genetics/165.4.2213.