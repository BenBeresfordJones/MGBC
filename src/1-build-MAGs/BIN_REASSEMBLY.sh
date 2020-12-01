#!/bin/bash

timestamp() {
date +"%H:%M:%S"
}

module load kneaddata/0.7.3 metawrap/1.2.3-c0 megahit/1.1.3--py36_0

## BIN REASEMBLY

SRR=$1
INDIR=$2
THREADS=$3

SCRIPTS=$INDIR/SCRIPTS
QC=$INDIR/QC
BINNING=$INDIR/BINNING
BIN_REFINE=$INDIR/BIN_REFINE
BIN_REASSEMBLY=$INDIR/BIN_REASSEMBLY


echo "$(timestamp) INFO : Running bin REASSEMBLY commands."

echo "/software/pathogen/etc/farmpy/0.42.1/wrappers/bsub.py 0.1 -q long $SRR.fc 'watch_file_count.sh \\\"$INDIR/*/$SRR.*\\\" $SCRIPTS/$SRR.filecount.txt'" | sh
echo "/software/pathogen/etc/farmpy/0.42.1/wrappers/bsub.py 0.1 -q long $SRR.fc 'watch_file_count.sh \\\"$INDIR/*/$SRR.*\\\" $SCRIPTS/$SRR.filecount.txt'" >> $SCRIPTS/command.log
echo -e "$(date +%s)\tBIN-REASSEMBLY_START" >> $SCRIPTS/$SRR.filecount.txt


metawrap reassemble_bins -o $BIN_REASSEMBLY/$SRR.BIN_REASSEMBLY -1 $QC/Reads_post_qc/"$SRR"_1_kneaddata_paired_1.fastq -2 $QC/Reads_post_qc/"$SRR"_1_kneaddata_paired_2.fastq -t $THREADS -m 40 -c 50 -x 5 -b $BIN_REFINE/$SRR.BIN_REFINE/metawrap_50_5_bins


# check output


rm -r $BIN_REASSEMBLY/$SRR.BIN_REASSEMBLY/original_bins $BIN_REASSEMBLY/$SRR.BIN_REASSEMBLY/work_files $BIN_REASSEMBLY/$SRR.BIN_REASSEMBLY/reassembled_bins.checkm $BIN_REASSEMBLY/$SRR.BIN_REASSEMBLY/reassembled_bins.png


if [ ! -f $BIN_REASSEMBLY/$SRR.BIN_REASSEMBLY/reassembled_bins.stats ]
then
     echo "$(timestamp) ERROR : Something went wrong with bin REASSEMBLY. Exiting."
     exit 1
fi


if [ $INDIR == PRJEB_31298 ]
then
     echo "$(timestamp) INFO : Starting another sample for MAG_pipeline completion."
     head -n 2 $SCRIPTS/binning.RUN.sh | sh
     cat $SCRIPTS/binning.RUN.sh > $SCRIPTS/bin_last
     tail -n +3 $SCRIPTS/bin_last > $SCRIPTS/binning.RUN.sh
fi


echo "$(timestamp) INFO : Generating statistics for the bin reassembly."

if [ ! -f $INDIR/bin_reassembly_qc.tsv ]
then
     echo -e "SAMPLE\tBIN\tNEW_COMP\tNEW_CONT\tNEW_N50\tNEW_SIZE\tORIG_COMP\tORIG_CONT\tORIG_N50\tORIG_SIZE" > $INDIR/bin_reassembly_qc.tsv
fi

TMP=$BIN_REASSEMBLY/$SRR.BIN_REASSEMBLY/tmp

mkdir $TMP

tail -n +2 $BIN_REASSEMBLY/$SRR.BIN_REASSEMBLY/original_bins.stats | cut -f2,3,6,7 > $TMP/orig
tail -n +2 $BIN_REASSEMBLY/$SRR.BIN_REASSEMBLY/reassembled_bins.stats | cut -f1,2,3,6,7 > $TMP/new

paste $TMP/new $TMP/orig | while read LINE
do
     echo -e "$SRR\t$LINE" >> $INDIR/bin_reassembly_qc.tsv
done

rm -r $TMP

echo -e "$(date +%s)\tBIN-REASSEMBLY_END" >> $SCRIPTS/$SRR.filecount.txt

echo "$(timestamp) INFO : Done!"
