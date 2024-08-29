CREATE OR REPLACE TABLE int_entrez_clean AS 
WITH 
authors_details_cte AS (
    SELECT DISTINCT
        pubmed_id,
        ARRAY_AGG(STRUCT_PACK(author_name, author_affiliation, author_index)) AS author_details,
    FROM (
        SELECT DISTINCT
            * EXCLUDE(authors),
            ARRAY_POSITION(authors, author_name) AS author_index,
        FROM (
            SELECT DISTINCT
                pubmed_id,
                authors,
                UNNEST(authors) AS author_name,
                UNNEST(author_affiliations) AS author_affiliation
            FROM stg_entrez_clean
            )
        )
        GROUP BY pubmed_id
),

clean_abstract AS (
    SELECT 
    pubmed_id,
    abstract
    FROM (
        SELECT DISTINCT
            pubmed_id,
            STRING_AGG(abst) OVER (PARTITION BY pubmed_id ORDER BY _index) AS abstract,
            STRLEN(abstract) AS abstract_length
        FROM (
            SELECT 
                pubmed_id,
                abst,
                ARRAY_POSITION(abstract, abst) AS _index
            FROM (
                SELECT 
                    pubmed_id,
                    abstract,
                    UNNEST(abstract) AS abst
                FROM stg_entrez_clean
                )
            )
        )
    QUALIFY ROW_NUMBER() OVER (PARTITION BY pubmed_id ORDER BY abstract_length DESC) = 1 
),

clean_references AS (
    SELECT
        pubmed_id,
        ARRAY_AGG(DISTINCT ref) AS all_references 
    FROM 
        (SELECT DISTINCT
            pubmed_id,
            unnest.doi_references AS ref
        FROM stg_entrez_clean, UNNEST(doi_references)
        
        UNION ALL 

        SELECT DISTINCT
            pubmed_id,
            unnest.pubmed_references AS ref
        FROM stg_entrez_clean, UNNEST(pubmed_references)

        UNION ALL 

        SELECT DISTINCT
            pubmed_id,
            unnest.pmc_references AS ref
        FROM stg_entrez_clean, UNNEST(pmc_references)
        )
    GROUP BY pubmed_id
)

SELECT DISTINCT
    pubmed_id,
    pmc_id,
    doi,
    pub_type,
    accepted_date,
    pubdate,
    CASE WHEN EXTRACT(YEAR FROM accepted_date) IS NULL THEN (CASE WHEN pubdate = '' THEN NULL ELSE CAST(LEFT(pubdate,4) AS INT64) END) ELSE EXTRACT(YEAR FROM accepted_date) END AS publication_year,
    CASE WHEN pubdate = '' THEN NULL ELSE CAST(LEFT(pubdate,4) AS INT64) END AS pub_year,
    major_mesh,
    mesh_terms,
    keywords,
    chemicals,
    title,
    clean_abstract.abstract,
    author_details,
    clean_references.all_references,
    pubmed_references,
    doi_references,
    pmc_references
FROM stg_entrez_clean
LEFT JOIN authors_details_cte
USING(pubmed_id)
LEFT JOIN clean_abstract
USING(pubmed_id)
LEFT JOIN clean_references
USING(pubmed_id)
;