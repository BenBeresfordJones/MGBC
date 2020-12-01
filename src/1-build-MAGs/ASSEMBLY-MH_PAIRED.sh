#!/bin/bash

timestamp() {
date +"%H:%M:%S"
}

module load kneaddata/0.7.3 metawrap/1.2.3-c0 megahit/1.1.3--py36_0

## PAIRED layout

SRR=$1
INDIR=$2
THREADS=$3
EARLYEND=$4

SCRIPTS=$INDIR/SCRIPTS
QC=$INDIR/QC
ASSEMBLY=$INDIR/ASSEMBLY/$SRR.ASSEMBLY
BINNING=$INDIR/BINNING

echo "$(timestamp) INFO : Running ASSEMBLY command."

echo "$(timestamp) INFO : Running MEGAHIT."

metawrap assembly --megahit -m 40 -t $THREADS -1 $QC/Reads_post_qc/"$SRR"_1_kneaddata_paired_1.fastq -2 $QC/Reads_post_qc/"$SRR"_1_kneaddata_paired_2.fastq -o $ASSEMBLY


# check output

if [ ! -f $ASSEMBLY/megahit/done ]
then
     echo "$(timestamp) WARNING : Could not assemble sample with MEGAHIT."
     echo "$(timestamp) ERROR : Unable to assembly sample with both assemblers. Potentially poor quality sample. Exiting."
     echo "error" > $ASSEMBLY/error
     exit 1
else
     echo "$(timestamp) INFO : Congratulations - sample assembled with MEGAHIT."
     mv $ASSEMBLY/megahit/final.contigs.fa $ASSEMBLY
     rm -r $ASSEMBLY/megahit
     echo "MEGAHIT" > $ASSEMBLY/done
     rm $SRR.qc.o $SRR.qc.e $QC/"$SRR"_*.log # remove qc log files
     echo "/software/pathogen/etc/farmpy/0.42.1/wrappers/bsub.py 10 -q long --threads $THREADS $SRR.mm_binning 'metawrap binning -m 10 -t $THREADS -o $BINNING/ERR3357539.METAMAX -a $ASSEMBLY/final.contigs.fa --metabat2 --maxbin2 $QC/Reads_post_qc/"$SRR"_1_kneaddata_paired_1.fastq $QC/Reads_post_qc/"$SRR"_1_kneaddata_paired_2.fastq'" >> $SCRIPTS/command.log
     echo "/software/pathogen/etc/farmpy/0.42.1/wrappers/bsub.py 10 -q long --threads 1 $SRR.c_binning 'metawrap binning -m 10 -t 1 -o $BINNING/$SRR.CONCOCT -a $ASSEMBLY/final.contigs.fa --concoct $QC/Reads_post_qc/"$SRR"_1_kneaddata_paired_1.fastq $QC/Reads_post_qc/"$SRR"_1_kneaddata_paired_2.fastq'" >> $SCRIPTS/command.log
     echo "/software/pathogen/etc/farmpy/0.42.1/wrappers/bsub.py 10 -q long --threads $THREADS $SRR.mm_binning 'BINNING-MM.sh $SRR $INDIR $THREADS $ASSEMBLY/final.contigs.fa PAIRED $EARLYEND'" >> $SCRIPTS/binning.log
     echo "/software/pathogen/etc/farmpy/0.42.1/wrappers/bsub.py 10 -q long --threads 1 $SRR.c_binning 'BINNING-C.sh $SRR $INDIR $THREADS $ASSEMBLY/final.contigs.fa PAIRED $EARLYEND'" >> $SCRIPTS/binning.log
     if [ $EARLYEND == ASSEMBLY ]
     then
          echo "$(timestamp) INFO : Early end of the pipeline at assembly, next step scripts in SCRIPTS/binning.log"
     else
          echo "/software/pathogen/etc/farmpy/0.42.1/wrappers/bsub.py 10 -q long --threads $THREADS $SRR.mm_binning 'BINNING-MM.sh $SRR $INDIR $THREADS $ASSEMBLY/final.contigs.fa PAIRED $EARLYEND'" | sh
          echo "/software/pathogen/etc/farmpy/0.42.1/wrappers/bsub.py 10 -q long --threads 1 $SRR.c_binning 'BINNING-C.sh $SRR $INDIR $THREADS $ASSEMBLY/final.contigs.fa PAIRED $EARLYEND'" | sh
     fi
fi
