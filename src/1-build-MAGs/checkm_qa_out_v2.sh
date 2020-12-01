cut -f 1,6,7,9,12,14,16,19 qa_out > qa_out_CUT 
# Cut -f 6,7,9,12 = Completeness, Contamination, Genome size (bp), # contigs
# -f 14, 16, 19 = N50 (contigs), Mean contig length (bp), GC
head -n 1 qa_out_CUT > PASSED_QC.txt
awk ' $2 >= 90 && $3 <= 5 && $4 <= 8000000 && $5 <= 500 && $6 >= 10000 && $7 >= 5000' qa_out_CUT >> PASSED_QC.txt
cut -f1 PASSED_QC.txt | tail -n +2 > Validated_genomes.txt
awk ' $2 < 90; $3 > 5; $4 > 8000000; $5 > 500; $6 < 10000; $7 < 5000 ' qa_out_CUT | uniq > FAILED_QC.txt
# rm qa_out_CUT
