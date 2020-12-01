# !/bin/bash


usage()
{
cat << EOF
usage: $0 options

Do complete analysis on an IPS annotation output.

OPTIONS:
   -a      IPS v5 annotation output file (gff format).
   -D      Directory containing the IPS reference databases [not implemented]
   -o      Directory to write to [default: <.>]
   -p      Prefix for output files [ default: <-i>].
   -f      Original .faa file used for running IPS.

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
     echo "$(timestamp) ERROR : Please supply the path to the IPS annotation output file."
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
     PREFIX=ips.annotation
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
     DATA=/lustre/scratch118/infgen/team162/bb11/External_databases/InterPro
fi

if [ ! -d $DATA ]
then
     echo "(timestamp) ERROR : IPS family database directory cannot be found. Exiting..."
     usage
     exit 1
fi

FAM_INDEX=$DATA/FAMILY_index.txt
if [ ! -f $FAM_INDEX ]
then
     echo "$(timestamp) ERROR : FAMILY_index.txt file cannot be located. Exiting."
     usage
     exit 1
fi

OUTFILE=$OUTDIR/$PREFIX


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
EOUT=$TMP/ips-out.tsv

grep "InterPro:" $ANNOTATION > $EOUT


# get counts of genes annotated with different databases
echo "$(timestamp) INFO : Getting gene counts for databases."

echo "$(timestamp) INFO : There are $GENE_COUNT predicted genes for this genome."

# TOTAL IPR ID
IPR_COUNT=$(cut -f1 $EOUT | sort | uniq | wc -l)
echo "$(timestamp) INFO : There are $IPR_COUNT IPR id assigned genes."

# FAMILY IPR ID
FAMILY_COUNT=$(grep -Fwf $FAM_INDEX $EOUT | cut -f1 | sort | uniq | wc -l)
echo "$(timestamp) INFO : There are $FAMILY_COUNT family-type IPR assigned genes."


echo -e "ORIG_GENE_COUNT\t$GENE_COUNT" > $OUTFILE.stats.tsv
echo -e "TOTAL_IPR_COUNT\t$IPR_COUNT" >> $OUTFILE.stats.tsv
echo -e "FAMILY_IPR_COUNT\t$FAMILY_COUNT" >> $OUTFILE.stats.tsv

# get IPRs for this annotation

cut -f1 $EOUT | sed -E 's/^(.*)_(.)(..)_(.*)/\1_\2#\3_\4/g' | sed -E 's/^(.*)_(.)(.)_(.*)/\1_\2#\3_\4/g' > $TMP/genes.txt # get gene names, correcting sanger ids
grep -o "InterPro:IPR.*" $EOUT | cut -d '"' -f1 | cut -d: -f2 > $TMP/ipr_list.txt

paste $TMP/genes.txt $TMP/ipr_list.txt | sort | uniq > $TMP/gene-ipr.tsv


# all IPR ids
cut -f2 $TMP/gene-ipr.tsv | sort | uniq -c | sed 's/^ *//g' | sed 's/ /\t/g' > $TMP/all_ipr_ids.tsv

# family IPR ids
grep -Fwf $FAM_INDEX $TMP/gene-ipr.tsv | cut -f2 | sort | uniq -c | sed 's/^ *//g' | sed 's/ /\t/g' > $TMP/family_ipr_ids.tsv


# all IPR
while read LINE
do
     DESCR=$(echo $LINE | cut -d " " -f2 | grep -Fwf - $DATA/entry.list | cut -f2,3)
     echo -e "$LINE\t$DESCR"
done < $TMP/all_ipr_ids.tsv > $OUTFILE.all_ipr.out.tsv
echo "$(timestamp) INFO : All IPR ids done."

# family
while read LINE
do
     DESCR=$(echo $LINE | cut -d " " -f2 | grep -wf - $DATA/InterPro_FAMILY.tsv | cut -f2,7)
     echo -e "$LINE\t$DESCR"
done < $TMP/family_ipr_ids.tsv > $OUTFILE.family_ipr.out.tsv
echo "$(timestamp) INFO : FAMILIES done."

echo "$(timestamp) INFO : Done!"

