#!/bin/bash

# 1: Duplicate Removal and Merging

projectName=$1
projectDir=$2
scriptsDir=$3
temporaryDir=${projectDir/project/scratch/}

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
  jobID=$(qsub -v R1="$R1reads",R2="$R2reads",SID=$sampleName,projectDir="$projectDir",scriptsDir="$scriptsDir" -P $projectName $scriptsDir/removeDuplicates.pbs)
  allDuplicateJobs+=($jobID)
done < $projectDir/samplesInputs.txt

# 2: Read Alignment

index=0
while IFS=$'\t' read -r -a sampleNameAndFiles
do
  sampleName=${sampleNameAndFiles[0]}
  R1=$temporaryDir/FASTQ/${sampleName}_noDuplicates_R1.fastq.gz
  R2=$temporaryDir/FASTQ/${sampleName}_noDuplicates_R2.fastq.gz
  jobID=$(qsub -W depend=afterok:${allDuplicateJobs[$index]} -v R1=$R1,R2=$R2,SID=$sampleName,projectDir="$projectDir",scriptsDir="$scriptsDir" -P $projectName $scriptsDir/map.pbs)
  allMapJobs+=($jobID)
  index=$((index+1))
done < $projectDir/samplesInputs.txt

# 3: DNA Metics Calculation

index=0
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

  qsub -W depend=afterok:${allMapJobs[$index]]} -v originalReadsFile=$originalReadsFile,noDuplicatesFile=$noDuplicatesFile,alignmentsFile=$alignmentsFile,SID=$sampleName,projectDir="$projectDir",scriptsDir="$scriptsDir" -P $projectName $scriptsDir/DNAmetrics.pbs
done < $projectDir/samplesInputs.txt

echo -e "Sample ID\tStarting Reads\tUseful Reads\tDuplication Rate\tAligned Reads\tMapped Rate\tMedian Insert Size\tEstimated Coverage" > $projectDir/DNAmetrics.txt

# 4: Short Variant Calling

# Germline
sampleIDs=$(cut -f 1 $projectDir/samplesInputs.txt) 
sampleTypes=$(cut -f 2 $projectDir/samplesInputs.txt)
sampleIDs=($sampleIDs)
sampleTypes=($sampleTypes)
for((sampleIndex = 0; sampleIndex < ${#sampleIDs[@]}; sampleIndex++))
do # Each normal sample versus the human genome reference.
{
  if [ ${sampleTypes[$sampleIndex]} == "Normal" ]
  then
    normalFile=$temporaryDir/mapped/${sampleIDs[$sampleIndex]}.bam
    qsub -W depend=afterok:${allMapJobs[$sampleIndex]} -v normalFile=$normalFile,SID=${sampleIDs[$sampleIndex]},projectDir="$projectDir",scriptsDir="$scriptsDir" -P $projectName $scriptsDir/SNVgermline.pbs
  fi
}
done

# Somatic
NormalIDs=$(cut -f 3 $projectDir/patientsSamples.txt)
TumourIDs=$(cut -f 4 $projectDir/patientsSamples.txt)
outputIDs=$(cut -f 5 $projectDir/patientsSamples.txt)
NormalIDs=($NormalIDs)
TumourIDs=($TumourIDs)
outputIDs=($outputIDs)
function join { local IFS="$1"; shift; echo "$*"; }
allMapJobsString=$(join : ${allMapJobs[@]})
for((sampleIndex = 0; sampleIndex < ${#outputIDs[@]}; sampleIndex++))
do # Each normal and tumour pair.
{
  normalFile=$temporaryDir/mapped/${NormalIDs[$sampleIndex]}.bam
  tumourFile=$temporaryDir/mapped/${TumourIDs[$sampleIndex]}.bam
  outputID=${outputIDs[$sampleIndex]}
  qsub -W depend=afterok:$allMapJobsString -v normalFile=$normalFile,tumourFile=$tumourFile,outputID=$outputID,projectDir="$projectDir",scriptsDir="$scriptsDir" -P $projectName $scriptsDir/SNVsomatic.pbs
}
done

# 5: Structural Variant Calling

comparisons=${#outputIDs[@]}

# Sample sets for each patient

comparisonIndex=0
while [ $comparisonIndex -lt $comparisons ]
do
  inputString="$temporaryDir/mapped/${NormalIDs[$comparisonIndex]}.bam "
  normalSample=${NormalIDs[$comparisonIndex]}
  labelString="$normalSample "
  outputID=${outputIDs[$comparisonIndex]}
  while [[ $comparisonIndex -lt $comparisons && ${NormalIDs[$comparisonIndex]} == $normalSample ]]
  do
    tumourSample=${TumourIDs[$comparisonIndex]}	  
    inputString=${inputString}"$temporaryDir/mapped/$tumourSample.bam "
    labelString=${labelString}"$tumourSample "
    comparisonIndex=$((comparisonIndex+1))
  done
  labelString=${labelString%?} # Remove the last space.
  qsub -W depend=afterok:$allMapJobsString -v inputString="$inputString",labelString="$labelString",genome=hg38,outputID=$outputID,projectDir="$projectDir",scriptsDir="$scriptsDir" -P $projectName $scriptsDir/structural.pbs
done

# 6: Purity And Ploidy

for((sampleIndex = 0; sampleIndex < ${#outputIDs[@]}; sampleIndex++))
do # Each normal and tumour pair.
{
  normalID=${NormalIDs[$sampleIndex]}
  normalFile=$temporaryDir/mapped/$normalID.bam
  tumourID=${TumourIDs[$sampleIndex]}
  tumourFile=$temporaryDir/mapped/$tumourID.bam
  outputID=${outputIDs[$sampleIndex]}
  qsub -W depend=afterok:$allMapJobsString -v normalFile=$normalFile,tumourFile=$tumourFile,normalID=$normalID,tumourID=$tumourID,outputID=$outputID,projectDir="$projectDir",scriptsDir="$scriptsDir" -P $projectName $scriptsDir/purityPloidy.pbs
}
done
