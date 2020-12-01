# ensure farmpy module is loaded.
# 1: taxonomy level
# 2: mmseqs cluster membership file (tsv)
# 3: output directory

# set up environment variables.

module load r/3.6.0

#TAX_LEVEL=None

#MMSEQS=None

#OUT=None


TAX_LEVEL=$1

MMSEQS=$(readlink -f $2)

OUT=$3


if [ $TAX_LEVEL = None ] || [  $MMSEQS = None ] || [ $OUT = None ] ; then 
	echo "Some non-optional parameters were not entered; include taxonomical level, path to mmseqs cluster membership (.tsv file), and specify the output directory to make.";
	exit 1
fi



WORK_DIR=$(pwd)
MOUSE_DATA=/lustre/scratch118/infgen/team162/bb11/TREES/FINAL/GTDBTK/HIGH_QUALITY_GTDBTk_lowest_taxonomy.csv
HUMAN_DATA=/lustre/scratch118/infgen/team162/bb11/External_databases/MGnify/HUMAN_ONLY/HIGH_QUALITY_HUMAN_ONLY.tsv


# make output directory

if [ ! -d $OUT ]; then
	mkdir $OUT
else
	exit 1; echo "Output directory already exists. Exiting."
fi

mkdir $OUT/tmp

cd $OUT/tmp


# get high quality genomes for mouse and human hosts that are classified with the given taxonomical rank

grep -w $TAX_LEVEL $MOUSE_DATA | cut -d, -f1 | sed 's/.fa//g' > mouse_tmp
sed 's/$/_/g' mouse_tmp > mouse_tmp_2

grep -w $TAX_LEVEL $HUMAN_DATA | cut -f1 > human_tmp
sed 's/$/_/g' human_tmp > human_tmp_2


# mouse

echo "Extracting mouse contigs for this taxonomical rank."

grep -F -f mouse_tmp_2 $MMSEQS > mouse_out_tmp.tsv

for GENOME in $(cat mouse_tmp_2); do
	echo "awk ' \$2 ~ /$GENOME/ ' mouse_out_tmp.tsv" | sh >> mouse_out.tsv
	echo "$GENOME search done"
done


# human

echo "Extracting human contigs for this taxonomical rank."

grep -F -f human_tmp_2 $MMSEQS > human_out_tmp.tsv

for GENOME in $(cat human_tmp_2); do
        echo "awk ' \$2 ~ /$GENOME/ ' human_out_tmp.tsv" | sh >> human_out.tsv
        echo "$GENOME search done"
done

#DONE!


echo "Done."

echo "Getting host specific and shared clusters."

Rscript ~/Scripts/INT_HOST_CLUSTERS.R


cut -d, -f1 mouse_specific_clusters.csv | sort | uniq > mouse_clusters
cut -d, -f1 human_specific_clusters.csv | sort | uniq > human_clusters
cut -d, -f1 shared_host_clusters.csv | sort | uniq > shared_clusters

# run python script to get fastas for contigs
