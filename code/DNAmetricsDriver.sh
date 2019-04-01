#!/bin/bash

while IFS=$'\t' read -r -a sampleNameAndFiles
do
  sampleName=${sampleNameAndFiles[0]}

  if [ ${#sampleNameAndFiles[@]} -gt 4 ]
  then
    originalReadsFile=/scratch/HeadNeck/${sampleName}_merged_R1.fastq.gz
  else
    originalReadsFile=${sampleNameAndFiles[2]}
  fi

  noDuplicatesFile=/project/HeadNeck/DNAsequencing/FASTQ/${sampleName}_noDuplicates_R1.fastq.gz
  alignmentsFile=/project/HeadNeck/DNAsequencing/mapped/${sampleName}.bam

  qsub -v originalReadsFile=$originalReadsFile,noDuplicatesFile=$noDuplicatesFile,alignmentsFile=$alignmentsFile,SID=$sampleName DNAmetrics.pbs
done < /project/HeadNeck/DNAsequencing/samplesInputs.txt

echo -e "Sample ID\tStarting Reads\tUseful Reads\tDuplication Rate\tAligned Reads\tMapped Rate\tMedian Insert Size\tEstimated Coverage" > /project/HeadNeck/DNAsequencing/DNAmetrics.txt
