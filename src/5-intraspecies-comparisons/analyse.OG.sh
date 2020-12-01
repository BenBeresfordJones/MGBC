#!/bin/bash

usage()
{
cat << EOF
usage: $0 options

Compare an eggNOG OG between human and mouse genomes, returning genome taxonomies and pangenome membership.

OPTIONS:
   -i      OG id.
   -D      Directory containing the eggNOG reference databases [not implemented]
   -o      Directory to write to [default: OG_<-i>]
   -P      Prefix for output directory.

EOF
}

OG_NUM=
DATA=
OUTDIR=

while getopts “i:o:P:” OPTION
do
     case ${OPTION} in
	 i)
	     OG_NUM=${OPTARG}
	     ;;
         o)
             OUTDIR=${OPTARG}
             ;;
	 P)
	     PREFIX=${OPTARG}
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

if [ -z $OG_NUM ]
then
     echo "$(timestamp) ERROR : Please supply an OG number for an enzyme to compare."
     usage
     exit 1
fi

if [ -z $OUTDIR ]
then
     OUTDIR=OG_"$OG_NUM"
fi

if [ ! -z $PREFIX ]
then
     OUTDIR=$PREFIX/$OUTDIR
fi

echo "$(timestamp) INFO : Writing output to $OUTDIR."

if [ -d $OUTDIR ]
then
     echo "$(timestamp) ERROR : Output directory exists already. Please choose another name."
     usage
     exit 1
fi

TMP=$OUTDIR/tmp

mkdir -p $OUTDIR
mkdir $TMP

MOUSE_DATA=/lustre/scratch118/infgen/team162/bb11/Human_mouse_comparison/HUMAN_MOUSE_HQ_REPS/PANGENOMES/MOUSE
HUMAN_DATA=/lustre/scratch118/infgen/team162/bb11/Human_mouse_comparison/HUMAN_MOUSE_HQ_REPS/PANGENOMES/HUMAN_FINAL

H_DB=/lustre/scratch118/infgen/team162/bb11/Human_mouse_comparison/HUMAN_MOUSE_HQ_REPS/GTDB_HQ_GENOMES/human_hq_GTDBTk.tsv
M_DB=/lustre/scratch118/infgen/team162/bb11/Human_mouse_comparison/HUMAN_MOUSE_HQ_REPS/GTDB_HQ_GENOMES/mouse_hq_GTDBTk.tsv

echo "$(timestamp) INFO : Getting genomes for $OG_NUM."

# get genomes that encode clusters annotated as the enzyme of interest
grep -Fw "$OG_NUM" $HUMAN_DATA/*.HUMAN/eggnog-out/pangenome-eggnog/pangenome-eggnog.tmp/eggnog-out.tsv -h | cut -f1 | grep -Fwhf - $HUMAN_DATA/*.HUMAN/eggnog-out/tmp/genome-cluster_mem-index.tsv | cut -f2 | sort | uniq > $TMP/human_OG.tmp
grep -Fw "$OG_NUM" $MOUSE_DATA/*.MOUSE/eggnog-out/pangenome-eggnog/pangenome-eggnog.tmp/eggnog-out.tsv -h | cut -f1 | grep -Fwhf - $MOUSE_DATA/*.MOUSE/eggnog-out/tmp/genome-cluster_mem-index.tsv | cut -f2 | sort | uniq > $TMP/mouse_OG.tmp

echo "$(timestamp) INFO : Getting taxonomies for $OG_NUM."

# get taxonomies for genomes
grep -Fwf $TMP/human_OG.tmp $H_DB > $OUTDIR/human.$OG_NUM.taxonomy.out
grep -Fwf $TMP/mouse_OG.tmp $M_DB > $OUTDIR/mouse.$OG_NUM.taxonomy.out

echo "$(timestamp) INFO : Building pangenomes for $OG_NUM."
# get pangenome data
# human

echo "$(timestamp) INFO : Building HUMAN pangenome."

for PAN in $HUMAN_DATA/*.HUMAN
do
     PANGENOME=$(echo $PAN | rev | cut -d/ -f1 | rev)
     GEN_COUNT=$(wc -l $PAN/genome_ids.txt | cut -d " " -f1)
     TAXONOMY=$(head -n1 $PAN/genome_ids.txt | grep -Fwf - $H_DB | cut -f2,4,6)
     HCOUNT=$(grep -Fwhcf $PAN/genome_ids.txt $TMP/human_OG.tmp)
     echo -e "$PANGENOME\t$HCOUNT\t$GEN_COUNT\tHUMAN\t$TAXONOMY" >> $OUTDIR/pangenome.$OG_NUM.out
done

echo "$(timestamp) INFO : Building MOUSE pangenome."

for PAN in $MOUSE_DATA/*.MOUSE
do
     PANGENOME=$(echo $PAN | rev | cut -d/ -f1 | rev)
     GEN_COUNT=$(wc -l $PAN/genome_ids.txt | cut -d " " -f1)
     TAXONOMY=$(head -n1 $PAN/genome_ids.txt | grep -Fwf - $M_DB | cut -f2,4,6)
     MCOUNT=$(grep -Fwhcf $PAN/genome_ids.txt $TMP/mouse_OG.tmp)
     echo -e "$PANGENOME\t$MCOUNT\t$GEN_COUNT\tMOUSE\t$TAXONOMY" >> $OUTDIR/pangenome.$OG_NUM.out
done

echo "$(timestamp) INFO : Done! Workflow complete."

