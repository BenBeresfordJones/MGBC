#!/usr/bin/env bash

# ensure that checkm moduleis loaded before use.
# designed to run with 5GB, and the number of threads defined by the input. 

THREADS=$1

# run qa module
checkm qa ./lineage.ms . -o 2 -f qa_out --tab_table -t $THREADS

# run the qa_out script
sh /nfs/users/nfs_b/bb11/Scripts/checkm_qa_out_v2.sh

