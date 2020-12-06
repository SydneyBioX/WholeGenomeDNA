#!/bin/bash

alignmentsDirectory=$1
delimiter=$2

alignmentsFiles=$(find $alignmentsDirectory -name \*bam)
alignmentsFiles=($alignmentsFiles)

for alignmentsFile in ${alignmentsFiles[@]}
do
  echo "Calculating average coverage for $alignmentsFile"
  qsub -v alignmentsFile=$alignmentsFile /home/562/ds6924/processes/calcAverageCoverage.pbs
done
