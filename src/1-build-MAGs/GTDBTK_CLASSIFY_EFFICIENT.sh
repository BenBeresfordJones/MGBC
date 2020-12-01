#!/bin/bash

BATCHFILE=$1
THREADS=$2
EXTEN=$3

IDENT=identify
ALIGN=align
CLASS=classify

mkdir $IDENT $ALIGN $CLASS


gtdbtk identify --batchfile $BATCHFILE --out_dir $IDENT -x $EXTEN --cpus $THREADS
gdtbtk align --identify_dir $IDENT --out_dir $ALIGN --cpus $THREADS

rm -r $IDENT/intermediate_results

gtdbtk classify --batchfile $BATCHFILE --align_dir $ALIGN --out_dir $CLASS --cpus $THREADS -x $EXTEN


echo "Done!"
