#!/bin/bash

timestamp() {
date +"%H:%M:%S"
}

module load kneaddata/0.7.3 metawrap/1.2.3-c0 megahit/1.1.3--py36_0

## SINGLE layout

SRR=$1
INDIR=$2
THREADS=$3
EARLYEND=$4

SCRIPTS=$INDIR/SCRIPTS
QC=$INDIR/QC
ASSEMBLY=$INDIR/ASSEMBLY/$SRR.ASSEMBLY
BINNING=$INDIR/BINNING

echo "$(timestamp) INFO : Running ASSEMBLY command."

megahit -t $THREADS -r $QC/Reads_post_qc/"$SRR"_kneaddata.fastq -o $ASSEMBLY


# check output

if [ ! -f $ASSEMBLY/done ]
then
     echo "$(timestamp) WARNING : Could not assemble sample with MEGAHIT. Exiting."
     rm -r $ASSEMBLY/intermediate_contigs $ASSEMBLY/opts.txt
     exit 1
else
     echo "$(timestamp) INFO : Congratulations - sample assembled with MEGAHIT."
     rm -r $ASSEMBLY/intermediate_contigs $ASSEMBLY/log $ASSEMBLY/opts.txt
     rm $SRR.qc.o $SRR.qc.e $QC/"$SRR"_*.log # remove qc log files
     echo "/software/pathogen/etc/farmpy/0.42.1/wrappers/bsub.py 10 -q long --threads $THREADS $SRR.mm_binning 'metawrap binning -m 10 -t $THREADS -o $BINNING/$SRR.METAMAX -a $ASSEMBLY/final.contigs.fa --metabat2 --maxbin2 $QC/Reads_post_qc/"$SRR"_kneaddata.fastq'" >> $SCRIPTS/command.log
     echo "/software/pathogen/etc/farmpy/0.42.1/wrappers/bsub.py 10 -q basement --threads 1 $SRR.c_binning 'metawrap binning -m 10 -t 1 -o $BINNING/$SRR.CONCOCT -a $ASSEMBLY/final.contigs.fa --concoct $QC/Reads_post_qc/"$SRR"_kneaddata.fastq'" >> $SCRIPTS/command.log
     echo "/software/pathogen/etc/farmpy/0.42.1/wrappers/bsub.py 10 -q long --threads $THREADS $SRR.mm_binning 'BINNING-MM.sh $SRR $INDIR $THREADS $ASSEMBLY/final.contigs.fa SINGLE $EARLYEND'" >> $SCRIPTS/binning.log
     echo "/software/pathogen/etc/farmpy/0.42.1/wrappers/bsub.py 10 -q basement --threads 1 $SRR.c_binning 'BINNING-C.sh $SRR $INDIR $THREADS $ASSEMBLY/final.contigs.fa SINGLE $EARLYEND'" >> $SCRIPTS/binning.log
     if [ $EARLYEND == ASSEMBLY ]
     then
          echo "$(timestamp) INFO : Early end of the pipeline at assembly, next step scripts in SCRIPTS/binning.log"
     else
          echo "/software/pathogen/etc/farmpy/0.42.1/wrappers/bsub.py 10 -q long --threads $THREADS $SRR.mm_binning 'BINNING-MM.sh $SRR $INDIR $THREADS $ASSEMBLY/final.contigs.fa SINGLE $EARLYEND'" | sh
          echo "/software/pathogen/etc/farmpy/0.42.1/wrappers/bsub.py 10 -q long --threads 1 $SRR.c_binning 'BINNING-C.sh $SRR $INDIR $THREADS $ASSEMBLY/final.contigs.fa SINGLE $EARLYEND'" | sh
     fi
fi

