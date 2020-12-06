#!/bin/bash

projectName=$1
projectDir=$2
scriptsDir=$3

normalIDs=()
tumourIDs=()
outputIDs=()
vcfFiles=()

while IFS=$'\t' read -r -a patientIDandComparisonSamples
do
  normalIDs+=(${patientIDandComparisonSamples[1]})
  tumourIDs+=(${patientIDandComparisonSamples[2]}) 
  outputIDs+=(${patientIDandComparisonSamples[3]})
  vcfFiles+=(${patientIDandComparisonSamples[2]}_${patientIDandComparisonSamples[1]}.filtered.vcf.gz) # OSCC and TCGA
  #vcfFiles+=(${patientIDandComparisonSamples[2]}somaticPassed.vcf) # CSCC
done < $projectDir/patientsSamples.txt


for((sampleIndex = 0; sampleIndex < ${#outputIDs[@]}; sampleIndex++))
do # Each normal and tumour pair.
{
  normalID=${normalIDs[$sampleIndex]}
  tumourID=${tumourIDs[$sampleIndex]}
  outputID=${outputIDs[$sampleIndex]}
  vcfFile=${vcfFiles[$sampleIndex]}
  normalFile=$projectDir/Final_bams/$normalID.final.bam
  tumourFile=$projectDir/Final_bams/$tumourID.final.bam
  qsub -v normalFile=$normalFile,tumourFile=$tumourFile,vcfFile=$vcfFile,normalID=$normalID,tumourID=$tumourID,outputID=$outputID,projectDir="$projectDir" -P $projectName $scriptsDir/purityPloidy.pbs
}
done
