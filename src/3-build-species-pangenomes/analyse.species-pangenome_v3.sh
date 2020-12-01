#!/bin/bash

usage()
{
cat << EOF
usage: $0 options

Analyse an eggnog output for a pangenome.

OPTIONS:
   -i      Path to the pangenome directory.
   -D      Directory containing the eggNOG reference databases [not implemented]
   -o      Directory to write to [default: <-i>/eggnog-out]
   -H      Host organism: either HUMAN or MOUSE

EOF
}

INDIR=
DATA=
OUTDIR=
HOST_ORG=

while getopts “i:o:H:” OPTION
do
     case ${OPTION} in
         i)
             INDIR=${OPTARG}
             ;;
         o)
             OUTDIR=${OPTARG}
             ;;
	 H)
	     HOST_ORG=${OPTARG}
	     ;;
         ?)
             usage
             exit
             ;;
     esac
done

timestamp() {
date +"%H:%M:%S"
}

echo "$(date)"
echo "$(timestamp) INFO : Running $@"

WKDIR=$(pwd)

if [ -z $INDIR ]
then
     echo "$(timestamp) ERROR : Please supply the path to the cluster output directory."
     usage
     exit 1
fi

CLUSTER_DIR=$(find $INDIR | grep "cluster_90.out" | head -n1)

if [ ! -d $CLUSTER_DIR ]
then
     echo "$(timestamp) ERROR : Could not locate the cluster directory. Exiting."
     usage
     exit 1
fi

ANNOTATION=$(find $CLUSTER_DIR | grep "annotations")

if [ ! -f $ANNOTATION ]
then
     echo "$(timestamp) ERROR : Could not locate the eggnog annotation file in the cluster directory supplied. Exiting."
     usage
     exit 1
fi

ORIG_FAA=$(find $CLUSTER_DIR | grep "extracted_seqs.faa")


if [ ! -f $ORIG_FAA ]
then
     echo "$(timestamp) ERROR : Could not find the extracted_seqs.faa file. Exiting."
     usage
     exit 1
fi

if [ ! -f $INDIR/genome_ids.txt ]
then
     echo "$(timestamp) ERROR : Cannot locate the genome_ids.txt file for this pangenome. Exiting."
     usage
     exit 1
fi

if [ -z $HOST_ORG ]
then
     echo "$(timestamp) ERROR : Please supply either HUMAN or MOUSE with -H to specify the host organism."
     usage
     exit 1
fi

if [[ $HOST_ORG != MOUSE ]] && [[ $HOST_ORG != HUMAN ]]
then
     echo "$(timestamp) ERROR : Please supply either HUMAN or MOUSE as the host organism."
     usage
     exit 1
fi

if [ -z $OUTDIR ]
then
     OUTDIR=$INDIR/eggnog-out
fi

if [ ! -d $OUTDIR ]
then
     mkdir $OUTDIR
fi

PAN_PREFIX=pangenome-eggnog
PAN_OUT=$OUTDIR/pangenome-eggnog

CORE_PREFIX=core-genome

echo "$(timestamp) INFO : Writing output files to $OUTDIR."

echo "$(timestamp) INFO : Setting up to analyse eggNOG output."

TMP=$OUTDIR/tmp

if [ ! -d $TMP ]
then
     mkdir $TMP
fi

if [ -z $DATA ]
then
     DATA=/lustre/scratch118/infgen/team162/bb11/Human_mouse_comparison/FUNCTIONAL_COMPARISON/REPRESENTATIVE_eggNOG/KEGG_DB
fi

if [ ! -d $DATA ]
then
     echo "(timestamp) ERROR : KEGG database directory cannot be found. Exiting..."
     usage
     exit 1
fi

OUTFILE=$OUTDIR/$PREFIX

### RUN EGGNOG ANALYSIS ###

# loading databases
CLUS_90_MEM=/lustre/scratch118/infgen/team162/bb11/Human_mouse_comparison/FUNCTIONAL_COMPARISON/LINCLUST/CLUS_90/mmseqs_cluster.tsv
#/lustre/scratch118/infgen/team162/bb11/Human_mouse_comparison/FUNCTIONAL_COMPARISON/GENERA_COMPARISON/Protein_Catalogues/HIGH_QUAL_CLUSTERS/CLUS_90/mmseqs_cluster.tsv
UHGP_100=/lustre/scratch118/infgen/team162/bb11/Human_mouse_comparison/FUNCTIONAL_COMPARISON/UHGG_FAA-100456/get_cluster_membership.out.tsv
#/lustre/scratch118/infgen/team162/bb11/Human_mouse_comparison/FUNCTIONAL_COMPARISON/GENERA_COMPARISON/Protein_Catalogues/HUMAN_HIGH_QUAL/ughp100_hq_cluster_membership.sorted.out

H_DB=/lustre/scratch118/infgen/team162/bb11/Human_mouse_comparison/FUNCTIONAL_COMPARISON/BUILD_PANGENOME/GTDB_DBs/human-100456.tsv
#/lustre/scratch118/infgen/team162/bb11/Human_mouse_comparison/HUMAN_MOUSE_HQ_REPS/GTDB_HQ_GENOMES/human_hq_GTDBTk.tsv
M_DB=/lustre/scratch118/infgen/team162/bb11/Human_mouse_comparison/FUNCTIONAL_COMPARISON/BUILD_PANGENOME/GTDB_DBs/mouse-18075.tsv
#/lustre/scratch118/infgen/team162/bb11/Human_mouse_comparison/HUMAN_MOUSE_HQ_REPS/GTDB_HQ_GENOMES/mouse_hq_GTDBTk.tsv


if [ ! -f $OUTDIR/all_data.tsv ]
then

echo "$(timestamp) INFO : Getting eggnog data."

get.eggnog-data.sh -a $ANNOTATION -o $PAN_OUT -p $PAN_PREFIX -f $ORIG_FAA



### Get data for all genomes.

echo "$(timestamp) INFO : Analysing data for all genomes."
echo "$(timestamp) INFO : Setting up."

if [ -f $TMP/genome-cluster_mem-index.tsv ]
then
     rm $TMP/genome-cluster_mem-index.tsv
fi


if [ -f $TMP/KO-genome_count.tsv ]
then
     rm $TMP/KO-genome_count.tsv
fi

TOTAL_GENOME_COUNT=$(wc -l $INDIR/genome_ids.txt | cut -d " " -f1)

sed 's/$/_/g' $INDIR/genome_ids.txt > $TMP/genome_ids.txt

if [[ $HOST_ORG == HUMAN ]]
then
     grep -f $TMP/genome_ids.txt $UHGP_100 > $TMP/ughp_100.tmp.tsv
     cut -f1 $TMP/ughp_100.tmp.tsv | grep -Fwf - $CLUS_90_MEM > $TMP/clus_90.tmp.tsv

     echo "$(timestamp) INFO : Building a cluster-genome index database."
     for GENOME in $(cat $TMP/genome_ids.txt)
     do
	  echo -e "\t\tFinding cluster reps for ${GENOME%"_"}."
          echo $GENOME | grep -f - $TMP/ughp_100.tmp.tsv | cut -f1 | grep -Fwf - $TMP/clus_90.tmp.tsv | cut -f1 | sort | uniq | while read CLUSTER
          do
     	  echo -e "$CLUSTER\t${GENOME%"_"}" >> $TMP/genome-cluster_mem-index.tsv
          done
     done

     cut -f2 $PAN_OUT/$PAN_PREFIX.KO.out.tsv | while read KO
     do
	  echo -e "\t\tExtracting genomes for $KO."
          KO_GENOME_COUNT=$(echo "$KO" | grep -Fwf - $ANNOTATION | cut -f1 | grep -Fwf - $TMP/genome-cluster_mem-index.tsv | cut -f2 | sort | uniq | wc -l)
	  echo -e "$KO\t$KO_GENOME_COUNT\t$TOTAL_GENOME_COUNT" >> $TMP/KO-genome_count.tsv
     done

elif [[ $HOST_ORG == MOUSE ]]
then
     grep -f $TMP/genome_ids.txt $CLUS_90_MEM > $TMP/clus_90.tmp.tsv

     echo "$(timestamp) INFO : Building a cluster-gene index database."
     for GENOME in $(cat $TMP/genome_ids.txt)
     do
	  echo -e "\t\tFinding cluster reps for ${GENOME%"_"}."
	  echo $GENOME | grep -f - $TMP/clus_90.tmp.tsv | cut -f1 | sort | uniq | while read CLUSTER
	  do
	       echo -e "$CLUSTER\t${GENOME%"_"}" >> $TMP/genome-cluster_mem-index.tsv
	  done
     done

     cut -f2 $PAN_OUT/$PAN_PREFIX.KO.out.tsv | while read KO
     do
	  echo -e "\t\tExtracting genomes for $KO."
	  KO_GENOME_COUNT=$(echo "$KO" | grep -Fwf - $ANNOTATION | cut -f1 | grep -Fwf - $TMP/genome-cluster_mem-index.tsv | cut -f2 | sort | uniq | wc -l)
	  echo -e "$KO\t$KO_GENOME_COUNT\t$TOTAL_GENOME_COUNT" >> $TMP/KO-genome_count.tsv
     done
else
     echo "$(timestamp) ERROR : Could not resolve host. Exiting."
     exit 1
fi

echo "$(timestamp) INFO : Finished collecting data."



echo "$(timestamp) INFO : Defining core genome and building presence-absence matrices."

SPECIES_NAME=$(echo $INDIR | rev | cut -d/ -f1 | rev)

pangenome-eggnog.R -i $TMP/KO-genome_count.tsv -n $SPECIES_NAME -o $OUTDIR


echo "$(timestamp) INFO : Finished workflow."

fi

echo "$(timestamp) INFO : Generating pangenome with EGGNOG_OGs."
## get OG COG pangenome.

echo "$HOST_ORG"

#if [[ $HOST_ORG == HUMAN ]]
#then

#     cut -f2 $PAN_OUT/$PAN_PREFIX.EGGNOG_OG.out.tsv | while read KO
#     do
#	  echo -e "\t\tExtracting genomes for $KO."
#	  KO_GENOME_COUNT=$(echo "$KO" | grep -Fwf - $ANNOTATION | cut -f1 | grep -Fwf - $TMP/genome-cluster_mem-index.tsv | cut -f2 | sort | uniq | wc -l)
#	  KO_GENOME_COUNT_NR=$(echo "$KO" | grep -Fwf - $ANNOTATION | cut -f1 | grep -Fwf - $TMP/genome-cluster_mem-index.tsv | cut -f2 | wc -l) # non-redundant genome count
#	  echo -e "$KO\t$KO_GENOME_COUNT\t$KO_GENOME_COUNT_NR\t$TOTAL_GENOME_COUNT" >> $TMP/EGGNOG_COG-genome_count.tsv
#     done
#elif [[ $HOST_ORG == MOUSE ]]


TOTAL_GENOME_COUNT=$(wc -l $INDIR/genome_ids.txt | cut -d " " -f1)

if [ -f $TMP/EGGNOG_COG-genome_count.tsv ]; then rm $TMP/EGGNOG_COG-genome_count.tsv; fi

if [[ $HOST_ORG == HUMAN ]]
then

     cut -f2 $PAN_OUT/$PAN_PREFIX.EGGNOG_OG.out.tsv | awk ' $1 ~ /^COG/ ' | cut -d "@" -f1 | sort | uniq | while read KO
     do
          echo -e "\t\tExtracting genomes for $KO."
          KO_GENOME_COUNT=$(echo "$KO" | grep -Fwf - $ANNOTATION | cut -f1 | grep -Fwf - $TMP/genome-cluster_mem-index.tsv | cut -f2 | sort | uniq | wc -l)
	  KO_GENOME_COUNT_NR=$(echo "$KO" | grep -Fwf - $ANNOTATION | cut -f1 | grep -Fwf - $TMP/genome-cluster_mem-index.tsv | cut -f2 | wc -l) # non-redundant genome count
          echo -e "$KO\t$KO_GENOME_COUNT\t$KO_GENOME_COUNT_NR\t$TOTAL_GENOME_COUNT" >> $TMP/EGGNOG_COG-genome_count.tsv
     done

elif [[ $HOST_ORG == MOUSE ]]
then
     cut -f2 $PAN_OUT/$PAN_PREFIX.EGGNOG_OG.out.tsv | awk ' $1 ~ /^COG/ ' | cut -d "@" -f1 | sort | uniq | while read KO
     do
          echo -e "\t\tExtracting genomes for $KO."
          KO_GENOME_COUNT=$(echo "$KO" | grep -Fwf - $ANNOTATION | cut -f1 | grep -Fwf - $TMP/genome-cluster_mem-index.tsv | cut -f2 | sort | uniq | wc -l)
          KO_GENOME_COUNT_NR=$(echo "$KO" | grep -Fwf - $ANNOTATION | cut -f1 | grep -Fwf - $TMP/genome-cluster_mem-index.tsv | cut -f2 | wc -l) # non-redundant genome count
          echo -e "$KO\t$KO_GENOME_COUNT\t$KO_GENOME_COUNT_NR\t$TOTAL_GENOME_COUNT" >> $TMP/EGGNOG_COG-genome_count.tsv
     done

else

     echo "$(timestamp) ERROR : Could not resolve host. Exiting."
     exit 1

fi

echo "$(timestamp) INFO : Done!"


echo "$(timestamp) INFO : Defining core genome and building presence-absence matrices."

if [ ! -d $OUTDIR/EGGNOG_COGS ]
then
     mkdir $OUTDIR/EGGNOG_COGS ]
fi

SPECIES_NAME=$(echo $INDIR | rev | cut -d/ -f1 | rev)

pangenome-eggnog_OG-COG.R -i $TMP/EGGNOG_COG-genome_count.tsv -n $SPECIES_NAME -o $OUTDIR/EGGNOG_COGS


echo "$(timestamp) INFO : Finished workflow."

