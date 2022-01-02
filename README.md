![logo](https://github.com/BenBeresfordJones/MGBC/blob/main/MGBC_logo.png?raw=true)

[![DOI](https://zenodo.org/badge/317599395.svg)](https://zenodo.org/badge/latestdoi/317599395)

The Mouse Gastrointestinal Bacterial Catalogue (MGBC)
============================================

Welcome to the MGBC repository! Here you will find the pipelines, scripts and data files for analysing mouse gut microbiome samples and buildling the MGBC genome catalogue.

If you use this resource or the linked [MGBC-Toolkit](https://github.com/BenBeresfordJones/MGBC-Toolkit), please cite our paper: 

Beresford-Jones, B.S., Forster, S.C., Stares, M.D., Notley, G., Viciani, E., Browne, H.P., Boehmler, D.J., Soderholm, A.T., Kumar, N., Vervier, K., Cross, J.R., Almeida, A., Lawley, T.D., Pedicord, V.A., 2021. The Mouse Gastrointestinal Bacteria Catalogue enables translation between the mouse and human gut microbiotas via functional mapping. Cell Host Microbe. https://doi.org/10.1016/j.chom.2021.12.003


## Summary and availability of datasets

__Genomes:__
* MGBC collection:
   * 26,640 high-quality, non-redundant genomes: [MGBC-hqnr_26640.tar.gz](https://zenodo.org/record/4840600/files/MGBC-hqnr_26640.tar.gz?download=1)
   * Genome metadata: [MGBC_md_26640.tar.gz](https://zenodo.org/record/4840600/files/MGBC_md_26640.tar.gz?download=1)
   * Genome protein coding sequences (.faa): [MGBC-faa_26640.tar.gz](https://zenodo.org/record/4840600/files/MGBC-faa_26640.tar.gz?download=1)
   * Genome annotations (GenBank flat file format)
      * Part 1 (MGBC000001-MGBC129999): [MGBC-gbk_26640-d1.tar.gz](https://zenodo.org/record/5534741/files/MGBC-gbk_26640-d1.tar.gz?download=1)
      * Part 2 (MGBC130000-MGBC167528): [MGBC-gbk_26640-d2.tar.gz](https://zenodo.org/record/5532847/files/MGBC-gbk_26640-d2.tar.gz?download=1)
   * This is the final genome set following dereplication that is used for the study's analyses.
* Full genome collection:
   * 35,925 high-quality genomes: [MGBC-hq_35925.tar.gz](https://zenodo.org/record/4837230/files/MGBC-hq_35925.tar.gz?download=1)
   * 29,129 medium-plus quality genomes: [MGBC-mq_29129.tar.gz](https://zenodo.org/record/4876551/files/MGBC-mq_29129.tar.gz?download=1)
   * Genome metadata: [MGBC_md_65097.tar.gz](https://zenodo.org/record/4837230/files/MGBC_md_65097.tar.gz?download=1)
   * This is the complete collection of genomes generated/curated for this study.
* Mouse Culture Collection:
   * Genome assemblies for the 276 sequenced isolates (post-qc) are available from BioProject [PRJEB45232](https://www.ncbi.nlm.nih.gov/bioproject/PRJEB45232)
   * Genome annotations (GenBank flat file format): [MCC-gbk_276.tar.gz](https://zenodo.org/record/5534741/files/MCC-gbk_276.tar.gz?download=1)
   * Deposition of cultured isolates from the paper to DSMZ is on-going, and accessions of available isolates are being [actively updated on this GitHub](https://github.com/BenBeresfordJones/MGBC/blob/main/MCC_deposition_accessions.xlsx).

__Protein catalogues:__
* MGBC-UHGG combined catalogue - 100% sequence identity clusters: [mgbc-uhgg_clus100.tar.gz](https://zenodo.org/record/4840586/files/mgbc-uhgg_clus100.tar.gz?download=1)
* MGBC-UHGG combined catalogue - 90% sequence identity clusters: [mgbc-uhgg_clus90.tar.gz](https://zenodo.org/record/4840586/files/mgbc-uhgg_clus90.tar.gz?download=1)
* MGBC-UHGG combined catalogue - 80% sequence identity clusters: [mgbc-uhgg_clus80.tar.gz](https://zenodo.org/record/4840586/files/mgbc-uhgg_clus80.tar.gz?download=1)
* MGBC-UHGG combined catalogue - 50% sequence identity clusters: [mgbc-uhgg_clus50.tar.gz](https://zenodo.org/record/4840586/files/mgbc-uhgg_clus50.tar.gz?download=1)
* MGBC protein catalogue - 100% sequence identity clusters: [mgbc_hq-mq_clus100.tar.gz](https://zenodo.org/record/4840586/files/mgbc_hq-mq_clus100.tar.gz?download=1)
    * This catalogue contains the gene clusters from all non-redundant high and medium plus quality genomes of the MGBC.


__Kraken2/Bracken database:__
* MGBC Kraken2/Bracken database: [MGBC-26640_KrakenBracken.tar.gz](https://zenodo.org/record/4836362/files/MGBC-26640_KrakenBracken.tar.gz?download=1)
    * This custom database leverages the 26,640 high quality genomes of the MGBC to achieve ~90% average read classification for mouse gut metagenome samples.

__The global mouse metagenome compilation:__
* Bracken output for 2,446 mouse gut metagenomes: [bracken-out_2664.tar.gz](https://zenodo.org/record/4836362/files/bracken-out_2664.tar.gz?download=1)
    * Species-level data on the microbiome composition for 2,446 mouse gut metagenome samples.
* Sample metadata for these mouse gut metagenomes: [sample-metadata_2446.tar.gz](https://zenodo.org/record/4836362/files/sample-metadata_2446.tar.gz?download=1)


## Data and code used in this project

This repository is structured as follows :

- the `src` directory contains the source materials and pipelines to be able to reproduce our analyses. These pipelines include:
   1) metagenome binning and MAG synthesis
   2) construction of protein catalogues
   3) assembly and functional annotation of species pangenomes
   4) species-level functional analyses

- the `data` directory contains the reference datasets for the functional schemes and some example intermediate output files for `src`

- the `figures` directory contains the scripts used to build the figures for the manuscript

- the `supp` directory contains a description of the Supplementary Data Tables from the paper

Please read on for a detailed over-view of the `src` directory. Specific information on the other directories can be found in the relevant README files.

## `src/`

The `src` directory contains four sub-directories organised to reflect the main workflows of this project. 

### `1-build-MAGs/`

This directory includes the custom MAG building pipeline that leverages MetaWRAP to get the best quality bins out of single samples. In addition it also contains QC and taxonomy pipelines/scripts.

__Overview of workflow:__
* `MAG_pipeline.sh`: runs metagenome QC, assembly, binning and refinement for MAG synthesis.  
* `QC_TAX_pipeline`: wrapper for running CheckM and GTDB-Tk on refined bins.  
* `get.RNA_profile.sh`: generate tRNA and rRNA profiles for a genome; designed to be run in parallel.  


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
  * N50 ≥10,000
  * Mean contig length ≥5,000
- Genome ids that pass QC can be found `<-o>/CheckM/Validated_genomes.txt`


#### Other scripts in this directory:
* `GTDBTK_CLASSIFY_EFFICIENT.sh`: the same as GTDB-Tk's `classify_wf` except with a smaller temporary file footprint.
* `get_lowest_taxonomy_v1.0.R`: takes GTDB-Tk output (`gtdbtk.bac120.summary.tsv`) and summarises the lowest taxonomy obtained - output is used in other pipelines.
* `get.RNA_profile.sh`: generate tRNA and rRNA analyses for a genome. Automatically tries to tar archive the RNA sequences for later use.
* `get.coverage.sh`: uses samtools and bowtie to generate bam alignments for MAGs and isolate genomes from their fastq files. Facilitates getting coverage for these genomes (to be added).
* the remaining files are part of the `MAG_pipeline.sh` pipeline




### `2-build-protein-catalogues/`

This directory includes the scripts to build the protein catalogues. As a prerequisite, CDS predictions should be generated for genomes (e.g. using prokka) and the .faa files for each genome concatenated (using `cat *.faa`). The resulting .faa file serves as input for this pipeline.

__Overview of workflow:__
* `mmseqs_wf_bsub.sh`: pipeline for running mmseqs2 (builds database and clusters sequences).  
* `CLUSTER_STATS.sh`: generate human vs mouse analyses for clusters.


#### `mmseqs_wf_bsub.sh`
Build protein cluster databases from concatenated protein sequence file.

__Requirements:__
* mmseqs2 (tested with v10.6d92c--h2d02072_0)
* bsub.py v0.42.1

This pipeline was coded for running within LSF cluster environments.

__Usage:__
```
mmseqs_wf_bsub.sh -i <INFILE> -s <OUTDIR> -t <THREADS> -T <TMPDIR> -FENH -m <MEMORY> 
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
- the `2-build-protein-catalogues/` directory needs to be part of your `$PATH` system variable to access `linclust.sh`
- output files are written to `<-o>/CLUS_X/`, where _X_ represents the chosen sequence identity threshold(s)
  * `mmseqs_cluster_rep.fa`: fasta file containing sequence representatives
  * `mmseqs_cluster.tsv`: cluster membership file



#### Other scripts in this directory:
* `CLUSTER_STATS.sh`: run in the `CLUS_X` directory to generate human vs mouse statistics for comparing cluster membership. Output is written to `CLUS_x/tmp/cluster_stats.out`



### `3-build-species-pangenomes/`

This directory includes the scripts for building and functionally annotating species pangenomes.

__Overview of workflow:__
* `get.pangenome_MGBC1094.sh`: build and functionally annotate a species pangenome from the clustered protein catalogue from phase 2. eggNOG v2 and InterProScan v5 are run in parallel to generate functional annotations.


#### `get.pangenome_MGBC1094.sh`
Build a host-specific pangenome for a species using a clustered protein catalogue. 

__Requirements:__
* eggNOG-mapper v2.0.1
* InterProScan v5.39-77.0-W01
* bsub.py v0.42.1

This pipeline was coded for running within LSF cluster environments.

__Usage:__
```
get.pangenome_MGBC1094.sh -i <GENOME_REP_ID> -t <THREADS> -q <QUEUE> -H <HOST> -p <OUT_DIR> -CEI -l <SEQID>
``` 
Arguments:  
Input [REQUIRED]:  
`-i`      Representative genome id without file suffix (i.e. .fna, .fa)  
`-t`      Number of threads with which to run analyses.  
`-q`      Queue to submit jobs to, for use with cluster analysis [default: normal]  
`-H`      Specify host - either HUMAN or MOUSE.  

Output - pick one of the following options:  
`-o`      Output directory in which to generate the results, mutually exclusive with -p [-p flag is default option].  
`-p`      Path to directory to build a unique output directory (e.g. REP_ID.TAX.HOST) [default: .]  
_NB:_ For smooth integration with downstream pipelines, I recommend using `-p HUMAN` or `-p MOUSE` for human and mouse pangenomes respectively, run from the same directory.   

Action:  
`-C`      Build pangenome using mmseqs gene clusters.  
`-l`      Protein cluster sequence identity threshold to use with `-C`. Can be one of 50, 80, 90 or 100 [default: 90]  
`-E`      Run eggNOG v2 on pangenome.  
`-I`      Run InterProScan on pangenome.  


__Notes:__
- need to update the path variables to the required data inside the file:
  * `$LINCLUST_DB`: path to directory containing CLUS_X directories
      * this will be the same directory as supplied to `mmseqs_wf_bsub.sh` with the `<-o>` flag
  * `$M_REPMEMS` and `$H_REPMEMS`: tab-separated representative genome index files for each host, where   
     * column 1 contains the genome id,
     * column 2 contains the representative genome id for the species cluster,
     * column 3 indicates the lowest taxonomy as determined by GTDB-Tk and `get_lowest_taxonomy_v1.0.R`
     * `mgbc_rep_index_26640.tsv` and `uhgg_rep_index_100456.tsv` are given as examples in the `data/` directory
     * e.g.
```
MGBC000001	MGBC000001	g__Schaedlerella
MGBC000002	MGBC129157	s__CAG-485 sp002362485
MGBC000003	MGBC000003	g__Schaedlerella
MGBC000005	MGBC000328	s__Phocaeicola vulgatus
MGBC000006	MGBC000320	s__Schaedlerella sp000364245
```
   * the `3-build-species-pangenomes/` directory needs to be part of your `$PATH` system variable to access `GET_FASTA_FROM_CONTIGS_v4.py`
   * output files are written to `$OUTDIR/cluster_"<-l>".out`
      * eggNOG output -->  `<-i>.dmnd.emapper.annotations`
      * InterProScan output --> `ips_out.gff`

The other scripts in this directory are used by the pipelines discussed above.


### `4-functional-analyses/`

This directory includes the scripts for comparing the functional profiles of bacterial species of the human and mouse gut microbiota. 

__Overview of workflow:__
* `summarise.eggnog_annotations.sh`: summarise eggNOG v2 annotations generated with `get.pangenome_MGBC1094.sh`.
* `summarise.ips_gff.sh`: summarise InterProScan v5 annotations generated with `get.pangenome_MGBC1094.sh`.  
* `summarise.all_functions.MGBC120421.sh`: compile data for all pangenomes and generate functional profiles for each species.
* `build.function_presence_absence.sh`: generate presence-absence matrices for each functional scheme.
* `analyse.pangenome-distance_MGBC.R`: generate distance matrices for each functional scheme.


#### `summarise.eggnog_annotations.sh`

Summarise the eggNOG v2 output annotation file for a pangenome, returning feature-gene and gene-genome indices. Additionally calculates annotation efficiency data.

This pipeline was coded for running within LSF cluster environments.

__Usage:__
```
summarise.eggnog_annotations.sh -i <EGGNOG_OUT> -a <FAA> -o <OUTDIR> -g <GENOME_ID> -H <HOST>
``` 
Arguments:  
`-i`  Path to emapper v2 output file from `get.pangenome_MGBC1094.sh` i.e. `<-i>.dmnd.emapper.annotations`  
`-a`  Path to original fasta file used for eggNOG annotation i.e. `$OUTDIR/Cluster_"<-l>"/extracted_seqs.faa`   
`-o`  Directory to write to [REQUIRED]  
`-g`  Path to `genome_ids.txt` file in pangenome `$OUTDIR`  
`-H`  Host organism: either HUMAN or MOUSE  


__Notes:__
- need to update the path variables to the required data inside the file:
  * `$CLUS_MEM`: path to cluster membership file for the protein cluster catalogue used to generate the pangenome
 
 
#### `summarise.ips_gff.sh`

Summarise the InterProScan v5 output annotation file for a pangenome, returning feature-gene and gene-genome indices. Additionally calculates annotation efficiency data.

This pipeline was coded for running within LSF cluster environments.

__Usage:__
```
summarise.ips_gff.sh -i <IPS_OUT> -a <FAA> -o <OUTDIR> -g <GENOME_ID> -H <HOST>
``` 
Arguments:  
`-i`      Path to IPS output file from `get.pangenome_MGBC1094.sh` i.e. `ips_out.gff`  
`-a`      Path to original fasta file used for IPS i.e. `$OUTDIR/Cluster_"<-l>"/extracted_seqs.faa`   
`-o`      Directory to write to [REQUIRED]  
`-g`      Path to genome ids file  
`-H`      Host organism: either HUMAN or MOUSE  


__Notes:__
- need to update the path variables to the required data inside the file:
  * `$CLUS_MEM`: path to cluster membership file for the protein cluster catalogue used to generate the pangenome
  * `$IPS_DATA`: path to the InterPro database i.e. `data/InterPro_DBs/`



#### `summarise.all_functions.MGBC120421.sh`

Summarises the functional annotations generated for all pangenomes using the `summarise.ips_gff.sh` and `summarise.eggnog_annotations.sh` scripts described above. Generates analyses of human and mouse specific functional features as well as total feature-level analsyes. Automatically runs `summarise.pangenome_function.MGBC120421.sh` on the pangenomes to build feature-genome indexes ready for downstream distance matrix calculation.


__Requirements:__
* Requires `summarise.ips_gff.sh` and `summarise.eggnog_annotations.sh` to have already been run on all pangenomes, and their temporary files to still be available.

This pipeline was coded for running within LSF cluster environments, and runs jobs (via a bsub array) for paralellising analyses.

__Usage:__
```
summarise.all_functions.MGBC120421.sh <OUTDIR>
``` 
Arguments:  
The script only needs to be run with the output directory specified. The script builds this directory if it does not already exist. 

__Notes:__
- need to update the path variables to the required data inside the file:
  * `$PANGENOMES`: path to the directory where `HUMAN` and `MOUSE` directories exist, containing the pangenomes for each host organism. 


#### `build.function_presence_absence.sh`

Compiles species functional profiles to generate genome-function presence-absence matrices for each InterProScan and eggNOG functional scheme. 

__Usage:__
```
build.function_presence_absence.sh <OUTDIR>
``` 
Arguments:  
The script only needs to be run with the output directory (e.g. DISTANCE_MATRICES) specified. The script builds this directory if it does not already exist. 

__Notes:__
- need to update the path variables to the required data inside the file:
  * `$HUMAN` and `$MOUSE`: paths to the `HUMAN` and `MOUSE` pangenome directories, containing the species pangenomes for each host organism. 


#### `build.function_presence_absence.sh`

Compiles species functional profiles to generate genome-function presence-absence matrices for each InterProScan and eggNOG functional scheme. 

__Usage:__
```
build.function_presence_absence.sh <OUTDIR>
``` 
Arguments:  
The script only needs to be run with the output directory (e.g. DISTANCE_MATRICES) specified. The script builds this directory if it does not already exist. 

__Notes:__
- need to update the path variables to the required data inside the file:
  * `$HUMAN` and `$MOUSE`: paths to the `HUMAN` and `MOUSE` pangenome directories, containing the species pangenomes for each host organism. 


#### `analyse.pangenome-distance_MGBC.R`

Takes presence-absence matrix as input and produces a distance matrix from the functional profiles of each species.

__Requirements:__
* R v3.6.0

__Usage:__
```
analyse.pangenome-distance_MGBC.R -i <INFILE> -m <DIST_METHOD> -p <PREFIX> -o <OUTDIR>
``` 
Arguments:  
`-i` Path to tsv file containing data for feature distribution across a core or pangenome (e.g. output from `build.function_presence_absence.sh`).  
`-m` Which METHOD to use for distance matrix calculation. Any of the distance methods supported by Vegan's 'vegdist' function are allowed.  
`-b` Flag to use BINARY distance analyses. \[default: FALSE\]  
`-p` Prefix to give files that are being written.  
`-o` Directory to write output files to.  

__Notes:__
- need to update the path variables to the required data inside the file:
  * `$HUMAN` and `$MOUSE`: paths to the `HUMAN` and `MOUSE` pangenome directories, containing the species pangenomes for each host organism. 


The other scripts in this directory are used by the pipelines discussed above.
