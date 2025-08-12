library(dplyr)
library(stringr)
library(GenomicRanges)
library(data.table)
library(EnrichedHeatmap)
library(circlize)
library(pheatmap)

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

bed_dir <- "."

# Read all BED files and combine
bed_gr_list <- lapply(parsed$ref, read_bed_with_concat_seqname, bed_dir = bed_dir)

# Remove any NULLs (missing BED files)
bed_gr_list <- bed_gr_list[!sapply(bed_gr_list, is.null)]

# Concatenate all into a master GRanges object
master_gr <- do.call(c, bed_gr_list)

# look up each range’s gene/ref from the metadata column
gene_strands <- strand_lookup[ mcols(master_gr)$ref ]

# 1. Define the window around the TSS
window_size <- 5000
num_cols <- 2 * window_size + 1 # Total columns for -5000 to +5000, including 0

# 2. Initialize an empty matrix for the heatmap
# Use the names from the tss object for rows, or create generic ones if they don't exist.
tss_names <- names(tss)

heatmap_matrix <- matrix(0,
                         nrow = length(tss),
                         ncol = num_cols,
                         dimnames = list(tss_names, -window_size:window_size))

cat("Initialized a", nrow(heatmap_matrix), "x", ncol(heatmap_matrix), "matrix.\n")
cat("Starting to process each TSS...\n")

# 3. Loop through each TSS to create a row in the matrix
for (i in 1:length(tss)) {

  # Get information for the current TSS
  current_tss <- tss[i]
  tss_pos <- start(current_tss)
  tss_chrom <- as.character(seqnames(current_tss))
  tss_strand <- as.character(strand(current_tss))

  # Define the search region (+/- 5000 bp) around the TSS
  search_window <- GRanges(seqnames = tss_chrom,
                           ranges = IRanges(start = tss_pos - window_size,
                                            end = tss_pos + window_size))

  # Find all motifs from your master list that fall within this window
  overlapping_motifs <- subsetByOverlaps(master_gr, search_window, ignore.strand = TRUE)

  # If no motifs are found in the window, the row correctly remains all zeros,
  # so we can skip to the next TSS.
  if (length(overlapping_motifs) == 0) {
    next
  }

  # 4. Process each overlapping motif found for the current TSS
  for (j in 1:length(overlapping_motifs)) {
    motif <- overlapping_motifs[j]
    motif_score <- motif$coverage

    # Calculate the motif's position relative to the TSS
    # This creates a vector of all base pairs covered by the motif
    rel_positions <- (start(motif):end(motif)) - tss_pos

    # --- Handle strand-specificity ---
    if (tss_strand == "+") {
      # For the positive strand, use positions and scores as they are
      final_positions <- rel_positions
      final_score <- motif_score
    } else if (tss_strand == "-") {
      # For the negative strand, reverse the relative positions and flip the score's sign
      final_positions <- -rel_positions
      final_score <- -motif_score
    } else {
      # If the TSS strand is not '+' or '-', skip it.
      next
    }

    # 5. Place the score into the matrix

    # Filter for positions that are actually within our -5000 to +5000 window
    valid_indices <- which(final_positions >= -window_size & final_positions <= window_size)

    if (length(valid_indices) > 0) {
      # Get the final positions that fall within our defined window
      positions_in_window <- final_positions[valid_indices]

      # Convert the relative positions (e.g., -5000) to matrix column indices (e.g., 1)
      matrix_cols <- positions_in_window + window_size + 1

      # Assign the score to the corresponding cells in the matrix row
      # Note: If motifs overlap, the score of the last processed motif will be used.
      heatmap_matrix[i, matrix_cols] <- final_score
    }
  }

  # Optional: Print progress
  if (i %% 100 == 0) {
    cat("Processed", i, "of", length(tss), "TSSs.\n")
  }
}

cat("Finished processing all TSSs.\n")
cat("The 'heatmap_matrix' is now ready for plotting.\n")
col_title <- paste("Enrichment Heatmap of\n", gene_table[1, 1], "\n(",analysed_genes, " out of ", total_genes, " contain the gene of interest)", sep = "")

file_name = paste(gene_table[1, 1], "_PQSs_heatmap.png", sep = "")

my_color_func <- colorRamp2(c(-2, 0, 2), c("blue", "lightyellow", "red"))

# Generate a sequence of values to sample colors from
# This creates a fine-grained sequence of breaks from -2 to 2.
my_breaks <- seq(-2, 2, by = 0.01)

# Apply the color function to the breaks to get a corresponding vector of colors
my_colors <- my_color_func(my_breaks)

phm <- pheatmap(heatmap_matrix, cluster_rows = TRUE, cluster_cols = FALSE, show_colnames = FALSE, main=col_title,color = my_colors,
         breaks = my_breaks)



save_pheatmap_png <- function(x, filename, width=1200, height=1000, res = 150) {
  png(filename, width = width, height = height, res = res)
  grid::grid.newpage()
  grid::grid.draw(x$gtable)
  dev.off()
}

save_pheatmap_png(phm, file_name)



# Load the necessary libraries
library(ggplot2)

# Calculate the average of each column in the matrix
average_values <- colMeans(heatmap_matrix)

# Get the column names (which represent the positions)
positions <- colnames(heatmap_matrix)

# Create the data frame with 'Position' and 'Average_Value' columns
df_line_plot <- data.frame(
  Position = as.numeric(positions),
  Average_Value = average_values
)

# Create the ggplot object
p <- ggplot(df_line_plot, aes(x = Position, y = Average_Value, color = Average_Value)) +
  # Create a line graph
  geom_line(size = 1) +
  # Define the custom color gradient
  scale_color_gradientn(
    #colors = c("blue", "lightyellow", "red"),
    colors = c("red","red","red"),
    values = scales::rescale(c(-2, 0, 2)),
    limits = c(-2, 2),
    name = "Average\nValue"
  ) +
  # Add a vertical dashed line at the TSS (Position 0)
  geom_vline(xintercept = 0, linetype = "dashed", color = "black") +
  # Add a horizontal dashed line at y=0
  geom_hline(yintercept = 0, linetype = "dashed", color = "grey") +
  # Set the titles and labels
  labs(
    title = "Average Enrichment Profile Around the TSS",
    x = "Position Relative to TSS (bp)",
    y = "Average Enrichment Score"
  ) +
  # Use a minimal theme for a cleaner look
  theme_minimal()

# Save the plot to a PNG file
file_name = paste(gene_table[1, 1], "_PQSs_heatmap_averaged.png", sep = "")
ggsave(file_name, plot = p, width = 8, height = 6, dpi = 150)

cat("Line graph saved to 'average_enrichment_line_graph.png'")
