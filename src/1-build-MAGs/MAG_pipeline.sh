# !/bin/bash


usage()
{
cat << EOF
usage: $0 options

generate scripts for and run MAG synthesis pipeline.

OPTIONS:
   -i      Path to input file containing SRR's (or MAG names without the .fastq).
   -s      Path to the metagenome study.
   -t      Number of threads
   -S      Do not run pipeline, just generate the scripts.
   -e      Early end - end after running ASSEMBLY, -BINNING- or REFINE.
   -f      File count - keep track of the number of files that are being produced by each job.

EOF
}

INFILE=
INDIR=
THREADS=
JUST_SCRIPTS=
EARLYEND=
FILECOUNT=

while getopts “i:s:t:Se:f” OPTION
do
     case ${OPTION} in
         i)
             INFILE=${OPTARG}
             ;;
         s)
             INDIR=${OPTARG}
             ;;
         t)
             THREADS=${OPTARG}
             ;;
	 S)
	     JUST_SCRIPTS=TRUE
	     ;;
	 e)
	     EARLYEND=$OPTARG
	     ;;
	 f)
	     FILECOUNT=TRUE
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

echo "$(date)"
echo "$(timestamp) INFO : Running $@"


if [ -z $INFILE ] || [ ! -f $INFILE ]
then
     echo "$(timestamp) ERROR : Please supply a valid SRR file with the -i flag."
     usage
     exit 1
fi

if [ -z $INDIR ] || [ ! -d $INDIR ]
then
     echo "$(timestamp) ERROR : Please specify the path to the metagenome study dirctory with the -s flag"
     usage
     exit 1
fi

if [ ! -d $INDIR/Metagenomes ]
then
     echo "$(timestamp) ERROR : Cannot locate the Metagenomes directory within the metagenome study directory."
     usage
     exit 1
fi

if [ -z $THREADS ]
then
     THREADS=1
fi

if [ -z $EARLYEND ]
then
     EARLYEND=FULL
elif [ $EARLYEND == ASSEMBLY ] || [ $EARLYEND == BINNING ] || [ $EARLYEND == REFINE ]
then
     echo "$(timestamp) INFO : Terminating pipeline early after $EARLYEND step."
else
     echo "$(timestamp) ERROR : Please provide a correct option for the step after which to end: ASSEMBLY, BINNING, REFINE."
     usage
     exit 1
fi

if [ -z $FILECOUNT ]
then
     FILECOUNT=FALSE
fi


# determine whether paired or unpaired
SRRCOUNT=$(wc -l $INFILE | cut -d " " -f1)
FASTQCOUNT=$(ls $INDIR/Metagenomes | grep -cw "fastq")
FQ1COUNT=$(ls $INDIR/Metagenomes | grep -c "_1.fastq")
FQ2COUNT=$(ls $INDIR/Metagenomes | grep -c "_2.fastq")


echo "$(timestamp) INFO : Setting up."

makedir() {
if [ ! -d $1 ]; then mkdir $1; fi
}

SCRIPTS=$INDIR/SCRIPTS
QC=$INDIR/QC
ASSEMBLY=$INDIR/ASSEMBLY
BINNING=$INDIR/BINNING
BIN_REFINE=$INDIR/BIN_REFINE
BIN_REASSEMBLY=$INDIR/BIN_REASSEMBLY

makedir $QC
makedir $ASSEMBLY
makedir $BINNING
makedir $BIN_REFINE
makedir $BIN_REASSEMBLY


if [ -d $SCRIPTS ]; then rm -r $SCRIPTS; fi

mkdir $SCRIPTS


echo "$(timestamp) INFO : Generating SCRIPTS for analyses."

## IF SINGLE
if [ $FQ1COUNT == 0 ] && [ $FQ2COUNT == 0 ] && [ $SRRCOUNT == $FASTQCOUNT ]
then
     echo "$(timestamp) INFO : Running analyses for SINGLE layout samples."

     for SRR in $(cat $INFILE)
     do
          echo "/software/pathogen/etc/farmpy/0.42.1/wrappers/bsub.py 15 -q long --threads 1 $SRR.qc 'QC_SINGLE.sh $SRR $INDIR $THREADS $EARLYEND'" >> $SCRIPTS/QC.sh
          echo "/software/pathogen/etc/farmpy/0.42.1/wrappers/bsub.py 15 -q long --threads 1 $SRR.qc 'kneaddata -i $INDIR/Metagenomes/"$SRR".fastq -t 1 -db /lustre/scratch118/infgen/team162/bb11/External_databases/C57BL6/PRJNA310854/ -db /lustre/scratch118/infgen/team162/ys4/BBS/PhiX174_Bowtie2 --output $QC'" >> $SCRIPTS/command.log

          echo "/software/pathogen/etc/farmpy/0.42.1/wrappers/bsub.py 15 -q long --threads $THREADS $SRR.mh_assembly 'megahit -t $THREADS -r $QC/Reads_post_qc/"$SRR"_kneaddata.fastq -o $ASSEMBLY/$SRR.assembly.fa'" >> $SCRIPTS/command.log


     done

elif [ $FQ1COUNT == $FQ2COUNT ] && [ $SRRCOUNT == $FQ1COUNT ]
then
     echo "$(timestamp) INFO : Running analyses for PAIRED layout samples."

     for SRR in $(cat $INFILE)
     do
          echo "/software/pathogen/etc/farmpy/0.42.1/wrappers/bsub.py 15 -q long --threads 1 $SRR.qc 'QC_PAIRED.sh $SRR $INDIR $THREADS $EARLYEND'" >> $SCRIPTS/QC.sh
          echo "/software/pathogen/etc/farmpy/0.42.1/wrappers/bsub.py 15 -q long --threads 1 $SRR.qc 'kneaddata -i $INDIR/Metagenomes/"$SRR"_1.fastq -i $INDIR/Metagenomes/"$SRR"_2.fastq -t 1 -db /lustre/scratch118/infgen/team162/bb11/External_databases/C57BL6/PRJNA310854/ -db /lustre/scratch118/infgen/team162/ys4/BBS/PhiX174_Bowtie2 --output $QC'" >> $SCRIPTS/command.log

	  echo "/software/pathogen/etc/farmpy/0.42.1/wrappers/bsub.py 100 -q long --threads $THREADS $SRR.ms_assembly 'metawrap assembly --metaspades -m 95 -t $THREADS -1 $QC/Reads_post_qc/"$SRR"_1_kneaddata_paired_1.fastq -2 $QC/Reads_post_qc/"$SRR"_1_kneaddata_paired_2.fastq -o $ASSEMBLY/$SRR.ASSEMBLY'" >> $SCRIPTS/command.log
	  echo "/software/pathogen/etc/farmpy/0.42.1/wrappers/bsub.py 40 --threads $THREADS -q long $SRR.mh_assembly 'metawrap assembly --megahit -m 40 -t $THREADS -1 $QC/Reads_post_qc/"$SRR"_1_kneaddata_paired_1.fastq -2 $QC/Reads_post_qc/"$SRR"_1_kneaddata_paired_2.fastq -o $ASSEMBLY/$SRR.ASSEMBLY'" >> $SCRIPTS/command.log
     done

else
     echo "ERROR : $SRRCOUNT $FASTQCOUNT $FQ1COUNT $FQ2COUNT"
     exit 1
fi


if [ -z $JUST_SCRIPTS ]
then
     sh $SCRIPTS/QC.sh
fi


if [ $FILECOUNT == TRUE ]
then
     echo "$(timestamp) INFO : Starting file counting commands."
     for SRR in $(cat $INFILE)
     do
	  echo "/software/pathogen/etc/farmpy/0.42.1/wrappers/bsub.py 0.1 -q basement $SRR.fc 'watch_file_count.sh \"$INDIR/*/$SRR.*\" $SCRIPTS/$SRR.filecount.txt'" | sh
     done
fi


echo "$(timestamp) INFO : Finished SCRIPT building."
