#!/usr/bin/env nextflow

/* test pipeline structure */

/* see example here - https://github.com/cbcrg/grape-nf/blob/master/grape.nf#L191 */

/*** TO DO
 - allow multiple input files to be read
 - add bbduk for adapter trimming (+/- quality trimming)
 - add kmergenie for velvet kmer finder
 - add commands to run vanilla velvet (with kmer size), spades, unicycler+spades
 - generate guids, log of these, and output file structure
 ***/

/* parameters */
params.index = "example_data/file_list.csv"
params.outputPath = "example_output"

/* initial logging */
log.info "Pipeline Test -- version 0.1"
log.info "Input file              : ${params.index}"
log.info "Output path             : ${params.outputPath}"

/* input validation */
outputPath = file(params.outputPath)

Channel
    .fromPath(params.index)
    .splitCsv(header:true)
    .map{ row-> tuple(row.sampleid, row.uuid, file(row.fq1), file(row.fq2)) }
    .set { samples_ch }


/* fastQC */

process fastQC {

	publishDir outputPath, mode: 'copy'
	
	input:
    	set sampleid, uuid, file(fq1), file(fq2) from samples_ch
	
	output:
		file "log.txt" 
		file "*fastqc.*"
	
	//tag each process with the guid
	tag "$uuid"
	
	"""
	cat $fq1 $fq2 > ${uuid}_merge.fq.gz
	fastqc ${uuid}_merge.fq.gz > log.txt
	rm ${uuid}_merge.fq.gz
	"""

	
}

/*
process kmerGenie { 
	

	'''
	source activate py27
	kmergenie
	source deactivate
	'''

}

*/

