#!/bin/bash
# This script runs VarDict for somatic mutation calling using tumor-normal BAM files.

# Ensure exactly three arguments are provided
if [ "$#" -ne 3 ]; then
  echo "Usage: $0 <step> <start_row> <stop_row>"
  exit 1
fi

# Parse input arguments
step=$1          # Pipeline step to execute (0 for setup, 1 for processing rows)
start_row=$2     # Start processing from this row in the CSV file
stop_row=$3      # Stop processing at this row

# File paths and configurations
csv="/n/data1/hms/dbmi/gulhan/lab/ankit/scripts/mutation_calling/mutect1/tumor_normal_duplex.csv"               # Input CSV file
out_dir="/n/data1/hms/dbmi/gulhan/lab/ankit/scripts/mutation_calling/vardict_output"    # Output directory
email="asingh46@mgh.harvard.edu"               # Email to receive job notifications

# Reference genome and gnomAD files (ensure that the gnomAD VCF is v4.2)
#ref_genome=/n/data1/hms/dbmi/gulhan/lab/REFERENCE/b37/Homo_sapiens_assembly19/Homo_sapiens_assembly19.fasta             # b37
#gnomad=/n/data1/hms/dbmi/gulhan/lab/software/helper_scripts/mutation_calling_scripts/af-only-gnomad.raw.sites.b37.vcf.gz 
ref_genome=/n/data1/hms/dbmi/gulhan/lab/REFERENCE/hg38/cgap_matches/Homo_sapiens_assembly38.fa                         # hg38                  
gnomad=/n/data1/hms/dbmi/gulhan/lab/software/helper_scripts/mutation_calling_scripts/af-only-gnomad.hg38.vcf.gz


# Path to interval BED files
## b37 ##
#interval_path=/n/data1/hms/dbmi/gulhan/lab/REFERENCE/b37/Homo_sapiens_assembly19/bed               # chromosome interval
#interval_path=/n/data1/hms/dbmi/gulhan/lab/REFERENCE/b37/Homo_sapiens_assembly19/bed/10mil_bp_bed  # 10 million bp interval

## hg38 ##
interval_path=/n/data1/hms/dbmi/gulhan/lab/REFERENCE/hg38/high_confidence_regions/by_chr
# interval_path=/n/data1/hms/dbmi/gulhan/lab/REFERENCE/hg38/high_confidence_regions/10million_bp

# Path to VarDict package
vardict_path=/n/data1/hms/dbmi/gulhan/lab/ankit/scripts/mutation_calling/vardict

# Resource allocation
step1_partitions="short"
step1_time_limit="2:00:00"
step1_mem_alloc="70G"

step2_partitions="short"
step2_time_limit="00:10:00"
step2_mem_alloc="3G"


# Check input file and directory
if [[ ! -f ${csv} ]]; then
    echo "Error: Input CSV file not found at ${csv}"
    exit 1
fi

# Check if all directories exist
if [[ -d ${out_dir} && -d ${out_dir}/step1_out && -d ${out_dir}/step2_out && -d ${out_dir}/step3_out ]]; then
    echo "All directories exist."
else
    echo "One or more directories are missing. Creating them..."
    mkdir -p ${out_dir}/step1_out ${out_dir}/step2_out ${out_dir}/step3_out
    if [[ $? -ne 0 ]]; then
        echo "Error: Failed to create directories. Check permissions."
        exit 1
    fi
    echo "Directories successfully created."
fi



# Steps of the pipeline
case $step in

    ### Step 0: Environment Setup ###
    0)
        echo "Step 0: Environment Setup"
        echo "Load required modules: module load gcc/9.2.0 java/jdk-1.8u112 R/4.2.1"
    ;;

    ### Step 1: Run VarDict ###
    1)
        echo "Step 1: Run VarDict"
        row=1  

        while IFS=, read -r tumor_bam normal_bam sample_id; do
            if [[ ${row} -lt ${start_row} ]]; then
                row=$((row + 1))
                continue
            fi

            if [[ ${row} -gt ${stop_row} ]]; then
                break
            fi

            if [[ "${sample_id}" == "SampleID" ]]; then
                echo "Skipping header row..."
                continue
            fi

            echo "Processing sample ${sample_id}, row ${row}"
            row=$((row + 1))

            # Process each BED file for the current sample
            for bed_file in ${interval_path}/*bed; do
                segment_id=$(basename $bed_file | cut -d'.' -f1)
                output_file=${out_dir}/step1_out/${sample_id}_${segment_id}.txt


                if [[ -f ${output_file} ]]; then
                    echo "${output_file} already exists. Skipping..."
                    continue;
                else
                    # Submit VarDict job to Slurm
                    sbatch -J "vd_step1_${sample_id}_${segment_id}" \
                        -p "${step1_partitions}" \
                        -t "${step1_time_limit}" \
                        --mem="${step1_mem_alloc}" \
                        --mail-type=FAIL \
                        -o "/n/data1/hms/dbmi/gulhan/lab/ankit/slurm_output/vardict_step1_%j.out" -e "/n/data1/hms/dbmi/gulhan/lab/ankit/slurm_output/vardict_step1_%j.err" \
                        --wrap="${vardict_path}/step1_run_vardict.sh \
                                ${normal_bam} \
                                ${tumor_bam} \
                                ${output_file} \
                                ${bed_file} \
                                ${ref_genome}"
                fi
            
            done
        done < $csv
    ;;

    ### Step 2: Statistical Testing for Somatic Events ###
    2)
        echo "Step 2: Statistical Testing for Somatic Events"
        row=1 

        while IFS=, read -r tumor_bam normal_bam sample_id; do

            if [[ ${row} -lt ${start_row} ]]; then
                row=$((row + 1))
                continue
            fi

            if [[ ${row} -gt ${stop_row} ]]; then
                break
            fi

            if [[ "${sample_id}" == "SampleID" ]]; then
                echo "Skipping header row..."
                continue
            fi

            echo "Processing sample ${sample_id}, row ${row}"
            row=$((row + 1))

            # Perform statistical tests for each BED file
            for bed_file in ${interval_path}/*bed; do

                segment_id=$(basename ${bed_file} | cut -d'.' -f1)
                input_file=${out_dir}/step1_out/${sample_id}_${segment_id}.txt
                output_file=${out_dir}/step2_out/${sample_id}_${segment_id}.txt

                if [[ ! -f ${input_file} ]]; then
                    echo "${input_file} does not exist. Skipping..."
                    continue;
                elif [[ -f ${output_file} ]]; then
                    echo "${output_file} already exists. Skipping..."
                    continue;
                else
                    sbatch -J "vd_step2_${sample_id}_${segment_id}" \
                            -p "${step2_partitions}" \
                            -t "${step2_time_limit}" \
                            --mem="${step2_mem_alloc}" \
                            --mail-type=FAIL \
                            -o "/n/data1/hms/dbmi/gulhan/lab/ankit/slurm_output/vardict_step2_%j.out" -e "/n/data1/hms/dbmi/gulhan/lab/ankit/slurm_output/vardict_step2_%j.err" \
                            --wrap="${vardict_path}/step2_vardict_testsomatic.R ${input_file} ${output_file}"
                fi

            done
        done < $csv
    ;;

    ### Step 3: Transform Step 2 Output into VCF ###
    3)
        echo "Step 3: Convert Step 2 Output into VCF Format"

        # Start an interactive job
        #srun --pty -p interactive -t 8:00:00 --mem=20G bash
        row=1

        while IFS=, read -r tumor_bam normal_bam sample_id; do
            if [[ ${row} -lt ${start_row} ]]; then
                row=$((row + 1))
                continue
            fi

            if [[ ${row} -gt ${stop_row} ]]; then
                break
            fi

            if [[ "${sample_id}" == "SampleID" ]]; then
                echo "Skipping header row..."
                continue
            fi

            echo "Processing sample ${sample_id}, row ${row}"
            row=$((row + 1))

            # Convert to VCF format
            for bed_file in ${interval_path}/*bed; do
                segment_id=$(basename ${bed_file} | cut -d'.' -f1)
                input_file=${out_dir}/step2_out/${sample_id}_${segment_id}.txt
                output_file=${out_dir}/step3_out/${sample_id}_${segment_id}.vcf

                if [[ ! -f ${input_file} ]]; then
                    echo "${input_file} does not exist. Skipping..."
                    continue;
                elif [[ -f ${output_file} ]]; then
                    echo "${output_file} already exists. Skipping..."
                    continue;
                else
                    ${vardict_path}/step3_vardict_var2vcf_paired.pl -f 0.00 ${input_file} > ${output_file}
                    echo "${output_filename} created!"
                fi

                echo "Created VCF: ${output_file}"
            done
        done < $csv
    ;;

  *)
    echo "Invalid step: ${step}"
    exit 1
  ;;
esac

