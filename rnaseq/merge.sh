#!/bin/bash

# USAGE ./merge.sh indir outfile
# Will scan all subdirectories of indir directory and merge column 1 
# of all ReadsPerGene.out.tab files into single tab delimited file.

INDIR=$1
OUTFILE=$2

FIRST=$(find ${INDIR} -name ReadsPerGene.out.tab | head -n1)
DIFFS=$(find ${INDIR} -name ReadsPerGene.out.tab | xargs -n1 -I {} bash -c "cmp <(cut -f1 {}) <(cut -f1 ${FIRST})" 2>/dev/null | head )
DIFFC=${#DIFFS} 

if [ $DIFFC -gt 0 ]
then
  echo "ERROR: Gene ids appear to be different between output files."
  exit 1
fi

cut -f1-2 $FIRST > $OUTFILE
find ${INDIR} -name ReadsPerGene.out.tab | tail -n +2 | xargs -n1 -I {} bash -c "cut -f2 {} | paste ${OUTFILE} /dev/stdin > tmp; mv tmp ${OUTFILE};"
FILELIST=$(dirname $OUTFILE)/column_ids.txt
echo "ENSEMBL_ID" > ${FILELIST}
find ${INDIR} -name ReadsPerGene.out.tab >> ${FILELIST}
