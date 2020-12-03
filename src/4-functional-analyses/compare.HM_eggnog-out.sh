
OUT=$1
HUMANPG=$2
MOUSEPG=$3

if [ ! -d $OUT ]
then
     mkdir $OUT
fi

DATA=/lustre/scratch118/infgen/team162/bb11/Human_mouse_comparison/FUNCTIONAL_COMPARISON/REPRESENTATIVE_eggNOG/KEGG_DB

summarise_HM()
{

     DB=$1

     # Human
     cut -f2 $HUMANPG/*.HUMAN/eggnog-out/pangenome-eggnog/pangenome-eggnog.$DB.out.tsv | sort | uniq -c | sed 's/^ *//g' | sed 's/ /\t/g' > $OUT/$DB.human.tmp
     # Mouse
     cut -f2 $MOUSEPG/*.MOUSE/eggnog-out/pangenome-eggnog/pangenome-eggnog.$DB.out.tsv | sort | uniq -c | sed 's/^ *//g' | sed 's/ /\t/g' > $OUT/$DB.mouse.tmp

     cut -f2 $OUT/$DB.human.tmp | grep -Fwf - $OUT/$DB.mouse.tmp | cut -f2 > $OUT/$DB.shared.tmp

     for i in $(cat $OUT/$DB.shared.tmp)
     do
	  MCOUNT=$(grep -Fw "$i" $OUT/$DB.mouse.tmp | cut -f1)
	  HCOUNT=$(grep -Fw "$i" $OUT/$DB.human.tmp | cut -f1)
	  DESCR=$(grep -Fw "$i" $DATA/$DB | cut -f2)
	  printf "$i\t$HCOUNT\t$MCOUNT\t$DESCR\n"
     done > $OUT/$DB.shared.tsv

     grep -Fwvf $OUT/$DB.shared.tmp $OUT/$DB.human.tmp | while read LINE
     do
	  DESCR=$(echo $LINE | cut -d " " -f2 | grep -Fwf - $DATA/$DB | cut -f2)
	  printf "$LINE\t$DESCR\n"
     done > $OUT/$DB.human.tsv

     grep -Fwvf $OUT/$DB.shared.tmp $OUT/$DB.mouse.tmp | while read LINE
     do
	  DESCR=$(echo $LINE | cut -d " " -f2 | grep -Fwf - $DATA/$DB | cut -f2)
	  printf "$LINE\t$DESCR\n"
     done > $OUT/$DB.mouse.tsv


     echo "$DB done!"

}

summarise_HM KO
summarise_HM PATHWAY
summarise_HM MODULE
summarise_HM CAZY
summarise_HM COG
summarise_HM ENZYME
summarise_HM REACTION


echo "Workflow done!"
