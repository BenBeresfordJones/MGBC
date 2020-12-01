#!/bin/bash

usage()
{
cat << EOF
usage: $0 options

Run checkm and GTDBTk on qc'ed genomes.

OPTIONS:
   -i      Path to directory containing genomes on which to run pipeline.
   -t      Number of threads.
   -o	   Directory to write output to.
   -x	   Genome suffix, default = fna.

EOF
}

INDIR=
THREADS=
OUTDIR=
SUFFIX=

while getopts “i:o:t:x:” OPTION
do
        case ${OPTION} in
                i)
                        INDIR=${OPTARG}
                        ;;
                t)
                        THREADS=${OPTARG}
                        ;;
		o)
			OUTDIR=${OPTARG}
			;;
		x)
			SUFFIX=${OPTARG}
			;;
                ?)
                        usage
                        exit
                        ;;
    esac
done

module load bsub.py/0.42.1 checkm/1.1.2--py_1 gtdbtk/1.3.0--py_1

if [ -z $INDIR ] || [ ! -d $INDIR ]
then
	echo "ERROR: Please supply path to directory containing genomes."
	usage
	exit 1
fi

if [ -z $THREADS ]
then
	THREADS=1
fi

if [ -z $OUTDIR ]
then
	echo "ERROR: Please supply an output directory."
	usage
	exit 1
fi

if [ ! -d $OUTDIR ]
then
     mkdir $OUTDIR
fi

if [ -z $SUFFIX ]
then
	SUFFIX=fna
fi

# run checkm

CHECKM_OUT=$OUTDIR/CHECKM

if [ ! -d $CHECKM_OUT ]; then mkdir $CHECKM_OUT; fi

if [ -f $CHECKM_OUT/qa_out ]
then
	echo "WARNING: CheckM already ran... Skipping QC."
else
	echo "Running CheckM."
	checkm lineage_wf -t $THREADS -x $SUFFIX $INDIR $CHECKM_OUT

	checkm qa $CHECKM_OUT/lineage.ms $CHECKM_OUT -o 2 -f $CHECKM_OUT/qa_out --tab_table -t $THREADS
fi

if [ ! -f $CHECKM_OUT/qa_out ]
then
	echo "ERROR: CheckM has not run correctly. Exiting."
	exit 1
fi

rm -r $CHECKM_OUT/bins $CHECKM_OUT/storage

# parse output

cut -f 1,6,7,9,12,14,16,19 $CHECKM_OUT/qa_out > $CHECKM_OUT/qa_out_CUT
# Cut -f 6,7,9,12 = Completeness, Contamination, Genome size (bp), # contigs
# -f 14, 16, 19 = N50 (contigs), Mean contig length (bp), GC
head -n 1 $CHECKM_OUT/qa_out_CUT > $CHECKM_OUT/PASSED_QC.txt
awk ' $2 >= 90 && $3 <= 5 && $4 <= 8000000 && $5 <= 500 && $6 >= 10000 && $7 >= 5000' $CHECKM_OUT/qa_out_CUT >> $CHECKM_OUT/PASSED_QC.txt
cut -f1 $CHECKM_OUT/PASSED_QC.txt | tail -n +2 > $CHECKM_OUT/Validated_genomes.txt
awk ' $2 < 90; $3 > 5; $4 > 8000000; $5 > 500; $6 < 10000; $7 < 5000 ' $CHECKM_OUT/qa_out_CUT | uniq > $CHECKM_OUT/FAILED_QC.txt

echo "QC complete."

# build GTDB-Tk output dirs

GTDB_OUT=$OUTDIR/GTDBTK
if [ ! -d $GTDB_OUT ]; then mkdir $GTDB_OUT; fi

# build GTDB-Tk batchfile

echo "Running GTDB-Tk."

BATCHFILE=$GTDB_OUT/gtdbtk_batchfile.tsv

while read GENOME
do
	GENPATH=$(readlink -f $INDIR/$GENOME.$SUFFIX)
	printf "$GENPATH\t$GENOME\n"
done < $CHECKM_OUT/Validated_genomes.txt > $BATCHFILE

# run GTDB-Tk

#IDENT=$GTDB_OUT/identify
#ALIGN=$GTDB_OUT/align
#CLASS=$GTDB_OUT/classify
#mkdir $IDENT $ALIGN $CLASS

gtdbtk identify --batchfile $BATCHFILE --out_dir $GTDB_OUT --cpus $THREADS
gtdbtk align --identify_dir $GTDB_OUT --out_dir $GTDB_OUT --cpus $THREADS

rm -r $GTDB_OUT/identify/intermediate_results

gtdbtk classify --batchfile $BATCHFILE --align_dir $GTDB_OUT --out_dir $GTDB_OUT --cpus $THREADS

if [ ! -f $GTDB_OUT/classify/gtdbtk.bac120.summary.tsv ]
then
	echo "ERROR: GTDB-Tk did not run correctly."
	exit 1
fi

cp $GTDB_OUT/classify/gtdbtk.bac120.summary.tsv $GTDB_OUT

echo "DONE!"



