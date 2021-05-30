#!/usr/bin/env Rscript

library("optparse")
 
option_list = list(
	make_option(c("-i", "--in_data"), type="character", default=NULL, 
              help="Path to tsv file containing data for feature distribution across a core or pangenome", metavar="character"),
        make_option(c("-m", "--METHOD"), type="character", default=NULL,
              help="Which METHOD to use for distance matrix calculation", metavar="character"),
        make_option(c("-b", "--BINARY"), action="store_true", default=FALSE,
              help="Flag to use BINARY distance analyses [default %default]"),
        make_option(c("-p", "--out_prefix"), type="character", default=NULL,
              help="Prefix to give files that are being written, e.g. CORE, PAN, SOFTCORE", metavar="character"),
	make_option(c("-o", "--outdir"), type="character", default=NULL,
              help="Directory to write to", metavar="character")
); 
 
opt_parser = OptionParser(option_list=option_list);
opt = parse_args(opt_parser);


if (is.null(opt$in_data)){
  print_help(opt_parser)
  stop("Please supply the path to the data file.", call.=FALSE)
}

if (is.null(opt$METHOD)){
  print_help(opt_parser)
  stop("Please supply the vegdist METHOD to use for distance calculation", call.=FALSE)
}

if (is.null(opt$out_prefix)){
  print_help(opt_parser)
  stop("Please supply the output file prefix.", call.=FALSE)
}

if (is.null(opt$outdir)){
  print_help(opt_parser)
  stop("Please supply the output directory.", call.=FALSE)
}


library(vegan)
set.seed(0)

write("Loading data...", file=stdout())

data <- read.delim(file=opt$in_data, header=TRUE)
m <- t(as.matrix(data[,2:ncol(data)]))
#m <- t(data[,2:ncol(data)]) # remove feature column, assumed to be first column
# m <- apply(m, 2, as.numeric) # removes species names!

write("Generating distance matrix... This may take some time.", file=stdout())
dist_mat <- vegdist(x = m, method = opt$METHOD, binary = opt$BINARY)

dist_mat <- as.matrix(dist_mat)

#write("Ordinating the distance matrix in both 2- and 3- dimensions.", file=stdout())
#d2 <- cmdscale(dist_mat, k = 2, eig = TRUE)
#d3 <- cmdscale(dist_mat, k = 3, eig = TRUE)

prefix <- paste(opt$out_prefix, opt$METHOD, "binary", opt$BINARY, sep = ".")
dm_file <- paste(prefix, "dist_mat.RData", sep = ".")
#d_file <- paste(prefix, "d.RData", sep = ".") 
#d3_file <- paste(prefix, "d3.RData", sep = ".") 

dm_out <- paste(opt$outdir, dm_file, sep = "/")
#d_out <- paste(opt$outdir, d_file, sep = "/")
#d3_out <- paste(opt$outdir, d3_file, sep = "/")

# save distance matrix and the ordinations
save(dist_mat, file = dm_out)
#save(d2, d3, file = d_out)

write("Distance matrix saved to:", file = stdout())
write(dm_out, file = stdout())
