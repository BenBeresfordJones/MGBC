The Mouse Microbial Genome Collection (MMGC)
============================================

Welcome to the MMGC repository! Here you will find the pipelines, scripts and data files required to establish the average mouse microbiome at the species-level and further compare the microbiotas of humans and mice. 


This work is currently under review for publication :fire:.





## Mouse microbiome resources for your research

The below resources are not found on GitHub, but are freely available elsewhere to facilitate your analyses of the mouse gut microbiome:

* [Custom Kraken2/Bracken database](https://doi.org/10.5281/zenodo.4300642) for species-level analysis of mouse gut shotgun metagenomes

* [Clustered protein catalogues](https://doi.org/10.5281/zenodo.4300919) for gene-level analyses.

* MMGC genomes! Our non-redundant and near-complete mouse MAGs, as well as our isolate genomes, are now accessible via this [FTP URL](http://ftp.ebi.ac.uk/pub/databases/metagenomics/genome_sets/mmgc/):

                 `http://ftp.ebi.ac.uk/pub/databases/metagenomics/genome_sets/mmgc/`
    

Check out the Supplementary Tables in this repository for more information on our genomes.




## Data and code used in this project

This archive is structured as follows :

- the _src_ directory contains the source materials to be able to reproduce our analyses. These pipelines include:
   * custom MAG synthesis
   * pangenome building and analysis 

- the _data_ directory contains the starting and intermediate datasets used to carry out the experiments

- the _figures_ directory contains the scripts used to build the figures for the manuscript

- the _supp_ directory contains the Supplementary Data files from the paper

Please read on for a detailed over-view of each directory. More specific information can be found in the README files in the relevant directory.
