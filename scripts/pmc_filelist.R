library(xml2)
library(tidyverse)
library(DBI)
library(duckdb)

# The goal of this script is to combine all csv files obtained from PMC (bulk download)
# into a single data frame. This dataframe can then be entered into our database, which
# allows us to acces it from multiple places. 

# Connect to DuckDB database
database_path <- file.path("data", "pmdd.db")

con <- dbConnect(duckdb(), dbdir = database_path)

# Load entrez_clean table as data frame
entrez_clean <- dbGetQuery(con, "SELECT * FROM entrez_clean;")

# Close connection to database
duckdb_shutdown(duckdb())


# Get all PMC IDs to extract keywords from 
pmc_kws <- entrez_clean %>% 
  filter(keywords %in% c('NULL', 'N/A')) %>% 
  select(pmc_id) %>% 
  filter(!is.na(pmc_id)) %>% 
  unique()

# Combine all *filelist.csv files
### Adapted from https://michaelinom.medium.com/how-to-combine-all-csv-files-from-the-same-folder-into-one-data-frame-automatically-with-r-1775876a876c ###

pmc_filelist <- read.csv(paste0("/Volumes/Vault/PMC/","oa_comm_xml.PMC000xxxxxx.baseline.2024-06-18.filelist.csv") , header=TRUE)

## This for loop took ~20 hrs to run. There must be a more efficient way to do this.
## Could try this next: https://stackoverflow.com/questions/69341214/merging-thousands-of-csv-files-into-a-single-dataframe-in-r
for (file in list.files("/Volumes/Vault/PMC/", pattern = "*.csv")){
  temporary <-read.csv(paste0("/Volumes/Vault/PMC/",file), header=TRUE)
  pmc_filelist <-unique(rbind(pmc_filelist, temporary))
  rm(temporary)
}

write.csv(pmc_filelist, "/Volumes/Vault/PMC/pmc_filelist_all.csv")

