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

- the _src_ directory contains the source materials and pipelines to be able to reproduce our analyses. These pipelines include:
   * custom MAG synthesis
   * pangenome building and analysis 

- the _data_ directory contains the starting and intermediate datasets used to carry out the experiments

- the _figures_ directory contains the scripts used to build the figures for the manuscript

- the _supp_ directory contains the Supplementary Data files from the paper

Please read on for a detailed over-view of each directory. More specific information can be found in the README files in the relevant directory.



## src directory

The _src_ directory contains four sub-directories organised to reflect different stages in this project. 

### 1-build-MAGs/

This directory includes the custom MAG building pipeline that leverages MetaWRAP to get the best quality bins out of single samples. In addition it also contains QC and taxonomy pipelines/scripts.

#### `MAG_pipeline.sh`
Build metagenome-assembled genomes quickly and easily from shotgun metagenomes.

__Requirements__
* KneadData (tested v0.7.3)
* MetaWRAP (tested v1.2.3)
* GTDBT-Tk v1.3.0 r95
* bsub.py v0.42.1

This pipeline was coded for running within LSF cluster environments, and runs multiple parallel job submissions to rapidly generate high-quality bins.

__Usage:__
```
MAG_pipeline.sh -i path/to/sample_ids -s path/to/study_directory -t threads -e REFINE
``` 
Arguments:  
`-i` path to input file listing the sample file names without any file suffix.  
`-s` path to the metagenome study directory (see below).  
`-t` number of threads.  
`-S` do not run pipeline, just generate the scripts.  
`-e` early end - end after running ASSEMBLY or REFINE.  
`-f` file count - keep track of the number of files that are being produced by each job for troubleshooting purposes.  

__Notes:__
- the `1-build-MAGs/` directory need to be part of your `$PATH` system variable
- this pipeline uses a specific file structure:
  * STUDY_NAME/
    * Metagenomes/
      * metagenome sample files e.g.
      * `SRR6051702.fastq` # single read
      * `SRR11404551_1.fastq` `SRR11404551_2.fastq` # paired end
    * SAMPLE_IDs.txt: file listing the names of the metagenome samples in the `Metagenomes/` directory with out a suffix or paired end index.
     e.g.  
          ```
          SRR6051702
          SRR11404551 
          ```
- the pipeline runs: QC - ASSEMBLY - BINNING - REFINE - REASSEMBLY
- output MAGs will be found in the REFINE or REASSEMBLY directory (if run)
- reassembling bins is a computationally expensive and resource intensive process, potentially generating hundreds of thousands of temporary files. It is therefore recommended to use the `-e REFINE` option if running on many samples.


#### `QC_TAX_pipeline.sh`
Runs CheckM on genomes and returns QC outcomes, before running GTDB-Tk classifier.

__Requirements__
* CheckM v1.1.2
* GTDBT-Tk v1.3.0 r95

__Usage:__
```
QC_TAX_pipeline.sh -i path/to/genome_directory -t threads -o path/to/output -x fa
``` 
Arguments:  
`-i` path to directory containing genomes on which to run pipeline.  
`-o` directory to write output to.  
`-t` number of threads.  
`-x` genome suffix, default = fna.  

__Notes:__
- runs CheckM and GTDB-Tk on genomes in the genome directory
- QC specifications are:
  * Completeness ≥90%
  * Contamination ≤5%
  * Genome size ≤8Mb
  * Number of contigs ≤500
  * N50 ≥10000
  * Mean contig length ≥5000
- Genome ids that pass QC can be found `<-o>/CheckM/Validated_genomes.txt`


#### Other scripts in this directory:
* `GTDBTK_CLASSIFY_EFFICIENT.sh`: the same as GTDB-Tk's `classify_wf` except with a smaller temporary file footprint.
* `get_lowest_taxonomy_v1.0.R`: takes GTDB-Tk output and summarises the lowest taxonomy obtained - output is used in other pipelines.
* `get.RNA_profile.sh`: generate tRNA and rRNA analyses for a genome. Automatically tries to tar archive the RNA sequences for later use.
* `get.coverage.sh`: uses samtools and bowtie to generate bam alignments for MAGs and isolate genomes from their fastq files. Facilitates getting coverage for these genomes (to be added).
* the remaining files are part of the `MAG_pipeline.sh` pipeline


### 2-build-protein-catalogues/


