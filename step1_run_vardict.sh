#!/bin/bash

tumor=$1
normal=$2
out=$3
bed=$4
ref_genome=$5

echo ${out}

/n/data1/hms/dbmi/gulhan/lab/software/helper_scripts/mutation_calling_scripts/vardict/VarDict/VarDictJava/build/install/VarDict/bin/VarDict -G $ref_genome \
 -f 0.00 \
 -b "$tumor|$normal" \
 -c 1 \
 -S 2 \
 -E 3 \
 -g 4 \
 --nosv $bed > $out 
