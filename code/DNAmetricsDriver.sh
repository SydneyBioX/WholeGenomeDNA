#!/bin/bash

projectName=$1
projectDir=$2
temporaryDir=${projectDir/project/scratch/}

while IFS=$'\t' read -r -a sampleNameAndFiles
do
  sampleName=${sampleNameAndFiles[0]}

  if [ ${#sampleNameAndFiles[@]} -gt 4 ]
  then
    originalReadsFile=$temporaryDir/merged/${sampleName}_merged_R1.fastq.gz
  else
    originalReadsFile=${sampleNameAndFiles[2]}
  fi

  noDuplicatesFile=$temporaryDir/FASTQ/${sampleName}_noDuplicates_R1.fastq.gz
  alignmentsFile=$temporaryDir/mapped/${sampleName}.bam

  qsub -v originalReadsFile=$originalReadsFile,noDuplicatesFile=$noDuplicatesFile,alignmentsFile=$alignmentsFile,SID=$sampleName,projectDir="$projectDir" -P $projectName DNAmetrics.pbs
done < $projectDir/samplesInputs.txt

echo -e "Sample ID\tStarting Reads\tUseful Reads\tDuplication Rate\tAligned Reads\tMapped Rate\tMedian Insert Size\tEstimated Coverage" > $projectDir/DNAmetrics.txt
