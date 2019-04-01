#!/bin/bash

while IFS=$'\t' read -r -a sampleNameAndFiles
do
  sampleName=${sampleNameAndFiles[0]}
  R1=/project/HeadNeck/DNAsequencing/FASTQ/${sampleName}_noDuplicates_R1.fastq.gz
  R2=/project/HeadNeck/DNAsequencing/FASTQ/${sampleName}_noDuplicates_R2.fastq.gz
  qsub -v R1=$R1,R2=$R2,SID=$sampleName map.pbs
done < /project/HeadNeck/DNAsequencing/samplesInputs.txt