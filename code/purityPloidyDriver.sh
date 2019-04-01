#!/bin/bash

PatientIDs=$(cut -f 1 /project/HeadNeck/DNAsequencing/patientsSamples.txt)
NormalIDs=$(cut -f 2 /project/HeadNeck/DNAsequencing/patientsSamples.txt)
TumourIDs=$(cut -f 3 /project/HeadNeck/DNAsequencing/patientsSamples.txt)

for((sampleIndex = 0; sampleIndex < ${#PatientIDs[@]}; sampleIndex++))
do # Each normal and tumour pair.
{
  normalFile=/project/HeadNeck/DNAsequencing/mapped/${NormalIDs[$sampleIndex]}.bam
  tumourFile=/project/HeadNeck/DNAsequencing/mapped/${TumourIDs[$sampleIndex]}.bam
  qsub -v normalFile=$normalFile,tumourFile=$tumourFile,SID=${PatientIDs[$sampleIndex]} purityPloidy.pbs
}
done

