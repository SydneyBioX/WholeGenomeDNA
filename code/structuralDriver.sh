#!/bin/bash

# Aligner indices and genome indicies have to be in the same directory.
# ln -s /project/StatBio/sequence/hg38/GCA_000001405.15_GRCh38_no_alt_analysis_set.fna /project/StatBio/indexes/bwa/hg38/GCA_000001405.15_GRCh38_no_alt_analysis_set.fa
# samtools faidx /project/StatBio/indexes/bwa/hg38/GCA_000001405.15_GRCh38_no_alt_analysis_set.fa

patientIDs=()
conditions=()
normalIDs=()
tumourIDs=()

while IFS=$'\t' read -r -a patientIDandComparisonSamples
do
  patientIDs+=(${patientIDandComparisonSamples[0]})
  conditions+=("${patientIDandComparisonSamples[1]}")
  normalIDs+=(${patientIDandComparisonSamples[2]})
  tumourIDs+=(${patientIDandComparisonSamples[3]})
done < /project/HeadNeck/DNAsequencing/patientsSamples.txt
comparisons=${#conditions[@]}

# Sample sets for each patient

comparisonIndex=0
while [ $comparisonIndex -lt $comparisons ]
do
  inputString=INPUT="/project/HeadNeck/DNAsequencing/mapped/${normalIDs[$comparisonIndex]}.bam "
  labelString=INPUT_LABEL="Normal "
  normalSample=${normalIDs[$comparisonIndex]}
  patientID=${patientIDs[$comparisonIndex]}
  while [[ $comparisonIndex -lt $comparisons && ${normalIDs[$comparisonIndex]} == $normalSample ]]
  do
    inputString=${inputString}INPUT="/project/HeadNeck/DNAsequencing/mapped/${tumourIDs[$comparisonIndex]}.bam "
    labelString=${labelString}INPUT_LABEL=\""${conditions[$comparisonIndex]}\" "
    comparisonIndex=$((comparisonIndex+1))
  done
  qsub -v inputString="$inputString",labelString="$labelString",patientID=$patientID structural.pbs
done
