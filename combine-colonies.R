# Check if tidyverse is installed before proceeding
if (!requireNamespace("tidyverse", quietly = TRUE)) {
  stop("Package 'tidyverse' is not installed. Please install it with install.packages('tidyverse') and try again.")
}

# Load tidyverse
library(tidyverse)

# Combines all colonies in *_roi_list.tsv files into one file
path_to_output = "output" # Path to output from macro, default is "output"
files <- list.files(path = path_to_output, pattern = "_roi_list\\.tsv$", full.names = TRUE)

# Read all files, tagging its rows with the source filename
combined <- files %>%
  set_names() %>%                                  # name each entry by its path
  map_dfr(~ read_tsv(.x, show_col_types = FALSE),  # read TSV without type messages
          .id = "file") %>%                        # collect into one tibble, .id holds the file key
  mutate(file = basename(file)) %>%                # reduce pathname to filename only
  mutate(image = str_remove(file, "_roi_list.tsv")) %>%
  filter(str_detect(Name, "^Well_[0-9]+_[0-9]+")) %>%  # Only matches the colonies
  mutate(
    well = str_extract(Name, "Well_[0-9]+"),
    colony = str_extract(Name, "[0-9]+$")) %>%
  select(image, well, colony, x = X, y = Y, width = Width, height = Height, area = Points)

# Write the combined colony file to disk
combined_filename <- paste0(today(), "_combined-colonies.tsv")
write_tsv(combined, combined_filename)

# Count colonies per Well on each image
counts <- combined %>%
  group_by(image, well) %>%
  summarise(count = n())

counts_filename <- paste0(today(), "_counts.tsv")
write_tsv(counts, counts_filename)
