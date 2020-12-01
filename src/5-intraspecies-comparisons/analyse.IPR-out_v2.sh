#!/bin/bash

usage()
{
cat << EOF
usage: $0 options

Compare an IPR family between human and mouse genomes, returning genome taxonomies and pangenome membership.

OPTIONS:
   -i      IPR id.
   -D      Directory containing the IPR reference databases [not implemented]
   -o      Directory to write to [default: <-i>]
   -P      Prefix for output directory.

EOF
}

IPR=
DATA=
OUTDIR=

while getopts “i:o:P:” OPTION
do
     case ${OPTION} in
	 i)
	     IPR=${OPTARG}
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

if [ -z $IPR ]
then
     echo "$(timestamp) ERROR : Please supply an IPR number for a family to compare."
     usage
     exit 1
fi

if [ -z $OUTDIR ]
then
     OUTDIR="$IPR"
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

MOUSE_DATA=/lustre/scratch118/infgen/team162/bb11/Human_mouse_comparison/FUNCTIONAL_COMPARISON/PANGENOMES/MOUSE/DONE
#/lustre/scratch118/infgen/team162/bb11/Human_mouse_comparison/HUMAN_MOUSE_HQ_REPS/PANGENOMES/MOUSE
HUMAN_DATA=/lustre/scratch118/infgen/team162/bb11/Human_mouse_comparison/FUNCTIONAL_COMPARISON/PANGENOMES/HUMAN/DONE
#/lustre/scratch118/infgen/team162/bb11/Human_mouse_comparison/HUMAN_MOUSE_HQ_REPS/PANGENOMES/HUMAN_FINAL

H_DB=/lustre/scratch118/infgen/team162/bb11/Human_mouse_comparison/FUNCTIONAL_COMPARISON/BUILD_PANGENOME/GTDB_DBs/human-100456.tsv
#/lustre/scratch118/infgen/team162/bb11/Human_mouse_comparison/HUMAN_MOUSE_HQ_REPS/GTDB_HQ_GENOMES/human_hq_GTDBTk.tsv
M_DB=/lustre/scratch118/infgen/team162/bb11/Human_mouse_comparison/FUNCTIONAL_COMPARISON/BUILD_PANGENOME/GTDB_DBs/mouse-18075.tsv
#/lustre/scratch118/infgen/team162/bb11/Human_mouse_comparison/HUMAN_MOUSE_HQ_REPS/GTDB_HQ_GENOMES/mouse_hq_GTDBTk.tsv

# get genomes that encode clusters annotated as the enzyme of interest

# correct gene names in IPS output
for i in $HUMAN_DATA/*.HUMAN # HUMAN
do
     TMPDIR=$i/IPS-out/pangenome-ips/pangenome-ips.tmp
     if [ ! -f $TMPDIR/ips-out_2.tsv ]
     then
	  paste $TMPDIR/genes.txt $TMPDIR/ips-out.tsv > $TMPDIR/ips-out_2.tsv
     fi
done

for i in $MOUSE_DATA/*.MOUSE # MOUSE
do
     TMPDIR=$i/IPS-out/pangenome-ips/pangenome-ips.tmp
     if [ ! -f $TMPDIR/ips-out_2.tsv ]
     then
          paste $TMPDIR/genes.txt $TMPDIR/ips-out.tsv > $TMPDIR/ips-out_2.tsv
     fi
done

grep -Fw "$IPR" $HUMAN_DATA/*.HUMAN/IPS-out/pangenome-ips/pangenome-ips.tmp/ips-out_2.tsv -h | cut -f1 | grep -Fwhf - $HUMAN_DATA/*.HUMAN/IPS-out/tmp/genome-cluster_mem-index.tsv | cut -f2 | sort | uniq > $TMP/human_EC.tmp
grep -Fw "$IPR" $MOUSE_DATA/*.MOUSE/IPS-out/pangenome-ips/pangenome-ips.tmp/ips-out_2.tsv -h | cut -f1 | grep -Fwhf - $MOUSE_DATA/*.MOUSE/IPS-out/tmp/genome-cluster_mem-index.tsv | cut -f2 | sort | uniq > $TMP/mouse_EC.tmp

# get taxonomies for genomes
grep -Fwf $TMP/human_EC.tmp $H_DB > $OUTDIR/human.$IPR.taxonomy.out.tsv
grep -Fwf $TMP/mouse_EC.tmp $M_DB > $OUTDIR/mouse.$IPR.taxonomy.out.tsv


# get pangenome data
# human

for PAN in $HUMAN_DATA/*.HUMAN
do
     PANGENOME=$(echo $PAN | rev | cut -d/ -f1 | rev)
     GEN_COUNT=$(wc -l $PAN/genome_ids.txt | cut -d " " -f1)
     TAXONOMY=$(head -n1 $PAN/genome_ids.txt | grep -Fwf - $H_DB | cut -f2,4,6)
     HCOUNT=$(grep -Fwhcf $PAN/genome_ids.txt $TMP/human_EC.tmp)
     echo -e "$PANGENOME\t$HCOUNT\t$GEN_COUNT\tHUMAN\t$TAXONOMY" >> $OUTDIR/pangenome.$IPR.out.tsv
done

for PAN in $MOUSE_DATA/*.MOUSE
do
     PANGENOME=$(echo $PAN | rev | cut -d/ -f1 | rev)
     GEN_COUNT=$(wc -l $PAN/genome_ids.txt | cut -d " " -f1)
     TAXONOMY=$(head -n1 $PAN/genome_ids.txt | grep -Fwf - $M_DB | cut -f2,4,6)
     MCOUNT=$(grep -Fwhcf $PAN/genome_ids.txt $TMP/mouse_EC.tmp)
     echo -e "$PANGENOME\t$MCOUNT\t$GEN_COUNT\tMOUSE\t$TAXONOMY" >> $OUTDIR/pangenome.$IPR.out.tsv
done

echo "$(timestamp) INFO : Done!"

