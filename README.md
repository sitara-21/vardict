# VarDict
Pipeline to run VarDict Mutation Caller
This repo includes different components and respective scripts for those components required to run VarDict mutation caller. The main script ```00_vardict_pipeline.sh``` contains different components for running VarDict on samples from end-to-end. Description of each component can be found below.

## Step1
Run VarDict: This step runs vardict on tumor and normal files mentioned in the reference .csv file (sample csv 'tumor_normal_duplex.csv' attached). Initiates VarDict software by running ```step1_run_vardict.sh```.

## Step2
Statistical Testing for Somatic Events: Performs statistical tests to filter for statistically significant somatic mutation events using ```step2_vardict_testsomatic.R``` R-script.

## Step3
Transform output files from Step2 into VCFs for downstream analysis by running ```step3_vardict_var2vcf_paired.pl```.

## Step4
Filter out any Germline mutations and gzip the VCF files from Step3 by running ```step4_filtering.sh```.
