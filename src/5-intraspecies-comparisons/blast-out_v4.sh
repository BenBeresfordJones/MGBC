#!/bin/bash


usage()
{
cat << EOF
usage: $0 options

Analyse runs blastp and analyses results.

OPTIONS:
   -i      Path to fasta file to run pblast on.
   -s      Sequence identity to use as threshold [default: 50].
   -o      Directory to write blast outputs to.

EOF
}

BLAST_IN=
SEQ_ID=
OUT=

while getopts “i:s:o:” OPTION
do
     case ${OPTION} in
         i)
             BLAST_IN=${OPTARG}
             ;;
         o)
             OUT=${OPTARG}
             ;;
         s)
             SEQ_ID=${OPTARG}
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


if [ -z $BLAST_IN ]
then
     echo "$(timestamp) ERROR : Please supply a path to the blast output file."
     usage
     exit 1
fi

if [ ! -f $BLAST_IN ]
then
     echo "$(timestamp) ERROR : The blast output file specified does not exist."
     usage
     exit 1
fi


if [ -z $SEQ_ID ]
then
     SEQ_ID=50
fi


if [ -z $OUT ]
then
     OUT=$(pwd)
fi

if [ ! -d $OUT ]; then mkdir $OUT; fi


### RUN BLAST ###
CLUS_100_REP=/lustre/scratch118/infgen/team162/bb11/Human_mouse_comparison/FUNCTIONAL_COMPARISON/LINCLUST/CLUS_100/mmseqs_cluster_rep.fa
GEN_NAME=$(echo $BLAST_IN | rev | cut -d/ -f1 | rev | sed 's/.faa//g' | sed 's/.fa//g')
BLAST_OUT=$(echo "$OUT/$GEN_NAME.blast")

echo "Running blast."

blastp -query $BLAST_IN -db $CLUS_100_REP -outfmt "6 qseqid sseqid pident bitscore evalue length qlen slen" -evalue 1e-5 -max_target_seqs 50000 -out $BLAST_OUT


# loading databases
CLUS_100_MEM=/lustre/scratch118/infgen/team162/bb11/Human_mouse_comparison/FUNCTIONAL_COMPARISON/LINCLUST/CLUS_100/mmseqs_cluster.tsv
UHGP_100=/lustre/scratch118/infgen/team162/bb11/Human_mouse_comparison/FUNCTIONAL_COMPARISON/UHGG_FAA-100456/get_cluster_membership.out.tsv
#/lustre/scratch118/infgen/team162/bb11/Human_mouse_comparison/FUNCTIONAL_COMPARISON/GENERA_COMPARISON/Protein_Catalogues/HUMAN_HIGH_QUAL/ughp100_hq_cluster_membership.sorted.out

H_DB=/lustre/scratch118/infgen/team162/bb11/Human_mouse_comparison/FUNCTIONAL_COMPARISON/BUILD_PANGENOME/GTDB_DBs/human-100456.tsv
#/lustre/scratch118/infgen/team162/bb11/Human_mouse_comparison/HUMAN_MOUSE_HQ_REPS/GTDB_HQ_GENOMES/human_hq_GTDBTk.tsv
M_DB=/lustre/scratch118/infgen/team162/bb11/Human_mouse_comparison/FUNCTIONAL_COMPARISON/BUILD_PANGENOME/GTDB_DBs/mouse-18075.tsv
#/lustre/scratch118/infgen/team162/bb11/Human_mouse_comparison/HUMAN_MOUSE_HQ_REPS/GTDB_HQ_GENOMES/mouse_hq_GTDBTk.tsv

BLAST_IN=$BLAST_OUT


echo "$(timestamp) INFO : Analysing blast output."

OUTDIR=$OUT/ANALYSIS_"$SEQ_ID"
if [ ! -d $OUTDIR ]; then mkdir $OUTDIR; fi

ANALYSIS_PATH=$OUTDIR/$GEN_NAME

awk -v SEQ_ID=$SEQ_ID ' $3 >= SEQ_ID && $4 >= 50 ' $BLAST_IN > $ANALYSIS_PATH.qc

cut -f2 $ANALYSIS_PATH.qc | grep -Fwf - $CLUS_100_MEM > $ANALYSIS_PATH.genes-tmp


echo "$(timestamp) INFO : Getting human data."

cut -f2 $ANALYSIS_PATH.genes-tmp | grep -F "GUT_GENOME" | grep -Fwf - $UHGP_100 > $ANALYSIS_PATH.genes-human

cut -f2 $ANALYSIS_PATH.genes-human | cut -d_ -f1,2 | sort | uniq | grep -Fwf - $H_DB > $ANALYSIS_PATH.genome_taxonomy-human.tsv

while read LINE
do
     GENOME=$(echo $LINE | cut -d \  -f2)
     BLAST_DATA=$(echo $LINE | cut -d \  -f1 | grep -Fwf - $ANALYSIS_PATH.genes-tmp | cut -f1 | uniq | grep -Fwf - $ANALYSIS_PATH.qc | head -n1)
     TAXONOMY=$(echo $GENOME | cut -d_ -f1,2 | grep -Fwf - $ANALYSIS_PATH.genome_taxonomy-human.tsv)
     echo -e "$TAXONOMY\t$BLAST_DATA\tHUMAN"
done < $ANALYSIS_PATH.genes-human > $ANALYSIS_PATH.human.tsv



echo "$(timestamp) INFO : Getting mouse data."

cut -f2 $ANALYSIS_PATH.genes-tmp | grep -Fv "GUT_GENOME" > $ANALYSIS_PATH.genes-mouse

rev $ANALYSIS_PATH.genes-mouse | cut -d_ -f1 --complement | rev | sort | uniq | grep -Fwf - $M_DB > $ANALYSIS_PATH.genome_taxonomy-mouse.tsv

while read GENE
do
     BLAST_DATA=$(echo $GENE | grep -Fwf - $ANALYSIS_PATH.genes-tmp | cut -f1 | uniq | grep -Fwf - $ANALYSIS_PATH.qc | head -n1)
     TAXONOMY=$(echo $GENE | rev | cut -d_ -f1 --complement | rev | grep -Fwf - $ANALYSIS_PATH.genome_taxonomy-mouse.tsv)
     echo -e "$TAXONOMY\t$BLAST_DATA\tMOUSE"
done < $ANALYSIS_PATH.genes-mouse > $ANALYSIS_PATH.mouse.tsv


cat $ANALYSIS_PATH.human.tsv $ANALYSIS_PATH.mouse.tsv > $ANALYSIS_PATH.summary.tsv

echo "$(timestamp) INFO : Done!"

