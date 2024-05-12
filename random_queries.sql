
SELECT pubmed_id, authors
FROM entrez_clean;
WHERE pubmed_id IN (32023366, 34035477, 35574174, 36317488, 1496412);

-- How many keywords and MeSH terms are used in the PMDD literature
SELECT
    COUNT(DISTINCT(k.keyword)) as keyword_count,
    COUNT(DISTINCT(m.mesh)) as mesh_count
FROM entrez_clean
LEFT JOIN (SELECT pubmed_id, keyword FROM entrez_clean, UNNEST(keywords) AS keyword) AS k
    USING(pubmed_id)
LEFT JOIN (SELECT pubmed_id, mesh FROM entrez_clean, UNNEST(mesh_terms) AS mesh) AS m
    USING(pubmed_id);

--What keyword is used in most PMDD papers? 
SELECT
    keyword,
    COUNT(DISTINCT(pubmed_id)) AS pubmed_papers
FROM (SELECT pubmed_id, LOWER(UNNEST(keywords)) AS keyword FROM entrez_clean)
GROUP BY keyword
ORDER BY pubmed_papers DESC;

--What MeSH term is used in most PMDD papers? 
SELECT
    mesh,
    COUNT(DISTINCT(pubmed_id)) AS pubmed_papers
FROM (SELECT pubmed_id, LOWER(UNNEST(mesh_terms)) AS mesh FROM entrez_clean)
GROUP BY mesh
ORDER BY pubmed_papers DESC;


-- Who are the most prolific authors?
SELECT 
    unn.author_details.author_name,
    unn.author_details.author_id,
    COUNT(DISTINCT(pubmed_id)) AS pubmed_papers,
FROM entrez_clean, UNNEST(author_details) AS unn
GROUP BY unn.author_details.author_name, unn.author_details.author_id
ORDER BY pubmed_papers DESC;

--Which institution produced the most papers on PMDD?
SELECT 
    unn.author_details.author_affiliation,
    COUNT(DISTINCT(pubmed_id)) AS pubmed_papers,
FROM entrez_clean, UNNEST(author_details) AS unn
GROUP BY unn.author_details.author_affiliation
ORDER BY pubmed_papers DESC;

--Are there institutions in Canada working on PMDD?
SELECT 
    unn.author_details.author_affiliation,
    COUNT(DISTINCT(pubmed_id)) AS pubmed_papers,
FROM entrez_clean, UNNEST(author_details) AS unn
WHERE LOWER(unn.author_details.author_affiliation) LIKE '%canada%'
GROUP BY unn.author_details.author_affiliation
ORDER BY pubmed_papers DESC;

--Are there institutions in Toronto working on PMDD?
SELECT 
    unn.author_details.author_affiliation,
    COUNT(DISTINCT(pubmed_id)) AS pubmed_papers,
FROM entrez_clean, UNNEST(author_details) AS unn
WHERE LOWER(unn.author_details.author_affiliation) LIKE '%toronto%'
GROUP BY unn.author_details.author_affiliation
ORDER BY pubmed_papers DESC;


WITH json AS 
    (SELECT 
        UNNEST(Set.Publication, max_depth := 3)
    FROM read_json('pmdd_entrez.json'))
SELECT COUNT(DISTINCT(pubmed_id)) FROM json


SELECT DISTINCT *
FROM read_csv(pubmed_ids.csv)

esearch -db pubmed -query "pmdd OR premenstrual dysphoric disorder OR luteal phase dysphoric disorder OR pmdd [MESH]" |\
efetch -format xml |\
xtract -pattern PubmedArticle -element MedlineCitation/PMID > pubmed_ids.csv