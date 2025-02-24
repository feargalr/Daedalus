# Define the directory containing your files
input_dir <- "./"
output_file <- "merged_counts_table.csv"

# Get a list of all files in the directory
files <- list.files(input_dir, full.names = TRUE)

# Initialize an empty list to store data frames
data_list <- list()

# Loop through each file and read the data
for (file in files) {
  # Read the file assuming tab-separated values
  data <- read.table(file, header = FALSE, sep = "\t", col.names = c("Sequence", basename(file)), stringsAsFactors = FALSE)
  
  # Add to the list
  data_list[[file]] <- data
}

# Merge all data frames by the "Sequence" column
merged_data <- Reduce(function(x, y) merge(x, y, by = "Sequence", all = TRUE), data_list)

# Replace NAs with 0 (optional, if counts should be zero for missing sequences)
merged_data[is.na(merged_data)] <- 0

# Write the merged table to a CSV file
write.csv(merged_data, output_file, row.names = FALSE)

cat("Merged count table saved to:", output_file, "\n")
