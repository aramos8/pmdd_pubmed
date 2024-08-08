# Introduction

PMDD (premenstrual dysphoric disorder) is condition affecting menstruating people, both from a psychological perspective and physical perspective. PMDD is characterized by a combination of mood and physical symptoms that occur during the luteal phase of the menstrual cycle, including depression, irritability, joint pain, breast pain, cravings, lethargy, and poor concentration, among others. The condition has had a rather turbulent path to being recognized, with some controversial involvement from big pharma (Moynihan and Cassels, 2005, as cited by [Schroll and Lauritsen, 2022](https://doi.org/10.1111/aogs.14360)). The condition was first introduced into the DSM-III (Diagnostic and Statistical Manual of Mental Disorders, third edition) in 1987 under the name late luteal phase dysphoric disorder (LLPDD); however, after reassessing the symptoms reported by patients the diagnosis criteria was revised and the name premenstrual dysphoric disorder was coined in the DSM-IV in 1993. At this point, the condition was classified as a "condition for further study", and in 2012 it was revised in the DSM-5 edition under the class "depressive disorder". It wasn't until 2019 that PMDD was added to the ICD-11 under code [GA34.41](https://icd.who.int/browse/2024-01/mms/en#1526774088), granting the condition full medical recognition under the WHO. 

As a condition that encompasses both mental heath and the menstrual cycle, PMDD is a disorder that is not discussed widely, and people with PMDD may find a difficult time finding accurate information to educate themselves about the symptoms they may experience and their treatment options. In addition, given its relatively recent introduction to the ICD, the condition is not widely known among clinicians and physicians, so patients are commonly tasked with the responsibility to source literature to share with them to support their treatment, and often diagnosis.

To facilitate visibility to PMDD scientific literature, this project focuses on the extraction of PMDD publication data from PubMed and exploratory analysis of the extracted data. The objective of this project is to get familiar with PubMed data to build an automated dashboard that tracks information that can be leveraged by patients to educate themselves on their condition, and to provide their doctors with literature to discuss treatment options. In addition, with the objective of supporting the scientific community, a web-app will be developed providing a visual map of how the literature focused on PMDD is cited with the objective of facillitating collaboration among research groups. 


## Exploratory Data Analysis

This step of the project will focus on extracting and exploring the PMDD literature data available in PubMed. The objective is to gain an understanding of the available data and what insights may be of interest to include in a dashboard. In this initial step, PMDD data available up until July 30, 2024 will be downloaded from PubMed using Entrez command line tools, modelled using DuckDB, and explored in an R notebook. 

A more comprehensive description of the work will is included in the following steps. 

### 1. Pulling Data from Pubmed using the command line interface for Entrez

The `pmdd_entrez.sh` script is writen based on instructions provided in the [Entrez Direct: E-utilities on the Unix Command Line](https://www.ncbi.nlm.nih.gov/books/NBK179288/#chapter6.Structured_Data) by NCBI. The objective of this script is to collect the desired fields from PubMed in an XML file. 

To pull the data from NCBI, go to the `data` directory and run the following command.  
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

However, there are considerable inconsistencies on how Entrez packs the data into the XML (e.g. varying levels of nesting in the XML, like in the Affiliations field), so instead the data in the XML will be repackaged and will be modelled downstream using SQL. 

*NOTE: The `esearch` portion of the bash script indicates that there are 1371 papers for the query we used. However, after modelling the data there are 1352 papers. Running the following command outputs a list of the PubMed IDs to see if the repackaging of the XML file is causing some drops.*
```
esearch -db pubmed -query "pmdd OR premenstrual dysphoric disorder OR luteal phase dysphoric disorder OR pmdd [MESH]" |\
efetch -format xml |\
xtract -pattern PubmedArticle -element MedlineCitation/PMID > pubmed_ids.csv
```
*The resulting CSV contains the same 1352 pubmed IDs, confirming that the XML repackaging in the bash script is not leading to a drop of articles*

### 2. Converting XML data to JSON

The `pmdd_entrez.sh` bash script outputs the data into an XML format. However, converting the XML file to JSON makes it easier to import the data into a DuckDB local database.

To achieve this format conversion, this pipeline uses [yq](https://github.com/mikefarah/yq). 

Homebrew installation is recommended: 

```
brew install yq
```

Once installed, run the following command in the `data` directory to cary out the conversion: 
```
yq -p=xml -o=json pmdd_entrez.xml > pmdd_entrez.json
```

### 3. Loading the JSON file to DuckDB

Parsing of the JSON file was done using `read_json`, following the advice available in this [GitHub issue](https://github.com/duckdb/duckdb/issues/7015).

### 4. Model the data in DuckDB

After loading the JSON file, the next step is to extract the relevant information and model it in a way that it can serve multiple functions downstream. As such, the PMDD PubMed data in the JSON file was modelled into a denormalized table, which will be used as the main source of data in downstream analyses and visualizations. 

DuckDB's `read_json` function did most of the heavy lifting. All that was left to do was nest all applicable fields (e.g. keywords, MeSH terms, author details) in an easy to process format. This work resulted in table `entrez_clean` which will now be used downstream in R and with further SQL modelling (if required). 

*NOTE: If further modelling using SQL is needed, this project will use `dbt` to manage the dependencies in the ETL pipeline. At the current state of this project, however, only the `entrez_clean` table is used for all downstream calculations in R.*


### 5. Build notebook with visualizations and insights in R

This notebook will provide an exploratory analysis of the PMDD literature data obtained from PubMed. The objective is to get familiar with the data and start coming up with ideas of ways to visualize the data in a dashboard. 

As this is intended as an exploratory part of the project, the PMDD literature data will include all publications available up until July 30, 2024. 

## R Shiny Dashboard (TBD)

The goal is to build a dashboard that helps patients find PMDD literature to educate themselves on the condition, as well as to find literature they would ike to discuss with their doctors. 

This dashboard will be build using R Shiny within a Snakemake workflow. 
