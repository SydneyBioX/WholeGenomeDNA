#!/bin/bash

projectName=$1
projectDir=$2
scriptsDir=$3
temporaryDir=${projectDir/project/scratch/}
NormalIDs=$(cut -f 3 $projectDir/patientsSamples.txt)
TumourIDs=$(cut -f 4 $projectDir/patientsSamples.txt)
outputIDs=$(cut -f 5 $projectDir/patientsSamples.txt)
NormalIDs=($NormalIDs)
TumourIDs=($TumourIDs)
outputIDs=($outputIDs)

for((sampleIndex = 0; sampleIndex < ${#outputIDs[@]}; sampleIndex++))
do # Each normal and tumour pair.
{
  normalID=${NormalIDs[$sampleIndex]}
  tumourID=${TumourIDs[$sampleIndex]}
  outputID=${outputIDs[$sampleIndex]}
  normalFile=$temporaryDir/mapped/$normalID.bam
  tumourFile=$temporaryDir/mapped/$tumourID.bam
  qsub -v normalFile=$normalFile,tumourFile=$tumourFile,normalID=$normalID,tumourID=$tumourID,outputID=$outputID,projectDir="$projectDir" -P $projectName $scriptsDir/purityPloidy.pbs
}
done

