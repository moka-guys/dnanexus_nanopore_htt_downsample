# dnanexus_nanopore_htt_downsample v1.0

## What does this app do?
repeatHMM is a tool used for counting triplet repeats in Oxford Nanopore data. It's performance is affected by BAM read depth. This app takes a BAM with Oxford Nanopore long reads aligned to HTT gene and downsamples to the required read depth for processing through repeatHMM.

## What are typical use cases for this app?
This app is used as part of the Oxford Nanopore HTT repeat counting workflow.

## What data are required for this app to run?
The app requires 3 inputs:
1. Sorted BAM file containing Oxford Nanopore reads aligned to hg19 reference sequence. The BAM file must have previously been run through the DNAnexus Sambamba_Chanjo app using the bed file `Pan_XXXX` (HTT repeat region +-500bp). 
2. The `*.sambamba_ouput.bed` output file (see 1.)
3. The read depth to downsample to (default 4000x).

## What does this app output?
The app outputs 2 files:
1. sorted downsampled BAM file
2. BAM index file

## How does this app work?
The app uses the `*.sambamba_ouput.bed` file to find the average coverage of the BAM across the HTT repeat region +-500bp. It calculates the proportion of reads to keep to achieve the desired read depth. It then uses Picard DownsampleSam to downsample the input BAM to the desired coverage. If the input BAM is already less than the desired coverage, the BAM is still processed through Picard DownsampleSam but with the argument P=1.0 so that all reads are kept. (Low coverage samples should be identified at a later stage when coverage is checked as part of QC) 

## What are the limitations of this app
This app should only be used for Oxford Nanopore data as part of the HTT repeat counting workflow.

## This app was made by Viapath Genome Informatics 