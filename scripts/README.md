## ETL

This directory contains scripts used to extract, transform and load the PMDD data obtained from Pubmed. 

1. `pmdd_entrez.sh` - downloads PMDD data from Pubmed (outputs an XML file)

```{bash}
bash scripts/etl/pmdd_entrez.sh
```

1. `stg_entrez_clean.R` - extracts fields of interest from the XML file obtained from Pubmed and loads the processed data into the `pmdd.db` database. 
```{bash}
Rscript scripts/etl/stg_entrez_clean.R
```

1. `*.sql` - SQL queries used to model the data as needed. The final table, `dim_publication_summary` is then exported as a `.csv` file into the `scripts/dashboard/` directory to load into the dashboard. 

```{bash}
duckdb data/pmdd.db < scripts/etl/int_entrez_clean.sql
duckdb data/pmdd.db < scripts/etl/stg_keyterms.sql
duckdb data/pmdd.db < scripts/etl/dim_publication_summary.sql
```

1. Run `app.R`

```{bash}
R -e "shiny::runApp('app.R', port = 3838)"
```

