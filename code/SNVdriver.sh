#!/bin/bash

# Germline
sampleIDs=$(cut -f 1 /project/HeadNeck/DNAsequencing/samplesInputs.txt) 
sampleTypes=$(cut -f 2 /project/HeadNeck/DNAsequencing/samplesInputs.txt)
sampleIDs=($sampleIDs)
sampleTypes=($sampleTypes)
for((sampleIndex = 0; sampleIndex < ${#sampleIDs[@]}; sampleIndex++))
do # Each normal sample versus the human genome reference.
{
  if [ ${sampleTypes[$sampleIndex]} == "Normal" ]
  then
    normalFile=/project/HeadNeck/DNAsequencing/mapped/${sampleIDs[$sampleIndex]}.bam
    qsub -v normalFile=$normalFile,SID=${sampleIDs[$sampleIndex]} SNVgermline.pbs
  fi
}
done

PatientIDs=$(cut -f 1 /project/HeadNeck/DNAsequencing/patientsSamples.txt)
NormalIDs=$(cut -f 2 /project/HeadNeck/DNAsequencing/patientsSamples.txt)
TumourIDs=$(cut -f 3 /project/HeadNeck/DNAsequencing/patientsSamples.txt)
PatientIDs=($PatientIDs)
NormalIDs=($NormalIDs)
TumourIDs=($TumourIDs)
# Somatic
for((sampleIndex = 0; sampleIndex < ${#PatientIDs[@]}; sampleIndex++))
do # Each normal and tumour pair.
{
  normalFile=/project/HeadNeck/DNAsequencing/mapped/${NormalIDs[$sampleIndex]}.bam
  tumourFile=/project/HeadNeck/DNAsequencing/mapped/${TumourIDs[$sampleIndex]}.bam
  qsub -v normalFile=$normalFile,tumourFile=$tumourFile,SID=${PatientIDs[$sampleIndex]} SNVsomatic.pbs
}
done
