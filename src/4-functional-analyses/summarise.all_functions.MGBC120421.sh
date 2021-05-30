#!/bin/bash

## script to summarise all the functional annotations generated for the pangenomes using IPS and eggNOG.
## Outputs human and mouse specific functional features as well as total.
## Runs summarise.pangenome_function.MGBC120421.sh on the pangenomes to build feature-genome indexes ready for downstream distance matrix calculation.

# uses the pangenome directory to find human and mouse files
# requires summarise.ips_gff.sh and summarise.eggnog_annotations.sh to have already been run, and their temporary files to still be patent.

PANGENOMES=/lustre/scratch118/infgen/team162/bb11/MGBC/PANGENOME
OUTDIR=$1

if [ ! -d $OUTDIR ]; then mkdir $OUTDIR; fi

IPS_OUT=$OUTDIR/IPS
ENOG_OUT=$OUTDIR/EGGNOG

mkdir $IPS_OUT $ENOG_OUT

module load bsub.py/0.42.1

# eggNOG

summarise_eggnog() {
	COL_INDEX=$1
	OUTSUF=$2
	echo "Mouse"
	cut -f $COL_INDEX $PANGENOMES/MOUSE/*.MOUSE/EGGNOG_OUT/emapper.tmp.tsv  | grep "\S" | sed 's/,/\n/g' | sort -u > $ENOG_OUT/m_${OUTSUF}.txt
	echo "Human"
	cut -f $COL_INDEX $PANGENOMES/HUMAN/*.HUMAN/EGGNOG_OUT/emapper.tmp.tsv  | grep "\S" | sed 's/,/\n/g' | sort -u > $ENOG_OUT/h_${OUTSUF}.txt

	if [ $OUTSUF == COG ]
	then
		cat $ENOG_OUT/m_${OUTSUF}.txt $ENOG_OUT/h_${OUTSUF}.txt | fold -w 1 | sort -u  > $ENOG_OUT/all.${OUTSUF}.txt
	else
		cat $ENOG_OUT/m_${OUTSUF}.txt $ENOG_OUT/h_${OUTSUF}.txt | sort -u > $ENOG_OUT/all.${OUTSUF}.txt
	fi
}

echo "GO"
summarise_eggnog 7 GO
echo "Enzyme"
summarise_eggnog 8 ENZYME
echo "KEGG"
summarise_eggnog 9 KEGG
echo "Pathway"
summarise_eggnog 10 PATHWAY
echo "Module"
summarise_eggnog 11 MODULE
echo "Reaction"
summarise_eggnog 12 REACTION
echo "CAZy"
summarise_eggnog 16 CAZY
echo "COG"
summarise_eggnog 21 COG


# IPS

summarise_ips() {

	MD_ID=$1
	echo "Mouse"
	grep -Fw "$MD_ID" $PANGENOMES/MOUSE/*.MOUSE/IPS_OUT/ips.summary.tsv | cut -f2 | sed 's/+/\n/g' | sort -u > $IPS_OUT/m_${MD_ID}.txt
	echo "Human"
	grep -Fw "$MD_ID" $PANGENOMES/HUMAN/*.HUMAN/IPS_OUT/ips.summary.tsv | cut -f2 | sed 's/+/\n/g' | sort -u > $IPS_OUT/h_${MD_ID}.txt

	cat $IPS_OUT/m_${MD_ID}.txt $IPS_OUT/h_${MD_ID}.txt | sort -u > $IPS_OUT/all.$MD_ID.txt
}

echo "GO"
summarise_ips GO
echo "InterPro"
summarise_ips InterPro
echo "KEGG"
summarise_ips KEGG
echo "MetaCyc"
summarise_ips MetaCyc
echo "Reactome"
summarise_ips Reactome

echo "Done!"


readlink -f $PANGENOMES/MOUSE/*.MOUSE $PANGENOMES/HUMAN/*.HUMAN | while read LINE
do
	echo "summarise.pangenome_function.MGBC120421.sh $LINE $OUTDIR"
done > $OUTDIR/run_sum_pangen_function.sh

awk ' /summarise.pangenome_function.MGBC120421/ {x="SUMPANFUNC"++i;}{print > x} ' $OUTDIR/run_sum_pangen_function.sh

FCOUNT=$(ls SUMPANFUNC* | wc -l)
bsub.py --start 1 --end $FCOUNT 1 spf.array "sh SUMPANFUNCINDEX"
bwait -w 'ended(spf.array)'

rm SUMPANFUNC*
rm spf.array.?.*

