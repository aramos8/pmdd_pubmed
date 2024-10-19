[![deploy_rshinyapp](https://github.com/aramos8/pmdd_pubmed/actions/workflows/deploy_rshinyapp.yml/badge.svg)](https://github.com/aramos8/pmdd_pubmed/actions/workflows/deploy_rshinyapp.yml)

# PMDD Publications in Pubmed

This project builds a dashboard with a summary of the scientific publications available for PMDD research. 

The dashboard is currently hosted in [shinyapps.io](https://anaramos.shinyapps.io/pmdd_pubmed/), and [GitHub pages](https://aramos8.github.io/pmdd_pubmed/) (using `shinylive`).

*NOTE: The dashboard hosted in GitHub Pages can take a couple of minutes to load. Also, there have been cases where Safari on desktop does not load the dashboard properly. If that is the case please try another browser. Alternatively, the dashboard hosted on shinyapps.io should always load properly.*

## Running the pipeline

If you decide to clone this repository and run the pipeline locally, create a new `mamba` virtual environment using the `environment.yml` file and then run:

```{bash}
snakemake -F deploy_app
```

Please note that the `environment.yml` file does not include any of the R packages used in this project.

## To Do

- Clean keyterms
    - New terms after updating data are not falling in the right category (e.g. "25-OH vitamin D" in "Other")
- Update dashboard to load faster
- Update pipeline to use Pubmed data from their FTP service to get citation data
- Add citation details to dashboard
- Update colors in dashboard









