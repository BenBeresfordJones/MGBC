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

echo "$(timestamp) INFO : Running METASPADES first."

metawrap assembly --metaspades -m 110 -t $THREADS -1 $QC/Reads_post_qc/"$SRR"_1_kneaddata_paired_1.fastq -2 $QC/Reads_post_qc/"$SRR"_1_kneaddata_paired_2.fastq -o $ASSEMBLY


# check metaspades output

if [ ! -f $ASSEMBLY/assembly_report.html ]
then
     echo "$(timestamp) WARNING : Could not complete assembly with METASPADES. Running assembly with MEGAHIT."
     echo "/software/pathogen/etc/farmpy/0.42.1/wrappers/bsub.py 40 -q long --threads $THREADS $SRR.mh_assembly 'ASSEMBLY-MH_PAIRED.sh $SRR $INDIR $THREADS $EARLYEND'" | sh
     if [ -d $ASSEMBLY/metaspades.tmp ]; then rm -r $ASSEMBLY/metaspades.tmp; fi
else
     echo "$(timestamp) INFO : Congratulations - assembly completed with METASPADES."
     mv $ASSEMBLY/QUAST_out/transposed_report.tsv $ASSEMBLY
     echo "METASPADES" > $ASSEMBLY/done
     rm -r $ASSEMBLY/QUAST_out
     rm $SRR.qc.o $SRR.qc.e $QC/"$SRR"_*.log # remove qc log files
     echo "/software/pathogen/etc/farmpy/0.42.1/wrappers/bsub.py 10 -q long --threads $THREADS $SRR.mm_binning 'metawrap binning -m 10 -t $THREADS -o $BINNING/$SRR.METAMAX -a $ASSEMBLY/final_assembly.fasta --metabat2 --maxbin2 $QC/Reads_post_qc/"$SRR"_1_kneaddata_paired_1.fastq $QC/Reads_post_qc/"$SRR"_1_kneaddata_paired_1.fastq'" >> $SCRIPTS/command.log
     echo "/software/pathogen/etc/farmpy/0.42.1/wrappers/bsub.py 10 -q long --threads 1 $SRR.c_binning 'metawrap binning -m 10 -t 1 -o $BINNING/$SRR.CONCOCT -a $ASSEMBLY/final_assembly.fasta --concoct $QC/Reads_post_qc/"$SRR"_1_kneaddata_paired_1.fastq $QC/Reads_post_qc/"$SRR"_1_kneaddata_paired_1.fastq'" >> $SCRIPTS/command.log
     echo "/software/pathogen/etc/farmpy/0.42.1/wrappers/bsub.py 10 -q long --threads $THREADS $SRR.mm_binning 'BINNING-MM.sh $SRR $INDIR $THREADS $ASSEMBLY/final_assembly.fasta PAIRED $EARLYEND'" >> $SCRIPTS/binning.log
     echo "/software/pathogen/etc/farmpy/0.42.1/wrappers/bsub.py 10 -q long --threads 1 $SRR.c_binning 'BINNING-C.sh $SRR $INDIR $THREADS $ASSEMBLY/final_assembly.fasta PAIRED $EARLYEND'" >> $SCRIPTS/binning.log
     if [ $EARLYEND == ASSEMBLY ]
     then
	  echo "$(timestamp) INFO : Early end of the pipeline at assembly, next step scripts in SCRIPTS/binning.log"
     else
          echo "/software/pathogen/etc/farmpy/0.42.1/wrappers/bsub.py 10 -q long --threads $THREADS $SRR.mm_binning 'BINNING-MM.sh $SRR $INDIR $THREADS $ASSEMBLY/final_assembly.fasta PAIRED $EARLYEND'" | sh
          echo "/software/pathogen/etc/farmpy/0.42.1/wrappers/bsub.py 10 -q long --threads 1 $SRR.c_binning 'BINNING-C.sh $SRR $INDIR $THREADS $ASSEMBLY/final_assembly.fasta PAIRED $EARLYEND'" | sh
     fi
fi

if [ -d $ASSEMBLY/metaspades ]; then rm -r $ASSEMBLY/metaspades; fi
