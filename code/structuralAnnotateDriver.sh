#!/bin/bash

projectName=$1
projectDir=$2
scriptsDir=$3

# Unique patients

patientIDs=$(cut -f 4 $projectDir/patientsSamples.txt | uniq)
patientIDs=($patientIDs)

index=0
while [ $index -lt ${#patientIDs[@]} ]
do
  outputID=${patientIDs[$index]}
  qsub -v outputID=$outputID,projectDir="$projectDir" -P $projectName $scriptsDir/structuralAnnotate.pbs
  index=$((index+1))
done
