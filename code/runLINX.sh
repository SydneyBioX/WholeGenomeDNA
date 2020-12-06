#!/bin/bash

projectDir=$1

tumourIDs=()
outputIDs=()
outputDir=$projectDir/structuralVariants/LINX/

if [[ ! -d $outputDir ]]
then
    mkdir -p $outputDir
fi

while IFS=$'\t' read -r -a patientIDandComparisonSamples
do
  tumourIDs+=(${patientIDandComparisonSamples[2]}) 
  outputIDs+=(${patientIDandComparisonSamples[3]})
done < $projectDir/patientsSamples.txt

for((sampleIndex = 0; sampleIndex < ${#outputIDs[@]}; sampleIndex++))
do
{
  java -Xmx4g -jar /home/562/ds6924/software/sv-linx_v1.11.jar -sample ${tumourIDs[$sampleIndex]} -sv_vcf $projectDir/purityPloidy/purple/${tumourIDs[$sampleIndex]}.purple.sv.vcf.gz -purple_dir $projectDir/purityPloidy/purple/ -output_dir $projectDir/structuralVariants/LINX/ -ref_genome_version HG38 -check_drivers -check_fusions -gene_transcripts_dir /home/562/ds6924/databases/ -known_fusion_file /home/562/ds6924/databases/known_fusion_data.csv -viral_hosts_file /home/562/ds6924/databases/viral_host_ref.csv -line_element_file /home/562/ds6924/databases/line_elements.hg38.csv -fragile_site_file /home/562/ds6924/databases/fragile_sites_hmf.hg38.csv -write_vis_data
}
done
