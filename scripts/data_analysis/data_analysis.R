library(dplyr)
library(stringr)
library(GenomicRanges)
library(data.table)
library(EnrichedHeatmap)
library(circlize)

args <- commandArgs(trailingOnly = TRUE)
if (length(args) != 1) {
  stop("Usage: Rscript data_analysis.R <gene_presence_absence.tsv> [bed_dir]\n",
       "  <gene_presence_absence.tsv>  – path to your gene table (TSV)\n")
}
gene_table_file <- args[1]

gene_table <- fread(gene_table_file)

total_genes <- ncol(gene_table)-1
print(total_genes)
# Drop any columns with NaN
not_any_na <- function(x) all(!is.na(x))
gene_table <- gene_table %>% select(where(not_any_na))

analysed_genes <- ncol(gene_table)-1
print(analysed_genes)

# If needed: Remove the first column
df_long <- gene_table %>% select(-Reference) %>% t() %>% as.data.frame()
colnames(df_long) <- "info"
df_long$ref <- rownames(df_long)
rownames(df_long) <- NULL

parsed <- df_long %>%
  mutate(
    info_clean = str_remove_all(info, "[()]"),
    seqname = str_extract(info_clean, "^[^,]+"),
    strand = str_extract(info_clean, ",(minus|plus),") %>% str_remove_all(","),
    start = as.numeric(str_extract(info_clean, ",[0-9]+,") %>% str_remove_all(",")),
    end = as.numeric(str_extract(info_clean, ",[0-9]+$") %>% str_remove_all(",")),
    strand = ifelse(strand == "plus", "+", "-"),
    new_start = pmin(start, end),
    new_end = pmax(start, end)
  )

strand_lookup <- setNames(parsed$strand, parsed$ref)

# Create concatenated seqnames
concat_seqnames <- paste(parsed$seqname, parsed$ref, sep = "_")

# Build GRanges with concatenated seqnames
strains <- GRanges(
  seqnames = concat_seqnames,
  ranges = IRanges(start = parsed$new_start, end = parsed$new_end),
  strand = parsed$strand
)

# Optionally set names to something meaningful, e.g. just parsed$ref or parsed$seqname
names(strains) <- parsed$ref

strains

tss = promoters(strains, upstream = 0, downstream = 1)

# Function to read a single BED file into GRanges with modified seqnames
read_bed_with_concat_seqname <- function(ref_name, bed_dir = ".") {
  bed_file <- file.path(bed_dir, paste0(ref_name, ".bed"))
  if (!file.exists(bed_file)) {
    warning(paste("BED file not found:", bed_file))
    return(NULL)
  }

  # Read the BED file with fread; expect at least 6 columns:
  # chr, start, end, ..., coverage (5th column), strand (6th column)
  bed_dt <- fread(bed_file, header = FALSE, col.names = c("chr", "start", "end", "unused", "coverage", "strand"))

  # Convert coverage to numeric, just in case
  bed_dt[, coverage := as.numeric(coverage)]

  # Create seqnames by concatenating BED chr and the ref_name, separated by _
  seqnames_concat <- paste0(bed_dt$chr, "_", ref_name)

  # Build GRanges
  gr <- GRanges(
    seqnames = seqnames_concat,
    ranges = IRanges(start = bed_dt$start + 1, end = bed_dt$end), # BED is 0-based start, half-open; GRanges is 1-based closed
    strand = "*",  # Strand is '.' in your bed; set to "*" (unknown)
    coverage = bed_dt$coverage
  )
  mcols(gr)$ref <- ref_name
  return(gr)
}

# Directory where your BED files are stored, change if needed
bed_dir <- "."

# Read all BED files and combine
bed_gr_list <- lapply(parsed$ref, read_bed_with_concat_seqname, bed_dir = bed_dir)

# Remove any NULLs (missing BED files)
bed_gr_list <- bed_gr_list[!sapply(bed_gr_list, is.null)]

# Concatenate all into a master GRanges object
master_gr <- do.call(c, bed_gr_list)

# look up each range’s gene/ref from the metadata column
gene_strands <- strand_lookup[ mcols(master_gr)$ref ]

# flip sign only for minus strand, leave everything else exactly as read
is_minus <- gene_strands == "-"
mcols(master_gr)$coverage[is_minus] <- - mcols(master_gr)$coverage[is_minus]

#mcols(master_gr)$coverage <- abs(mcols(master_gr)$coverage)

mat1 = normalizeToMatrix(master_gr, tss, value_column = "coverage",
    extend = 5000, mean_mode = "w0", w = 10)
mat1

col_title <- paste("Enrichment Heatmap of\n", gene_table[1, 1], "\n(",analysed_genes, " out of ", total_genes, " contain the gene of interest)", sep = "")

file_name = paste(gene_table[1, 1], "_PQSs_heatmap.pdf", sep = "")

col_fun = colorRamp2(c(-2, 0, 2), c("blue", "white", "red"))

pdf(file_name, width = 5, height = 6)
EnrichedHeatmap(mat1, col = col_fun, name = "PQSs",
    column_title = col_title)
dev.off()
