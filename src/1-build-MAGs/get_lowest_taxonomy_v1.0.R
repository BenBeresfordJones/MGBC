#!/usr/bin/env Rscript

# get lowest taxonomy from GTDBTk output file gtdbtk.bac120.summary.tsv

gtdbtk_out <- read.delim("gtdbtk.bac120.summary.tsv", header=TRUE)

get.lowest_taxonomy <- function(x) {
  taxonomy <- as.character(x)
  split_tax <- strsplit(taxonomy, ";")
  rev_split_tax <- lapply(split_tax, rev)
  rev_split_tax_level_removed <- lapply(rev_split_tax, function(x) {
    gsub(".__", "", x = x)
  })
  index_list = lapply(rev_split_tax_level_removed, function(x) {
    which(unlist(x)!="")[1]
  })
  len <- c(1:length(index_list))
  unlist(lapply(len, function(x) {
    rev_split_tax[[x]][index_list[[x]]]
  }))
}

lowest <- get.lowest_taxonomy(gtdbtk_out[,2])

# convert level indicator into whole word
level_conversion <- function(x) {
        tmp <- x
        tmp <- gsub("s__", "species__", tmp)
        tmp <- gsub("g__", "genus__", tmp)
        tmp <- gsub("f__", "family__", tmp)
        tmp <- gsub("o__", "order__", tmp)
        tmp <- gsub("c__", "class__", tmp)
        tmp <- gsub("p__", "phylum__", tmp)
        tmp
        }

lowest_convert <- level_conversion(lowest)

# get rank and name

lowest_rank <- unlist(lapply(strsplit(lowest_convert, split = "__"), function(x) {
 x[1]
 }))

lowest_name <- unlist(lapply(strsplit(lowest_convert, split = "__"), function(x) {
	x[2]
 }))


# generate output

output_to_write <- paste(gtdbtk_out[,1], lowest, lowest_convert, lowest_rank, lowest_name, sep = ",", gtdbtk_out[,2])


write(output_to_write, file = "GTDBTk_lowest_taxonomy.csv")
