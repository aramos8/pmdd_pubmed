-- This query pulls all the keywords, MeSH terms and chemicals from int_entrez_clean and creates a new list of keyterms

CREATE OR REPLACE TABLE stg_keyterms AS 

-- Get all keyterms and assign category
--- A singular version of the keyterm is generated to facilitate consolidation of similar terms downstream
WITH unnest AS (
    SELECT 
        pubmed_id,
        UNNEST(keywords) AS keyterm,
        regexp_replace(UNNEST(keywords), 's$', '') AS singular_keyterm,
        CASE 
            WHEN LOWER(UNNEST(keywords)) LIKE '%drug therapy%' THEN 'Drug Therapy'
            WHEN LOWER(UNNEST(keywords)) LIKE '%pharmacotherapy%' THEN 'Drug Therapy'
            WHEN LOWER(UNNEST(keywords)) LIKE '%hormone%therapy' THEN 'Drug Therapy'
            WHEN LOWER(UNNEST(keywords)) LIKE '%estrogen%therapy' THEN 'Drug Therapy'
            WHEN LOWER(UNNEST(keywords)) LIKE '%chemotherapy%' THEN 'Drug Therapy'
            WHEN LOWER(UNNEST(keywords)) LIKE '%phytotherapy%' THEN 'Drug Therapy'
            WHEN LOWER(UNNEST(keywords)) LIKE '%radiotherapy%' THEN 'Drug Therapy'
            WHEN LOWER(UNNEST(keywords)) LIKE '%exercise%' THEN 'Non-Drug Therapy'
            WHEN LOWER(UNNEST(keywords)) LIKE '%therapy%' THEN 'Non-Drug Therapy'
            WHEN LOWER(UNNEST(keywords)) LIKE '%stimulation%' THEN 'Non-Drug Therapy'
            WHEN LOWER(UNNEST(keywords)) LIKE '%symptom%' THEN 'Symptoms'
            WHEN LOWER(UNNEST(keywords)) LIKE '%food crav%' THEN 'Symptoms'
            WHEN LOWER(UNNEST(keywords)) LIKE '%depression%' THEN 'Symptoms'
            WHEN LOWER(UNNEST(keywords)) LIKE '%dizz%' THEN 'Symptoms'
            WHEN LOWER(UNNEST(keywords)) LIKE '%headache%' THEN 'Symptoms'
            WHEN LOWER(UNNEST(keywords)) LIKE '%irritab%' THEN 'Symptoms'
            WHEN LOWER(UNNEST(keywords)) LIKE '%anxiety%' THEN 'Symptoms'
            WHEN LOWER(UNNEST(keywords)) LIKE '%sleep%' THEN 'Symptoms'
            WHEN LOWER(UNNEST(keywords)) LIKE '%pain%' THEN 'Symptoms'
            WHEN LOWER(UNNEST(keywords)) LIKE '%fatigue%' THEN 'Symptoms'
            WHEN LOWER(UNNEST(keywords)) LIKE '%impuls%' THEN 'Symptoms'
            WHEN LOWER(UNNEST(keywords)) LIKE '%dysmenorrhea%' THEN 'Symptoms'
            WHEN LOWER(UNNEST(keywords)) LIKE '%negativ%' THEN 'Symptoms'
            WHEN LOWER(UNNEST(keywords)) LIKE '%memory%' THEN 'Symptoms'
            WHEN LOWER(UNNEST(keywords)) LIKE 'suicid%' THEN 'Symptoms'
        END AS keyterm_category
    FROM int_entrez_clean

    UNION ALL 

    SELECT 
        pubmed_id,
        UNNEST(mesh_terms) AS keyterm,
        regexp_replace(UNNEST(mesh_terms), 's$', '') AS singular_keyterm,
        CASE 
            WHEN LOWER(UNNEST(mesh_terms)) LIKE '%drug therapy%' THEN 'Drug Therapy'
            WHEN LOWER(UNNEST(mesh_terms)) LIKE '%pharmacotherapy%' THEN 'Drug Therapy'
            WHEN LOWER(UNNEST(mesh_terms)) LIKE '%hormone%therapy' THEN 'Drug Therapy'
            WHEN LOWER(UNNEST(mesh_terms)) LIKE '%estrogen%therapy' THEN 'Drug Therapy'
            WHEN LOWER(UNNEST(mesh_terms)) LIKE '%chemotherapy%' THEN 'Drug Therapy'
            WHEN LOWER(UNNEST(mesh_terms)) LIKE '%phytotherapy%' THEN 'Drug Therapy'
            WHEN LOWER(UNNEST(mesh_terms)) LIKE '%radiotherapy%' THEN 'Drug Therapy'
            WHEN LOWER(UNNEST(mesh_terms)) LIKE '%exercise%' THEN 'Non-Drug Therapy'
            WHEN LOWER(UNNEST(mesh_terms)) LIKE '%therapy%' THEN 'Non-Drug Therapy'
            WHEN LOWER(UNNEST(mesh_terms)) LIKE '%stimulation%' THEN 'Non-Drug Therapy'
            WHEN LOWER(UNNEST(mesh_terms)) LIKE '%symptom%' THEN 'Symptoms'
            WHEN LOWER(UNNEST(mesh_terms)) LIKE '%food crav%' THEN 'Symptoms'
            WHEN LOWER(UNNEST(mesh_terms)) LIKE '%depression%' THEN 'Symptoms'
            WHEN LOWER(UNNEST(mesh_terms)) LIKE '%dizz%' THEN 'Symptoms'
            WHEN LOWER(UNNEST(mesh_terms)) LIKE '%headache%' THEN 'Symptoms'
            WHEN LOWER(UNNEST(mesh_terms)) LIKE '%irritab%' THEN 'Symptoms'
            WHEN LOWER(UNNEST(mesh_terms)) LIKE '%anxiety%' THEN 'Symptoms'
            WHEN LOWER(UNNEST(mesh_terms)) LIKE '%sleep%' THEN 'Symptoms'
            WHEN LOWER(UNNEST(mesh_terms)) LIKE '%pain%' THEN 'Symptoms'
            WHEN LOWER(UNNEST(mesh_terms)) LIKE '%fatigue%' THEN 'Symptoms'
            WHEN LOWER(UNNEST(mesh_terms)) LIKE '%impuls%' THEN 'Symptoms'
            WHEN LOWER(UNNEST(mesh_terms)) LIKE '%dysmenorrhea%' THEN 'Symptoms'
            WHEN LOWER(UNNEST(mesh_terms)) LIKE '%negativ%' THEN 'Symptoms'
            WHEN LOWER(UNNEST(mesh_terms)) LIKE '%memory%' THEN 'Symptoms'
            WHEN LOWER(UNNEST(mesh_terms)) LIKE 'suicid%' THEN 'Symptoms'
        END AS keyterm_category
    FROM int_entrez_clean

    UNION ALL 

    SELECT 
        pubmed_id,
        UNNEST(chemicals) AS keyterm,
        regexp_replace(UNNEST(chemicals), 's$', '') AS singular_keyterm,
        CASE WHEN UNNEST(chemicals) != 'N/A' THEN 'Drug Therapy' END AS keyterm_category
    FROM int_entrez_clean
),

clean_1 AS (
    SELECT 
        pubmed_id,
        keyterm,
        CASE 
            WHEN LOWER(singular_keyterm) IN (SELECT DISTINCT LOWER(keyterm) FROM unnest) THEN singular_keyterm
            ELSE keyterm
        END AS keyterm_clean
    FROM unnest
    WHERE keyterm != 'N/A'
),

clean_2 AS (
    SELECT 
        pubmed_id,
        keyterm,
        CASE
            WHEN keyterm_clean IN ('PMDD/PMS', 'PMS/PMDD', 'PMS/premenstrual dysphoric disorder') THEN 'PMS/PMDD'
            WHEN keyterm_clean IN ('GABAA-receptor', 'GABAA receptor', 'GABA(A) receptor', 'GABAAR', 'GABA-AR') THEN 'GABAA receptor'
            WHEN LOWER(keyterm_clean) LIKE ('%premenstrual dysphoric disorder%') THEN 'PMDD'
            WHEN LOWER(keyterm_clean) LIKE ('%premenstrual dysphoric syndrome%') THEN 'PMDD'
            WHEN LOWER(keyterm_clean) LIKE ('%premenstrual syndrome%') THEN 'PMS'
            WHEN LOWER(keyterm_clean) IN ('combined oral contraceptive pills (cocps)', 'combined oral contraceptive pill') THEN 'Combined Oral Contraceptive Pills (COCPS)'
            WHEN LOWER(keyterm_clean) LIKE ('cognitive%behavio%ral therapy') OR LOWER(keyterm_clean) = 'Thérapie cognitive et comportementale' THEN 'Cognitive Behavioral Therapy'
            WHEN LOWER(keyterm_clean) LIKE '%ssri%' THEN 'SSRI'
            WHEN LOWER(keyterm_clean) LIKE '%serotonin%uptake inhibitor%' THEN 'SSRI'
            WHEN LOWER(keyterm_clean) LIKE 'serotonin%nor%ine re%uptake inhibitor%' THEN 'SNRI'
            ELSE keyterm_clean
        END AS keyterm_clean,
        ARRAY_AGG(keyterm) OVER (PARTITION BY LOWER(keyterm_clean)) AS terms,
    FROM clean_1
),

clean_3 AS (
    SELECT DISTINCT
        clean_2.pubmed_id,
        MIN(keyterm_clean) OVER (PARTITION BY terms) AS keyterm,
        unnest.keyterm_category
    FROM clean_2
    LEFT JOIN unnest 
    ON clean_2.pubmed_id = unnest.pubmed_id
    AND (clean_2.keyterm = unnest.keyterm OR clean_2.keyterm = unnest.singular_keyterm)
    AND unnest.keyterm_category IS NOT NULL
)

SELECT DISTINCT
    * EXCLUDE(keyterm_category),
    COALESCE(MAX(keyterm_category) OVER (PARTITION BY keyterm), 'Other') AS keyterm_category
FROM clean_3
;
