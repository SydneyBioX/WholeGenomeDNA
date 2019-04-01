#!/bin/bash
sampleIDs=$(cut -f 1 /project/HeadNeck/DNAsequencing/samplesInputs.txt) 
sampleIDs=($sampleIDs)
GenomeSeq=/project/HeadNeck/sequence/hg38/GCA_000001405.15_GRCh38_no_alt_analysis_set.fna
GeneDatabase=/project/HeadNeck/databases/hg38/gencodeGenes29hg38.bed
transposonsDirs=(/project/HeadNeck/DNAsequencing/LINE1/ /project/HeadNeck/DNAsequencing/Alu/ /project/HeadNeck/DNAsequencing/SVA/)
transposonsInfos=(/usr/local/melt/2.1.5/me_refs/Hg38/LINE1_MELT.zip /usr/local/melt/2.1.5/me_refs/Hg38/ALU_MELT.zip /usr/local/melt/2.1.5/me_refs/Hg38/SVA_MELT.zip)

# Step 1: Preprocessing to extract discordant pairs from alignments.
echo "Time: $(date). Begin retrotransposons analysis of all samples." >> /project/HeadNeck/DNAsequencing/DNAlog.txt
for((sampleIndex = 0; sampleIndex < ${#SampleIDs[@]}; sampleIndex++))
do
{
  jobID=$(qsub -v INPUT=/project/HeadNeck/DNAsequencing/mapped/${sampleIDs[$sampleIndex]}.bam,GENO=$GenomeSeq preprocessMELT.pbs)
  all1Jobs+=($jobID)
}
done

# Step 2: Determine insertion sites in individual samples.
for((sampleIndex = 0; sampleIndex < ${#SampleIDs[@]}; sampleIndex++))
do
{
  for((RTindex = 0; RTindex < 3; RTindex++))
  do
    jobID=$(qsub -W depend=afterok:${all1Jobs[$sampleIndex]} -v INPUT=${alignmentsFiles[$sampleIndex]},GENO=$GenomeSeq,TRANSDIR=${transposonsDirs[$RTindex]},TRANSINFO=${transposonsInfos[$RTindex]} transposonsIndividual.pbs)
    all2Jobs=$all2Jobs:$jobID
  done
}
done

# Step 3: Joint analysis. After all individual samples and each of the retrotransposon types have finished processing.

for((RTindex = 0; RTindex < 3; RTindex++))
do
  jobID=$(qsub -W depend=afterok${all2Jobs} -v TRANSDIR=${transposonsDirs[$RTindex]},TRANSINFO=${transposonsInfos[$RTindex]},GENO=$GenomeSeq,GENEDB=$GeneDatabase transposonsJoint.pbs)
  all3Jobs=$all3Jobs:$jobID
done

# Step 4: Genotyping. Each sample is genotyped separately.
for alignmentsFile in ${alignmentsFiles[@]};
do
{
  for((RTindex = 0; RTindex < 3; RTindex++))
  do
    jobID=$(qsub -W depend=afterok${all3Jobs} -v INPUT=$alignmentsFile,TRANSDIR=${transposonsDirs[$RTindex]},TRANSINFO=${transposonsInfos[$RTindex]},GENO=$GenomeSeq transposonsGenotype.pbs)
    all4Jobs=$all4Jobs:$jobID
  done
}
done

# Step 5: Create a single Variant Call File (VCF) for all samples.
for((RTindex = 0; RTindex < 3; RTindex++))
do
  jobID=$(qsub -W depend=afterok${all4Jobs} -v TRANSDIR=${transposonsDirs[$RTindex]},TRANSINFO=${transposonsInfos[$RTindex]},GENO=$GenomeSeq transposonsVCF.pbs)
  all5Jobs=$all5Jobs:$jobID
done

qsub -W depend=afterok${all5Jobs} -l select=1:ncpus=1:mem=1GB,walltime=00:00:01 bash -c 'echo "Time: $(date). End retrotransposons analysis of all samples." >> /project/HeadNeck/DNAsequencing/DNAlog.txt'
