library(GenomicRanges)
library(rtracklayer)
library(GenomicFeatures)
library(BiocParallel)
library(ComplexHeatmap)
library(circlize)
library(optparse)

option_list <- list(
  make_option(c("-i", "--input"), type="character", help="Input file name", metavar="FILE")
)

opt <- parse_args(OptionParser(option_list = option_list))

input_file <- opt$input

cat("Input file is:", input_file, "\n")

