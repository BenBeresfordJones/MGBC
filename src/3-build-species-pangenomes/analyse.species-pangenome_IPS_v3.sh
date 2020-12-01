#!/bin/bash

usage()
{
cat << EOF
usage: $0 options

Analyse an InterProScan output for a pangenome.

OPTIONS:
   -i      Path to the pangenome directory.
   -D      Directory containing the IPS family reference databases [not implemented]
   -o      Directory to write to [default: <-i>/IPS-out]
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

ANNOTATION=$INDIR/ips_out.gff

if [ ! -f $ANNOTATION ]
then
     echo "$(timestamp) ERROR : Could not locate the ips_out.gff file in the cluster directory supplied. Exiting."
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
     OUTDIR=$INDIR/IPS-out
fi

if [ ! -d $OUTDIR ]
then
     mkdir $OUTDIR
fi

PAN_PREFIX=pangenome-ips
PAN_OUT=$OUTDIR/pangenome-ips

CORE_PREFIX=core-genome

echo "$(timestamp) INFO : Writing output files to $OUTDIR."

echo "$(timestamp) INFO : Setting up to analyse IPS output."

TMP=$OUTDIR/tmp

if [ ! -d $TMP ]
then
     mkdir $TMP
fi

if [ -z $DATA ]
then
     DATA=/lustre/scratch118/infgen/team162/bb11/External_databases/InterPro
fi

if [ ! -d $DATA ]
then
     echo "(timestamp) ERROR : IPS Family database directory cannot be found. Exiting..."
     usage
     exit 1
fi

OUTFILE=$OUTDIR/$PREFIX

### RUN IPS ANALYSIS ###

# loading databases
CLUS_90_MEM=/lustre/scratch118/infgen/team162/bb11/Human_mouse_comparison/FUNCTIONAL_COMPARISON/LINCLUST/CLUS_90/mmseqs_cluster.tsv
UHGP_100=/lustre/scratch118/infgen/team162/bb11/Human_mouse_comparison/FUNCTIONAL_COMPARISON/UHGG_FAA-100456/get_cluster_membership.out.tsv
#/lustre/scratch118/infgen/team162/bb11/Human_mouse_comparison/FUNCTIONAL_COMPARISON/GENERA_COMPARISON/Protein_Catalogues/HUMAN_HIGH_QUAL/ughp100_hq_cluster_membership.sorted.out

H_DB=/lustre/scratch118/infgen/team162/bb11/Human_mouse_comparison/FUNCTIONAL_COMPARISON/BUILD_PANGENOME/GTDB_DBs/human-100456.tsv
M_DB=/lustre/scratch118/infgen/team162/bb11/Human_mouse_comparison/FUNCTIONAL_COMPARISON/BUILD_PANGENOME/GTDB_DBs/mouse-18075.tsv


if [ ! -f $OUTDIR/FAM_all_data.tsv ]
then

     echo "$(timestamp) INFO : Getting IPS data."

     get.ips-data.sh -a $ANNOTATION -o $PAN_OUT -p $PAN_PREFIX -f $ORIG_FAA

     GENE_IPR=$PAN_OUT/$PAN_PREFIX.tmp/gene-ipr.tsv

### Get data for all genomes.

     echo "$(timestamp) INFO : Analysing data for all genomes."
     echo "$(timestamp) INFO : Setting up."


     TOTAL_GENOME_COUNT=$(wc -l $INDIR/genome_ids.txt | cut -d " " -f1)

     sed 's/$/_/g' $INDIR/genome_ids.txt > $TMP/genome_ids.txt

     if [ ! -f $TMP/genome-cluster_mem-index.tsv ]
     then

	  if [ -f $INDIR/eggnog-out/tmp/genome-cluster_mem-index.tsv ]
	  then
	       cp $INDIR/eggnog-out/tmp/genome-cluster_mem-index.tsv $TMP

	  elif [[ $HOST_ORG == HUMAN ]]
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

          else
               echo "$(timestamp) ERROR : Could not resolve host. Exiting."
               exit 1
          fi

     fi


     if [ -f $TMP/all-IPR-genome_count.tsv ]
     then
	  rm $TMP/all-IPR-genome_count.tsv
     fi

     cut -f2 $PAN_OUT/$PAN_PREFIX.all_ipr.out.tsv | while read IPR
     do
          echo -e "\t\tExtracting genomes for $IPR."
	  IPR_GENOME_COUNT=$(echo "$IPR" | grep -Fwf - $GENE_IPR | cut -f1 | grep -Fwf - $TMP/genome-cluster_mem-index.tsv | cut -f2 | sort | uniq | wc -l)
	  echo -e "$IPR\t$IPR_GENOME_COUNT\t$TOTAL_GENOME_COUNT" >> $TMP/all-IPR-genome_count.tsv
     done


     if [ -f $TMP/family-IPR-genome_count.tsv ]
     then
	  rm $TMP/family-IPR-genome_count.tsv
     fi

     cut -f2 $PAN_OUT/$PAN_PREFIX.family_ipr.out.tsv | while read IPR
     do
          echo -e "\t\tExtracting genomes for $IPR."
          IPR_GENOME_COUNT=$(echo "$IPR" | grep -Fwf - $GENE_IPR | cut -f1 | grep -Fwf - $TMP/genome-cluster_mem-index.tsv | cut -f2 | sort | uniq | wc -l)
	  IPR_GENOME_COUNT_NR=$(echo "$IPR" | grep -Fwf - $GENE_IPR | cut -f1 | grep -Fwf - $TMP/genome-cluster_mem-index.tsv | wc -l)
          echo -e "$IPR\t$IPR_GENOME_COUNT\t$IPR_GENOME_COUNT_NR\t$TOTAL_GENOME_COUNT" >> $TMP/family-IPR-genome_count.tsv
     done


     echo "$(timestamp) INFO : Finished collecting data."


     echo "$(timestamp) INFO : Defining core genome and building presence-absence matrices."


     SPECIES_NAME=$(echo $INDIR | rev | cut -d/ -f1 | rev)

     cp ~/Scripts/pangenome-IPS_2.R $TMP

     Rscript $TMP/pangenome-IPS_2.R -A $TMP/all-IPR-genome_count.tsv -F $TMP/family-IPR-genome_count.tsv -n $SPECIES_NAME -o $OUTDIR

     echo "$(timestamp) INFO : Finished workflow."

else

     echo "$(timestamp) WARNING : $OUTDIR/all_data.tsv already exists. Please make sure you know what you are doing."
     exit 1
     usage

fi

