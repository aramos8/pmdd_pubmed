-- This query pulls the fields of interest to build the dashboard

CREATE OR REPLACE TABLE dim_publication_summary AS 

SELECT 
    pubmed_id,
    pmc_id,
    doi,
    title,
    CASE WHEN abstract = 'N/A' THEN 'Not available' ELSE abstract END AS abstract,
    publication_year,
    STRUCT_PACK(stg_keyterms.keyterm, stg_keyterms.keyterm_category) AS keyterms
FROM int_entrez_clean
LEFT JOIN stg_keyterms
USING(pubmed_id)
ORDER BY pubmed_id;