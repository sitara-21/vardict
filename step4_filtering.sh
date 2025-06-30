#!/bin/bash
# Usage check

module load gcc bcftools

if [ "$#" -ne 2 ]; then
     echo "Usage: $0 <step3_dir> <out_dir>"
    exit 1
fi

step3_dir=$1
out_dir=$2


mkdir -p ${out_dir}
# filter vardict calls
for file in ${step3_dir}/*.vcf; do
    id=$(basename $file | cut -d'.' -f1)
    if [ ! -f ${out_dir}/${id}.vcf ]; then
        bcftools view -i 'INFO/STATUS!="Germline" && INFO/SSF!=1 && REF!="N"' $file -Oz -o ${out_dir}/${id}.vcf.gz
    else
        echo ${out_dir}/${id}.vcf.final.vcf exists.
    fi
done

