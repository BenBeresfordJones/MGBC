# !/bin/bash


usage()
{
cat << EOF
usage: $0 options

Do complete analysis on an eggnog annotation output.

OPTIONS:
   -a      eggNOG v2 annotation output file.
   -D      Directory containing the eggNOG refernce databases [not implemented]
   -o      Directory to write to [default: <.>]
   -p      Prefix for output files [ default: <-i>].
   -f      Original .faa file used for running eggnog.

EOF
}

ANNOTATION=
DATA=
OUTDIR=
PREFIX=
ORIG_FAA=

while getopts “a:o:p:f:” OPTION
do
     case ${OPTION} in
         a)
             ANNOTATION=${OPTARG}
             ;;
         o)
             OUTDIR=${OPTARG}
             ;;
         p)
             PREFIX=${OPTARG}
             ;;
	 f)
	     ORIG_FAA=$OPTARG
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

WKDIR=$(pwd)

if [ -z $ANNOTATION ]
then
     echo "$(timestamp) ERROR : Please supply the path to the eggnog annotation output file."
     usage
     exit 1
fi

if [ -z $OUTDIR ]
then
     OUTDIR=$WKDIR
fi

if [ ! -d $OUTDIR ]
then
     mkdir $OUTDIR
fi

if [ -z $PREFIX ]
then
     PREFIX=$(echo $ANNOTATION | sed 's/dmnd.emapper.annotations/eggnog-out/g')
fi

echo "$(timestamp) INFO : Writing output files to $OUTDIR."

echo "$(timestamp) INFO : Setting up to analyse eggNOG output."

TMP=$OUTDIR/$PREFIX.tmp

if [ ! -d $TMP ]
then
     mkdir $TMP
fi

if [ -z $DATA ]
then
     DATA=/lustre/scratch118/infgen/team162/bb11/Human_mouse_comparison/FUNCTIONAL_COMPARISON/REPRESENTATIVE_eggNOG/KEGG_DB
fi

if [ ! -d $DATA ]
then
     echo "(timestamp) ERROR : KEGG database directory cannot be found. Exiting..."
     usage
     exit 1
fi

MODULES=$DATA/MODULE
PATHWAYS=$DATA/PATHWAY

OUTFILE=$OUTDIR/$PREFIX

# 1 gene
# 8 enzymes
# 9 ko
# 10 pathway
# 11 module
# 12 reaction
# 14 brite
# 16 CAZy
# 19 eggNOG OGs
# 21 COG category
# 22 eggnog free text


echo "$(timestamp) INFO : Processing file."

# get count of original genes defined by annotate_bacteria.
echo "$(timestamp) INFO : Getting original gene count, if original .faa file supplied.."
if [ ! -z $ORIG_FAA ]
then
     GENE_COUNT=$(grep -Fc ">" $ORIG_FAA)
else
     echo "$(timestamp) INFO : Original .faa file not supplied.... skipping."
fi

echo "$(timestamp) INFO : Making tmp directory - $TMP"
EOUT=$TMP/eggnog-out.tsv

grep -Fwv -e "#" -e "#query_name" $ANNOTATION > $EOUT


# get counts of genes annotated with different databases
echo "$(timestamp) INFO : Getting gene counts for different databases."

echo "$(timestamp) INFO : There are $GENE_COUNT predicted genes for this genome."
# KEGG
KO_COUNT=$(cut -f9 $EOUT | grep -c "\S")
echo "$(timestamp) INFO : There are $KO_COUNT KEGG (KO) assigned genes."
# COG
#COG_COUNT=$(cut -f21 $EOUT | grep -c "\S")
COG_COUNT_NO_RS=$(cut -f21 $EOUT | grep "\S" | grep -cv -e "S" -e "R")
echo "$(timestamp) INFO : There are $COG_COUNT_NO_RS COG assigned genes."
# eggNOG OGs
EGGNOG_OG_COUNT=$(cut -f19 $EOUT | grep -c "\S")
echo "$(timestamp) INFO : There are $EGGNOG_OG_COUNT eggNOG OG assigned genes."
EGGNOG_FREE_TEXT_COUNT=$(cut -f22 $EOUT | grep -c "\S")
# CAZy
CAZY_COUNT=$(cut -f16 $EOUT | grep -c "\S")
echo "$(timestamp) INFO : There are $CAZY_COUNT CAZy genes."

echo -e "ORIG_GENE_COUNT\t$GENE_COUNT" > $OUTFILE.stats.tsv
echo -e "KO_COUNT\t$KO_COUNT" >> $OUTFILE.stats.tsv
echo -e "COG_COUNT\t$COG_COUNT_NO_RS" >> $OUTFILE.stats.tsv
echo -e "EGGNOG_OG_COUNT\t$EGGNOG_OG_COUNT" >> $OUTFILE.stats.tsv
echo -e "EGGNOG_FREE_TEXT_COUNT\t$EGGNOG_FREE_TEXT_COUNT" >> $OUTFILE.stats.tsv
echo -e "CAZY_COUNT\t$CAZY_COUNT" >> $OUTFILE.stats.tsv

# define function to extract data for different columns

extract-data() {

     COL_INDEX=$1

     cut -f$COL_INDEX $EOUT | grep "\S" | sed 's/,/\n/g' | sort | uniq -c | sed 's/^ *//g' | sed 's/ /\t/g'

}

echo "$(timestamp) INFO : Extracting data for each database."

# 8 enzymes
extract-data 8 > $TMP/ENZYME.raw.txt
# 9 ko
extract-data 9 > $TMP/KO.raw.txt
# 10 pathway
extract-data 10 | grep "map" > $TMP/PATHWAY.raw.txt
# 11 module
extract-data 11 > $TMP/MODULE.raw.txt
# 12 reaction
extract-data 12 > $TMP/REACTION.raw.txt
# 16 CAZy
extract-data 16 > $TMP/CAZY.raw.txt
# 19 eggNOG OGs
extract-data 19 > $TMP/EGGNOG_OG.raw.txt
# 21 COG category
extract-data 21 > $TMP/COG.raw.txt


# 22 eggnog free text - too many commas...
#extract-data 22 > $OUTFILE.FREETEXT.raw.txt

# ENZYME
while read LINE
do
     DESCR=$(echo $LINE | cut -d " " -f2 | sed 's/^/ec:/g' | grep -wf - $DATA/ENZYME | cut -f2)
     echo -e "$LINE\t$DESCR"
done < $TMP/ENZYME.raw.txt > $OUTFILE.ENZYME.out.tsv
echo "$(timestamp) INFO : ENZYME done."

# KO
while read LINE
do
     DESCR=$(echo $LINE | cut -d " " -f2 | grep -wf - $DATA/KEGG_ORTHOLOGY | cut -f2)
     echo -e "$LINE\t$DESCR"
done < $TMP/KO.raw.txt > $OUTFILE.KO.out.tsv
echo "$(timestamp) INFO : KO done."

# PATHWAY
while read LINE
do
     DESCR=$(echo $LINE | cut -d " " -f2 | grep -wf - $DATA/PATHWAY | cut -f2)
     echo -e "$LINE\t$DESCR"
done < $TMP/PATHWAY.raw.txt > $OUTFILE.PATHWAY.out.tsv
echo "$(timestamp) INFO : PATHWAY done."

# MODULE
while read LINE
do
     DESCR=$(echo $LINE | cut -d " " -f2 | grep -wf - $DATA/MODULE | cut -f2)
     echo -e "$LINE\t$DESCR"
done < $TMP/MODULE.raw.txt > $OUTFILE.MODULE.out.tsv
echo "$(timestamp) INFO : MODULE done."

# REACTION
while read LINE
do
     DESCR=$(echo $LINE | cut -d " " -f2 | grep -wf - $DATA/REACTION | cut -f2)
     echo -e "$LINE\t$DESCR"
done < $TMP/REACTION.raw.txt > $OUTFILE.REACTION.out.tsv
echo "$(timestamp) INFO : REACTION done."

# COG
for COG in $(cat $DATA/COG_LETTERS);
do
     COUNT=$(grep -c "$COG" $TMP/COG.raw.txt)
     DESCR=$(grep -w "[$COG]" $DATA/COG)
     echo -e "$COUNT\t$DESCR"
done > $OUTFILE.COG.out.tsv
echo "$(timestamp) INFO : COG done."

# CAZY
cp $TMP/CAZY.raw.txt $OUTFILE.CAZY.out.tsv
echo "$(timestamp) INFO : CAZY done."
# EGGNOG_OG
cp $TMP/EGGNOG_OG.raw.txt $OUTFILE.EGGNOG_OG.out.tsv
echo "$(timestamp) INFO : EGGNOG_OG done."


echo "$(timestamp) INFO : Done!"

