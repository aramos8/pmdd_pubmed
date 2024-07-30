# Documentation

This README is intended to keep track of the general plan for this work. During initial stages of this project, all calculations and visualizations will be done using an Rmd notebook. Once I identify which visualizations i want to keep track of I will build a Shiny dashboard, integrating the entire pipeline into a Snakemake workflow.


## Plan

### 1. Pull Data from Pubmed using the command line interface for Entrez

The `pmdd_entrez.sh` script is writen based on instructions provided in the [Entrez Direct: E-utilities on the Unix Command Line](https://www.ncbi.nlm.nih.gov/books/NBK179288/#chapter6.Structured_Data) provided by NCBI. The objective of this script is to collect the desired fields from PubMed in an XML file. 

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

However, there are considerable inconsistencies on how Entrez packs the data into the XML (e.g. varying levels of nesting in the XML, like in the Affiliations field), so I found it easier to model the data downstream using SQL when I repackaged the XML with the fields I pulled from PubMed. 

*NOTE: The `esearch` portion of the bash script indicates that there are 1371 papers for the query we used. However, after modelling the data I see 1352 papers. I ran the following command to get a list of the pubmed IDs to see if the repackaging I did to the XML is causing some drops.*
```
esearch -db pubmed -query "pmdd OR premenstrual dysphoric disorder OR luteal phase dysphoric disorder OR pmdd [MESH]" |\
efetch -format xml |\
xtract -pattern PubmedArticle -element MedlineCitation/PMID > pubmed_ids.csv
```
*The resulting CSV contains the same 1352 pubmed IDs, so I can confirm that my XML repackaging is not leading to a drop of articles*

### 2. Convert XML data to JSON

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

### 3. Load JSON to DuckDB

This step was actually much easier than anticipated. Naturally, at the beginning I was overcomplicating the process. After reading a bunch of documentation and syntax examples, I came across this [GitHub issue](https://github.com/duckdb/duckdb/issues/7015), which helped me get the final version of the SQL query using `read_json`.

### 4. Model the data in DuckDB

After loading the JSON file, now it is a matter of extracting the relevant information and modelling it in a way that it can serve multiple functions downstream. This table is intended to be a denormalized table, which I will use as the main source of data in downstream analyses. 

DuckDB's `read_json` function did most of the heavy lifting. All that was left for me to do was nest all applicable fields (e.g. keywords, MeSH terms, author details) in an easy to process format. This work resulted in table `entrez_clean` which will now be used downstream in R and with further SQL modelling. 

Depending on how much more SQL I write for this modelling, I may use `dbt` to help me better manage the data transofrmations in this project. At the current state of this project, however, I am only using the `entrez_clean` table and doing all downstream calculations in R. 


### 5. Build notebook with visualizations and insights in R

Since this will be my first project working with R, I will start exploring the data and building visualizations using an Rmd notebook. This allows me to strengthen my R skills while also getting more familiar with the data to explore hidden insights. Once I identify a set of visualizations I will want to keep track of, I will build a Shinny dashboard, ideally hosting it in GitHub and automatically updating the findings using GitHub actions. To do this I will work on building a Snakemake workflow. 

#### R Shiny Dashboard
TBD


### 6. Snakemake workflow

TBD