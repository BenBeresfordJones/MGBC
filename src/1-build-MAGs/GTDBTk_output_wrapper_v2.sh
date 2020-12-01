#!/usr/bin/env bash

### AUTHOR: BENJAMIN BERESFORD-JONES  ###



# set everything up

module load r/3.6.0

LOWEST_TAX=/nfs/users/nfs_b/bb11/Scripts/get_lowest_taxonomy_v1.0.R

if [ ! -s $LOWEST_TAX ]; then
	echo "The location or name of get_lowest_taxonomy.R script has been changed."; exit 1
fi

if [ -s GTDBTk_lowest_taxonomy.csv ]; then rm GTDBTk_lowest_taxonomy.csv; fi

if [ -s pre_KRAKEN_batchfile.txt ]; then rm pre_KRAKEN_batchfile.txt; fi



# run 'get_lowest_taxonomy_v1.0.R'

Rscript $LOWEST_TAX


# Agathobacter rectale is divergent between the GTDB taxonomy file and the gtdbtk tool.
# Change Agathobacter rectalis into Agathobacter rectale - otherwise no taxid generated.

sed -i 's/Agathobacter rectalis/Agathobacter rectale/g' GTDBTk_lowest_taxonomy.csv



# get the taxid for each species and generate the output file

cut -d, -f1 GTDBTk_lowest_taxonomy.csv > GENOME_IDS
cut -d, -f6 GTDBTk_lowest_taxonomy.csv > TAXONOMY

while read p; do
	LOWEST=$(echo $p | cut -d, -f3)
	TAXID=$(grep -P "$LOWEST\t" /nfs/pathogen005/team162/taxonomy/names.dmp | cut -f1)
	echo $TAXID;
	done < GTDBTk_lowest_taxonomy.csv > TAX_IDS

paste GENOME_IDS TAX_IDS TAXONOMY > pre_KRAKEN_batchfile.txt

rm GENOME_IDS TAX_IDS TAXONOMY


echo "DONE!"
