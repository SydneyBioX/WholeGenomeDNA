#!/bin/bash

projectName=$1
projectDir=$2
scriptsDir=$3
temporaryDir=${projectDir/project/scratch/}

while IFS=$'\t' read -r -a sampleNameAndFiles
do
  sampleName=${sampleNameAndFiles[0]}
  R1=$temporaryDir/FASTQ/${sampleName}_noDuplicates_R1.fastq.gz
  R2=$temporaryDir/FASTQ/${sampleName}_noDuplicates_R2.fastq.gz
  qsub -v R1=$R1,R2=$R2,SID=$sampleName,projectDir="$projectDir" -P $projectName map.pbs
done < $projectDir/samplesInputs.txt
