# ETL

This directory contains scripts used to extract, transform and load the PMDD data obtained from Pubmed. 

1. `pmdd_entrez.sh` - downloads PMDD data from Pubmed (outputs an XML file)
1. `stg_entrez_clean.R` - extracts fields of interest from the XML file obtained from Pubmed and loads the processed data into the `pmdd.db` database. 
1. `*.sql` - SQL queries used to model the data as needed. The final table, `dim_publication_summary` is then exported as a `.csv` file into the `scripts/dashboard/` directory to load into the dashboard. 