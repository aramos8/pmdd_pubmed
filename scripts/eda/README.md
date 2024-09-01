# Exploratory Data Analysis

This step of the project is focused on extracting and exploring the PMDD literature data available in PubMed. The objective is to gain an understanding of the available data and what insights may be of interest to include in a dashboard. In this initial step, PMDD data available up until July 30, 2024 was downloaded from PubMed using Entrez command line tools, modelled using DuckDB, and explored in an R notebook ([scripts/eda/pmdd_literature_exploration.Rmd](https://github.com/aramos8/pmdd_pubmed/blob/main/scripts/eda/pmdd_literature_exploration.Rmd)). 

A more comprehensive description of the work is included in the following steps. 

## Introduction to PMDD

PMDD (premenstrual dysphoric disorder) is a condition affecting menstruating people, both from a psychological perspective and physical perspective. PMDD is characterized by a combination of mood and physical symptoms that occur during the luteal phase of the menstrual cycle, including depression, irritability, joint pain, breast pain, cravings, lethargy, and poor concentration, among others. The condition has had a rather turbulent path to being recognized, with some controversial involvement from big pharma (Moynihan and Cassels, 2005, as cited by [Schroll and Lauritsen, 2022](https://doi.org/10.1111/aogs.14360)). PMDD was first introduced into the DSM-III (Diagnostic and Statistical Manual of Mental Disorders, third edition) in 1987 under the name late luteal phase dysphoric disorder (LLPDD); however, after reassessing the symptoms reported by patients the diagnosis criteria was revised and the name premenstrual dysphoric disorder was coined in the DSM-IV in 1993. At this point, the condition was classified as a "Condition for further study", and in 2012 it was [revised in the DSM-5](https://www.ncbi.nlm.nih.gov/books/NBK519704/table/ch3.t24) edition under the class "Depressive Disorder". It wasn't until 2019 that PMDD was added to the ICD-11 under code [GA34.41](https://icd.who.int/browse/2024-01/mms/en#1526774088), granting the condition full medical recognition. 

As a condition that encompasses both mental heath and the menstrual cycle, PMDD is a disorder that is not discussed widely, and people with PMDD may find a difficult time finding accurate information to educate themselves about the symptoms they may experience and their treatment options. In addition, given its relatively recent introduction to the ICD, the condition is not widely known among clinicians and physicians, so patients are commonly tasked with the responsibility to source literature to share with them to support their treatment, and often diagnosis.

To facilitate visibility of PMDD scientific literature, this project focuses on the extraction of PMDD publication data from PubMed and exploratory analysis of the extracted data. The objective of this project is to get familiar with PubMed data to build an automated dashboard that tracks information that can be leveraged by patients to educate themselves on their condition, and to provide their doctors with literature to discuss treatment options. In addition, with the objective of supporting the scientific community, a web-app will be developed providing a visual map of how the literature focused on PMDD is cited with the objective of facilitating collaboration among research groups. 

## Analysis

### 1. Pulling Data from Pubmed using the command line interface for Entrez

The `pmdd_entrez.sh` script is written based on instructions provided in the [Entrez Direct: E-utilities on the Unix Command Line](https://www.ncbi.nlm.nih.gov/books/NBK179288/#chapter6.Structured_Data) by NCBI. The objective of this script is to collect the desired fields from PubMed in an XML file. 

To pull the data from NCBI, go to the `scripts` directory and run the following command.  
```
bash pmdd_entrez.sh
```

- The query used to pull the data is `pmdd OR premenstrual dysphoric disorder OR luteal phase dysphoric disorder OR pmdd [MESH]`
- Output file: `pmdd_entrez.xml`

Parsing the raw XML directly was explored by calling: 
```
esearch -db pubmed -query "pmdd OR premenstrual dysphoric disorder OR pmdd [MESH]" |\
efetch -format xml
```

However, there are considerable inconsistencies on how Entrez packs the data into the XML (e.g. varying levels of nesting in the XML, like in the Affiliations field), so instead the data in the XML will be repackaged and will be modelled downstream using SQL and R. 

*NOTE: The `esearch` portion of the bash script indicates that there are 1371 papers for the query we used. However, after modelling the data there are 1352 papers. Running the following command outputs a list of the PubMed IDs to see if the repackaging of the XML file is causing some drops.*
```
esearch -db pubmed -query "pmdd OR premenstrual dysphoric disorder OR luteal phase dysphoric disorder OR pmdd [MESH]" |\
efetch -format xml |\
xtract -pattern PubmedArticle -element MedlineCitation/PMID > pubmed_ids.csv
```
*The resulting CSV contains the same 1352 pubmed IDs, confirming that the XML repackaging in the bash script is not leading to a drop of articles*


#### Additional data from PMC

While exploring the data, it was clear that some publications do not include the keywords through PubMed, but they do through PMC. Therefore, PMC data was bulk downloaded in XML format following the steps indicated by NCBI's [FTP Service](https://www.ncbi.nlm.nih.gov/pmc/tools/ftp/#bulk). 

*Please note that while PMC provides open access for users to read publications, bulk download of PMC data is only allowed via NCBI approved retrieval methods (see [here](https://www.ncbi.nlm.nih.gov/pmc/tools/openftlist/) for more details)*

PMC data was downloaded using their FTP service, using the following command line prompt:
```
wget --accept "*xml*" --reject "*.txt" --no-directories --recursive --no-parent \
ftp://ftp.ncbi.nlm.nih.gov/pub/pmc/oa_bulk/
```

With all `.tar.gz` files available in an external drive, the data is then read in R using the `archive_read` function from the `archive` package. 

After extractracting the keywords from the publications downloaded from PMC, only 22 out of the 150 identified papers included keywords, corresponding to less than 2% of all the PMDD publications explored. Therefore, PMC keywords will not be included in this report.


### 2. Extracting XML data

The `pmdd_entrez.sh` bash script outputs the data into an XML format. However, importing the XML directly into DuckDB was not readily available. Therefore, in this project the data in the XML file obtained from Pubmed is extracted using the `xml2` package in R. 

This step is accomplished by the `pmdd_entrez.R` script, which includes a function to extract the data from the XML, imports the data into a data frame, and then does a bit of cleaning of the resulting data frame. Lastly, the cleaned data frame is imported to the `pmdd.db` database as `entrez_clean_df`.

### 3. Model the data in DuckDB

The local [DuckDB](https://duckdb.org/docs/) database `pmdd.db` was built and included in the `/data` directory of this repository (not synced to GitHub due to size limitations). 

Most of the necessary data cleaning steps were done in `pmdd_entrez.R`, and final modeling steps were done in `pmdd_entrez.sql` found in the `/scripts` directory (e.g. repackaging author details, combining all references into single field, combining all abstract pieces into single paragraph). The resulting table was saved as `entrez_clean` in the database.

*NOTE: If further modelling using SQL is needed, this project will use [`dbt`](https://docs.getdbt.com) to manage the dependencies in the ETL pipeline. At the current state of this project, however, only the `entrez_clean` table is used for all downstream calculations in R.*


### 4. Build notebook with visualizations and insights in R

This notebook provides an exploratory analysis of the PMDD literature data obtained from PubMed. The objective is to get familiar with the data and start coming up with ideas of ways to visualize the data in a dashboard. 

As this is intended as an exploratory part of the project, the PMDD literature data will include all publications available up until July 30, 2024. 


