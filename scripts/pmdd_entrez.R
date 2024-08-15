library(xml2)
library(tidyverse)
library(DBI)
library(duckdb)

# This script extracts data from XML file obtained from Pubmed using Entrez command line tools. 
# The data from the XML file wil be stored in a data frame, which is then added to the pmdd.db DuckDB database
# for downstream processing.

###### The strategy used in this script was adapted from https://rpubs.com/Howetowork/499292 ######

#-----------------------------------------------------------
  
# Load and read the raw XML file 
file <- "data/pmdd_entrez.xml"
xml <- read_xml(file)

# Get the PubMedIDs
pmid_list <- xml_find_all(xml, ".//pubmed_id") %>% xml_text()
#pmid_list <- tail(pmid_list0, n = 20)   ## To test the script with a subset of the data

# Write function to get all the fields into data frame
get_details <- function(id) {
  pubmed_id <- id
  
  # pmc_id
  if(length(xml_find_all(xml, paste("//Publication[pubmed_id=", id, "]/pmc_id")) %>% xml_text()) > 0){
    pmc_id <- xml_find_all(xml, paste("//Publication[pubmed_id=", id, "]/pmc_id")) %>% xml_text()
  }else{
    pmc_id <- 'N/A'
  }
  
  # doi
  if(length(xml_find_all(xml, paste("//Publication[pubmed_id=", id, "]/doi")) %>% xml_text()) > 0){
    doi <- xml_find_all(xml, paste("//Publication[pubmed_id=", id, "]/doi")) %>% xml_text()
  }else{
    doi <- 'N/A'
  }
  
  # pub_type
  if(length(xml_find_all(xml, paste("//Publication[pubmed_id=", id, "]/pub_type/type")) %>% xml_text()) > 0){
    pub_type <- list(xml_find_all(xml, paste("//Publication[pubmed_id=", id, "]/pub_type/type")) %>% xml_text())
  }else{
    pub_type <- 'N/A'
  }
  
  # accepted_date
  if(length(xml_find_all(xml, paste("//Publication[pubmed_id=", id, "]/accepted_date")) %>% xml_text()) > 0){
    accepted_date <-xml_find_all(xml, paste("//Publication[pubmed_id=", id, "]/accepted_date")) %>% xml_text()
  }else{
    accepted_date <- 'N/A'
  }
  
  # pubdate
  if(length(xml_find_all(xml, paste("//Publication[pubmed_id=", id, "]/pubdate")) %>% xml_text()) > 0){
    pubdate <- xml_find_all(xml, paste("//Publication[pubmed_id=", id, "]/pubdate")) %>% xml_text()
  }else{
    pubdate <- 'N/A'
  }
  
  # major_mesh
  if(length(xml_find_all(xml, paste("//Publication[pubmed_id=", id, "]/major_mesh/major_mesh_term")) %>% xml_text()) > 0){
    major_mesh <- list(xml_find_all(xml, paste("//Publication[pubmed_id=", id, "]/major_mesh/major_mesh_term")) %>% xml_text())
  }else{
    major_mesh <- 'N/A'
  }
  
  # mesh_terms
  if(length(xml_find_all(xml, paste("//Publication[pubmed_id=", id, "]/mesh_terms/mesh_term")) %>% xml_text()) > 0){
    mesh_terms <- list(xml_find_all(xml, paste("//Publication[pubmed_id=", id, "]/mesh_terms/mesh_term")) %>% xml_text())
  }else{
    mesh_terms <- 'N/A'
  }
  
  # keywords
  if(length(xml_find_all(xml, paste("//Publication[pubmed_id=", id, "]/keywords/keyword")) %>% xml_text()) > 0){
    keywords <- list(xml_find_all(xml, paste("//Publication[pubmed_id=", id, "]/keywords/keyword")) %>% xml_text())
  }else{
    keywords <- 'N/A'
  }
  
  # title
  if(length(xml_find_all(xml, paste("//Publication[pubmed_id=", id, "]/title")) %>% xml_text()) > 0){
    title <- xml_find_all(xml, paste("//Publication[pubmed_id=", id, "]/title")) %>% xml_text()
  }else{
    title <- 'N/A'
  }
  
  # abstract
  if(length(xml_find_all(xml, paste("//Publication[pubmed_id=", id, "]/abstract")) %>% xml_text()) > 0){
    abstract <- list(xml_find_all(xml, paste("//Publication[pubmed_id=", id, "]/abstract")) %>% xml_text())
  }else{
    abstract <- 'N/A'
  }
  # authors
  if(length(xml_find_all(xml, paste("//Publication[pubmed_id=", id, "]/authors")) %>% xml_text()) > 0){
    authors <- list(xml_find_all(xml, paste("//Publication[pubmed_id=", id, "]/authors")) %>% xml_text())
  }else{
    authors <- 'N/A'
  }
  
  # author_affiliations
  if(length(xml_find_all(xml, paste("//Publication[pubmed_id=", id, "]/author_affiliations")) %>% xml_text()) > 0){
    author_affiliations <- list(xml_find_all(xml, paste("//Publication[pubmed_id=", id, "]/author_affiliations")) %>% xml_text())
  }else{
    author_affiliations <- 'N/A'
  }
  
  # references
  if(length(xml_find_all(xml, paste("//Publication[pubmed_id=", id, "]/doi_references/doi_reference")) %>% xml_text()) > 0){
    doi_references <- list(xml_find_all(xml, paste("//Publication[pubmed_id=", id, "]/doi_references/doi_reference")) %>% xml_text())
  }else{
    doi_references <- 'N/A'
  }
  
  if(length(xml_find_all(xml, paste("//Publication[pubmed_id=", id, "]/pubmed_references/pubmed_reference")) %>% xml_text()) > 0){
    pubmed_references <- list(xml_find_all(xml, paste("//Publication[pubmed_id=", id, "]/pubmed_references/pubmed_reference")) %>% xml_text())
  }else{
    pubmed_references <- 'N/A'
  }
  
  if(length(xml_find_all(xml, paste("//Publication[pubmed_id=", id, "]/pmc_references/pmc_reference")) %>% xml_text()) > 0){
    pmc_references <- list(xml_find_all(xml, paste("//Publication[pubmed_id=", id, "]/pmc_references/pmc_reference")) %>% xml_text())
  }else{
    pmc_references <- 'N/A'
  }
  
  as.data.frame(cbind(pubmed_id=pubmed_id,
                      pmc_id=pmc_id,
                      doi=doi,
                      pub_type=pub_type,
                      accepted_date=accepted_date,
                      pubdate=pubdate,
                      major_mesh=major_mesh,
                      mesh_terms=mesh_terms,
                      keywords=keywords,
                      title=title,
                      abstract=abstract,
                      authors=authors,
                      author_affiliations=author_affiliations,
                      doi_references=doi_references,
                      pubmed_references=pubmed_references,
                      pmc_references=pmc_references)
  )
}

# Run function to get details
pmdd_entrez_clean_list <- lapply(pmid_list, get_details)
pmdd_entrez_raw_df <- as.data.frame(do.call("rbind", pmdd_entrez_clean_list), stringsAsFactors = FALSE)

# Clean data frame to unnest select fields and remove added '\t'
pmdd_entrez_clean_df <- pmdd_entrez_raw_df %>% 
  unnest(c(pubmed_id, pmc_id, doi, accepted_date, pubdate, title)) %>% 
  mutate(
    pubmed_id = str_squish(pubmed_id),
    pmc_id = str_squish(pmc_id),
    doi = str_squish(doi),
    accepted_date = as.Date(str_squish(accepted_date)),
    pubdate = str_squish(pubdate)
         )

### Import data frame into DuckDB database ###

# Connect to DuckDB database
database_path <- file.path("data", "pmdd.db")

con <- dbConnect(duckdb(), dbdir = database_path)

# Ensure databse connection is closed when closing this notebook
#on.exit(dbDisconnect(con), add = TRUE)

# Register data frame as DuckDB table
dbWriteTable(con, "entrez_clean_df", pmdd_entrez_clean_df)

# Close connection to database
duckdb_shutdown(duckdb())



