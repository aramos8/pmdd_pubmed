# Documentation

This README is intended to keep track of the general plan for this work. In the beginning, the pipeline will consist of a series of separate files, and later, as I get more familiar with working with R and Entrez, I will build the pipeline with an orchestrator and/or Snakemake. 

However, during these initial stages of this project, I want to make sure I keep track of how I am doing the work


## Plan

### 1. Pull Data from Pubmed using the command line interface for Entrez

The `pmdd_entrez.sh` script was writen based on instructions provided in the [Entrez Direct: E-utilities on the Unix Command Line](https://www.ncbi.nlm.nih.gov/books/NBK179288/#chapter6.Structured_Data) provided by NCBI. The objective of this script is to collect the desired fields from PubMed in an XML file. 

To pull the data from NCBI, simply run the following command.  
```
bash pmdd_entrez.sh
```

- The query used to pull the data is `pmdd OR premenstrual dysphoric disorder OR luteal phase dysphoric disorder OR pmdd [MESH]`
- Output file: `pmdd_entrez.xml`

I explored the possibility of parsing the raw XML directly by calling: 
```
esearch -db pubmed -query "pmdd OR premenstrual dysphoric disorder OR pmdd [MESH]" |\
efetch -format xml
```
However, there are a lot of inconsistencies on how Entrez packs the data into the XML (e.g. varying levels of nesting in the XML, like in the Affiliations field), so I found it easier to model the data downstream when I repackaged the XML with the fields I pulled from PubMed. 

*NOTE: The `esearch` portion of the bash script indicates that there are ### papers for the query we used. However, after modelling the data I see 1334 papers. I ran the following command to get a list of the pubmed IDs to see if the repackaging I did to the XML is causing some drops.*
```
esearch -db pubmed -query "pmdd OR premenstrual dysphoric disorder OR luteal phase dysphoric disorder OR pmdd [MESH]" |\
efetch -format xml |\
xtract -pattern PubmedArticle -element MedlineCitation/PMID > pubmed_ids.csv
```
*The resulting CSV contains the same 1334 pubmed IDs, so I can confirm that my XML repackaging is not leading to a drop of articles*

### Convert XML data to JSON

Since the bash script above outputs the data into an XML format, we need to convert this file into JSON format to be able to pull into our DuckDB database. 

To achieve this format conversion, this pipeline uses [yq](https://github.com/mikefarah/yq). 

Homebrew installation is recommended, so I used: 

```
brew install yq
```

Once installed, run the following command to cary out the converstion: 
```
yq -p=xml -o=json pmdd_entrez.xml > pmdd_entrez.json
```

### Load JSON to DuckDB

Thi step was actually much easier than anticipated. Naturally, at the beginning I was overcomplicating the process. After reading a bunch of documentation and syntax examples, I came across this [GitHub issue](https://github.com/duckdb/duckdb/issues/7015), which helped me get the final version of the SQL query using `read_json`.

### Model the data in DuckDB

After loading the JSON file, now it is a matter of extracting the relevant information and modelling it in a way that it can serve multiple functions downstream. This table is intended to be a denormalized table, which I will use as the main source of data in downstream analyses. 

DuckDB's `read_json` function did most of the heavy lifting. All that was left for me to do was nest all applicable fields (e.g. keywords, MeSH terms, author details) in an easy to process format. This work resulted in table `entrez_clean` which will now be used downstream in R and with further SQL modelling. 

Depending on how much more SQL I write for this modelling, I may use `dbt` to help me better manage the data transofrmations in this project. 

*NOTE: It may be interesting to use `dbt` here as well to showcase that skillset*

### Build notebook with visualizations and insights in R
 It may be interesting to build a dashboard that can keep track of how often a PMDD publication is published

### Add to GitHub


### Build Snakemake file or single bash script for entire pipeline