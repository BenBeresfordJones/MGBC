#!/bin/bash

timestamp() {
date +"%H:%M:%S"
}

module load kneaddata/0.7.3 metawrap/1.2.3-c0

## SINGLE layout

SRR=$1
INDIR=$2
THREADS=$3
EARLYEND=$4

SCRIPTS=$INDIR/SCRIPTS
QC=$INDIR/QC
ASSEMBLY=$INDIR/ASSEMBLY
BINNING=$INDIR/BINNING
BIN_REFINE=$INDIR/BIN_REFINE
BIN_REASSEMBLY=$INDIR/BIN_REASSEMBLY

echo "$(timestamp) INFO : Running kneaddata command."

kneaddata -i $INDIR/Metagenomes/$SRR.fastq -t 1 -db /lustre/scratch118/infgen/team162/bb11/External_databases/C57BL6/PRJNA310854/ -db /lustre/scratch118/infgen/team162/ys4/BBS/PhiX174_Bowtie2 --output $QC

# check output

if [ ! -f $QC/"$SRR"_kneaddata.fastq ]
then
     echo "$(timestamp) ERROR : Something went wrong with kneaddata... Exiting."
     exit 1
fi

if [ ! -d $QC/Reads_post_qc ]
then
     mkdir $QC/Reads_post_qc
fi

mv $QC/"$SRR"_kneaddata.fastq $QC/Reads_post_qc
rm $QC/"$SRR"_*.fastq


echo "$(timestamp) INFO : QC done, running ASSEMBLY."

echo "/software/pathogen/etc/farmpy/0.42.1/wrappers/bsub.py 15 -q long --threads $THREADS $SRR.mh_assembly 'ASSEMBLY-MH_SINGLE.sh $SRR $INDIR $THREADS $EARLYEND'" | sh


echo "$(timestamp) INFO : Cleaning up pre-qc files."

if [ -f $INDIR/Metagenomes/$SRR ]
then
     gzip $INDIR/Metagenomes/$SRR
     rm $INDIR/Metagenomes/$SRR.fastq
fi

echo "$(timestamp) INFO : Done."
