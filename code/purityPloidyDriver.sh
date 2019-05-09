#!/bin/bash

PatientIDs=$(cut -f 1 /project/HeadNeck/DNAsequencing/patientsSamples.txt)
NormalIDs=$(cut -f 2 /project/HeadNeck/DNAsequencing/patientsSamples.txt)
TumourIDs=$(cut -f 3 /project/HeadNeck/DNAsequencing/patientsSamples.txt)
PatientIDs=($PatientIDs)
NormalIDs=($NormalIDs)
TumourIDs=($TumourIDs)

for((sampleIndex = 0; sampleIndex < ${#PatientIDs[@]}; sampleIndex++))
do # Each normal and tumour pair.
{
  cancerID=${TumourIDs[$sampleIndex]}	
  normalFile=/project/HeadNeck/DNAsequencing/mapped/${NormalIDs[$sampleIndex]}.bam
  tumourFile=/project/HeadNeck/DNAsequencing/mapped/${cancerID}.bam
  qsub -v normalFile=$normalFile,tumourFile=$tumourFile,SID=${PatientIDs[$sampleIndex]},CID=$cancerID purityPloidy.pbs
}
done

