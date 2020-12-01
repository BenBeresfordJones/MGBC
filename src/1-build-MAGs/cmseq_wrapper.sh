#!/bin/bash

usage()
{
cat << EOF
usage: $0 options

Annotate, align and infer strain heteregeniety for MAGs.

OPTIONS:
Required:
   -i      Path to MAG genome.
   -o	   Output direcory.

Optional:
   -t      Number of threads.
   -T	   Path to directory containing GFF.tar and FNA.tar archives. (not implemented)
   -g	   Path to GFF file. (not implemented)
   -f      Path to FNA file. (not implemented)

EOF
}

# variables
INFILE=
OUTDIR=
THREADS=
TARDIR=
GFFPATH=
FNAPATH=

while getopts “i:o:t:T:g:f:” OPTION
do
     case ${OPTION} in
	 i)
	     INFILE=${OPTARG}
	     ;;
         t)
             THREADS=${OPTARG}
             ;;
         T)
             TARDIR=${OPTARG}
             ;;
         o)
             OUTDIR=${OPTARG}
             ;;
         g)
             GFFPATH=${OPTARG}
             ;;
         f)
             FNAPATH=${OPTARG}
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

# databases
TARDIR=/lustre/scratch118/infgen/team162/bb11/External_databases/Mouse_metagenomes/MAGS/ANNOTATIONS

# check arguments
if [ -z $INFILE ] || [ ! -f $INFILE ]
then
     echo "$(timestamp) ERROR : Please supply path to a valid MAG bin."
     usage
     exit 1
fi

if [ -z $OUTDIR ]
then
     echo "$(timestamp) ERROR : Please supply the directory to generate output."
     usage
     exit 1
fi

if [ ! -d $OUTDIR ]
then
     mkdir $OUTDIR
fi

if [ -z $THREADS ]
then
     THREADS=1
fi

#if [ ! -z $TARDIR ] && [ ! -d $TARDIR ]
#then
#     echo "$(timestamp) ERROR : Please supply a valid path to a directory containing annotation tar archives."
#     usage
#     exit 1
#elif [ ! -z $TARDIR ] && [ -d $TARDIR ]
#then
#     if [ ! -f $TARDIR/GFF.tar ] || [ ! -f $TARDIR/FNA.tar ]
#     then
#	  echo "$(timestamp) ERROR : Either one or both of GFF.tar and FNA.tar archives are not valid in $TARDIR."
#	  usage
#	  exit 1
#     fi
#fi

# setting up
module load automated-annotation/1.182770-c2 bowtie2/2.3.5--py37he860b03_0 samtools/1.9--h91753b0_8

MAG_ID=$(echo $INFILE | rev | cut -d/ -f1 | cut -d. -f1 --complement | rev)
SAMPLE=$(echo $MAG_ID | cut -d. -f2)
TMP=$MAG_ID.tmp

if [ ! -d $TMP ]
then
     mkdir $TMP
fi

# annotate MAG with annotate_bacteria

echo "$(timestamp) INFO : Running annotate_bacteria workflow on MAG."

annotate_bacteria_wrapper.sh -i $INFILE -t $THREADS -G $TMP -F $TMP -N $TARDIR/FFN.tar -A $TARDIR/FAA.tar -S $TARDIR/FSA.tar

# check output
if [ ! -f $TMP/$MAG_ID.fna ] || [ ! -f $TMP/$MAG_ID.gff ]
then
     echo "$(timestamp) ERROR : Annotation failed. Exiting."
     #rm -r $TMP
     exit 1
else
     echo "$(timestamp) INFO : Annotation finished correctly."
fi

if [ $(echo "$SAMPLE" | grep -Ff - /lustre/scratch118/infgen/team162/bb11/External_databases/Mouse_metagenomes/paths.txt | wc -l) == 1 ]
then
     READ1=$(echo "$SAMPLE" | grep -Ff - /lustre/scratch118/infgen/team162/bb11/External_databases/Mouse_metagenomes/paths.txt | head -n1)
     if [ ! -f $READ1 ]
     then
	  echo "$(timestamp) ERROR : Metagenomic read ($READ1) is not valid."
	  exit 1
     fi
     cmseq.sh -t $THREADS -i $READ1 -r $TMP/$MAG_ID.fna -g $TMP/$MAG_ID.gff -o $TMP/$MAG_ID

elif [ $(echo "$SAMPLE" | grep -Ff - /lustre/scratch118/infgen/team162/bb11/External_databases/Mouse_metagenomes/paths.txt | wc -l) == 2 ]
then
     READ1=$(echo "$SAMPLE" | grep -Ff - /lustre/scratch118/infgen/team162/bb11/External_databases/Mouse_metagenomes/paths.txt | head -n1)
     READ2=$(echo "$SAMPLE" | grep -Ff - /lustre/scratch118/infgen/team162/bb11/External_databases/Mouse_metagenomes/paths.txt | tail -n1)
     if [ ! -f $READ1 ] || [ ! -f $READ2 ]
     then
          echo "$(timestamp) ERROR : Metagenomic reads ($READ1 and/or $READ2) are not valid."
          exit 1
     fi
     cmseq.sh -t $THREADS -i $READ1 -n $READ2 -r $TMP/$MAG_ID.fna -g $TMP/$MAG_ID.gff -o $TMP/$MAG_ID

else
     echo "$(timestamp) ERROR : Cannot locate metagenomic reads."
     exit 1
fi


# check output
if [ ! -f $TMP/$MAG_ID.cmseq.tsv ]
then
     echo "$(timestamp) ERROR : cmseq workflow has failed to yield output tsv file."
     exit 1
fi

if [ $(cat $TMP/$MAG_ID.cmseq.tsv | wc -l) == 0 ]
then
     echo "$(timestamp) ERROR : cmseq workflow failed, and tsv file is empty. Exiting."
     rm $TMP/$MAG_ID.cmseq.tsv
     exit 1
fi

mv $TMP/$MAG_ID.cmseq.tsv $OUTDIR
tar -rvf $TARDIR/FNA.tar $TMP/$MAG_ID.fna --remove-files
tar -rvf $TARDIR/GFF.tar $TMP/$MAG_ID.gff --remove-files

rm $TMP/$MAG_ID.*.bt2
rm $TMP/$MAG_ID.*.bai
rmdir $TMP


echo "$(timestamp) INFO : Finished workflow."
