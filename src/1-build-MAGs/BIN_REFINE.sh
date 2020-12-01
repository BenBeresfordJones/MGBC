#!/bin/bash

timestamp() {
date +"%H:%M:%S"
}

module load kneaddata/0.7.3 metawrap/1.2.3-c0 megahit/1.1.3--py36_0

## BIN REFINEMENT

SRR=$1
INDIR=$2
THREADS=$3
ASSEMBLY=$4
LAYOUT=$5
EARLYEND=$6

SCRIPTS=$INDIR/SCRIPTS
QC=$INDIR/QC
BINNING=$INDIR/BINNING
BIN_REFINE=$INDIR/BIN_REFINE
BIN_REASSEMBLY=$INDIR/BIN_REASSEMBLY


echo "$(timestamp) INFO : Running bin REFINEMENT commands."

echo -e "$(date +%s)\tBIN-REFINE_START" >> $SCRIPTS/$SRR.filecount.txt

if [ -f $BINNING/$SRR.METAMAX/maxbin2_bins/bin.0.fa ] && [ -f $BINNING/$SRR.METAMAX/metabat2_bins/bin.1.fa ] && [ -f $BINNING/$SRR.CONCOCT/concoct_bins/bin.0.fa ]
then
     echo "$(timestamp) INFO : All binners ran successfully, starting full REFINEMENT."
     echo "/software/pathogen/etc/farmpy/0.42.1/wrappers/bsub.py 40 -q long --threads $THREADS $SRR.bin_refine 'metawrap bin_refinement -o $BIN_REFINE/$SRR.BIN_REFINE -t $THREADS -A $BINNING/$SRR.METAMAX/metabat2_bins/ -B $BINNING/$SRR.METAMAX/maxbin2_bins/ -C $BINNING/$SRR.CONCOCT/concoct_bins/ -c 50 -x 5'" >> $SCRIPTS/command.log
     metawrap bin_refinement -o $BIN_REFINE/$SRR.BIN_REFINE -t $THREADS -A $BINNING/$SRR.METAMAX/metabat2_bins/ -B $BINNING/$SRR.METAMAX/maxbin2_bins/ -C $BINNING/$SRR.CONCOCT/concoct_bins/ -c 50 -x 5

elif [ -f $BINNING/$SRR.METAMAX/maxbin2_bins/bin.0.fa ] && [ -f $BINNING/$SRR.METAMAX/metabat2_bins/bin.1.fa ] && [ ! -f $BINNING/$SRR.CONCOCT/concoct_bins/bin.0.fa ]
then
     echo "$(timestamp) INFO : CONCOCT did not run successfully, starting REFINEMENT with MAXBIN2 and METABAT2 bins."
     echo "/software/pathogen/etc/farmpy/0.42.1/wrappers/bsub.py 40 -q long --threads $THREADS $SRR.bin_refine 'metawrap bin_refinement -o $BIN_REFINE/$SRR.BIN_REFINE -t $THREADS -A $BINNING/$SRR.METAMAX/metabat2_bins/ -B $BINNING/$SRR.METAMAX/maxbin2_bins/ -c 50 -x 5'" >> $SCRIPTS/command.log
     metawrap bin_refinement -o $BIN_REFINE/$SRR.BIN_REFINE -t $THREADS -A $BINNING/$SRR.METAMAX/metabat2_bins/ -B $BINNING/$SRR.METAMAX/maxbin2_bins/ -c 50 -x 5

elif [ ! -f $BINNING/$SRR.METAMAX/maxbin2_bins/bin.0.fa ] && [ -f $BINNING/$SRR.METAMAX/metabat2_bins/bin.1.fa ] && [ -f $BINNING/$SRR.CONCOCT/concoct_bins/bin.0.fa ]
then
     echo "$(timestamp) INFO : MAXBIN2 did not run successfully, starting REFINEMENT with CONCOCT and METABAT2 bins."
     echo "/software/pathogen/etc/farmpy/0.42.1/wrappers/bsub.py 40 -q long --threads $THREADS $SRR.bin_refine 'metawrap bin_refinement -o $BIN_REFINE/$SRR.BIN_REFINE -t $THREADS -A $BINNING/$SRR.METAMAX/metabat2_bins/ -B $BINNING/$SRR.CONCOCT/concoct_bins/ -c 50 -x 5'" >> $SCRIPTS/command.log
     metawrap bin_refinement -o $BIN_REFINE/$SRR.BIN_REFINE -t $THREADS -A $BINNING/$SRR.METAMAX/metabat2_bins/ -B $BINNING/$SRR.CONCOCT/concoct_bins/ -c 50 -x 5

elif [ -f $BINNING/$SRR.METAMAX/maxbin2_bins/bin.0.fa ] && [ ! -f $BINNING/$SRR.METAMAX/metabat2_bins/bin.1.fa ] && [ -f $BINNING/$SRR.CONCOCT/concoct_bins/bin.0.fa ]
then
     echo "$(timestamp) INFO : METABAT2 did not run successfully, starting REFINEMENT with MAXBIN2 and CONCOCT bins."
     echo "/software/pathogen/etc/farmpy/0.42.1/wrappers/bsub.py 40 -q long --threads $THREADS $SRR.bin_refine 'metawrap bin_refinement -o $BIN_REFINE/$SRR.BIN_REFINE -t $THREADS -A $BINNING/$SRR.CONCOCT/concoct_bins/ -B $BINNING/$SRR.METAMAX/maxbin2_bins/ -c 50 -x 5'" >> $SCRIPTS/command.log
     metawrap bin_refinement -o $BIN_REFINE/$SRR.BIN_REFINE -t $THREADS -A $BINNING/$SRR.CONCOCT/concoct_bins/ -B $BINNING/$SRR.METAMAX/maxbin2_bins/ -c 50 -x 5
else
     echo "$(timestamp) ERROR : Not enough binners ran correctly to run bin refinement. Exiting."
     exit 1
fi


# check output

rm -r $BIN_REFINE/$SRR.BIN_REFINE/work_files $BIN_REFINE/$SRR.BIN_REFINE/figures $BIN_REFINE/$SRR.BIN_REFINE/*.contigs

if [ ! -f $BIN_REFINE/$SRR.BIN_REFINE/metawrap_50_5_bins/bin.1.fa ] && [ ! -f $BIN_REFINE/$SRR.BIN_REFINE/metawrap_50_5_bins/bin.2.fa ]
then
     echo "$(timestamp) ERROR : Something went wrong with the REFINEMENT, no bins were generated... Exiting."
     exit 1
fi

if [ -f $SRR.ms_assembly.o ] || [ -f $SRR.mh_assembly.o ]
then
     rm $SRR.m*_assembly.*
fi

if [ -f $SRR.mm_binning.o ] || [ -f $SRR.c_binning.o ]
then
     rm $SRR.*_binning.*
fi



## run reassembly

#if [ $LAYOUT == "PAIRED" ]
#then
#     if [ $EARLYEND == REFINE ]
#     then
#          echo "$(timestamp) INFO : Early end of the pipeline at $EARLYEND, next step scripts in SCRIPTS/reassembly.log"
#	  echo "/software/pathogen/etc/farmpy/0.42.1/wrappers/bsub.py 40 -q long --threads $THREADS $SRR.reassembly 'BIN_REASSEMBLY.sh $SRR $INDIR $THREADS'" >> $SCRIPTS/reassembly.log
#     else
#          echo "$(timestamp) INFO : Submitting bins for REASSEMBLY."
#	  echo "/software/pathogen/etc/farmpy/0.42.1/wrappers/bsub.py 40 -q long --threads $THREADS $SRR.reassembly 'BIN_REASSEMBLY.sh $SRR $INDIR $THREADS'" | sh
#     fi
#
#     echo "/software/pathogen/etc/farmpy/0.42.1/wrappers/bsub.py 40 --threads $THREADS -q long $SRR.reassembly 'metawrap reassemble_bins -o $BIN_REASSEMBLY/$SRR.BIN_REASSEMBLY -1 $QC/Reads_post_qc/"$SRR"_1_kneaddata_paired_1.fastq -2 $QC/Reads_post_qc/"$SRR"_1_kneaddata_paired_2.fastq -t $THREADS -m 40 -c 50 -x 5 -b $BIN_REFINE/$SRR.BIN_REFINE/metawrap_50_5_bins'" >> $SCRIPTS/command.log
#fi


# clean up unnecessary files now that MAGs are built

rm -r $BINNING/$SRR.METAMAX $BINNING/$SRR.CONCOCT

echo -e "$(date +%s)\tBIN-REFINE_END" >> $SCRIPTS/$SRR.filecount.txt

echo "$(timestamp) INFO : Running analysis on initial and refined bins."

# binner comparison

if [ ! -f $INDIR/binner_counts.tsv ]
then
     echo -e "SAMPLE\tMETABAT2\tMAXBIN2\tCONCOCT" > $INDIR/binner_counts.tsv
fi

MBCOUNT=$(ls $BIN_REFINE/$SRR.BIN_REFINE/metabat2_bins/*.fa | wc -l)
MXCOUNT=$(ls $BIN_REFINE/$SRR.BIN_REFINE/maxbin2_bins/*.fa | wc -l)
CCOUNT=$(ls $BIN_REFINE/$SRR.BIN_REFINE/concoct_bins/*.fa | wc -l)

echo -e "$SRR\t$MBCOUNT\t$MXCOUNT\t$CCOUNT" >> $INDIR/binner_counts.tsv


# bin stats

if [ ! -f $INDIR/bin_qc.tsv ]
then
     echo -e "SAMPLE\tBINNER\t$(head -n 1 $BIN_REFINE/$SRR.BIN_REFINE/metawrap_50_5_bins.stats)" > $INDIR/bin_qc.tsv
fi
if [ -f $BIN_REFINE/$SRR.BIN_REFINE/metabat2_bins.stats ]
then
     tail -n +2 $BIN_REFINE/$SRR.BIN_REFINE/metabat2_bins.stats | while read LINE
     do
          echo -e "$SRR\tMETABAT2\t$LINE" >> $INDIR/bin_qc.tsv
     done
     echo "/software/pathogen/etc/farmpy/0.42.1/wrappers/bsub.py 50 -q long --threads $THREADS $SRR.metabat2-tax 'BIN_TAXONOMY.sh $SRR $INDIR $THREADS metabat2_bins METABAT2'" | sh
fi

if [ -f $BIN_REFINE/$SRR.BIN_REFINE/maxbin2_bins.stats ]
then
     tail -n +2 $BIN_REFINE/$SRR.BIN_REFINE/maxbin2_bins.stats | while read LINE
     do
          echo -e "$SRR\tMAXBIN2\t$LINE" >> $INDIR/bin_qc.tsv
     done
     echo "/software/pathogen/etc/farmpy/0.42.1/wrappers/bsub.py 50 -q long --threads $THREADS $SRR.maxbin2-tax 'BIN_TAXONOMY.sh $SRR $INDIR $THREADS maxbin2_bins MAXBIN2'" | sh
fi

if [ -f $BIN_REFINE/$SRR.BIN_REFINE/concoct_bins.stats ]
then
     tail -n +2 $BIN_REFINE/$SRR.BIN_REFINE/concoct_bins.stats | while read LINE
     do
          echo -e "$SRR\tCONCOCT\t$LINE" >> $INDIR/bin_qc.tsv
     done
     echo "/software/pathogen/etc/farmpy/0.42.1/wrappers/bsub.py 50 -q long --threads $THREADS $SRR.concoct-tax 'BIN_TAXONOMY.sh $SRR $INDIR $THREADS concoct_bins CONCOCT'" | sh
fi

if [ -f $BIN_REFINE/$SRR.BIN_REFINE/metawrap_50_5_bins.stats ]
then
     tail -n +2 $BIN_REFINE/$SRR.BIN_REFINE/metawrap_50_5_bins.stats | while read LINE
     do
          echo -e "$SRR\tMETAWRAP\t$LINE" >> $INDIR/bin_qc.tsv
     done
     echo "/software/pathogen/etc/farmpy/0.42.1/wrappers/bsub.py 50 -q long --threads $THREADS $SRR.metawrap-tax 'BIN_TAXONOMY.sh $SRR $INDIR $THREADS metawrap_50_5_bins METAWRAP'" | sh
fi



echo "$(timestamp) INFO : Done!"


# to do: bin_qc bin_taxonomy
