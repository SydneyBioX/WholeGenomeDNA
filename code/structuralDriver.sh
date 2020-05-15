#!/bin/bash

projectName=$1
projectDir=$2
scriptsDir=$3

# Aligner indices and genome indicies have to be in the same directory.
# ln -s /project/StatBio/sequence/hg38/GCA_000001405.15_GRCh38_no_alt_analysis_set.fna /project/StatBio/indexes/bwa/hg38/GCA_000001405.15_GRCh38_no_alt_analysis_set.fna
# samtools faidx /project/StatBio/indexes/bwa/hg38/GCA_000001405.15_GRCh38_no_alt_analysis_set.fna
# Since version 2.9, an image file is needed for in-process alignment.
# java -cp /home/562/ds6924/software/gridss.jar gridss.PrepareReference /scratch/hm82/Reference/hs38DH.fasta

# Create a panel of normals first. See PONdriver.sh.

normalIDs=()
tumourIDs=()
outputIDs=()

while IFS=$'\t' read -r -a patientIDandComparisonSamples
do
  normalIDs+=(${patientIDandComparisonSamples[1]})
  tumourIDs+=(${patientIDandComparisonSamples[2]})
  outputIDs+=(${patientIDandComparisonSamples[3]})  
done < $projectDir/patientsSamples.txt
comparisons=${#outputIDs[@]}

# Sample sets for each patient

comparisonIndex=0
while [ $comparisonIndex -lt $comparisons ]
do
  inputString="$projectDir/Final_bams/${normalIDs[$comparisonIndex]}.final.bam "
  normalSample=${normalIDs[$comparisonIndex]}
  labelString="$normalSample "
  outputID=${outputIDs[$comparisonIndex]}
  while [[ $comparisonIndex -lt $comparisons && ${normalIDs[$comparisonIndex]} == $normalSample ]]
  do
    tumourSample=${tumourIDs[$comparisonIndex]}	  
    inputString=${inputString}"$projectDir/Final_bams/$tumourSample.final.bam "
    labelString=${labelString}"$tumourSample "
    comparisonIndex=$((comparisonIndex+1))
  done
  labelString=${labelString%?} # Remove the last space.
  inputString=${inputString%?} # Remove the last space.
  preprocessID=$(qsub -v inputString="$inputString",labelString="$labelString",outputID=$outputID,projectDir="$projectDir" -P $projectName $scriptsDir/structuralPreprocess.pbs)
  assembleID=$(qsub -W depend=afterok:$preprocessID -v inputString="$inputString",labelString="$labelString",outputID=$outputID,projectDir="$projectDir" -P $projectName $scriptsDir/structuralAssemble.pbs)
  qsub -W depend=afterok:$assembleID -v inputString="$inputString",labelString="$labelString",outputID=$outputID,projectDir="$projectDir" -P $projectName $scriptsDir/structuralCall.pbs
  echo qsub -W depend=afterok:$jobID -v outputID=$outputID,projectDir="$projectDir" -P $projectName $scriptsDir/structuralAnnotate.pbs
done
