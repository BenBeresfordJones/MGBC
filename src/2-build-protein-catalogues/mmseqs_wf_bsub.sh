#!/bin/bash

usage()
{
cat << EOF

usage: $0 options

Run mmseqs2 workflow.

OPTIONS:
   -i      Path to input file
   -o      Output directory in which to generate the final output directories (CLUS_x)
   -t      Number of threads to run the command with [default: 1]
   -T      Directory to use to build the initial indexing files for 
   -F      Generate with -min-seq-id 50 (orthologue)
   -E      Generate with -min-seq-id 80 (genus-level)
   -N      Generate with -min-seq-id 90 (species-level)
   -H      Generate with -min-seq-id 100
   -q      Queue to submit jobs to [default: normal]
   -m      Memory to submit jobs with, 120 is recommended

EOF
}

INPUT=
THREADS=
OUTDIR=
TMPDIR=
FIFTY=
EIGHTY=
NINETY=
HUNDRED=
BQUEUE=
MEMORY=

while getopts “i:o:t:T:FENHq:m:” OPTION
do
     case $OPTION in
         i)
             INPUT=$OPTARG
             ;;
         t)
             THREADS=$OPTARG
             ;;
	 o)
	     OUTDIR=$OPTARG
	     ;;
         T)
             TMPDIR=$OPTARG
             ;;
         F)
             FIFTY=TRUE
             ;;
         E)
             EIGHTY=TRUE
             ;;
         N)
             NINETY=TRUE
             ;;
         H)
             HUNDRED=TRUE
             ;;
	 q)
	     BQUEUE=$OPTARG
	     ;;
	 m)
	     MEMORY=$OPTARG
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


echo "$(timestamp) INFO : Running $0"


## SETTING UP

module load farmpy/0.42.1 mmseqs2/10.6d92c--h2d02072_0


WDIR=$(pwd)

if [ -z $INPUT ]
then
     echo "$(timestamp) ERROR : Please supply the appropriate path to the input directory with the -i flag"
     usage
     exit 1
fi

if [ ! -f $INPUT ]
then
     echo "$(timestamp) ERROR : INPUT file path supplied is not valid, file does not exist."
     usage
     exit 1
fi


if [ -z $THREADS ]
then
     echo "$(timestamp) INFO : No thread number specified, so defaulting to 1."
     THREADS=1
fi


if [ -z $BQUEUE ]
then
     BQUEUE=normal
fi


if [ -z $MEMORY ]
then
     echo "$(timestamp) ERROR : No memory value given via the -m flag."
     usage
     exiit 1
fi


if [ -z $TMPDIR ]
then
     echo "$(timestamp) INFO : No temporary directory specified so building database index in working directory."
     TMPDIR=$WDIR
fi


if [ ! -d $TMPDIR ]
then
     echo "$(timestamp) INFO : Making temporary directory."
     mkdir  $TMPDIR
fi


if [ -z $OUTDIR ]
then
     echo "$(timestamp) INFO : No output directory supplied so building subdirectories in working directory."
     OUTDIR=$WDIR
fi


if [ -d $OUTDIR ]
then
     echo "$(timestamp) WARNING : Output directory specified already exists."
else
	mkdir $OUTDIR
fi


echo "$(timestamp) INFO : Running mmseqs2 workflow."




if [ ! -f $TMPDIR/mmseqs.db ]
then
     echo "$(timestamp) INFO : Creating MMseqs database."
     mmseqs createdb $INPUT $TMPDIR/mmseqs.db
else
     echo "$(timestamp) INFO : mmseqs database hase already been created..."
fi


#mkdir $OUTPUT/CLUS_50 $OUTPUT/CLUS_80 $OUTPUT/CLUS_90

#cd $OUTPUT




if [ ! -z $FIFTY ]
then
     mkdir $OUTDIR/CLUS_50
     echo "Submitting linclust.sh job to cluster MMseqs with linclust with option --min-seq-id 0.5"
     echo "/software/pathogen/etc/farmpy/0.42.1/wrappers/bsub.py $MEMORY -q $BQUEUE --threads $THREADS linclust_50 'linclust.sh 0.5 $TMPDIR $OUTDIR/CLUS_50 $THREADS'" | sh
fi


if [ ! -z $EIGHTY ]
then
     mkdir $OUTDIR/CLUS_80
     echo "Submitting linclust.sh job to cluster MMseqs with linclust with option --min-seq-id 0.8"
     echo "/software/pathogen/etc/farmpy/0.42.1/wrappers/bsub.py $MEMORY -q $BQUEUE --threads $THREADS linclust_80 'linclust.sh 0.8 $TMPDIR $OUTDIR/CLUS_80 $THREADS'" | sh
fi

if [ ! -z $NINETY ]
then
     mkdir $OUTDIR/CLUS_90
     echo "Submitting linclust.sh job to cluster MMseqs with linclust with option --min-seq-id 0.9"
     echo "/software/pathogen/etc/farmpy/0.42.1/wrappers/bsub.py $MEMORY -q $BQUEUE --threads $THREADS linclust_90 'linclust.sh 0.9 $TMPDIR $OUTDIR/CLUS_90 $THREADS'" | sh
fi

if [ ! -z $HUNDRED ]
then
     mkdir $OUTDIR/CLUS_100
     echo "Submitting linclust.sh job to cluster MMseqs with linclust with option --min-seq-id 1"
     echo "/software/pathogen/etc/farmpy/0.42.1/wrappers/bsub.py $MEMORY -q $BQUEUE --threads $THREADS linclust_100 'linclust.sh 1 $TMPDIR $OUTDIR/CLUS_100 $THREADS'" | sh
fi


echo "All jobs submitted!"
