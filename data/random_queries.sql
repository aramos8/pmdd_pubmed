
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
CREATE OR REPLACE TABLE keyword_papers AS 
SELECT
    keyword,
    COUNT(DISTINCT(pubmed_id)) AS pubmed_papers
FROM (SELECT pubmed_id, LOWER(UNNEST(keywords)) AS keyword FROM entrez_clean)
GROUP BY keyword
ORDER BY pubmed_papers DESC;

SELECT 
    *
FROM (SELECT 
        pub_date,
        EXTRACT(YEAR FROM pub_date) AS pub_year,
        pubmed_id,
        kw.keywords AS keyword
    FROM entrez_clean, UNNEST(keywords) AS kw)
ORDER BY keyword;


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



--Papers per year
SELECT 
  pub_date,
  EXTRACT(YEAR FROM pub_date) AS pub_year,
  pubmed_id,
FROM entrez_clean;

SELECT 
  COUNT(DISTINCT(CASE WHEN pub_date IS NOT NULL THEN pubmed_id END)) AS with_date,
  COUNT(DISTINCT(CASE WHEN pub_date IS NULL THEN pubmed_id END)) AS without_date,
  COUNT(DISTINCT(pubmed_id)) AS all
FROM entrez_clean;


SELECT 
    pubmed_id,
    pub_date,
    CASE WHEN pub_date IS NULL THEN 1 ELSE 0 END
FROM entrez_clean
WHERE pubmed_id IN (10414640, 10732657, 17472544);

--Papers per institution
SELECT 
    pubmed_id,
    author.author_details.author_affiliation
FROM entrez_clean, UNNEST(author_details) AS author;




SELECT
    COUNT(DISTINCT pubmed_id) AS all,
    COUNT(DISTINCT(CASE WHEN accepted_date IS NULL THEN pubmed_id END)) AS missing_acc_date,
    COUNT(DISTINCT(CASE WHEN pubdate IS NULL THEN pubmed_id END)) AS missing_pubdate
FROM entrez_clean;


SELECT 
    pubmed_id,
    sub_date,
    accepted_date,
    publication_year,
    title,
    abstract
FROM entrez_clean
WHERE pubmed_id IN (
    SELECT DISTINCT pubmed_id 
    FROM entrez_clean, UNNEST(author_details) AS authors
    WHERE LOWER(authors.author_details.author_affiliation) LIKE '%canada%')
ORDER BY publication_year DESC;


SELECT 
    pubmed_id,
    accepted_date,
    pubdate,
    CAST(LEFT(pubdate,4) AS INT64) AS pub_year
FROM entrez_clean;

SELECT 
    pubmed_id,
    author.author_details.author_affiliation,
    STRING_SPLIT(author.author_details.author_affiliation, ',') [-1]
FROM entrez_clean, UNNEST(author_details) AS author;

SELECT 
    pubmed_id,
    COUNT(DISTINCT(author.author_details.author_name)) AS author_name,
    COUNT(DISTINCT(author.author_details.author_affiliation)) AS author_affiliation,
    COUNT(DISTINCT(CASE WHEN author.author_details.author_affiliation != 'N/A' THEN author.author_details.author_affiliation END)) AS no_na
FROM entrez_clean, UNNEST(author_details) AS author
GROUP BY pubmed_id;

SELECT 
    pubmed_id,
    author.author_details.author_name AS author_name,
    author.author_details.author_affiliation AS author_affiliation,
    author.author_details.author_index AS author_index
FROM entrez_clean, UNNEST(author_details) AS author
ORDER BY pubmed_id, author_index
;