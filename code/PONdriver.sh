sampleIDs=($(seq 1 1 10))
sampleIDs=( "${sampleIDs[@]/#/Oral_}" )
sampleIDs=( "${sampleIDs[@]/%/-N}" )
normalFiles=()
for((sampleIndex = 0; sampleIndex < ${#sampleIDs[@]}; sampleIndex++))
do # Each normal sample versus the human genome reference.
{
  sampleID=${sampleIDs[$sampleIndex]}
  normalFiles+=($projectDir/Final_bams/$sampleID.final.bam)
}
done

normalFiles=${normalFiles[@]}
sampleIDs=${sampleIDs[@]}

preprocessID=$(qsub -v inputString="$normalFiles",labelString="$sampleIDs",projectDir="$projectDir" $scriptsDir/makePONpreprocess.pbs)
assembleID=$(qsub -W depend=afterok:$preprocessID -v inputString="$normalFiles",labelString="$sampleIDs",projectDir="$projectDir" $scriptsDir/makePONassemble.pbs)
qsub -W depend=afterok:$assembleID -v inputString="$normalFiles",labelString="$sampleIDs",projectDir="$projectDir" $scriptsDir/makePONcall.pbs
