#!/bin/bash
projectName=$1
projectDir=$2
scriptsDir=$3
temporaryDir=${projectDir/project/scratch/}

# Germline
sampleIDs=$(cut -f 1 $projectDir/samplesInputs.txt) 
sampleTypes=$(cut -f 2 $projectDir/samplesInputs.txt)
sampleIDs=($sampleIDs)
sampleTypes=($sampleTypes)
for((sampleIndex = 0; sampleIndex < ${#sampleIDs[@]}; sampleIndex++))
do # Each normal sample versus the human genome reference.
{
  if [ ${sampleTypes[$sampleIndex]} == "Normal" ]
  then
    normalFile=$temporaryDir/mapped/${sampleIDs[$sampleIndex]}.bam
    qsub -v normalFile=$normalFile,SID=${sampleIDs[$sampleIndex]},projectDir="$projectDir" -P $projectName $scriptsDir/SNVgermline.pbs
  fi
}
done

NormalIDs=$(cut -f 3 $projectDir/patientsSamples.txt)
TumourIDs=$(cut -f 4 $projectDir/patientsSamples.txt)
outputIDs=$(cut -f 5 $projectDir/patientsSamples.txt)
NormalIDs=($NormalIDs)
TumourIDs=($TumourIDs)
outputIDs=($outputIDs)
# Somatic
for((sampleIndex = 0; sampleIndex < ${#outputIDs[@]}; sampleIndex++))
do # Each normal and tumour pair.
{
  normalFile=$temporaryDir/mapped/${NormalIDs[$sampleIndex]}.bam
  tumourFile=$temporaryDir/mapped/${TumourIDs[$sampleIndex]}.bam
  qsub -v normalFile=$normalFile,tumourFile=$tumourFile,outputID=${outputIDs[$sampleIndex]},projectDir="$projectDir" -P $projectName $scriptsDir/SNVsomatic.pbs
}
done
