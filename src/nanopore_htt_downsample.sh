#!/bin/bash

# The following line causes bash to exit at any point if there is any error
# and to output each line as it is executed -- useful for debugging
set -e -x -o pipefail

main() {

	# Download input files from inputSpec to ~/in/. Allows the use of DNA Nexus bash helper variables.
	dx-download-all-inputs

	# Calculate 90% of memory size for java
	mem_in_mb=`head -n1 /proc/meminfo | awk '{print int($2*0.9/1024)}'`
	# Set java command with the calculated maximum memory usage
	java="java -Xmx${mem_in_mb}m"

	# Create output directories for downsampled BAM file and index
	mkdir -p $HOME/out/downsampledbam/bam
	mkdir -p $HOME/out/downsampledbai/bam

	# Get average coverage of HTT repeat region +-500bp from field 10 of the first line of sambamba file
	# This will be a floating point number
	# grep for line containing the HTT repeat region +-500bp
	original_cov=$(grep 'chr4'$'\t''3076103'$'\t''3077166' ${sambambaoutput_path} | cut -f10)

	# Calculate downsample factor by dividing desired coverage by original coverage
	# Standard bash arithemtic can't handle floating points, so redirect into bc calculator program.
	# -l argument tells bc to use the standard math library
	downsample_factor=$(bc -l <<< "${downsampleto} / $original_cov")

	# If downsample factor is greater than 1.0 (because BAM is already lower than requested downsample to coverage),
	# set the downsample factor to 1.0 so that picard will still process BAM but all reads will be kept (the low coverage should
	# be picked up from coverage report at QC)
	# pipe downsample factor into awk script that checks if it is greater than 1.0
	# If it is greater than 0, awk exits with an exit status of 0 which means if block executes and downsample
	# factor is set to 1.0 (if it is <= 1 awk script exits with status of 1 (i.e. non-zero) so if block doesn't exectute)  
	if echo $downsample_factor | awk '{exit !( $1 > 1.0)}'; then
    	downsample_factor=1.0
	fi

	# Call Picard DownsampleSam on BAM. P= the probability of retaining a read (should be set to downsample factor)
	# By default always uses the same random seed of 1 meaning it is deterministic 
	# (i.e. will always produce same BAM if run with same inputs)
	$java -jar /picard.jar DownsampleSam I="$bam_path" \
	O="$HOME/out/downsampledbam/bam/${bam_prefix}.downsampled_${downsampleto}x.bam" \
	P=${downsample_factor} CREATE_INDEX=true

	# Move index file to output folder and rename to .bam.bai (samtools format) instead of .bai (picard format)
	# (Both create index using same algorithm as described in SAM http://samtools.sourceforge.net/SAMv1.pdf spec, 
	# they just use different extension)
	mv $HOME/out/downsampledbam/bam/${bam_prefix}.downsampled_${downsampleto}x.bai \
	$HOME/out/downsampledbai/bam/${bam_prefix}.downsampled_${downsampleto}x.bam.bai

	# Upload all outputs
	dx-upload-all-outputs --parallel
}
