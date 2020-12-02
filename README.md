The Mouse Microbial Genome Collection (MMGC)
============================================

Welcome to the MMGC repository! Here you will find the pipelines, scripts and data files required to establish the average mouse microbiome at the species-level and further compare the microbiotas of humans and mice. 


This work is currently under review for publication :fire:.





## Mouse microbiome resources for your research

The below resources are not found on GitHub, but are freely available elsewhere to facilitate your analyses of the mouse gut microbiome:

* [Custom Kraken2/Bracken database](https://doi.org/10.5281/zenodo.4300642) for species-level analysis of mouse gut shotgun metagenomes

* [Clustered protein catalogues](https://doi.org/10.5281/zenodo.4300919) for gene-level analyses.

* MMGC genomes! Our non-redundant and near-complete mouse MAGs, as well as our MCC isolate genomes, are now accessible via this FTP URL:  
<p align="center">
http://ftp.ebi.ac.uk/pub/databases/metagenomics/genome_sets/mmgc/  
</p>


Check out the Supplementary Tables in the `supp` directory of this repository for more information on our genomes.




## Data and code used in this project

This archive is structured as follows :

- the _src_ directory contains the source materials and pipelines to be able to reproduce our analyses. These pipelines include:
   * custom MAG synthesis
   * pangenome building and analysis 

- the _data_ directory contains the starting and intermediate datasets used to carry out the experiments

- the _figures_ directory contains the scripts used to build the figures for the manuscript

- the _supp_ directory contains the Supplementary Data files from the paper

Please read on for a detailed over-view of each directory. More specific information can be found in the README files in the relevant directory.



## `src/`

The _src_ directory contains four sub-directories organised to reflect different stages in this project. 

### `1-build-MAGs/`

This directory includes the custom MAG building pipeline that leverages MetaWRAP to get the best quality bins out of single samples. In addition it also contains QC and taxonomy pipelines/scripts.

#### `MAG_pipeline.sh`
Build metagenome-assembled genomes quickly and easily from shotgun metagenomes.

__Requirements:__
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
- this pipeline requires a specific file structure for the metagenome samples:
  * STUDY_NAME/
    * Metagenomes/
      * metagenome sample files e.g.
      * `SRR6051702.fastq` # single read
      * `SRR11404551_1.fastq` `SRR11404551_2.fastq` # paired end
    * SAMPLE_IDs.txt: file listing the names of the metagenome samples in the `Metagenomes/` directory with out a suffix or paired end index. 
    For example: `SRR6051702`, `SRR11404551`

- the pipeline runs: QC - ASSEMBLY - BINNING - REFINE - REASSEMBLY
- output MAGs will be found in the REFINE or REASSEMBLY directory (if run)
- reassembling bins is a computationally expensive and resource intensive process, potentially generating hundreds of thousands of temporary files. It is therefore recommended to use the `-e REFINE` option if running on many samples.


#### `QC_TAX_pipeline.sh`
Runs CheckM on genomes and returns QC outcomes, before running GTDB-Tk classifier.

__Requirements:__
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
* `get_lowest_taxonomy_v1.0.R`: takes GTDB-Tk output (`gtdbtk.bac120.summary.tsv`) and summarises the lowest taxonomy obtained - output is used in other pipelines.
* `get.RNA_profile.sh`: generate tRNA and rRNA analyses for a genome. Automatically tries to tar archive the RNA sequences for later use.
* `get.coverage.sh`: uses samtools and bowtie to generate bam alignments for MAGs and isolate genomes from their fastq files. Facilitates getting coverage for these genomes (to be added).
* the remaining files are part of the `MAG_pipeline.sh` pipeline




### `2-build-protein-catalogues/`

This directory includes the scripts to build the protein catalogues.

#### `mmseqs_wf_bsub.sh`
Build protein cluster databases from concatenated protein sequence file.

__Requirements:__
* mmseqs2 (tested with v10.6d92c--h2d02072_0)
* bsub.py v0.42.1

This pipeline was coded for running within LSF cluster environments.

__Usage:__
```
mmseqs_wf_bsub.sh -i <INFILE> -s <OUTDIR> -t <THREADS> -T <TMPDIR> -FENH -m 120 
``` 
Arguments:  
`-i` path to input file (concatenated protein sequences e.g. .faa to be clustered) [REQUIRED]  
`-o` output directory [default: .]  
`-T` directory to use to build the MMseqs database [default: .]  
`-F` cluster at 50% sequence identity (orthologue level)  
`-E` cluster at 80% sequence identity (genus level)  
`-N` cluster at 90% sequence identity (species level)  
`-H` cluster at 100% sequence identity  
`-t` number of threads to submit jobs with [default: 1]  
`-q` queue to submit jobs to [default: normal]  
`-m` memory to submit jobs with, 120 Gb is recommended [REQUIRED]  


__Notes:__
- will skip building MMseqs database if one already exist in `<TMPDIR>`
- the `2-build-protein-catalogues/` directory need to be part of your `$PATH` system variable to access `linclust.sh`
- output files are found written to `<-o>/CLUS_X/`, where _X_ represents the chosen sequence identity threshold(s)
  * `mmseqs_cluster_rep.fa`: fasta file containing sequence representatives
  * `mmseqs_cluster.tsv`: cluster membership file



#### Other scripts in this directory:
* `CLUSTER_STATS.sh`: run in the `CLUS_X` directory to generate human vs mouse statistics for comparing cluster membership. Output is written to `CLUS_x/tmp/cluster_stats.out`.


### `3-build-species-pangenomes/`

This directory features the pangenome building and analysis pipelines. Two separate pipelines are available for building pangenomes, depending on whether you are working with a species-level assignment (i.e. a known species) or a supra-species assignment (i.e. a previously uncharacterised species). The remaining files facilitate analysis of these pangenomes.

#### `get.species_pangenome_v2.sh`
Build a host-specific pangenome for a __known__ species. 

__Requirements:__
* eggNOG-mapper v2.0.1
* InterProScan v5.39-77.0-W01
* bsub.py v0.42.1

This pipeline was coded for running within LSF cluster environments.

__Usage:__
```
get.species_pangenome_v2.sh -i <"TAXON"> -t <THREADS> -H <HOST> -CEI
``` 
Arguments:  
Input:  
`-i` Taxonomical level to compare in quotation marks e.g.  
  * "s__Lactobacillus johnsonii" will get all genomes for this species
  * "f__Muribaculaceae" will get any genome that has been classified as a member of the Muribaculaceae family, including those assigned to genus or species taxonomic ranks  
  * "Muribaculaceae" (no rank tag) will get genomes that have been assigned a terminal rank of Muribaculaceae at the family level i.e. no genus- or species- level assignment  

`-t` number of threads with which to run analyses  
`-q` queue to submit jobs to [default: normal]    
`-H` Specifiy a host - either `HUMAN` or `MOUSE`  

Output - pick one of the following options: [default: `-p`]  
`-o` specify the output directory in which to generate the results  
`-p` supply path to directory in which to build output directory that is the same name as the taxonomical level supplied [default: `./<i>`]  

Action:  
`-C` get gene clusters that are unique and shared between each host.  
`-l` sequence identity threshold of clusters (use with `-C`). Can be one of 50, 80, 90 or 100. [default: 90]  
`-E` run eggNOG v2 on host-specific and shared clusters.  
`-I` run InterProScan on pangenome.  


__Notes:__
- need to update the paths to the required data:
  * [protein cluster databases](https://doi.org/10.5281/zenodo.4300919)
      * path to directory containing CLUS_X directories
  * taxonomy files (requires the output from `get_lowest_taxonomy_v1.0.R`)
      * `data/mouse-18075.tsv`
      * `data/human-100456.tsv`


#### `get.unknown_species_pangenome_v2.sh`
Build a host-specific pangenome for a __previously uncharacterised__ species i.e. cannot be assigned to a species-level taxonomic rank by GTDB-Tk. 

__Requirements:__
* eggNOG-mapper v2.0.1
* InterProScan v5.39-77.0-W01
* bsub.py v0.42.1

This pipeline was coded for running within LSF cluster environments.

__Usage:__
```
get.unknown_species_pangenome_v2.sh -i <GENOME_ID> -t <THREADS> -H <HOST> -CEI
``` 
Arguments:  
Input:  
`-i` representative genome identifier (currently: genome name) without any .fna or .fa suffix   
`-t` number of threads with which to run analyses  
`-q` queue to submit jobs to [default: normal]    
`-H` Specifiy a host - either `HUMAN` or `MOUSE`  

Output - pick one of the following options: [default: `-p`]  
`-o` specify the output directory in which to generate the results  
`-p` supply path to directory in which to build output directory that is the same name as the taxonomical level supplied [default: `./<i>`]  

Action:  
`-C` get gene clusters that are unique and shared between each host.  
`-l` sequence identity threshold of clusters (use with `-C`). Can be one of 50, 80, 90 or 100. [default: 90]  
`-E` run eggNOG v2 on host-specific and shared clusters.  
`-I` run InterProScan on pangenome.  


__Notes:__
- need to update the paths to the required data:
  * [protein cluster databases](https://doi.org/10.5281/zenodo.4300919)
      * path to directory containing CLUS_X directories  
  * taxonomy files (requires the output from `get_lowest_taxonomy_v1.0.R`)
      * `data/mouse-18075.tsv`
      * `data/human-100456.tsv`
  * 95% ANI output files for mouse
      * `data/drep_950_index-ALL.csv'
  * human genome-genome rep index
      * `data/human_rep_members.tsv'


#### `analyse.species-pangenome_v3.sh`

Analyse the __eggNOG-mapper v2__ output for a pangenome.

__Requirements:__
* R v3.6.0

This pipeline was coded for running within LSF cluster environments.

__Usage:__
```
analyse.species-pangenome_v3.sh -i <PANGENOME_DIR> -o <OUTDIR> -H <HOST>
``` 
Arguments:  
`-i` path to pangenome directory   
`-D` directory containing the eggNOG reference databases [not implemented]  
`-o` directory to write to [default: <-i>/eggnog-out]  
`-H` specifiy a host organism - either `HUMAN` or `MOUSE`  


__Notes:__
- need to update the paths to the required data:
  * taxonomy files (requires the output from `get_lowest_taxonomy_v1.0.R`)
      * `data/mouse-18075.tsv`
      * `data/human-100456.tsv`
  * [MMGC/UHGP MMseqs 90% cluster membership file](https://doi.org/10.5281/zenodo.4300919)  
      * mmseqs_cluster.tsv
  * UHGP 100% cluster membership file.
      * get_cluster_membership.out.tsv
      * will include code to be able to access
  * the KEGG database directory
      * `data/KEGG_DB`
 
 
#### `analyse.species-pangenome_IPS_v3.sh`

Analyse the __InterProScan v5__ output for a given pangenome.

__Requirements:__
* R v3.6.0

This pipeline was coded for running within LSF cluster environments.

__Usage:__
```
analyse.species-pangenome_IPS_v3.sh -i <PANGENOME_DIR> -o <OUTDIR> -H <HOST>
``` 
Arguments:  
`-i` path to pangenome directory   
`-D` directory containing the IPS reference databases [not implemented]  
`-o` directory to write to [default: <-i>/IPS-out]  
`-H` specifiy a host organism - either `HUMAN` or `MOUSE`  


__Notes:__
- need to update the paths to the required data:
  * taxonomy files (requires the output from `get_lowest_taxonomy_v1.0.R`)
      * `data/mouse-18075.tsv`
      * `data/human-100456.tsv`
  * [MMGC/UHGP MMseqs 90% cluster membership file](https://doi.org/10.5281/zenodo.4300919)  
      * mmseqs_cluster.tsv
  * UHGP 100% cluster membership file.
      * get_cluster_membership.out.tsv
      * will include code to be able to access
  * the InterPro family database
      * `data/InterPro
      

The other scripts in this directory are used by the pipelines discussed above.




