#!/bin/bash
sampleIDs=$(cut -f 1 /project/HeadNeck/DNAsequencing/samplesInputs.txt) 
sampleIDs=($sampleIDs)

# Aligner indices and genome indicies have to be in the same directory.
# ln -s /project/StatBio/sequence/hg38/GCA_000001405.15_GRCh38_no_alt_analysis_set.fna /project/StatBio/indexes/bwa/hg38/GCA_000001405.15_GRCh38_no_alt_analysis_set.fa
# samtools faidx /project/StatBio/indexes/bwa/hg38/GCA_000001405.15_GRCh38_no_alt_analysis_set.fa

# Germline 
for((sampleIndex = 0; sampleIndex < ${#sampleIDs[@]}; sampleIndex++))
do
{
  qsub -v INPUT=/project/HeadNeck/DNAsequencing/mapped/${sampleIDs[$sampleIndex]}.bam,SID=${sampleIDs[$sampleIndex]} structural.pbs
}
done
