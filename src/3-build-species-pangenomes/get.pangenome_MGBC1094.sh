#!/bin/bash

# Author: Benjamin Beresford-Jones
# Date: 18-04-2020
# Version 3.1: 29-03-2021

usage()
{
cat << EOF

usage: $0 options

Get all gene annotations for a given species cluster. Implements MGBC_1094 database.

OPTIONS:

Input [REQUIRED]:
   -i      Representative genome id without file suffix (i.e. .fna, .fa)
   -t      Number of threads with which to run analyses.
   -q      Queue to submit jobs to, for use with cluster analysis [default: normal]
   -H      Specify host - either HUMAN or MOUSE.

Output - pick one of the following options:
   -o      Output directory in which to generate the results, mutually exclusive with -p [-p flag is default option].
   -p      Path to directory to build a unique output directory (e.g. REP_ID.TAX.HOST) [default: .]

Action:
   -C      Build pangenome using mmseqs gene clusters.
   -l      Level to extract gene clusters at (use with -C). Can be one of 50, 80, 90 or 100 [default: 90]
   -E      Run eggNOG v2 on pangenome.
   -I      Run InterProScan on pangenome.

module load bsub.py/0.42.1 eggnog-mapper/2.0.1--py_1 interproscan/5.39-77.0-W01

EOF
}


timestamp() {
  date +"%H:%M:%S"
}


echo "$(timestamp) INFO : Running $0"


### READING COMMANDLINE ARGUMENTS ###

REP_GENOME=
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
             REP_GENOME=$OPTARG
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
	 t)
	     THREADS=$OPTARG
	     ;;
	 q)
	     BQUEUE=$OPTARG
	     ;;
	 G)
	     RUN_GTDB=TRUE
	     ;;
         I)
             RUN_INTERPROSCAN=TRUE
             ;;
         ?)
             usage
             exit
             ;;
     esac
done

echo "$(timestamp) INFO : Setting up to build pangenome..."

WKDIR=$(pwd)

## load databases and paths:
# taxon-labelled, representative genome indexes for both hosts
H_REPMEMS=/lustre/scratch118/infgen/team162/bb11/MGBC/BUILD_PANGENOME/uhgg_rep_index_100456.tsv
M_REPMEMS=/lustre/scratch118/infgen/team162/bb11/MGBC/BUILD_PANGENOME/mgbc_rep_index_26640.tsv

LINCLUST_DB=/lustre/scratch118/infgen/team162/bb11/MGBC/LINCLUST


# check genome index paths
if [ ! -f $H_REPMEMS ]
then
	echo "$(timestamp) ERROR : Cannot locate the human genome index ($H_REPMEMS)"
	exit 1
fi

if [ ! -f $M_REPMEMS ]
then
        echo "$(timestamp) ERROR : Cannot locate the mouse genome index ($M_REPMEMS)"
        exit 1
fi

# check input arguments
if [ -z $REP_GENOME ]
then
     echo "$(timestamp) ERROR : No representative genome id supplied."
     usage
     exit 1
fi


if [ -z $THREADS ]
then
     echo "$(timestamp) ERROR : Please supply the number of threads with the -t flag."
     usage
     exit 1
fi

# check host organism
if [ -z $HOST_ORG ]
then
     echo "$(timestamp) ERROR : No host organism specified with the -H flag, please pick from HUMAN or MOUSE."
     usage
     exit 1
fi

if [[ $HOST_ORG != HUMAN ]] && [[ $HOST_ORG != MOUSE ]]
then
     echo "$(timestamp) ERROR : Please supply one of HUMAN or MOUSE with the -H flag. The current entry is invalid."
     usage
     exit 1
fi

# check representative genome exists and is a species representative; get taxon
if $(grep -Fwq "$REP_GENOME" $M_REPMEMS $H_REPMEMS)
then
	REP_TAX=$(awk -v genid="$REP_GENOME" ' $1 ~ genid ' $M_REPMEMS $H_REPMEMS | cut -f3 | sed 's/ /_/g')
else
	echo "$(timestamp) ERROR : Representative genome could not be located within the genome index files. Exiting."
	usage
	exit 1
fi

if [ $(awk -v genid="$REP_GENOME" ' $1 ~ genid ' $M_REPMEMS $H_REPMEMS | awk ' $1 == $2 ' | wc -l) == 0 ]
then
	echo "$(timestamp) ERROR : Genome id provided is not a species representative. Exiting."
	usage
	exit 1
fi

# check output options
if [ ! -z $OUTDIR ] && [ ! -z $PREFIX ]
then
     echo "$(timestamp) ERROR : Please supply only one output format, either outdir PREFIX (-p) or specified OUTDIR (-o)."
     usage
     exit 1
elif [ -z $OUTDIR ] && [ -z $PREFIX ]
then
     echo "$(timestamp) WARNING : No output format specified so using standard outdir formulation in the working directory."
     OUTDIR=$REP_GENOME.$REP_TAX.$HOST_ORG
     echo "$(timestamp) INFO : Writing output to $OUTDIR"
elif [ -z $OUTDIR ]
then
     WRITEDIR=$REP_GENOME.$REP_TAX.$HOST_ORG
     OUTDIR=$PREFIX/$WRITEDIR
     echo "$(timestamp) INFO : Writing output to $OUTDIR"
     mkdir -p $PREFIX
else
     echo "$(timestamp) INFO : Writing output to $OUTDIR"
fi

if [ -z $BQUEUE ]
then
     BQUEUE=normal
fi

# load modules
module load bsub.py/0.42.1 drep/2.5.4 fastani/1.3--he1c1bb9_0 roary/3.13.0 r/3.6.0 eggnog-mapper/2.0.1--py_1 gtdbtk/1.3.0--py_1 fasttreemp/2.1.11 interproscan/5.39-77.0-W01


echo "$(timestamp) INFO : Determining host-specific genomes."

if [[ $HOST_ORG == HUMAN ]]
then
     echo "$(timestamp) INFO : Analysing genomes deriving from a HUMAN host."

     HCOUNT=$(grep -wc "$REP_GENOME" $H_REPMEMS)

     echo "$(timestamp) INFO : Building the pangenome for $HCOUNT human genomes."

     if [ $HCOUNT -eq 0 ]
     then
          echo "$(timestamp) ERROR : Cannot continue due to zero genomes for this species/host combination."
	  echo "$(timestamp) INFO : Please check that you have the correct genome id for the reference genome."
	  usage
	  exit 1
     fi

     if [ -d $OUTDIR ]
     then
          echo "$(timestamp) ERROR : Output directory already exists, please use a different name."
          usage
          exit 1
     else
          mkdir -p $OUTDIR
     fi

     # get genome ids
     grep -Fw "$REP_GENOME" $H_REPMEMS | cut -f1 > $OUTDIR/genome_ids.txt


elif [[ $HOST_ORG == MOUSE ]]
then
     echo "$(timestamp) INFO : Analysing genomes deriving from a MOUSE host."

     MCOUNT=$(grep -Fwc "$REP_GENOME" $M_REPMEMS)

     echo "$(timestamp) INFO : Building the pangenome for $MCOUNT mouse genomes"

     if [ $MCOUNT -eq 0 ]
     then
          echo "$(timestamp) ERROR : Cannot continue due to zero genomes for this species/host combination."
          echo "$(timestamp) INFO : Please check your representative genome against the metadata files."
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


     # get genome ids
     grep -Fw "$REP_GENOME" $M_REPMEMS | cut -f1 > $OUTDIR/genome_ids.txt

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

     CLUSMEM=$LINCLUST_DB/CLUS_"$CLUS_LEVEL"

	if [ ! -d $CLUSMEM ] || [ ! -f $CLUSMEM/combined_mmseqs_cluster.tsv ]
	then
		echo "$(timestamp) ERROR : cluster directory or contained file combined_mmseqs_cluster.tsv does not exist ($CLUSMEM)."
		exit 1
	fi

     CLUST_OUT=$OUTDIR/cluster_"$CLUS_LEVEL".out
     SCRIPTS=$OUTDIR/scripts
     mkdir $CLUST_OUT $SCRIPTS

     echo "$(timestamp) INFO : Getting gene clusters for genomes."

     grep -Ff $OUTDIR/genome_ids.txt $CLUSMEM/combined_mmseqs_cluster.tsv | cut -f1 | uniq | sort -u > $CLUST_OUT/cluster_reps.txt

     GENE_COUNT=$(wc -l $CLUST_OUT/cluster_reps.txt | cut -d " " -f1)

     echo "$(timestamp) INFO : Getting $GENE_COUNT representative sequences for this pangenome."
     echo "GET_FASTA_FROM_CONTIGS_v4.py -i $CLUSMEM/mmseqs_cluster_rep.fa -g $CLUST_OUT/cluster_reps.txt -o $CLUST_OUT"
     GET_FASTA_FROM_CONTIGS_v4.py -i $CLUSMEM/mmseqs_cluster_rep.fa -g $CLUST_OUT/cluster_reps.txt -o $CLUST_OUT

     if [ ! -z $RUN_EGGNOG ]
     then
	  echo "$(timestamp) INFO : Running eggNOG on cluster outputs."
	  echo "emapper.py --data_dir /nfs/pathogen/eggnogv2 -o $CLUST_OUT/$REP_GENOME.dmnd -i $CLUST_OUT/extracted_seqs.faa -m diamond --cpu $THREADS" > $SCRIPTS/run_eggnog.sh
          echo "/software/pathogen/etc/bsub.py/0.42.1/wrappers/bsub.py 20 -q $BQUEUE --threads $THREADS eggnog.$REP_GENOME 'sh $SCRIPTS/run_eggnog.sh'" | sh
          echo "$(timestamp) INFO : eggNOG v2 job submitted."
     fi

     if [ ! -z $RUN_INTERPROSCAN ]
     then
          echo "$(timestamp) INFO : Running InterProScan on cluster outputs."
	  echo "farm_interproscan -a $CLUST_OUT/extracted_seqs.faa -o $CLUST_OUT/ips_out.gff" > $SCRIPTS/run_ips.sh
          echo "/software/pathogen/etc/bsub.py/0.42.1/wrappers/bsub.py 10 ips.$REP_GENOME 'sh $SCRIPTS/run_ips.sh'" | sh
          echo "$(timestamp) INFO : InterProScan v5 job submitted."
     fi

fi

echo "$(timestamp) INFO : Pipeline complete."
