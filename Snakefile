rule download_pmdd_data:
    input: "scripts/etl/pmdd_entrez.sh"
    output: "data/pmdd_entrez.xml"
    shell: "bash scripts/etl/pmdd_entrez.sh"

rule extract_xml:
    input: "data/pmdd_entrez.xml"
    output: "data/pmdd.db"
    shell: "Rscript scripts/etl/stg_entrez_clean.R"

rule transform_data:
    input: "data/pmdd.db"
    output: "scripts/dashboard/dim_publication_summary.csv"
    shell: 
        """
        duckdb data/pmdd.db < scripts/etl/int_entrez_clean.sql
        duckdb data/pmdd.db < scripts/etl/stg_keyterms.sql
        duckdb data/pmdd.db < scripts/etl/dim_publication_summary.sql
        """
        
rule deploy_app:
    input: 
        "scripts/dashboard/dim_publication_summary.csv"
    shell: 
        """
        R -e 'shiny::runApp("app.R", port = 3838)'
        """

