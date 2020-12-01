#!/bin/bash

timestamp() {
date +"%H:%M:%S"
}

module load kneaddata/0.7.3 metawrap/1.2.3-c0

## PAIRED layout

SRR=$1
INDIR=$2
THREADS=$3
EARLYEND=$4

SCRIPTS=$INDIR/SCRIPTS
QC=$INDIR/QC

echo "$(timestamp) INFO : Running kneaddata command."

kneaddata -i $INDIR/Metagenomes/"$SRR"_1.fastq -i $INDIR/Metagenomes/"$SRR"_2.fastq -t 1 -db /lustre/scratch118/infgen/team162/bb11/External_databases/C57BL6/PRJNA310854/ -db /lustre/scratch118/infgen/team162/ys4/BBS/PhiX174_Bowtie2 --output $QC

# check output

QC_1=$QC/"$SRR"_1_kneaddata_paired_1.fastq
QC_2=$QC/"$SRR"_1_kneaddata_paired_2.fastq

if [ ! -f $QC_1 ] || [ ! -f $QC_2 ]
then
     echo "$(timestamp) ERROR : Something went wrong with kneaddata... Exiting."
     exit 1
fi


echo "$(timestamp) INFO : Standardising contig names."

sed -r -i "s/@$SRR\.(.*)\.2/@$SRR\.\1\.1/g" $QC_2



if [ ! -d $QC/Reads_post_qc ]
then
     mkdir $QC/Reads_post_qc
fi


mv $QC_1 $QC_2 $QC/Reads_post_qc
rm $QC/"$SRR"_*.fastq


echo "$(timestamp) INFO : QC done, running ASSEMBLY."

echo "/software/pathogen/etc/farmpy/0.42.1/wrappers/bsub.py 120 -q long --threads $THREADS $SRR.ms_assembly 'ASSEMBLY-MS_PAIRED.sh $SRR $INDIR $THREADS $EARLYEND'" | sh


echo "$(timestamp) INFO : Cleaning up pre-qc files."

if [ -f $INDIR/Metagenomes/$SRR ]
then
     gzip $INDIR/Metagenomes/$SRR
     rm $INDIR/Metagenomes/"$SRR"_1.fastq $INDIR/Metagenomes/"$SRR"_2.fastq # only delete files if the SRA version is maintained
fi

echo "$(timestamp) INFO : Done."
