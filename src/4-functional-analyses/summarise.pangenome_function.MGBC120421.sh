#!/bin/bash

PANDIR=$1 # pangenome directory for species
WKDIR=$2 # outdir for summarise.functions.sh

NGEN=$(wc -l $PANDIR/genome_ids.txt | cut -d " " -f1)

IPS=$PANDIR/IPS_OUT
ENOG=$PANDIR/EGGNOG_OUT

if [ ! -d $IPS ]; then mkdir $IPS; fi
if [ ! -d $ENOG ]; then mkdir $ENOG; fi

SPECIES=$(basename $PANDIR | cut -d. -f1)

# build summary file for IPS
if [ ! -f $IPS/ips.tmp.tsv ]
then
	grep -Fw -e "Dbxref" -e "Ontology_term" $PANDIR/cluster_90.out/ips_out.gff > $IPS/ips.tmp.tsv
fi

## IPS
get.ips_data() {
	DB=$1
	echo "$DB"

        grep -Fwf $WKDIR/IPS/all.$DB.txt $IPS/ips.tmp.tsv > $IPS/$DB.tmp
        cut -f1 $IPS/$DB.tmp | grep -Fwf - $IPS/gg_index.tsv > $IPS/$DB.tmp.gg

	while read f # feature
	do
        	GCOUNT=$(grep -Fw "$DB:$f" $IPS/ips.tmp.tsv | cut -f1 | grep -Fwf - $IPS/gg_index.tsv | cut -f2 | sort -u | wc -l)
        	GENIDS=$(grep -Fw "$DB:$f" $IPS/ips.tmp.tsv | cut -f1 | grep -Fwf - $IPS/gg_index.tsv | cut -f1 | sort -u | paste -sd ":")
        	printf "$SPECIES\t$DB\t$f\t$GCOUNT\t$NGEN\t$GENIDS\n"
	done < $WKDIR/IPS/all.$DB.txt | awk -v OFS='\t' '{$7=$6;$6=$4/$5}'1 > $IPS/$DB.tsv

        rm $IPS/$DB.tmp $IPS/$DB.tmp.gg
}


get.ips_data "GO"
get.ips_data "InterPro"
get.ips_data "KEGG"
get.ips_data "MetaCyc"
get.ips_data "Reactome"


## EGGNOG

# build summary file for eggnog

if [ ! -f $ENOG/emapper.tmp.tsv ]
then
	awk ' $1 !~ /^#/ ' $PANDIR/cluster_90.out/*.annotations > $ENOG/emapper.tmp.tsv
fi


get.eggnog_data() {
        DB=$1
	echo "$DB"

	grep -Fwf $WKDIR/EGGNOG/all.$DB.txt $ENOG/emapper.tmp.tsv > $ENOG/$DB.tmp
	cut -f1 $ENOG/$DB.tmp | grep -Fwf - $IPS/gg_index.tsv > $ENOG/$DB.tmp.gg

        while read f # feature
        do
                GCOUNT=$(grep -Fw "$f" $ENOG/$DB.tmp | cut -f1 | grep -Fwf - $ENOG/$DB.tmp.gg | cut -f2 | sort -u | wc -l)
                GENIDS=$(grep -Fw "$f" $ENOG/$DB.tmp | cut -f1 | grep -Fwf - $ENOG/$DB.tmp.gg | cut -f1 | sort -u | paste -sd ":")
                printf "$SPECIES\t$DB\t$f\t$GCOUNT\t$NGEN\t$GENIDS\n"
        done < $WKDIR/EGGNOG/all.$DB.txt | awk -v OFS='\t' '{$7=$6;$6=$4/$5}'1 > $ENOG/$DB.tsv

	rm $ENOG/$DB.tmp $ENOG/$DB.tmp.gg
}

get.eggnog_data GO
get.eggnog_data ENZYME
get.eggnog_data KEGG
get.eggnog_data PATHWAY
get.eggnog_data MODULE
get.eggnog_data REACTION
get.eggnog_data CAZY

#get.eggnog_data COG # COG will need a separate analysis

echo "Done!"
