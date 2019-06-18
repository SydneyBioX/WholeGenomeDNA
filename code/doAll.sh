#!/bin/bash

# 1: Duplicate Removal and Merging

while IFS=$'\t' read -r -a sampleNameAndFiles
do
  R1reads=()
  R2reads=()
  sampleName=${sampleNameAndFiles[0]}

  # Multiple pairs of files for a sampleNameAndFiles sample. Columns are LaneX_R1, LaneX_R2, LaneY_R1, LaneY_R2, ...
  for((infoIndex = 2; infoIndex < ${#sampleNameAndFiles[@]}; infoIndex+=2)) # First two columns are sample ID and sample type.
  do     
    R1reads+=(${sampleNameAndFiles[$infoIndex]})
    R2reads+=(${sampleNameAndFiles[((infoIndex+1))]})
  done

  R1reads=${R1reads[@]} # Convert from array to space-delimited string.
  R2reads=${R2reads[@]}
  jobID=$(qsub -v R1="$R1reads",R2="$R2reads",SID=$sampleName removeDuplicates.pbs)
  allDuplicateJobs+=($jobID)
done < /project/HeadNeck/DNAsequencing/samplesInputs.txt

# 2: Read Alignment

index=0
while IFS=$'\t' read -r -a sampleNameAndFiles
do
  sampleName=${sampleNameAndFiles[0]}
  R1=/scratch/HeadNeck/DNAsequencing/FASTQ/${sampleName}_noDuplicates_R1.fastq.gz
  R2=/scratch/HeadNeck/DNAsequencing/FASTQ/${sampleName}_noDuplicates_R2.fastq.gz
  jobID=$(qsub -W depend=afterok:${allDuplicateJobs[$index]} -v R1=$R1,R2=$R2,SID=$sampleName map.pbs)
  allMapJobs+=($jobID)
  index=$((index+1))
done < /project/HeadNeck/DNAsequencing/samplesInputs.txt

# 3: DNA Metics Calculation

index=0
while IFS=$'\t' read -r -a sampleNameAndFiles
do
  sampleName=${sampleNameAndFiles[0]}

  if [ ${#sampleNameAndFiles[@]} -gt 4 ]
  then
    originalReadsFile=/scratch/HeadNeck/${sampleName}_merged_R1.fastq.gz
  else
    originalReadsFile=${sampleNameAndFiles[2]}
  fi

  noDuplicatesFile=/scratch/HeadNeck/DNAsequencing/FASTQ/${sampleName}_noDuplicates_R1.fastq.gz
  alignmentsFile=/scratch/HeadNeck/DNAsequencing/mapped/${sampleName}.bam

  qsub -W depend=afterok:${allMapJobs[$index]]} -v originalReadsFile=$originalReadsFile,noDuplicatesFile=$noDuplicatesFile,alignmentsFile=$alignmentsFile,SID=$sampleName DNAmetrics.pbs
done < /project/HeadNeck/DNAsequencing/samplesInputs.txt

echo -e "Sample ID\tStarting Reads\tUseful Reads\tDuplication Rate\tAligned Reads\tMapped Rate\tMedian Insert Size\tEstimated Coverage" > /project/HeadNeck/DNAsequencing/DNAmetrics.txt

# 4: Short Variant Calling

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
    normalFile=/scratch/HeadNeck/DNAsequencing/mapped/${sampleIDs[$sampleIndex]}.bam
    qsub -W depend=afterok:${allMapJobs[$sampleIndex]} -v normalFile=$normalFile,SID=${sampleIDs[$sampleIndex]} SNVgermline.pbs
  fi
}
done

# Somatic
NormalIDs=$(cut -f 3 /project/HeadNeck/DNAsequencing/patientsSamples.txt)
TumourIDs=$(cut -f 4 /project/HeadNeck/DNAsequencing/patientsSamples.txt)
outputIDs=$(cut -f 5 /project/HeadNeck/DNAsequencing/patientsSamples.txt)
NormalIDs=($NormalIDs)
TumourIDs=($TumourIDs)
outputIDs=($outputIDs)
function join { local IFS="$1"; shift; echo "$*"; }
allMapJobsString=$(join : ${allMapJobs[@]})
for((sampleIndex = 0; sampleIndex < ${#outputIDs[@]}; sampleIndex++))
do # Each normal and tumour pair.
{
  normalFile=/scratch/HeadNeck/DNAsequencing/mapped/${NormalIDs[$sampleIndex]}.bam
  tumourFile=/scratch/HeadNeck/DNAsequencing/mapped/${TumourIDs[$sampleIndex]}.bam
  outputID=${outputIDs[$sampleIndex]}
  qsub -W depend=afterok:$allMapJobsString -v normalFile=$normalFile,tumourFile=$tumourFile,outputID=$outputID SNVsomatic.pbs
}
done

# 5: Structural Variant Calling

patientIDs=$(cut -f 1 /project/HeadNeck/DNAsequencing/patientsSamples.txt)
patientIDs=($patientIDs)
comparisons=${#outputIDs[@]}

# Sample sets for each patient

comparisonIndex=0
while [ $comparisonIndex -lt $comparisons ]
do
  inputString="INPUT=/scratch/HeadNeck/DNAsequencing/mapped/${NormalIDs[$comparisonIndex]}.bam "
  normalSample=${NormalIDs[$comparisonIndex]}
  labelString="INPUT_LABEL=$normalSample "
  patientID=${patientIDs[$comparisonIndex]}
  while [[ $comparisonIndex -lt $comparisons && ${NormalIDs[$comparisonIndex]} == $normalSample ]]
  do
    inputString=${inputString}"INPUT=/scratch/HeadNeck/DNAsequencing/mapped/${TumourIDs[$comparisonIndex]}.bam "
    tumourSample=${TumourIDs[$comparisonIndex]}
    labelString=${labelString}"INPUT_LABEL=$tumourSample "
    comparisonIndex=$((comparisonIndex+1))
  done
  qsub -W depend=afterok:$allMapJobsString -v inputString="$inputString",labelString="$labelString",patientID=$patientID structural.pbs
done

# 6: Purity And Ploidy

for((sampleIndex = 0; sampleIndex < ${#outputIDs[@]}; sampleIndex++))
do # Each normal and tumour pair.
{
  normalID=${NormalIDs[$sampleIndex]}
  normalFile=/scratch/HeadNeck/DNAsequencing/mapped/$normalID.bam
  tumourID=${TumourIDs[$sampleIndex]}
  tumourFile=/scratch/HeadNeck/DNAsequencing/mapped/.bam
  outputID=${outputIDs[$sampleIndex]}
  qsub -W depend=afterok:$allMapJobsString -v normalFile=$normalFile,tumourFile=$tumourFile,normalID=$normalID,tumourID=$tumourID,outputID=$outputID purityPloidy.pbs
}
done
