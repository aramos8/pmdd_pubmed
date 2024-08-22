library(tidyverse)
library(DBI)
library(duckdb)

# The goal of this script is to combine all csv files obtained from PMC (bulk download)
# into a single data frame. This data frame can then be entered into our database, which
# allows us to access it from multiple places. 


# Combine all *filelist.csv files obtained from the PMC FTP service
##Adapted from https://stackoverflow.com/questions/69341214/merging-thousands-of-csv-files-into-a-single-dataframe-in-r & https://dcl-prog.stanford.edu/purrr-parallel.html

filenames <- list.files("/Volumes/on_the_go/PMC/PMC_FTP/", pattern = "*.csv")

pmc_filelist <- purrr::map_dfr(paste0("/Volumes/on_the_go/PMC/PMC_FTP/", filenames), read.csv, .id = "archive") %>% 
  mutate(archive = filenames[as.numeric(archive)])


# Save as csv
write.csv(pmc_filelist, "/Volumes/on_the_go/PMC/pmc_filelist_all.csv")


### Import data frame into DuckDB database ###

# Connect to DuckDB database
database_path <- file.path("data", "pmdd.db")

con <- dbConnect(duckdb(), dbdir = database_path)


# Register data frame as DuckDB table
dbWriteTable(con, "pmc_filelist", pmc_filelist, overwrite = TRUE)

# Close connection to database
duckdb_shutdown(duckdb())
