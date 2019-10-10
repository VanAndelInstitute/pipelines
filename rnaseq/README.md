## rnaseq

A basic pipeline for processing of RNASeq data starting from fastqs, using trimmomatic, STAR, and subread's featurecounts.

Usage:

Generate fastqcs

`qsub fastq.pbs -v INDIR=fastq,OUTDIR=fastqc`

Trim adapters with trimmomatic using compilation of Nextera and Illumina (truseq) 
adapters provided in adapaters.fa

`qsub trim.pbs -v INDIR=fastq,OUTDIR=trimmed,ADAPTER=/home/eric.kort/Eric/pipelines/rnaseq/adapters.fa`

Align with star. Presupposes indexed genome in `primary/projects/jovinge/local/share/Transcriptomes/hs/star`.
I should really make that a variable some time.

`qsub align.pbs -v INDIR=fastq,OUTDIR=star`

Merge the counts from all fastqs after alignment, where `indir`.

`./merge.sh indir outfile`

