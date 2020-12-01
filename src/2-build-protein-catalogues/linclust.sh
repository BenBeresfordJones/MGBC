#!/bin/bash

timestamp() {
  date +"%H:%M:%S"
}

echo "$(timestamp) INFO : Running $0"


id=$1
cov=0.8
tmpdir=$2
out=$3
threads=$4

echo "$(timestamp) Clustering MMseqs with linclust with option -c ${id}"
echo "command: mmseqs linclust ${tmpdir}/mmseqs.db ${tmpdir}/mmseqs_cluster.db ${out}/mmseqs-tmp --min-seq-id ${id} --threads ${threads} -c ${cov} --cov-mode 1 --cluster-mode 2 --kmer-per-seq 80"
mmseqs linclust ${tmpdir}/mmseqs.db ${out}/mmseqs_cluster.db ${out}/mmseqs-tmp --min-seq-id ${id} --threads ${threads} -c ${cov} --cov-mode 1 --cluster-mode 2 --kmer-per-seq 80

echo "$(timestamp) [mmseqs script] Parsing output to create FASTA file of all sequences"
echo "command: mmseqs createseqfiledb ${tmpdir}/mmseqs.db ${out}/mmseqs_cluster.db ${out}/mmseqs_cluster_seq --threads ${threads}"
mmseqs createseqfiledb ${tmpdir}/mmseqs.db ${out}/mmseqs_cluster.db ${out}/mmseqs_cluster_seq --threads ${threads}
echo "command: mmseqs result2flat ${tmpdir}/mmseqs.db ${tmpdir}/mmseqs.db ${out}/mmseqs_cluster_seq ${out}/mmseqs_cluster.fa"
mmseqs result2flat ${tmpdir}/mmseqs.db ${tmpdir}/mmseqs.db ${out}/mmseqs_cluster_seq ${out}/mmseqs_cluster.fa

echo "$(timestamp) [mmseqs script] Parsing output to create TSV file with cluster membership"
echo "command: mmseqs createtsv ${tmpdir}/mmseqs.db ${tmpdir}/mmseqs.db ${out}/mmseqs_cluster.db ${out}/mmseqs_cluster.tsv --threads ${threads}"
mmseqs createtsv ${tmpdir}/mmseqs.db ${tmpdir}/mmseqs.db ${out}/mmseqs_cluster.db ${out}/mmseqs_cluster.tsv --threads ${threads}

echo "$(timestamp) [mmseqs script] Parsing output to create FASTA file of representative sequences"
echo "mmseqs result2repseq ${tmpdir}/mmseqs.db ${out}/mmseqs_cluster.db ${out}/mmseqs_cluster_rep --threads ${threads}"
mmseqs result2repseq ${tmpdir}/mmseqs.db ${out}/mmseqs_cluster.db ${out}/mmseqs_cluster_rep --threads ${threads}
echo "mmseqs result2flat ${tmpdir}/mmseqs.db ${tmpdir}/mmseqs.db ${out}/mmseqs_cluster_rep ${out}/mmseqs_cluster_rep.fa --use-fasta-header"
mmseqs result2flat ${tmpdir}/mmseqs.db ${tmpdir}/mmseqs.db ${out}/mmseqs_cluster_rep ${out}/mmseqs_cluster_rep.fa --use-fasta-header

echo "Done!"
