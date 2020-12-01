#!/bin/bash

usage()
{
cat << EOF
usage: $0 options

Generate bam file and get coverage of a MAG.

OPTIONS:
   -t      Number of threads [REQUIRED]
   -i      Input first or only read (.fastq or .fastq.gz format) [REQUIRED]
   -n      Input reverse read (.fastq or fastq.gz [OPTIONAL]
   -r      MAG genome file (.fa or .fasta) [REQUIRED]
   -o      Output files prefix (include path) [REQUIRED]

EOF
}

# variables
threads=
ref=
reads=
reads2=
outprefix=
gff=

while getopts “t:m:i:n:r:o:” OPTION
do
     case ${OPTION} in
         t)
             threads=${OPTARG}
             ;;
         i)
             reads=${OPTARG}
             ;;
         n)
             reads2=${OPTARG}
             ;;
         r)
             ref=${OPTARG}
             ;;
         o)
             outprefix=${OPTARG}
             ;;
         ?)
             usage
             exit
             ;;
     esac
done

# check arguments
if [[ -z ${threads} ]] || [[ -z ${reads} ]] || [[ -z ${ref} ]] || [[ -z ${outprefix} ]]
then
     echo "ERROR : Please supply correct arguments"
     usage
     exit 1
fi


timestamp() {
  date +"%H:%M:%S"
}

readname=$(basename ${outprefix})
refix=$(basename ${ref%%.fa*})
if [ ${threads} -eq 1 ]
then
    threads_sam=1
else
    threads_sam=$((${threads}-1))
fi

# index reference file
if [[ ! -s ${outprefix}.1.bt2 ]]
then
    echo "$(timestamp) [ CMseq ] Indexing MAG FASTA file"
    bowtie2-build ${ref} ${outprefix}
else
    echo "$(timestamp) [ CMseq ] Index found, skipping bowtie2-build"
fi


# initial mapping and sorting
echo "$(timestamp) [ CMseq ] Mapping reads against MAG ..."
if [[ -z ${reads2} ]]
then
    bowtie2 --very-sensitive-local -x ${outprefix} -p ${threads} -U ${reads} | samtools view -@ ${threads_sam} -uS - | samtools sort -@ ${threads_sam} - -o ${outprefix}.bam
#    samtools index -@ ${threads_sam} ${outprefix}.bam

else
    bowtie2 --very-sensitive-local -x ${outprefix} -p ${threads} -1 ${reads} -2 ${reads2} | samtools view -@ ${threads_sam} -uS - | samtools sort -@ ${threads_sam} - -o ${outprefix}.bam
#    samtools index -@ ${threads_sam} ${outprefix}.bam

fi

