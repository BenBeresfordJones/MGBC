#!/bin/bash

if [ ! -d tmp ]; then mkdir tmp; fi
cp mmseqs_cluster.tsv tmp

cd tmp

# total number of clusters - do not need to sort
TOTAL=$(cut -f1 mmseqs_cluster.tsv | uniq | wc -l)


grep -F "GUT_GENOME" mmseqs_cluster.tsv > with_GUT_GENOME
grep -vF "GUT_GENOME" mmseqs_cluster.tsv > without_GUT_GENOME
cut -f1 with_GUT_GENOME | grep -vF "GUT_GENOME" > MH
cut -f2 with_GUT_GENOME | grep -vF "GUT_GENOME" > HM
cat MH HM | uniq | sort | uniq > SHARED
cut -f1 with_GUT_GENOME | uniq > with_clusters
cut -f1 without_GUT_GENOME | uniq > without_clusters

grep -Ff SHARED with_GUT_GENOME | cut -f1 | uniq | sort | uniq > SHARED_CLUSTERS

grep -vFf SHARED_CLUSTERS with_clusters > HUMAN_ONLY_CLUSTERS
grep -vFf SHARED_CLUSTERS without_clusters > MOUSE_ONLY_CLUSTERS

MOUSE=$(wc -l MOUSE_ONLY_CLUSTERS | cut -d " " -f1)
HUMAN=$(wc -l HUMAN_ONLY_CLUSTERS | cut -d " " -f1)
SHARED=$(wc -l SHARED_CLUSTERS | cut -d " " -f1)

echo "Mouse-specific: $MOUSE" > cluster_stats.out
echo "Human-specific: $HUMAN" >> cluster_stats.out
echo "Shared: $SHARED" >> cluster_stats.out
echo "Total cluster count: $TOTAL" >> cluster_stats.out

PERC_SHARED=$(expr $SHARED / $TOTAL \* 100)
echo "Percentage of clusters shared: $PERC_SHARED" >> cluster_stats.out
