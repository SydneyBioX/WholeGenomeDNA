#!/bin/bash

projectDir=$1

sampleIDs=()
outputDir=$projectDir/telomeres/

if [[ ! -d $outputDir ]]
then
    mkdir -p $outputDir
fi

while IFS=$'\t' read -r -a patientIDandComparisonSamples
do
  sampleIDs+=(${patientIDandComparisonSamples[1]}) 
  sampleIDs+=(${patientIDandComparisonSamples[2]})
done < $projectDir/patientsSamples.txt

for((sampleIndex = 0; sampleIndex < ${#sampleIDs[@]}; sampleIndex++))
do
{
  java -Xmx4g -jar /home/562/ds6924/software/qmotif-1.2.jar -n 1 --bam $projectDir/Final_bams/${sampleIDs[$sampleIndex]}.final.bam -bai $projectDir/Final_bams/${sampleIDs[$sampleIndex]}.final.bam.bai --log telo.log -ini ~/databases/qMotifHg38.config -o $projectDir/telomeres/${sampleIDs[$sampleIndex]}.xml -o /tmp/telo.bam
}
done
