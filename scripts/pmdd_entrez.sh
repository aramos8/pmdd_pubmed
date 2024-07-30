 #!/bin/bash


#We first get all the papers that mention PMDD as a keyword or MeSH term
esearch -db pubmed -query "pmdd OR premenstrual dysphoric disorder OR luteal phase dysphoric disorder OR pmdd [MESH]" |\
efetch -format xml|\

#From those papers, we extract the fields of interest
xtract -set Set -rec Publication -pattern PubmedArticle -def "N/A" \
	-block PubmedData/ArticleIdList/ArticleId \
		-if @IdType -equals "pubmed" -pkg pubmed_id  -element ArticleId \
	-block PubmedData/ArticleIdList/ArticleId \
		-if @IdType -equals "pmc" -pkg pmc_id  -element ArticleId \
	-block PubmedData/ArticleIdList/ArticleId \
		-if @IdType -equals "doi" -pkg doi -element ArticleId \
	-block PublicationTypeList -pkg pub_type -wrp type -element PublicationType \
	-block History/PubMedPubDate \
		-if @PubStatus -equals "received" \
           -sep "-" -pkg sub_date -element Year,Month,Day \
    -block History/PubMedPubDate \
		-if @PubStatus -equals "accepted" \
           -sep "-" -pkg accepted_date -element Year,Month,Day \
	-block JournalIssue/PubDate -sep "-" -pkg pubdate -element Year,Month,Day \
	-block MeshHeadingList/MeshHeading/DescriptorName \
		-if @MajorTopicYN -equals "Y" -pkg major_mesh -wrp major_mesh_term -element DescriptorName \
    -block MeshHeadingList -pkg mesh_terms -wrp mesh_term -element DescriptorName \
    -block KeywordList -pkg keywords -wrp keyword -element Keyword \
	-block Article -wrp title -element ArticleTitle \
	-block Abstract -wrp abstract -element AbstractText \
	-block AuthorList/Author -pkg authors \
			-wrp author -sep " " -element Initials,LastName \
	-block AuthorList/Author -pkg author_ids -def "N/A" \
			-wrp author_id -sep "|||" -element Identifier \
	-block AuthorList/Author -pkg author_affiliations -def "N/A" \
			-wrp affiliation -sep "|||" -element Affiliation \
	-block Reference \
		-if @IdType -equals "doi" -pkg doi_references -wrp doi_reference -element ArticleId \
	-block Reference \
		-if @IdType -equals "pubmed" -pkg pubmed_references -wrp pubmed_reference -element ArticleId \
	-block Reference \
		-if @IdType -equals "pmc" -pkg pmc_references -wrp pmc_reference -element ArticleId > data/pmdd_entrez.xml
	# -block AuthorList/Author -pkg authors_full -def "N/A" \
	# 		-wrp author_full -sep "|||" -element Initials,LastName,Identifier,Affiliation \
