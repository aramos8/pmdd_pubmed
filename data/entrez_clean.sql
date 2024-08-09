-- This query imports the data from the JSON file converted from the XML file obtained from NCBI using Entrez.
-- Multiple CTEs are used in this model to make it easier to read. 

CREATE OR REPLACE TABLE entrez_clean AS 
WITH 
-- First, we load the JSON file in the unnest CTE
unnest AS (
        SELECT 
            UNNEST(Set.Publication, max_depth := 3)
        FROM read_json('pmdd_entrez.json')
    ),

--The JSON file obtained from ENTREZ results in inconsistent field formats. For the same column, there coulb be arrays and objects
--- To fix this, this CTE uses case statements to turn JSON OBJECTs into ARRAYs
even_nesting AS (
    SELECT 
        pubmed_id,
        pmc_id,
        doi,
        CASE WHEN JSON_TYPE(type) != 'ARRAY' THEN ARRAY_AGG(type) OVER (PARTITION BY pubmed_id) ELSE type END AS pub_type,
        sub_date,
        CAST(accepted_date AS DATE) AS accepted_date,
        pubdate,
        CASE WHEN JSON_TYPE(major_mesh_term) != 'ARRAY' THEN ARRAY_AGG(major_mesh_term) OVER (PARTITION BY pubmed_id) ELSE major_mesh_term END AS major_mesh,
        mesh_term AS mesh_terms,
        CASE WHEN JSON_TYPE(keyword) != 'ARRAY' THEN ARRAY_AGG(keyword) OVER (PARTITION BY pubmed_id) ELSE keyword END AS keywords,
        title,
        CASE WHEN JSON_TYPE(abstract) != 'ARRAY' THEN ARRAY_AGG(abstract) OVER (PARTITION BY pubmed_id) ELSE abstract END AS abstract,
        --CASE WHEN JSON_TYPE(author_full) != 'ARRAY' THEN ARRAY_AGG(author_full) OVER (PARTITION BY pubmed_id) ELSE author_full END AS authors,
        CASE WHEN JSON_TYPE(author) != 'ARRAY' THEN ARRAY_AGG(author) OVER (PARTITION BY pubmed_id) ELSE author END AS authors,
        CASE WHEN JSON_TYPE(author_id) != 'ARRAY' THEN ARRAY_AGG(author_id) OVER (PARTITION BY pubmed_id) ELSE author_id END AS author_ids,
        CASE WHEN JSON_TYPE(affiliation) != 'ARRAY' THEN ARRAY_AGG(affiliation) OVER (PARTITION BY pubmed_id) ELSE affiliation END AS author_affiliations,
        CASE WHEN JSON_TYPE(doi_reference) != 'ARRAY' THEN ARRAY_AGG(doi_reference) OVER (PARTITION BY pubmed_id) ELSE doi_reference END AS doi_references,
        pubmed_reference,
        pmc_reference
    FROM unnest
),

-- Once the data is loaded and uniform, we cast the remaining JSON fields as VARCHAR
casting AS (
    SELECT
        pubmed_id,    
        pmc_id,
        doi,
        CAST(pub_type AS VARCHAR[]) AS pub_type,
        sub_date,
        CAST(accepted_date AS DATE) AS accepted_date,
        pubdate,
        CAST(LEFT(pubdate,4) AS INT64) AS pub_year,
        CAST(major_mesh AS VARCHAR[]) AS major_mesh,
        CAST(mesh_terms AS VARCHAR[]) AS mesh_terms,
        CAST(keywords AS VARCHAR[]) AS keywords,
        title,
        CAST(abstract AS VARCHAR[]) AS abstract,
        CAST(authors AS VARCHAR[]) AS authors,
        CAST(author_ids AS VARCHAR[]) AS author_ids,
        CAST(author_affiliations AS VARCHAR[]) AS author_affiliations,
        CAST(doi_references AS VARCHAR[]) AS doi_references,
        CAST(pubmed_reference AS VARCHAR[]) AS pubmed_references,
        CAST(pmc_reference AS VARCHAR[]) AS pmc_references
    FROM even_nesting
),

-- With the data in good shape, we can now parse the authors details
authors_details_cte AS (
    SELECT DISTINCT
        pubmed_id,
        ARRAY_AGG(STRUCT_PACK(author_name, author_id, author_affiliation, author_index)) AS author_details,
    FROM (
        SELECT 
            * EXCLUDE(authors),
            ARRAY_POSITION(authors, author_name) AS author_index,
        FROM (
            SELECT 
                pubmed_id,
                authors,
                UNNEST(authors) AS author_name,
                UNNEST(author_affiliations) AS author_affiliation,
                UNNEST(author_ids) AS author_id
            FROM casting
            )
        )
        GROUP BY pubmed_id
),

clean_abstract AS (
    SELECT DISTINCT
        pubmed_id,
        STRING_AGG(abstracts.abstract) OVER (PARTITION BY pubmed_id) AS abstract
    FROM casting, UNNEST(abstract) as abstracts
),

clean_references AS (
    SELECT
        pubmed_id,
        ARRAY_AGG(DISTINCT ref) AS all_references 
    FROM 
        (SELECT DISTINCT
            pubmed_id,
            unnest.doi_references AS ref
        FROM casting, UNNEST(doi_references) AS unnest
        
        UNION ALL 

        SELECT DISTINCT
            pubmed_id,
            unnest.pubmed_references AS ref
        FROM casting, UNNEST(pubmed_references) AS unnest

        UNION ALL 

        SELECT DISTINCT
            pubmed_id,
            unnest.pmc_references AS ref
        FROM casting, UNNEST(pmc_references) AS unnest
        )
    GROUP BY pubmed_id
)

SELECT 
    pubmed_id,
    pmc_id,
    doi,
    pub_type,
    sub_date,
    accepted_date,
    pubdate,
    CASE WHEN EXTRACT(YEAR FROM accepted_date) IS NULL THEN pub_year ELSE EXTRACT(YEAR FROM accepted_date) END AS publication_year,
    major_mesh,
    mesh_terms,
    keywords,
    title,
    clean_abstract.abstract,
    author_details,
    clean_references.all_references,
    pubmed_references,
    pmc_references,
    doi_references
FROM casting
LEFT JOIN authors_details_cte
USING(pubmed_id)
LEFT JOIN clean_abstract
USING(pubmed_id)
LEFT JOIN clean_references
USING(pubmed_id);


