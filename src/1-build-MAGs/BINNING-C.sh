#!/bin/bash

timestamp() {
date +"%H:%M:%S"
}

module load kneaddata/0.7.3 metawrap/1.2.3-c0 megahit/1.1.3--py36_0

## PAIRED layout

SRR=$1
INDIR=$2
THREADS=$3
ASSEMBLY=$4
LAYOUT=$5
EARLYEND=$6

SCRIPTS=$INDIR/SCRIPTS
QC=$INDIR/QC
BINNING=$INDIR/BINNING


echo "$(timestamp) INFO : Running BINNING commands."

echo -e "$(date +%s)\tBINNING-C_START" >> $SCRIPTS/$SRR.filecount.txt

if [ $LAYOUT == "SINGLE" ]
then
     echo "$(timestamp) INFO : Binning SINGLE layout samples."

     metawrap binning -m 10 -a $ASSEMBLY --concoct -o $BINNING/$SRR.CONCOCT --single-end $QC/Reads_post_qc/"$SRR"_kneaddata.fastq

elif [ $LAYOUT == "PAIRED" ]
then

     echo "$(timestamp) INFO : Binning PAIRED layout samples."

     metawrap binning -m 10 -o $BINNING/$SRR.CONCOCT -a $ASSEMBLY --concoct $QC/Reads_post_qc/"$SRR"_1_kneaddata_paired_1.fastq $QC/Reads_post_qc/"$SRR"_1_kneaddata_paired_2.fastq

else
     echo "$(timestamp) ERROR : Cannot establish layout type."
     exit 1
fi


# check output

if [ ! -f $BINNING/$SRR.CONCOCT/concoct_bins/bin.0.fa ] && [ ! -f $BINNING/$SRR.CONCOCT/concoct_bins/bin.1.fa ]
then
     echo "$(timestamp) WARNING : Something went wrong with CONCOCT binning."
     echo -e "$SRR\tCONCOCT" >> $BINNING/WARNINGS
else
     echo "$SRR" >> $BINNING/C_DONE
fi

echo "$(timestamp) INFO : Cleaning up after binning."

rm -r $BINNING/$SRR.CONCOCT/work_files


echo -e "$(date +%s)\tBINNING-C_END" >> $SCRIPTS/$SRR.filecount.txt

# run bin refinement script

if $(grep -q "$SRR" $BINNING/MM_DONE) && $(grep -q "$SRR" $BINNING/C_DONE)
then
     echo "$(timestamp) INFO : All binners have now finished successfully, so submitting BIN REFINEMENT job."
     echo "/software/pathogen/etc/farmpy/0.42.1/wrappers/bsub.py 40 -q long --threads $THREADS $SRR.bin_refine 'BIN_REFINE.sh $SRR $INDIR $THREADS $ASSEMBLY $LAYOUT $EARLYEND'" | sh
else
     echo "$(timestamp) ERROR : One or more binners have not finished successfully, and therefore will not automatically start the REFINEMENT process."
fi

echo "/software/pathogen/etc/farmpy/0.42.1/wrappers/bsub.py 40 -q long --threads $THREADS $SRR.bin_refine 'BIN_REFINE.sh $SRR $INDIR $THREADS $ASSEMBLY $LAYOUT $EARLYEND'" >> $SCRIPTS/command.log

echo "Done"
