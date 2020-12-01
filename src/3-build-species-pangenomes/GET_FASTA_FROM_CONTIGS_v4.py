#!/usr/bin/python

# load environments

from Bio import SeqIO
from optparse import OptionParser
import sys
import os

def test_file(option, opt_str, value, parser):
    try:
        with open(value): setattr(parser.values, option.dest, value)
    except IOError:
        print('%s file cannot be opened' % option)
        sys.exit()

# define function to extract fasta sequences for contig ids of interest

# improve interactivity

def main(in_fasta, in_genes, out_dir):
	record_dict = SeqIO.index(in_fasta, "fasta")
	# get sequences
	ids = in_genes
	out_fasta = os.path.join(out_dir, "extracted_seqs.faa")
	data = open(ids, "rU").read().splitlines()
	output_handle = open(out_fasta, "w")
	seqrecords=[ ]
	for contig in data:
		seqrecords.append(record_dict[contig])
	SeqIO.write(seqrecords, output_handle, "fasta")
	output_handle.close()
	record_dict.close()


if __name__ == "__main__":
    usage="usage: %prog [options]"
    parser = OptionParser(usage=usage)
    parser.add_option("-i", "--input_fasta", dest="in_fasta",
                    help="/path/to/input fasta [REQUIRED]",
                    action="callback", callback=test_file, type="string")
    parser.add_option("-g", "--in_genes", dest="in_genes",
                    help="/path/to/in genes [REQUIRED]",
                    action="callback", callback=test_file, type="string")
    parser.add_option("-o", "--output_dir", dest="out_dir",
                    help="/path/to/output directory [REQUIRED]",
                    action="store", type="string")

    options, args = parser.parse_args()

    mandatories = ["in_fasta", "in_genes", "out_dir"]
    for m in mandatories:
        if not options.__dict__[m]:
            print("\nMust provide %s.\n" %m)
            parser.print_help()
            exit(-1)

    main(options.in_fasta, options.in_genes, options.out_dir)
