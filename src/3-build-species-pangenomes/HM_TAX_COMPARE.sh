#!/bin/sh

# Author: Benjamin Beresford-Jones
# Date: 11-04-2020


usage()
{
cat << EOF

usage: $0 options

Compare a taxonomical level between human and mice. Gets all high quality genomes for this taxonomical level for each host and facilitates further analysis.

OPTIONS:

Input [REQUIRED]:
   -i      Taxonomical level to compare in quotation marks e.g.
		"s__Lactobacillus johnsonii" will get all genomes for this species
		"f__Muribaculaceae" will get all genomes that have been classified at as Muribaculaceae at the family level or lower
		"Muribaculaceae" (no taxon tag) will get genomes that have been assigned a terminal rank of Muribaculaceae at the family level i.e. no genus- or species- level assignment
   -t      Number of threads with which to run analyses.

Output - pick one of the following options:
   -o      Instead of -p flag; output directory in which to generate the results [-p flag is default option].
   -p      Instead of -o flag; supply path to directory in which to use output directory that is the same name as the taxonomical level supplied [default: ./<i>]

Action:
   -R      Run roary on genomes, to generate a core genome alignment and compare genes unique and shared to each host-group.
   -A      Run ANI analysis of the genomes, to get an average ANI between human and mouse genomes, and within hosts.
   -C      Get gene clusters that are unique and shared between each host.
   -l      Level to extract gene clusters at (use with -C). Can be one of 50, 80, 90 [default] or 100.
   -E      Run eggNOG v2 on host-specific and shared clusters.

EOF
}


timestamp() {
  date +"%H:%M:%S"
}


echo "$(timestamp) INFO : Running $0"


### READING COMMANDLINE ARGUMENTS ###

TAX_LEVEL=
OUTDIR=
PREFIX=
RUN_ROARY=
RUN_ANI=
RUN_CLUS=
CLUS_LEVEL=
THREADS=
RUN_EGGNOG=

while getopts “i:o:RACl:t:E” OPTION
do
     case $OPTION in
         i)
             TAX_LEVEL=$OPTARG
             ;;
	 o)
	     OUTDIR=$OPTARG
	     ;;
	 p)
	     PREFIX=$OPTARG
	     ;;
	 R)
	     RUN_ROARY=TRUE
	     ;;
	 A)
	     RUN_ANI=TRUE
	     ;;
	 C)
	     RUN_CLUS=TRUE
	     ;;
	 l)
	     CLUS_LEVEL=$OPTARG
	     ;;
	 E)
	     RUN_EGGNOG=TRUE
	     ;;
	 t)
	     THREADS=$OPTARG
	     ;;
         ?)
             usage
             exit
             ;;
     esac
done


if [ -z $TAX_LEVEL ]
then
     echo "$(timestamp) ERROR : No taxonomical level supplied."
     usage
     exit 1
fi


if [ ! -z $OUTDIR ] && [ ! -z $PREFIX ]
then
     echo "$(timestamp) ERROR : Please supply only one output format, either outdir PREFIX (-p) or specified OUTDIR (-o)."
     usage
     exit 1
elif [ -z $OUTDIR ] && [ -z $PREFIX ]
then
     echo "$(timestamp) WARNING : No output format specified so using specified taxonomical level in the working directory."
     OUTDIR=$(echo "$TAX_LEVEL" | sed 's/ /_/g')
     echo "$(timestamp) INFO : Writing output to $OUTDIR"
elif [ -z $OUTDIR ]
then
     WRITEDIR=$(echo "$TAX_LEVEL" | sed 's/ /_/g')
     OUTDIR=$PREFIX/$WRITEDIR
     echo "$(timestamp) INFO : Writing output to $OUTDIR"
else
     echo "$(timestamp) INFO : Writing output to $OUTDIR"
fi


if [-z $THREADS ]
then
     echo "$(timestamp) ERROR : Please supply the number of threads with the -t flag."
     usage
     exit 1
fi

### SETTING UP ###

echo "$(timestamp) INFO : Setting up to extract genomes..."

WKDIR=$(pwd)

# load modules
module load farmpy/0.42.1 drep/2.5.4 fastani/1.3--he1c1bb9_0 roary/3.12.0=pl526h470a237_1 r/3.6.0 eggnog-mapper/2.0.1--py_1

# link to host-specific GTDBTk_lowest_taxonomy databases
H_DB=/lustre/scratch118/infgen/team162/bb11/Human_mouse_comparison/HUMAN_MOUSE_HQ_REPS/GTDB_HQ_GENOMES/human_hq_GTDBTk.tsv
M_DB=/lustre/scratch118/infgen/team162/bb11/Human_mouse_comparison/HUMAN_MOUSE_HQ_REPS/GTDB_HQ_GENOMES/mouse_hq_GTDBTk.tsv

# link to host-specific metadata
H_META=/lustre/scratch118/infgen/team162/bb11/External_databases/MGnify/HUMAN_ONLY/NEW_REPS/HIGH_QUAL_137996/hq_metadata_no16_wPaths.tsv
M_META=/lustre/scratch118/infgen/team162/bb11/Mouse_genomes/HIGH_QUALITY/genome_metadata_hq.tsv

# link to genome locations
#H_GEN
M_GEN=/lustre/scratch118/infgen/team162/bb11/Mouse_genomes/HIGH_QUALITY/Genomes
M_GFFS=/lustre/scratch118/infgen/team162/bb11/Mouse_genomes/HIGH_QUALITY/gff_annotations

# count genomes of interest
HCOUNT=$(grep -wc "$TAX_LEVEL" H_DB)
MCOUNT=$(grep -wc "$TAX_LEVEL" M_DB)


echo "$(timestamp) INFO : Comparing $HCOUNT human genomes with $MCOUNT mouse genomes."


if [ $HCOUNT -eq 0 ] || [ $MCOUNT -eq 0 ]
then
     echo "$(timestamp) ERROR : Cannot make comparison due to zero genomes for at least one host."
fi


if [ -d $OUTDIR ]
then
     echo "$(timestamp) ERROR : Output directory already exists, please use a different name."
     usage
     exit 1
else
     mkdir $OUTDIR
fi


# make temporary directory
TMP=$OUTDIR/tmp

mkdir $TMP




### GETTING GENOMES ###

grep -w "$TAX_LEVEL" $H_DB | cut -f1 > $OUTDIR/human_genome_ids.txt
grep -w "$TAX_LEVEL" $M_DB | cut -f1 > $OUTDIR/mouse_genome_ids.txt


echo "$(timestamp) INFO : Getting genomes..."

mkdir $OUTDIR/HUMAN.genomes $OUTDIR/MOUSE.genomes


# human genomes
grep -wf $OUTDIR/human_genomes_ids.txt $H_META | cut -f29 | while read PATH
do
     cp $PATH $OUTDIR/HUMAN.genomes
done


HGEN_COUNT=$(ls $OUTDIR/HUMAN.genomes | wc -l)

if [ $HCOUNT -eq $HGEN_COUNT ]
then
     echo "$(timestamp) INFO : $HGEN_COUNT out of $HCOUNT mouse genomes were successfully found."
else
     echo "$(timestamp) WARNING : Only $HGEN_COUNT of $HCOUNT mouse genomes were successfully found."
fi



# mouse genomes
for GENOME in $(cat $OUTDIR/mouse_genomes_ids.txt)
do
     if [ -f $M_GEN/$GENOME.fna ]
     then
	  cp $M_GEN/$GENOME.fna $OUTDIR/MOUSE.genomes
     else
	  cp $M_GEN/$GENOME.fa $OUTDIR/MOUSE.genomes
     fi
done


MGEN_COUNT=$(ls $OUTDIR/MOUSE.genomes | wc -l)

if [ $MCOUNT -eq $MGEN_COUNT ]
then
     echo "$(timestamp) INFO : $MGEN_COUNT out of $MCOUNT mouse genoems were successfully found."
else
     echo "$(timestamp) WARNING : Only $MGEN_COUNT of $MCOUNT mouse genomes were successfully found."
fi




# run roary

if [ ! -z $RUN_ROARY ]
then
     echo "$(timestamp) INFO : Running roary on genomes."

     TMPR=$TMP/roary
     mkdir $TMPR

#     readlink -f $OUTDIR/HUMAN.genomes/* > $TMPR/human.paths
#     readlink -f $OUTDIR/MOUSE.genomes/* > $TMPR/mouse.paths

     cp $OUTDIR/human_genomes_ids.txt $TMPR/human_roary_ids.txt

     COUNT=$(cat $OUTDIR/human_genome_ids.txt $OUTDIR/human_genome_ids.txt | wc -l)

     if [ $COUNT -gt 2000 ]
     then
          echo "$(timestamp) INFO : More than 2000 genomes cannot be compared with roary, so dereplicating human genomes first..." 

	  mkdir $TMPR/DREP
	  cp -r $OUTDIR/HUMAN.genomes $TMPR/DREP

	  # get genomeInfo
	  for i in $TMPR/DREP/HUMAN.genomes/*
	  do
	       GEN_NAME=$(echo $i | rev | cut -d/ -f1 | rev | sed 's/.fna//g')
	       grep -wF "$GEN_NAME" $H_META >> $TMPR/DREP/genomes.tsv
	  done

	  cut -f1,9,10 $TMPR/DREP/genomes.tsv --output-delimiter="," > $TMPR/DREP/genome_info.csv
	  sed -i "1i genome,completeness,contamination" genome_info.csv

	  # run dRep
	  cd $TMPR/DREP/HUMAN.genomes
	  dRep dereplicate . -p $THREADS -comp 50 -con 5 -pa 0.99 -sa 0.999 -nc 0.6 --genomeInfo ../genome_info.csv -g *.fna
	  rm -r data/ figures/ *.fna
	  ls dereplicated_genomes/ | cut -d. -f1 > $TMPR/human_roary_ids.txt
	  cd $WKDIR
	  echo "$(timestamp) INFO : Finished dRep. Data on dereplicated genomes can be found in $TMPR/DREP/HUMAN.genomes/data_tables"
     fi

	  echo "$(timestamp) INFO : Preparing to run roary on genomes."
          mkdir $TMPR/HUMAN.gff_files $TMPR/MOUSE.gff_files

          # human
	  grep -wf $OUTDIR/human_roary_ids.txt $H_META | cut -f22 > $TMPR/human_gff_ftps.txt
          wget -i $TMPR/human_gff_ftps.txt -P $TMPR/HUMAN.gff_files
          gunzip $TMPR/HUMAN.gff_files/*.gz
          ls $TMPR/HUMAN.gff_files/*.gff | rev | cut -d/ -f1 | rev > $TMPR/human_gffs_downloaded.txt
          WGET_COUNT=$(grep -vc -f $TMPR/human_gffs_downloaded.txt $TMPR/human_gff_ftps.txt)
          if [ $WGET_COUNT -eq 0 ]
          then
	       echo "$(timestamp) INFO : Human gff files have been successfully downloaded."
	  else
               grep -v -f $TMPR/human_gffs_downloaded.txt $TMPR/human_gff_ftps.txt > $TMPR/human_gff_ftps.2.txt
               wget -i $TMPR/human_gff_ftps.2.txt -P $TMPR/HUMAN.gff_files
	       gunzip $TMPR/HUMAN.gff_files/*.gz
	       ls $TMPR/HUMAN.gff_files/*.gff | rev | cut -d/ -f1 | rev > $TMPR/human_gffs_downloaded.txt
               WGET_COUNT=$(grep -vc -f $TMPR/human_gffs_downloaded.txt $TMPR/human_gff_ftps.txt)
               if [ $WGET_COUNT -eq 0 ]
	       then
		    echo "$(timestamp) INFO : Human gff files have been successfully downloaded."
	       else
		    echo "$(timestamp) WARNING : $WGET_COUNT gffs could not be downloaded... These are listed in $TMPR/gff.warnings"
		    grep -v -f $TMPR/human_gffs_downloaded.txt $TMPR/human_gff_ftps.txt > $TMPR/gff.warnings
	       fi
	  fi

	  # mouse
	  for GENOME in $(cat $OUTDIR/mouse_genomes_ids.txt)
	  do
               cp $M_GFFS/$GENOME.gff $TMPR/MOUSE.gff_files
	  done
	  MGFF_COUNT=$(ls $TMPR/MOUSE.gff_files.txt | wc -l)
	  if [ $MCOUNT -eq $MGFF_COUNT ]
	  then
	       echo "$(timestamp) INFO : All mouse gff files have been successfully found."
	  else
	       echo "$(timestamp) WARNING : Only $MGFF_COUNT mouse gff files out of $MCOUNT have been successfully found..."
          fi

	  mkdir $TMPR/COMBINED.gff_files
	  cp $TMPR/HUMAN.gff_files/*.gff $TMPR/MOUSE.gff_files/*.gff $TMPR/COMBINED.gff_files
	  cd $TMPR/COMBINED.gff_files

     echo "$(timestamp) INFO : Running roary."
	  roary *.gff -e -n -p $THREADS -f $OUTDIR/roary.out
     if [ -d $OUTDIR/roary.out ]
     then
	  cd $OUTDIR/roary.out
     else
	  mkdir $OUTDIR/query_pan_genome.out
	  cd $OUTDIR/query_pan_genome.out
     fi

     # run query_pan_genome
     echo "$(timestamp) INFO : Running query_pan_genome on roary output to get genomes that are specific to human- or mice-derived commensals." 
     H_GFF_LIST=$(ls $TMPR/HUMAN.gff_files/*.gff | paste -s -d,)
     M_GFF_LIST=$(ls $TMPR/MOUSE.gff_files/*.gff | paste -s -d,)
     if [ -f clustered_proteins ]
     then
	  ROARY_OUT=clustered_proteins
     else
	  ROARY_OUT=$(find $OUTDIR | grep "clustered_proteins")
     fi

     query_pan_genome -a difference --input_set_one $H_GFF_LIST --input_set_two $M_GFF_LIST -g $ROARY_OUT



fi

# run fastANI

if [ ! -z $RUN_ANI ]
then
     echo "$(timestamp) INFO : Running fastANI analysis on genomes."

     TMPA=$TMP/fastANI
     mkdir $TMPA $OUTDIR/fastANI.out

     readlink -f $OUTDIR/HUMAN.genomes/* > $TMPA/human.paths
     readlink -f $OUTDIR/MOUSE.genomes/* > $TMPA/mouse.paths

     # human-mouse
     fastANI --rl $TMPA/human.paths --ql $TMPA/mouse.paths -t $THREADS --minFraction 0.6 -o $OUTDIR/fastANI.out/HM.ani

     # mouse-mouse
     fastANI --rl $TMPA/mouse.paths --ql $TMPA/mouse.paths -t $THREADS --minFraction 0.6 -o $OUTDIR/fastANI.out/MM.ani

     # human-human
     fastANI --rl $TMPA/human.paths --ql $TMPA/human.paths -t $THREADS --minFraction 0.6 -o $OUTDIR/fastANI.out/HH.ani

# bsub.py 5 --threads 20 $i.fastani_file 'fastANI --rl $i/readlink.txt --ql $i/readlink.txt -t 20 --minFraction 0.6 --matrix -o $i/$i.FASTTREE_OUT
     echo "$(timestamp) INFO : Finished fastANI analyses. Outputs can be found in $OUTDIR/fastANI.out/"

fi


# get unique contig clusters from mmseqs

if [ ! -z $RUN_CLUS ]
then
     echo "$(timestamp) INFO : Preparing to run protein cluster analysis for genomes."

     if [ -z $CLUS_LEVEL ]
     then
	  CLUS_LEVEL=90
     fi

     H_CM_UGHP100=/lustre/scratch118/infgen/team162/bb11/Human_mouse_comparison/FUNCTIONAL_COMPARISON/GENERA_COMPARISON/Protein_Catalogues/HUMAN_HIGH_QUAL/ughp100_hq_cluster_membership.sorted.out
     CLUSMEM=/lustre/scratch118/infgen/team162/bb11/Human_mouse_comparison/FUNCTIONAL_COMPARISON/GENERA_COMPARISON/Protein_Catalogues/HIGH_QUAL_CLUSTERS/CLUS_"$CLUS_LEVEL"

     CLUST_OUT=$OUTDIR/cluster_"$CLUS_LEVEL".out
     TMPC=$TMP/cluster
     mkdir $TMPC $CLUST_OUT

     grep -Ff $OUTDIR/human_genome_ids.txt $H_CM_UGHP100 > $TMPC/h_ughp100.tmp.tsv
     cut -f1 $TMPC/h_ughp100.tmp.tsv | uniq > $TMPC/h_ughp100.tmp.txt
     grep -Ff $OUTDIR/human_genome_ids.txt $CLUSMEM/mmseqs_cluster.tsv > $TMPC/h_clusmem.tmp.tsv
     cut -f1 $TMPC/h_clusmem.tmp.tsv | uniq > $TMPC/h_clusmem.tmp.txt
     grep -Fwf $TMPC/h_ughp100.tmp.txt $CLUSMEM/mmseqs_cluster.tsv > $TMPC/h_clusmem.ughp100.tmp.tsv
     cut -f1 $TMPC/h_clusmem.ughp100.tmp.tsv | uniq > $TMPC/h_clusmem.ughp100.tmp.txt

     cat $TMPC/h_clusmem.tmp.txt $TMPC/h_clusmem.ughp100.tmp.txt | sort | uniq > $TMPC/human_cluster_reps.txt

     grep -Ff $OUTDIR/mouse_genome_ids.txt $CLUSMEM/mmseqs_cluster.tsv > $TMPC/m_clusmem.tmp.tsv
     cut -f1 $TMPC/m_clusmem.tmp.tsv | sort | uniq > $TMPC/mouse_cluster_reps.txt

     Rscript /lustre/scratch118/infgen/team162/bb11/bin/taxcomp/INT_HOST_CLUSTERS_v2.R -H $TMPC/human_cluster_reps.txt -M $TMPC/mouse_cluster_reps.txt -o $TMPC

     cut -d, -f1 $TMPC/mouse_specific_clusters.csv | sort | uniq > $TMPC/mouse_specific_clusters.txt
     cut -d, -f1 $TMPC/human_specific_clusters.csv | sort | uniq > $TMPC/human_specific_clusters.txt
     cut -d, -f1 $TMPC/shared_host_clusters.csv | sort | uniq > $TMPC/shared_host_clusters.txt

     mkdir $CLUST_OUT/MOUSE $CLUST_OUT/HUMAN $CLUST_OUT/SHARED

     GET_FASTA_FROM_CONTIGS_v4.py -i $CLUSMEM/mmseqs_cluster_rep.fa -g $TMPC/mouse_specific_clusters.txt -o $CLUST_OUT/MOUSE
     GET_FASTA_FROM_CONTIGS_v4.py -i $CLUSMEM/mmseqs_cluster_rep.fa -g $TMPC/human_specific_clusters.txt -o $CLUST_OUT/HUMAN
     GET_FASTA_FROM_CONTIGS_v4.py -i $CLUSMEM/mmseqs_cluster_rep.fa -g $TMPC/shared_host_clusters.txt -o $CLUST_OUT/SHARED

     if [ ! -z $RUN_EGGNOG ]
     then
	  echo "$(timestamp) INFO : Running eggNOG on cluster outputs."
	  emapper.py --data_dir /nfs/pathogen/eggnogv2 -o $CLUST_OUT/HUMAN/HUMAN.dmnd -i $CLUST_OUT/HUMAN/extracted_seqs.faa -m diamond --cpu $THREADS
          emapper.py --data_dir /nfs/pathogen/eggnogv2 -o $CLUST_OUT/MOUSE/MOUSE.dmnd -i $CLUST_OUT/MOUSE/extracted_seqs.faa -m diamond --cpu $THREADS
          emapper.py --data_dir /nfs/pathogen/eggnogv2 -o $CLUST_OUT/SHARED/SHARED.dmnd -i $CLUST_OUT/SHARED/extracted_seqs.faa -m diamond --cpu $THREADS
     fi


# finish roary script

# move all working scripts to internal bin scripts that are called by the module...
# run analyses on shared species and on families/classes

