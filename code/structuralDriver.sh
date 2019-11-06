#!/bin/bash

projectName=$1
projectDir=$2
scriptsDir=$3
temporaryDir=${projectDir/project/scratch/}

# Aligner indices and genome indicies have to be in the same directory.
# ln -s /project/StatBio/sequence/hg38/GCA_000001405.15_GRCh38_no_alt_analysis_set.fna /project/StatBio/indexes/bwa/hg38/GCA_000001405.15_GRCh38_no_alt_analysis_set.fna
# samtools faidx /project/StatBio/indexes/bwa/hg38/GCA_000001405.15_GRCh38_no_alt_analysis_set.fna

# Create a panel of normals first.

# sampleIDs=$(cut -f 1 $projectDir/samplesInputsNotCancer.txt) 
# sampleTypes=$(cut -f 2 $projectDir/samplesInputsNotCancer.txt)
# sampleIDs=($sampleIDs)
# sampleTypes=($sampleTypes)
# normalFiles=()
# SID=()
# for((sampleIndex = 0; sampleIndex < ${#sampleIDs[@]}; sampleIndex++))
# do # Each normal sample versus the human genome reference.
# {
#   sampleID=${sampleIDs[$sampleIndex]}	  
#   SID+=($sampleID)
#   normalFiles+=($projectDir/mapped/$sampleID.bam)
# }
# done
# normalFiles=${normalFiles[@]}
# SID=${SID[@]}
# qsub -v inputString="$normalFiles",labelString="$SID",projectDir="$projectDir",temporaryDir="$temporaryDir",normals=separate $scriptsDir/makePON.pbs

# patientIDs=$(cut -f 1 $projectDir/patientsSamplesTCGAyoungNotHMS.txt)
# patientIDs=($patientIDs)
# SVfiles=()
# for((sampleIndex = 0; sampleIndex < ${#patientIDs[@]}; sampleIndex++))
# do
# {
#   SVfiles+=(INPUT=$projectDir/structuralVariants/${patientIDs[$sampleIndex]}structural.vcf.gz)
# }
# done
# SVfiles=${SVfiles[@]}
# qsub -v inputString="$SVfiles",normals=matched,projectDir="$projectDir" $scriptsDir/makePON.pbs

normalIDs=()
tumourIDs=()
outputIDs=()

while IFS=$'\t' read -r -a patientIDandComparisonSamples
do
  normalIDs+=(${patientIDandComparisonSamples[2]})
  tumourIDs+=(${patientIDandComparisonSamples[3]})
  outputIDs+=(${patientIDandComparisonSamples[4]})
done < $projectDir/patientsSamples.txt
comparisons=${#outputIDs[@]}

# Sample sets for each patient

comparisonIndex=0
while [ $comparisonIndex -lt $comparisons ]
do
  inputString="$temporaryDir/mapped/${normalIDs[$comparisonIndex]}.bam "
  normalSample=${normalIDs[$comparisonIndex]}
  labelString="$normalSample "
  outputID=${outputIDs[$comparisonIndex]}
  while [[ $comparisonIndex -lt $comparisons && ${normalIDs[$comparisonIndex]} == $normalSample ]]
  do
    tumourSample=${tumourIDs[$comparisonIndex]}	  
    inputString=${inputString}"$temporaryDir/mapped/$tumourSample.bam "
    labelString=${labelString}"$tumourSample "
    comparisonIndex=$((comparisonIndex+1))
  done
  labelString=${labelString%?} # Remove the last space.
  inputString=${inputString%?} # Remove the last space.
  qsub -v inputString="$inputString",labelString="$labelString",genome=hg38,outputIDs=$outputID,projectDir="$projectDir" -P $projectName $scriptsDir/structural.pbs
done
