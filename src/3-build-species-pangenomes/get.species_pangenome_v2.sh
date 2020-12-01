#!/bin/bash

# Author: Benjamin Beresford-Jones
# Date: 18-04-2020
# Version 2: 02-09-2020

usage()
{
cat << EOF

usage: $0 options

Get all gene annotations for a given taxonomy.

OPTIONS:

Input [REQUIRED]:
   -i      Taxonomical level to compare in quotation marks e.g.
		"s__Lactobacillus johnsonii" will get all genomes for this species
		"f__Muribaculaceae" will get all genomes that have been classified at as Muribaculaceae at the family level or lower
		"Muribaculaceae" (no taxon tag) will get genomes that have been assigned a terminal rank of Muribaculaceae at the family level i.e. no genus- or species- level assignment
   -t      Number of threads with which to run analyses.
   -q      Queue to submit jobs to, for use with cluster analysis [default: normal]
   -H      Specifiy host - either HUMAN or MOUSE.

Output - pick one of the following options:
   -o      Instead of -p flag; output directory in which to generate the results [-p flag is default option].
   -p      Instead of -o flag; supply path to directory in which to use output directory that is the same name as the taxonomical level supplied [default: ./<i>]

Action:
   -R      NOT IMPLEMENTED - Run roary on genomes, to generate a core genome alignment and compare genes unique and shared to each host-group.
   -A      NOT IMPLEMENTED - Run ANI analysis of the genomes, to get an average ANI between human and mouse genomes, and within hosts.
   -C      Get gene clusters that are unique and shared between each host.
   -l      Level to extract gene clusters at (use with -C). Can be one of 50, 80, 90 [default] or 100.
   -E      Run eggNOG v2 on host-specific and shared clusters.
   -I	   Run InterProScan on pangenome.
   -G      NOT IMPLEMENTED - Run GTDBTk to get a bac120 alignment and tree.

EOF
}


timestamp() {
  date +"%H:%M:%S"
}


echo "$(timestamp) INFO : Running $0"


### READING COMMANDLINE ARGUMENTS ###

TAX_LEVEL=
OUTDIR=
PREFIX=
HOST_ORG=
RUN_ROARY=
RUN_ANI=
RUN_CLUS=
CLUS_LEVEL=
THREADS=
BQUEUE=
RUN_GTDB=
RUN_EGGNOG=
RUN_INTERPROSCAN=

while getopts “i:o:p:H:RACl:t:q:EIG” OPTION
do
     case $OPTION in
         i)
             TAX_LEVEL=$OPTARG
             ;;
	 o)
	     OUTDIR=$OPTARG
	     ;;
	 p)
	     PREFIX=$OPTARG
	     ;;
	 H)
	     HOST_ORG=$OPTARG
	     ;;
	 R)
	     RUN_ROARY=TRUE
	     ;;
	 A)
	     RUN_ANI=TRUE
	     ;;
	 C)
	     RUN_CLUS=TRUE
	     ;;
	 l)
	     CLUS_LEVEL=$OPTARG
	     ;;
	 E)
	     RUN_EGGNOG=TRUE
	     ;;
	 I)
	     RUN_INTERPROSCAN=TRUE
	     ;;
	 t)
	     THREADS=$OPTARG
	     ;;
	 q)
	     BQUEUE=$OPTARG
	     ;;
	 G)
	     RUN_GTDB=TRUE
	     ;;
         ?)
             usage
             exit
             ;;
     esac
done


if [ -z "$TAX_LEVEL" ]
then
     echo "$(timestamp) ERROR : No taxonomical level supplied."
     usage
     exit 1
fi


if [ ! -z $OUTDIR ] && [ ! -z $PREFIX ]
then
     echo "$(timestamp) ERROR : Please supply only one output format, either outdir PREFIX (-p) or specified OUTDIR (-o)."
     usage
     exit 1
elif [ -z $OUTDIR ] && [ -z $PREFIX ]
then
     echo "$(timestamp) WARNING : No output format specified so using specified taxonomical level in the working directory."
     OUTDIR=$(echo "$TAX_LEVEL" | sed 's/ /_/g').$HOST_ORG
     echo "$(timestamp) INFO : Writing output to $OUTDIR"
elif [ -z $OUTDIR ]
then
     WRITEDIR=$(echo "$TAX_LEVEL" | sed 's/ /_/g').$HOST_ORG
     OUTDIR=$PREFIX/$WRITEDIR
     echo "$(timestamp) INFO : Writing output to $OUTDIR"
else
     echo "$(timestamp) INFO : Writing output to $OUTDIR"
fi


if [ -z $THREADS ]
then
     echo "$(timestamp) ERROR : Please supply the number of threads with the -t flag."
     usage
     exit 1
fi


if [ -z $HOST_ORG ]
then
     echo "$(timestamp) ERROR : No host organism specified with the -H flag, please pick from HUMAN, MOUSE or BOTH."
     usage
     exit 1
fi


if [[ $HOST_ORG != HUMAN ]] && [[ $HOST_ORG != MOUSE ]]
then
     echo "$(timestamp) ERROR : Please supply one of HUMAN or MOUSE with the -H flag. The current entry is invalid."
     usage
     exit 1
fi


### SETTING UP ###

echo "$(timestamp) INFO : Setting up to analyse genomes..."

WKDIR=$(pwd)

# load modules
module load farmpy/0.42.1 drep/2.5.4 fastani/1.3--he1c1bb9_0 roary/3.12.0=pl526h470a237_1 r/3.6.0 eggnog-mapper/2.0.1--py_1 gtdbtk/1.0.2--py38_1 fasttreemp/2.1.11 interproscan/5.39-77.0-W01

# link to host-specific GTDBTk_lowest_taxonomy databases
#H_DB=/lustre/scratch118/infgen/team162/bb11/Human_mouse_comparison/HUMAN_MOUSE_HQ_REPS/GTDB_HQ_GENOMES/human_hq_GTDBTk.tsv
#M_DB=/lustre/scratch118/infgen/team162/bb11/Human_mouse_comparison/HUMAN_MOUSE_HQ_REPS/GTDB_HQ_GENOMES/mouse_hq_GTDBTk.tsv
H_DB=/lustre/scratch118/infgen/team162/bb11/Human_mouse_comparison/FUNCTIONAL_COMPARISON/BUILD_PANGENOME/GTDB_DBs/human-100456.tsv
M_DB=/lustre/scratch118/infgen/team162/bb11/Human_mouse_comparison/FUNCTIONAL_COMPARISON/BUILD_PANGENOME/GTDB_DBs/mouse-18075.tsv


# link to host-specific metadata - not used.
#H_META=/lustre/scratch118/infgen/team162/bb11/External_databases/MGnify/HUMAN_ONLY/NEW_REPS/HIGH_QUAL_137996/hq_metadata_no16_wPaths.tsv
#M_META=/lustre/scratch118/infgen/team162/bb11/Mouse_genomes/HIGH_QUALITY/genome_metadata_hq.tsv

# link to genome locations - not used
#H_GEN
#M_GEN=/lustre/scratch118/infgen/team162/bb11/Mouse_genomes/HIGH_QUALITY/Genomes
#M_GFFS=/lustre/scratch118/infgen/team162/bb11/Mouse_genomes/HIGH_QUALITY/gff_annotations


echo "$(timestamp) INFO : Determining host-specific genomes."


if [[ $HOST_ORG == HUMAN ]]
then
     echo "$(timestamp) INFO : Analysing genomes deriving from a HUMAN host."

     HCOUNT=$(grep -wc "$TAX_LEVEL" $H_DB)

     echo "$(timestamp) INFO : Getting the pangenome for $HCOUNT human genomes."


     if [ $HCOUNT -eq 0 ]
     then
          echo "$(timestamp) ERROR : Cannot continue due to zero genomes for this species/host combination."
	  echo "$(timestamp) INFO : Please check that you have the correct species name at gtdb.ecogenomics or with /lustre/scratch118/infgen/team162/bb11/Human_mouse_comparison/HUMAN_MOUSE_HQ_REPS/GTDB_HQ_GENOMES/human_hq_GTDBTk.tsv"
	  usage
	  exit 1
     fi


     if [ -d $OUTDIR ]
     then
          echo "$(timestamp) ERROR : Output directory already exists, please use a different name."
          usage
          exit 1
     else
          mkdir $OUTDIR
     fi


     # make temporary directory
     TMP=$OUTDIR/tmp

     mkdir $TMP

     # get genome ids
     grep -w "$TAX_LEVEL" $H_DB | cut -f1 > $OUTDIR/genome_ids.txt


elif [[ $HOST_ORG == MOUSE ]]
then
     echo "$(timestamp) INFO : Analysing genomes deriving from a MOUSE host."

     MCOUNT=$(grep -wc "$TAX_LEVEL" $M_DB)

     echo "$(timestamp) INFO : Getting the pangenome for $MCOUNT mouse genomes"


     if [ $MCOUNT -eq 0 ]
     then
          echo "$(timestamp) ERROR : Cannot continue due to zero genomes for this species/host combination."
          echo "$(timestamp) INFO : Please check that you have the correct species name at gtdb.ecogenomics.org"
          usage
          exit 1
     fi


     if [ -d $OUTDIR ]
     then
          echo "$(timestamp) ERROR : Output directory already exists, please use a different name."
          usage
          exit 1
     else
          mkdir $OUTDIR
     fi


     # make temporary directory
     TMP=$OUTDIR/tmp

     mkdir $TMP

     # get genome ids
     grep -w "$TAX_LEVEL" $M_DB | cut -f1 > $OUTDIR/genome_ids.txt


else
     "$(timestamp) ERROR : Could not resolve host organism. Exiting."
     usage
     exit 1
fi


### RUNNING CLUSTER ANALYSIS ###

if [ ! -z $RUN_CLUS ]
then
     echo "$(timestamp) INFO : Preparing to run protein cluster analysis for genomes."

     if [ -z $CLUS_LEVEL ]
     then
	  CLUS_LEVEL=90
     fi

     H_CM_UGHP100=/lustre/scratch118/infgen/team162/bb11/Human_mouse_comparison/FUNCTIONAL_COMPARISON/GENERA_COMPARISON/Protein_Catalogues/HUMAN_HIGH_QUAL/ughp100_hq_cluster_membership.sorted.out
     #CLUSMEM=/lustre/scratch118/infgen/team162/bb11/Human_mouse_comparison/FUNCTIONAL_COMPARISON/GENERA_COMPARISON/Protein_Catalogues/HIGH_QUAL_CLUSTERS/CLUS_"$CLUS_LEVEL"
     CLUSMEM=/lustre/scratch118/infgen/team162/bb11/Human_mouse_comparison/FUNCTIONAL_COMPARISON/LINCLUST/CLUS_"$CLUS_LEVEL"

     CLUST_OUT=$OUTDIR/cluster_"$CLUS_LEVEL".out
     TMPC=$TMP/cluster
     mkdir $TMPC $CLUST_OUT

     echo "$(timestamp) INFO : Getting clusters of interest for genomes."

     # species1
     sed 's/$/_/g' $OUTDIR/genome_ids.txt > $TMPC/genome_ids.txt
     grep -Ff $TMPC/genome_ids.txt $H_CM_UGHP100 > $TMPC/ughp100.tmp.tsv
     cut -f1 $TMPC/ughp100.tmp.tsv | uniq > $TMPC/ughp100.tmp.txt
     grep -Ff $TMPC/genome_ids.txt $CLUSMEM/mmseqs_cluster.tsv > $TMPC/clusmem.tmp.tsv
     cut -f1 $TMPC/clusmem.tmp.tsv | uniq > $TMPC/clusmem.tmp.txt
     grep -Fwf $TMPC/ughp100.tmp.txt $CLUSMEM/mmseqs_cluster.tsv > $TMPC/clusmem.ughp100.tmp.tsv
     cut -f1 $TMPC/clusmem.ughp100.tmp.tsv | uniq > $TMPC/clusmem.ughp100.tmp.txt

     cat $TMPC/clusmem.tmp.txt $TMPC/clusmem.ughp100.tmp.txt | sort | uniq > $TMPC/cluster_reps.txt

     GENE_COUNT=$(wc -l $TMPC/cluster_reps.txt | cut -d " " -f1)
     echo "$(timestamp) INFO : Getting $GENE_COUNT representative sequences for this pangenome."


     SPECIES_NAME=$(echo $TAX_LEVEL | sed 's/ /_/g')

     GET_FASTA_FROM_CONTIGS_v4.py -i $CLUSMEM/mmseqs_cluster_rep.fa -g $TMPC/cluster_reps.txt -o $CLUST_OUT



     if [ ! -z $RUN_EGGNOG ]
     then
	  echo "$(timestamp) INFO : Running eggNOG on cluster outputs."
	  echo "emapper.py --data_dir /nfs/pathogen/eggnogv2 -o $CLUST_OUT/$SPECIES_NAME.dmnd -i $CLUST_OUT/extracted_seqs.faa -m diamond --cpu $THREADS" > $TMPC/eggnog.sh
     fi

     if [ -z $BQUEUE ]
     then
	  BQUEUE=normal
     fi


     echo "/software/pathogen/etc/farmpy/0.42.1/wrappers/bsub.py 20 -q $BQUEUE --threads $THREADS eggNOG.$SPECIES_NAME 'sh $TMPC/eggnog.sh'" | sh

     echo "$(timestamp) INFO : EggNOG job submitted."



     if [ ! -z $RUN_INTERPROSCAN ]
     then
          echo "$(timestamp) INFO : Running InterProScan on cluster outputs."
	  echo "farm_interproscan -a $CLUST_OUT/extracted_seqs.faa -o $OUTDIR/ips_out.gff" > $TMPC/ips.sh
     fi

     echo "/software/pathogen/etc/farmpy/0.42.1/wrappers/bsub.py 10 ips-farm.$SPECIES_NAME 'sh $TMPC/ips.sh'" | sh

     echo "$(timestamp) INFO : InterProScan job submitted."


fi


