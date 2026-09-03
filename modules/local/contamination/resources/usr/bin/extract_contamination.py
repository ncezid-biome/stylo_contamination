#!/usr/bin/env python3

import json
import argparse
import pathlib
import copy

parser = argparse.ArgumentParser()
parser.add_argument('-s','--sample', type=str, required=True, help="sample id")
parser.add_argument('-k','--kraken', type=pathlib.Path, required=True, help="kraken report")
parser.add_argument('-o','--output', required=True, help="output file")
parser.add_argument('-t','--table', type=pathlib.Path, required=True, help="cutoff table in the format: genus1\tgenus2\tcutoff, if genus2 is detected and genus1 is present, check if genus2 goes above the threshold")
parser.add_argument('-ct','--contamination-threshold', type=float, required=True, help="contamination threshold")
args = parser.parse_args()


sample = args.sample
contaminated = False
index_hopping = False
unsupported_genus = False
no_data = False
genera = []
cutoff_dict = {}
root = 0

# read in cutoff table
with open(args.table) as cutoffs:
    for line in cutoffs.readlines()[1:]:
        line = line[:-1].split('\t')
        cutoff_dict[(line[0],line[1])] = float(line[2])

# read in kraken file
with open(args.kraken, 'r') as kraken:
    for line in kraken:
        # line format: percent coverage, num read clade, num reads taxon, rank, NCBI ID, scientific name
        # https://github.com/DerrickWood/kraken2/blob/master/docs/MANUAL.markdown#sample-report-output-format
        line = line[:-1].split('\t')
        if line[3] == 'R':
            root = float(line[0].strip(' ')) / 100
        elif line[3] == 'G':
            cov = float(line[0].strip(' '))
            adjusted_cov = cov / root
            genus = line[5].strip(' ')
            genera.append([genus,cov,adjusted_cov,''])

# sort by cov
genera = sorted(genera, key=lambda x: x[1], reverse=True)

# assign levels
if genera == []:
    no_data = True
else:
    primary = genera[0][0]
    genera[0][3] = 'PRIMARY'
    for i in genera[1:]:
        if i[2] > args.contamination_threshold:
            i[3] = 'CONTAM'
            contaminated = True
        elif (primary,i[0]) in cutoff_dict.keys():
            if i[2] > cutoff_dict[(primary,i[0])]:
                i[3] = 'INDEX'
                index_hopping = True
            else:
                i[3] = 'TYPICAL'
        elif (primary,'-') in cutoff_dict.keys():
            if i[2] > cutoff_dict[(primary,'-')]:
                i[3] = 'INDEX'
                index_hopping = True
            else:
                i[3] = 'TYPICAL'
        else: # primary genus is not in cutoff table, unsupported organism
            i[3] = 'UNKNOWN'
            unsupported_genus = True

# write output
with open(args.output, 'w') as results:
    if no_data:
        print('NO DATA') # for nextflow stdout filters
        results.write("# ERROR: not enough data\n")
    else:
        if contaminated:
            print('CONTAM') # for nextflow stdout filters
            results.write("# ERROR: 2 or more genera are above the contamination threshold\n")
        if index_hopping:
            print('INDEX')
            print('_' + primary + '_')
            results.write("# WARNING: potential index hopping or low level contamination detected\n")
        if unsupported_genus:
            print('UNSUPPORTED')
            print('_' + primary + '_')
            results.write("# WARNING: PRIMARY genus is unsupported, check kraken report for abnormal identifications\n")
        if not contaminated and not index_hopping and not unsupported_genus:
            print('PASS')
            print('_' + primary + '_')
    results.write("# KEY: PRIMARY=most abundant genus, CONTAM=contaminant genus, INDEX=potential index hopping genus, TYPICAL=typical misidentification of primary genus\n")
    results.write("# sample\tgenus\tcoverage\tadjusted_cov\tlevel\n")
    for i in genera:
        results.write('\t'.join([sample]+[str(j) for j in i]) + '\n')
