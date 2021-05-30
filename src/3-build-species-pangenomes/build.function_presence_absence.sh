#!/bin/bash

OUTDIR=$1

if [ ! -d $OUTDIR ]; then mkdir $OUTDIR; fi

HUMAN=/lustre/scratch118/infgen/team162/bb11/MGBC/PANGENOME/HUMAN
MOUSE=/lustre/scratch118/infgen/team162/bb11/MGBC/PANGENOME/MOUSE

## IPS

IPS_DM_PREP() {

	DB=$1

	echo "$DB"

	TMP=$OUTDIR/$DB.TMP
	if [ ! -d $TMP ]; then mkdir $TMP; fi

	echo "HUMAN"
	for i in $HUMAN/*.HUMAN/IPS_OUT
	do
		GENID=$(cut -f1 $i/$DB.tsv | uniq)
		echo "$GENID" > $TMP/$DB.$GENID.txt
		cut -f6 $i/$DB.tsv >> $TMP/$DB.$GENID.txt
	done

	echo "MOUSE"
	for i in $MOUSE/*.MOUSE/IPS_OUT 
        do
                GENID=$(cut -f1 $i/$DB.tsv | uniq)
                echo "$GENID" > $TMP/$DB.$GENID.txt
                cut -f6 $i/$DB.tsv >> $TMP/$DB.$GENID.txt
        done

	INDEX=$(ls $MOUSE/*.MOUSE/IPS_OUT/$DB.tsv | head -n1)
	echo "Feature" > $TMP/$DB.index
	cut -f3 $INDEX >> $TMP/$DB.index

	echo "Compiling temporary files."
	paste $TMP/$DB.index $TMP/$DB.*.txt > $OUTDIR/$DB.ips_presence_absence.tsv

	rm -r $TMP
	echo "Done"
}


IPS_DM_PREP GO
IPS_DM_PREP InterPro
IPS_DM_PREP KEGG
IPS_DM_PREP MetaCyc
IPS_DM_PREP Reactome


## EGGNOG

ENOG_DM_PREP() {

        DB=$1

        echo "$DB"

        TMP=$OUTDIR/$DB.TMP
        if [ ! -d $TMP ]; then mkdir $TMP; fi

        echo "HUMAN"
        for i in $HUMAN/*.HUMAN/EGGNOG_OUT
        do
                GENID=$(cut -f1 $i/$DB.tsv | uniq)
                echo "$GENID" > $TMP/$DB.$GENID.txt
                cut -f6 $i/$DB.tsv >> $TMP/$DB.$GENID.txt
        done

        echo "MOUSE"
        for i in $MOUSE/*.MOUSE/EGGNOG_OUT
        do
                GENID=$(cut -f1 $i/$DB.tsv | uniq)
                echo "$GENID" > $TMP/$DB.$GENID.txt
                cut -f6 $i/$DB.tsv >> $TMP/$DB.$GENID.txt
        done

        INDEX=$(ls $MOUSE/*.MOUSE/EGGNOG_OUT/$DB.tsv | head -n1)
        echo "Feature" > $TMP/$DB.index
        cut -f3 $INDEX >> $TMP/$DB.index

        echo "Compiling temporary files."
        paste $TMP/$DB.index $TMP/$DB.*.txt > $OUTDIR/$DB.eggnog_presence_absence.tsv

        rm -r $TMP
        echo "Done"
}

ENOG_DM_PREP CAZY
ENOG_DM_PREP ENZYME
ENOG_DM_PREP GO
ENOG_DM_PREP KEGG
ENOG_DM_PREP MODULE
ENOG_DM_PREP PATHWAY
ENOG_DM_PREP REACTION

echo "Finished!"
