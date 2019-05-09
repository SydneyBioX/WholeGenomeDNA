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
  R1=/project/HeadNeck/DNAsequencing/FASTQ/${sampleName}_noDuplicates_R1.fastq.gz
  R2=/project/HeadNeck/DNAsequencing/FASTQ/${sampleName}_noDuplicates_R2.fastq.gz
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

  noDuplicatesFile=/project/HeadNeck/DNAsequencing/FASTQ/${sampleName}_noDuplicates_R1.fastq.gz
  alignmentsFile=/project/HeadNeck/DNAsequencing/mapped/${sampleName}.bam

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
    normalFile=/project/HeadNeck/DNAsequencing/mapped/${sampleIDs[$sampleIndex]}.bam
    qsub -W depend=afterok:${allMapJobs[$sampleIndex]} -v normalFile=$normalFile,SID=${sampleIDs[$sampleIndex]} SNVgermline.pbs
  fi
}
done

# Somatic
PatientIDs=$(cut -f 1 /project/HeadNeck/DNAsequencing/patientsSamples.txt)
NormalIDs=$(cut -f 2 /project/HeadNeck/DNAsequencing/patientsSamples.txt)
TumourIDs=$(cut -f 3 /project/HeadNeck/DNAsequencing/patientsSamples.txt)
PatientIDs=($PatientIDs)
NormalIDs=($NormalIDs)
TumourIDs=($TumourIDs)
function join { local IFS="$1"; shift; echo "$*"; }
allMapJobsString=$(join : ${allMapJobs[@]})
for((sampleIndex = 0; sampleIndex < ${#PatientIDs[@]}; sampleIndex++))
do # Each normal and tumour pair.
{
  normalFile=/project/HeadNeck/DNAsequencing/mapped/${NormalIDs[$sampleIndex]}.bam
  tumourFile=/project/HeadNeck/DNAsequencing/mapped/${TumourIDs[$sampleIndex]}.bam
  qsub -W depend=afterok:$allMapJobsString -v normalFile=$normalFile,tumourFile=$tumourFile,SID=${PatientIDs[$sampleIndex]} SNVsomatic.pbs
}
done

# 5: Structural Variant Calling

for((sampleIndex = 0; sampleIndex < ${#sampleIDs[@]}; sampleIndex++))
do
{
  qsub -W depend=afterok:${allMapJobs[$sampleIndex]} -v INPUT=/project/HeadNeck/DNAsequencing/mapped/${sampleIDs[$sampleIndex]}.bam,SID=${sampleIDs[$sampleIndex]} structural.pbs
}
done

# 6: Purity And Ploidy

for((sampleIndex = 0; sampleIndex < ${#PatientIDs[@]}; sampleIndex++))
do # Each normal and tumour pair.
{
  cancerID=${TumourIDs[$sampleIndex]}	
  normalFile=/project/HeadNeck/DNAsequencing/mapped/${NormalIDs[$sampleIndex]}.bam
  tumourFile=/project/HeadNeck/DNAsequencing/mapped/${cancerID}.bam
  qsub -W depend=afterok:$allMapJobsString -v normalFile=$normalFile,tumourFile=$tumourFile,SID=${PatientIDs[$sampleIndex]},CID=$cancerID purityPloidy.pbs
}
done
