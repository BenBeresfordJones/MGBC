#!/bin/bash

usage()
{
cat << EOF
usage: $0 options

Get data for rRNA and tRNA encoding in a genome, and extract sequences.

OPTIONS:
Required:
   -i      Path to genome.
   -o	   Output directory.
   -p      Prefix for output files.

Optional:
   -t      Number of threads.
   -T	   Path to directory containing GFF.tar and FNA.tar archives. (not implemented)
   -g	   Path to GFF file. (not implemented)
   -f      Path to FNA file. (not implemented)

EOF
}

# variables
INFILE=
OUTDIR=
PREFIX=
THREADS=
TARDIR=
GFFPATH=
FNAPATH=

while getopts “i:o:p:t:T:g:f:” OPTION
do
     case ${OPTION} in
	 i)
	     INFILE=${OPTARG}
	     ;;
         t)
             THREADS=${OPTARG}
             ;;
	 p)
	     PREFIX=${OPTARG}
	     ;;
         T)
             TARDIR=${OPTARG}
             ;;
         o)
             OUTDIR=${OPTARG}
             ;;
         g)
             GFFPATH=${OPTARG}
             ;;
         f)
             FNAPATH=${OPTARG}
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

# databases
if [ -z $TARDIR ]
then
     TARDIR=/lustre/scratch118/infgen/team162/bb11/Mouse_genomes/MMGC_1.1/RNA_TAR
fi

if [ ! -f $TARDIR/trnascan.out.tar ] || [ ! -f $TARDIR/rnammer_16S.out.tar ] || [ ! -f $TARDIR/rnammer.out.tar ]
then
     echo "$(timestamp) ERROR : Please correct the path to Output tar archives."
fi

# check arguments
if [ -z $INFILE ] || [ ! -f $INFILE ]
then
     echo "$(timestamp) ERROR : Please supply path to a valid MAG bin."
     usage
     exit 1
fi

if [ -z $OUTDIR ]
then
     echo "$(timestamp) ERROR : Please supply the directory to generate output."
     usage
     exit 1
fi

if [ -z $PREFIX ]
then
     echo "$(timestamp) INFO : No prefix supplied, so using the input file name."
     PREFIX=$(echo "$INFILE" | rev | cut -d/ -f1 | cut -d. -f1 --complement | rev)
fi

if [ -f $OUTDIR/$PREFIX.rna_out.tsv ]
then
     echo "$(timestamp) ERROR : Output file already exists, please make sure you know what you are doing."
     usage
     exit 1
fi

if [ ! -d $OUTDIR ]
then
     mkdir $OUTDIR
fi

OUT=$(readlink -f $OUTDIR)

if [ -z $THREADS ]
then
     THREADS=1
fi

# setting up
module load rnammer/1.2 trnascan/2.0.5

WKDIR=$(pwd)
GEN_ID=$(echo $INFILE | rev | cut -d/ -f1 | cut -d. -f1 --complement | rev)
TMP=$GEN_ID.tmp

if [ ! -d $TMP ]
then
     mkdir $TMP
fi

cp $INFILE $TMP/$GEN_ID.fa

cd $TMP

# get tRNA data with trnascan-SE v2.0.5

tRNAscan-SE -B -H -o $PREFIX.trnascan.out --thread $THREADS $GEN_ID.fa

if [ ! -f $PREFIX.trnascan.out ]
then
     echo "$(timestamp) ERROR : Could not generate tRNAscan-SE output."
     exit 1
fi

TRNA_COUNT=$(sed -e '1,/-----/d' $PREFIX.trnascan.out | grep -Fwvc "pseudo")
TRNA_ISOTYPE_COUNT=$(sed -e '1,/-----/d' $PREFIX.trnascan.out | grep -Fwv "pseudo" | cut -f5 | sed 's/fMet/Met/g' | sed 's/Ile2/Ile/g' | grep -Fwv -e "Supres" -e "SelCys" -e "SeC" -e "Undet" -e "Sup" | sort -u | wc -l)



# get rRNA data with RNAmmer v1.2

rnammer -S bac -m msu -gff $PREFIX.rnammer.gff -f $PREFIX.rnammer.fa $INFILE

RRNA_5S_COUNT=$(grep -Fw "5s_rRNA" $PREFIX.rnammer.gff -c)
RRNA_16S_COUNT=$(grep -Fw "16s_rRNA" $PREFIX.rnammer.gff -c)
RRNA_23S_COUNT=$(grep -Fw "23s_rRNA" $PREFIX.rnammer.gff -c)

if [ ! -f $PREFIX.rnammer.gff ]
then
     echo "$(timestamp) ERROR : Could not generate RNAmmer output."
     exit 1
fi


rnammer -S bac -m ssu -f $PREFIX.rnammer_16S.fa $INFILE

if [ ! -f $PREFIX.rnammer_16S.fa ]
then
     echo "$(timestamp) ERROR : Could not generate RNAmmer output (16S)."
     exit 1
fi



# summarise data

printf "GENOME_ID\tTRNA_COUNT\tTRNA_ISOTYPE_COUNT\tRRNA_5S_COUNT\tRRNA_16S_COUNT\tRRNA_23S_COUNT\n" > $OUT/$PREFIX.rna_out.tsv
printf "$GEN_ID\t$TRNA_COUNT\t$TRNA_ISOTYPE_COUNT\t$RRNA_5S_COUNT\t$RRNA_16S_COUNT\t$RRNA_23S_COUNT\n" >> $OUT/$PREFIX.rna_out.tsv

if [ ! -f $OUT/genome_rna.summary.tsv ]
then
     printf "GENOME_ID\tTRNA_COUNT\tTRNA_ISOTYPE_COUNT\tRRNA_5S_COUNT\tRRNA_16S_COUNT\tRRNA_23S_COUNT\n" > $OUT/genome_rna.summary.tsv
fi

printf "$GEN_ID\t$TRNA_COUNT\t$TRNA_ISOTYPE_COUNT\t$RRNA_5S_COUNT\t$RRNA_16S_COUNT\t$RRNA_23S_COUNT\n" >> $OUT/genome_rna.summary.tsv


tar rvf $TARDIR/trnascan.out.tar $PREFIX.trnascan.out --remove-files
tar rvf $TARDIR/rnammer.out.tar $PREFIX.rnammer.gff $PREFIX.rnammer.fa --remove-files
tar rvf $TARDIR/rnammer_16S.out.tar $PREFIX.rnammer_16S.fa --remove-files


cd $WKDIR
rm  $TMP/$GEN_ID.fa
rmdir $TMP

echo "$(timestamp) INFO : Finished workflow."

