#!/bin/bash

usage()
{
cat << EOF
usage: $0 options

Summarise an InterProScan output, returning feature-gene and gene-genome indices.

OPTIONS:
   -i      Path to IPS output file (gff-format).
   -a      Path to original fasta file used for IPS. 
   -o      Directory to write to.
   -g	   Path to genome ids file.
   -H      Host organism: either HUMAN or MOUSE

EOF
}

INFILE=
INFASTA=
OUTDIR=
HOST_ORG=
GENOME_IDS=

while getopts “i:a:g:o:H:” OPTION
do
     case ${OPTION} in
         i)
             INFILE=${OPTARG}
             ;;
	 a)
	     INFASTA=${OPTARG}
	     ;;
         o)
             OUTDIR=${OPTARG}
             ;;
	 g)
	     GENOME_IDS=${OPTARG}
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

# load databases
CLUS_MEM=/lustre/scratch118/infgen/team162/bb11/MGBC/LINCLUST/CLUS_90/combined_mmseqs_cluster.tsv
IPS_DATA=/lustre/scratch118/infgen/team162/bb11/External_databases/InterPro


WKDIR=$(pwd)

if [ ! -f $CLUS_MEM ]
then
     echo "(timestamp) ERROR : Cluster membership file cannot be found. Exiting."
     exit 1
fi


if [ ! -d $IPS_DATA ]
then
     echo "(timestamp) ERROR : IPS data directory cannot be found. Exiting."
     exit 1
fi


if [ -z $INFILE ] || [ ! -f $INFILE ]
then
     echo "$(timestamp) ERROR : Please supply the path to the IPS output gff file."
     usage
     exit 1
fi


if [ -z $INFASTA ] || [ ! -f $INFASTA ]
then
     echo "$(timestamp) ERROR : Please supply the path to the fasta file used to run IPS. Exiting."
     usage
     exit 1
fi


if [ -z $GENOME_IDS ] || [ ! -f $GENOME_IDS ]
then
     echo "$(timestamp) ERROR : Please supply the genome_ids.txt file for this pangenome. Exiting."
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
     echo "$(timestamp) ERROR : Please supply the path to the directory to write the output to. Exiting."
     usage
     exit 1
fi


if [ ! -d $OUTDIR ]
then
     mkdir $OUTDIR
fi


echo "$(timestamp) INFO : Writing output files to $OUTDIR."

echo "$(timestamp) INFO : Setting up to analyse IPS output."

TMP=$OUTDIR/ips.tmp

if [ ! -d $TMP ]
then
     mkdir $TMP
fi

# get annotation efficiency statistics
echo "$(timestamp) INFO : Getting annotation efficiency statistics."
GENE_COUNT=$(grep -Fc ">" $INFASTA)
GO_TERM=$(grep "Ontology_term" $INFILE | cut -f1 | sort -u | wc -l)
IPS_ALL=$(grep "InterPro:" $INFILE | cut -f1 | sort -u | wc -l)
IPS_FAM=$(grep -Fwf $IPS_DATA/FAMILY_index.txt $INFILE | cut -f1 | sort -u | wc -l)
KEGG=$(grep "KEGG" $INFILE | cut -f1 | sort -u | wc -l)
METACYC=$(grep "MetaCyc" $INFILE | cut -f1 | sort -u | wc -l)
REACT=$(grep "Reactome" $INFILE | cut -f1 | sort -u | wc -l)

printf "ORIG_GENE_COUNT\t$GENE_COUNT\n" > $OUTDIR/annotation_stats.tsv
printf "GO_COUNT\t$GO_TERM\n" >> $OUTDIR/annotation_stats.tsv
printf "TOTAL_IPS_COUNT\t$IPS_ALL\n" >> $OUTDIR/annotation_stats.tsv
printf "FAMILY_IPS_COUNT\t$IPS_FAM\n" >> $OUTDIR/annotation_stats.tsv
printf "KEGG_COUNT\t$KEGG\n" >> $OUTDIR/annotation_stats.tsv
printf "METACYC_COUNT\t$METACYC\n" >> $OUTDIR/annotation_stats.tsv
printf "REACTOME_COUNT\t$REACT\n" >> $OUTDIR/annotation_stats.tsv

echo "$(timestamp) INFO : Getting output."
# summarise the IPS output
grep -Fw -e "Dbxref" -e "Ontology_term" $INFILE | grep -o -e 'Ontology_term=.*' -e 'Dbxref=".*"' | sed 's/;/\n/g' | grep -e "Ontology_term" -e "Dbxref" | sed -e 's/,/\n/g' -e 's/Ontology_term=//g' -e 's/Dbxref=//g' -e 's/"//g' | sed 's/:/\t/g' | sort -u > $OUTDIR/ips.summary.tsv

# get relevant gene clusters
if [[ $HOST_ORG == HUMAN ]]
then
	grep -Ff $GENOME_IDS $CLUS_MEM | awk ' $2 ~ /GUT_GENOME/ ' > $TMP/clus_tmp.tsv
	cut -f1 $TMP/clus_tmp.tsv > $TMP/c1.tmp
	cut -f2 $TMP/clus_tmp.tsv | cut -d "_" -f1,2 > $TMP/c2.tmp

elif [[ $HOST_ORG == MOUSE ]]
then
	grep -Ff $GENOME_IDS $CLUS_MEM | awk ' $2 ~ /MGBC/ ' > $TMP/clus_tmp.tsv
	cut -f1 $TMP/clus_tmp.tsv > $TMP/c1.tmp
	cut -f2 $TMP/clus_tmp.tsv | cut -d "_" -f1 > $TMP/c2.tmp

else
	echo "$(timestamp) ERROR : Could not resolve host, exiting."
	exit 1
fi

paste $TMP/c1.tmp $TMP/c2.tmp > $TMP/gg_tmp.tsv

while read GENOME
do
	awk -v gen=$GENOME ' $2 ~ gen ' $TMP/gg_tmp.tsv
done < $GENOME_IDS > $OUTDIR/gg_index.tsv

rm -r $TMP

echo "$(timestamp) INFO : Done."
