#!/bin/bash

projectName=$1
readsDir=$2
scriptFolder=$3

while read -r sampleID
do
  inputFilePath=$readsDir/$sampleID
  qsub -v inputFilePath=$inputFilePath -P $projectName $scriptFolder/splitFASTQ.pbs
done < $readsDir/samplesSplit.txt
