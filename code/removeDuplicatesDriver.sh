#!/bin/bash

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
  qsub -v R1="$R1reads",R2="$R2reads",SID=$sampleName removeDuplicates.pbs
done < /project/HeadNeck/DNAsequencing/samplesInputs.txt
