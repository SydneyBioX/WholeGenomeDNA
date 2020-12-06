collateCoverage <- function(directory)
{
  coverageFiles <- list.files(directory, "mosdepth.summary.txt", full.names = TRUE)
  sampleIDs <- gsub(".mosdepth.summary.txt", '', basename(coverageFiles))
  averageCoverages <- sapply(coverageFiles, function(coverageFile)
  {
    coverageTable <- read.delim(coverageFile)
    round(coverageTable[nrow(coverageTable), "mean"])	  
  })

  write.table(data.frame(`Sample ID` = sampleIDs, `Average Coverage` = averageCoverages, check.names = FALSE),
	      file.path(directory, "coverageSummary.txt"), sep = '\t', quote = FALSE, row.names = FALSE)
}
