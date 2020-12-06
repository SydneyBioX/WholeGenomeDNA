#!/bin/bash

projectName=$1
projectDir=$2
scriptsDir=$3

normalIDs=()
tumourIDs=()
outputIDs=()

while IFS=$'\t' read -r -a patientIDandComparisonSamples
do
  normalIDs+=(${patientIDandComparisonSamples[1]})
  tumourIDs+=(${patientIDandComparisonSamples[2]})
  outputIDs+=(${patientIDandComparisonSamples[3]})  
done < $projectDir/patientsSamples.txt
samples=${#outputIDs[@]}

# Create somatic VCF file for each cancer sample using GRIPSS.

sampleIndex=0
while [ $sampleIndex -lt $samples ]
do
  outputID=${outputIDs[$sampleIndex]}
  normalID=${normalIDs[$sampleIndex]}
  tumourID=${tumourIDs[$sampleIndex]}
  qsub -v outputID="$outputID",normalID="$normalID",tumourID="$tumourID",projectDir="$projectDir" -P $projectName $scriptsDir/structuralSomatic.pbs
  sampleIndex=$((sampleIndex + 1))
done
