
usage()
{
cat << EOF
usage: $0 options

Takes a list of genomes and return the cluster membership of genes from these genomes and extracts the sequences of these clusters.

OPTIONS:
   -g      Genome list
   -t      Temporary directory to use
   -o      Output directory
   -d      File with mmseqs output cluster membership [default : bb11/Human_mouse_comparison/FUNCTIONAL_COMPARISON/GENERA_COMPARISON/Protein_Catalogues/DOWNLOAD/uhgp-100.tsv]
   -s      File with mmseqs output cluster representative sequences [default : bb11/Human_mouse_comparison/FUNCTIONAL_COMPARISON/GENERA_COMPARISON/Protein_Catalogues/DOWNLOAD/uhgp-100.faa]
   -r      Remove temporary directory after running [default : FALSE]

EOF
}

GENOMES=
OUTDIR=
TMP=
DATA=
SEQS=
RMTMP=

while getopts “g:t:o:d:s:r” OPTION
do
     case $OPTION in
         g)
             GENOMES=$OPTARG
             ;;
         t)
             TMP=$OPTARG
             ;;
         o)
             OUTDIR=$OPTARG
             ;;
	 d)
	     DATA=$OPTARG
	     ;;
         s)
	     SEQS=$OPTARG
	     ;;
	 r)
	     RMTMP=TRUE
	     ;;
         ?)
             usage
             exit
             ;;
     esac
done




# input is a list of genomes for which to extract the membership for.

timestamp() {
  date +"%H:%M:%S"
}

if [ -z $TMP ] || [ -z $GENOMES ] || [ -z $OUTDIR ]
then
     echo "ERROR : Please supply the appropriate arguments"
     usage
     exit 1
fi


echo "$(timestamp) Setting up!"

# temporary directory
if [ -d $TMP ]
then
     rm -r $TMP
fi

mkdir $TMP

# outdir
if [ ! -d $OUTDIR ]; then mkdir $OUTDIR; fi

# cluster membership data
if [ -z $DATA ]
then
     DATA=/lustre/scratch118/infgen/team162/bb11/External_databases/UHGP/uhgp-100.tsv
#/lustre/scratch118/infgen/team162/bb11/Human_mouse_comparison/FUNCTIONAL_COMPARISON/GENERA_COMPARISON/Protein_Catalogues/DOWNLOAD/uhgp-100.tsv
fi

if [ -z $SEQS ]
then
     SEQS=/lustre/scratch118/infgen/team162/bb11/External_databases/UHGP/uhgp-100.faa
#/lustre/scratch118/infgen/team162/bb11/Human_mouse_comparison/FUNCTIONAL_COMPARISON/GENERA_COMPARISON/Protein_Catalogues/DOWNLOAD/uhgp-100.faa
fi

echo "Temporary directory : $TMP"
echo "Output directory : $OUTDIR"
echo "Input genomes : $GENOMES"
echo "Input data : $DATA"

echo "$(timestamp) Getting cluster membership for genomes."

echo "$(timestamp) making initial cluster file (grep1)."
grep -Ff $GENOMES $DATA > $TMP/cluster_membership_grep1.tsv # get all lines that have anything to do with the genomes of interest.
cut -f2 $TMP/cluster_membership_grep1.tsv > $TMP/cluster_mem.tmp.txt # get the membership genes

echo "$(timestamp) Finding genes of interest."
grep -Ff $GENOMES $TMP/cluster_mem.tmp.txt > $TMP/genes_of_interest.txt # get genes of interest

echo "$(timestamp) Finding clusters with genes of interest as representatives."
awk ' $1 == $2 ' $TMP/cluster_membership_grep1.tsv > $TMP/cluster_reps.tsv
cut -f2 $TMP/cluster_reps.tsv > $TMP/cluster_reps.txt # get cases where gene of interest is the cluster representative

echo "$(timestamp) Finding clusters with genes of interest as members."
awk ' $1 != $2 ' $TMP/cluster_membership_grep1.tsv > $TMP/cluster_non_reps.tsv # get all cases where the gene member is not the representative

echo "$(timestamp) Separating genes of interest into cluster reps and non-cluster reps."
grep -Fwvf $TMP/cluster_reps.txt $TMP/genes_of_interest.txt > $TMP/non_rep_genes_of_interest.txt # get the genes of interest which are not the cluster representatives

echo "$(timestamp) Getting non-cluster rep membership."
grep -Fwf $TMP/non_rep_genes_of_interest.txt $TMP/cluster_non_reps.tsv > $TMP/cluster_membership_grep2.tsv

echo "$(timestamp) Generating cluster membership output."
cat $TMP/cluster_reps.tsv $TMP/cluster_membership_grep2.tsv > $OUTDIR/get_cluster_membership.out.tsv


# get unique clusters

echo "$(timestamp) Getting sequences for genomes."
cut -f1 $OUTDIR/get_cluster_membership.out.tsv | sort | uniq > $OUTDIR/faa_to_extract.txt


if [ -z $RMTMP ]
then
     echo "Keeping temporary directory..."
else
     echo "Removing temporary directory..."
     rm -r $TMP
fi


echo "$(timestamp) Running GET_FASTA_FROM_CONTIGS_v4.py"
GET_FASTA_FROM_CONTIGS_v4.py -i $SEQS -g $OUTDIR/faa_to_extract.txt -o $OUTDIR

echo "$(timestamp) Done!"
