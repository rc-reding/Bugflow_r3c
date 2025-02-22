#!/usr/bin/env nextflow

/* 
DSL2 version of Bugflow: A pipeline for mapping followed by variant calling and de novo assembly of Illumina short read libraries

QC
 - Fastp v0.23.2
 - FastQC v0.11.9
 - MultiQC v1.12
 - Quast v5.0.2

Mapping and Variant calling
 - BWA mem and bcftools
 - Snippy v4.6
 
Assembly
 - Shovill v1.1.0 (spades and pilon)

AMRG Annotation
 - Abricate v0.8
 - AMRFinderPlus v3.11.2
 - BLASTN vs C. difficile curated AMR database (also contains C. diff toxin genes)
*/

/*
#==============================================
Enable DSL2
#==============================================
*/

nextflow.enable.dsl = 2

/*
#==============================================
Modules
#==============================================
*/

include { RAWFASTQC; RAWFASTQC_SINGLE; FASTP; FASTP_SINGLE; CLEANFASTQC; CLEANFASTQC_SINGLE; MULTIQC_READS; MULTIQC_CONTIGS } from './modules/processes-bugflow_dsl2.nf'
include { ASSEMBLY } from './modules/processes-bugflow_dsl2.nf'
include { QUAST_FROM_READS; QUAST_FROM_CONTIGS } from './modules/processes-bugflow_dsl2.nf'
include { AMR_PLM_FROM_READS; AMR_PLM_FROM_CONTIGS; PLATON_READS; PLATON_CONTIGS; MOBTYPER; CDIFF_AMRG_BLASTN_READS; SUMMARY_BLASTN; AMR_ABRFORMAT; AMRFINDERPLUS_CDIFF} from './modules/processes-bugflow_dsl2.nf'
include { MLST_FROM_READS; MLST_FROM_CONTIGS; MLST_CDIFF_FROM_READS; HCGMLST_READS_DE; HCGMLST_CONTIGS_DE } from './modules/processes-bugflow_dsl2.nf'
include { INDEXREFERENCE; REFMASK;  BWA; REMOVE_DUPLICATES; MPILEUP; SNP_CALL; FILTER_SNPS; CONSENSUS_FA} from './modules/processes-bugflow_dsl2.nf'
include { SNIPPYFASTQ; SNIPPYCORE } from './modules/processes-bugflow_dsl2.nf'
include { FIND_MIXED_SITES } from './modules/processes-bugflow_dsl2.nf'
include { KRAKEN2 } from './modules/processes-bugflow_dsl2.nf'
include { COUNT_BASES_CALLED } from './modules/processes-bugflow_dsl2.nf'
include { GENOME_DEPTH } from './modules/processes-bugflow_dsl2.nf'
include { DETAILED_CONSENSUS_FA } from './modules/processes-bugflow_dsl2.nf'
/*
#==============================================
Parameters
#==============================================
*/

params.ref = " "
params.mlst_loci = " "
params.reads = " "
params.outdir = " "
params.contigs = " "
params.mlstdb = "cdifficile"
params.prefix = "core"
params.blastn = " "
params.kraken2_db="/users/bag/bmb039/my_space/databases/kraken/standard_8GB"


/*
#==============================================
Workflows
#==============================================
*/

workflow cdiff_mapping {
    Channel.fromFilePairs(params.reads, checkIfExists: true)
        .map{it}
        .set{reads}
    Channel.fromPath(params.ref, checkIfExists:true)
        .first()
        .set{refFasta}
    main:
    INDEXREFERENCE(refFasta)     
    REFMASK(refFasta)
    FASTP(reads)
    BWA(FASTP.out.reads.combine(refFasta), INDEXREFERENCE.out)
    REMOVE_DUPLICATES(BWA.out)
    MPILEUP(REMOVE_DUPLICATES.out.dup_removed.combine(refFasta))
    SNP_CALL(MPILEUP.out.pileup.combine(refFasta))
    FILTER_SNPS(SNP_CALL.out.snps_called, refFasta, REFMASK.out.masked_ref)
    CONSENSUS_FA(FILTER_SNPS.out.filtered_snps, refFasta)
    FIND_MIXED_SITES(REMOVE_DUPLICATES.out.dup_removed,
        refFasta,
        params.mlst_loci)
    GENOME_DEPTH(REMOVE_DUPLICATES.out.dup_removed)

    for_detailed_ch = CONSENSUS_FA.out
        .join(FILTER_SNPS.out.filtered_snps)
        .join(SNP_CALL.out.allsites)
    DETAILED_CONSENSUS_FA(for_detailed_ch, REFMASK.out.masked_ref)
    COUNT_BASES_CALLED(DETAILED_CONSENSUS_FA.out.simple)
}


workflow cdiff_cgmlst {
    Channel.fromFilePairs(params.reads, checkIfExists: true)
        .map{it}
        .set{reads}
    
    main:
    RAWFASTQC_SINGLE(reads)
    FASTP(reads) // TODO: FASTP_SINGLE produces all the outputs that FASTP gives??
    FASTP_SINGLE(reads)
    CLEANFASTQC_SINGLE(FASTP_SINGLE.out.cat_fastq)
    //MULTIQC_READS(RAWFASTQC.out.mix(CLEANFASTQC.out).collect())
    //MULTIQC_READS(CLEANFASTQC.out.collect())
    MULTIQC_READS(CLEANFASTQC_SINGLE.out.collect())
    ASSEMBLY(FASTP.out.reads)
    QUAST_FROM_READS(ASSEMBLY.out.assembly)
    MULTIQC_CONTIGS(QUAST_FROM_READS.out.quast_dir.collect())
    MLST_CDIFF_FROM_READS(ASSEMBLY.out.assembly)
    HCGMLST_CONTIGS_DE(ASSEMBLY.out.assembly)
    CDIFF_AMRG_BLASTN_READS(ASSEMBLY.out.assembly, params.cdiff_amr_fasta)
    AMRFINDERPLUS_CDIFF(ASSEMBLY.out.assembly)
    //AMR_ABRFORMAT(ASSEMBLY.out.assembly)
    KRAKEN2(FASTP.out.reads, params.kraken2_db)
}
