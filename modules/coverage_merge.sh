#!/bin/sh
. /etc/profile.d/modules.sh;
module load python/2.7.5 glu

MANIFEST=$1
CASE_FILE=$2
OUTDIR=$3

NF=$(awk -F"," 'NR==1{print NF}' $MANIFEST)

if [[ $NF == 15 ]]; then
  #a[$2]+=$1 - accumulating values for each group("group" is considered as unique value of the 2nd field, used as array a index)
  awk -F "," 'NR>1{ a[$7"_"$13]+=$11*$15 }END{ for(i in a) print i"\t"a[i] | "sort -n"}' $MANIFEST > ${OUTDIR}/coverage_added_downsample.txt
  awk -F "," 'NR>1{ a[$7"_"$13]+=$11 }END{ for(i in a) print i"\t"a[i] | "sort -n"}' $MANIFEST > ${OUTDIR}/coverage_added.txt
  #compare if the final coverage is same before and after multiply downsample ratio
  awk -F"\t" 'BEGIN {print "ANALYSISID\tADDED_COV\tDOWNSAMPLE"} NR==FNR { if (n[$2] = $2);next} {print $0"\t",n[$2]?"NO":"YES"}' ${OUTDIR}/coverage_added.txt ${OUTDIR}/coverage_added_downsample.txt > ${OUTDIR}/Sum_Coverage.txt
else
  awk -F "," 'BEGIN{print "ANALYSISID\tADDED_COV\tDOWNSAMPLE"} NR>1{ a[$7"_"$13]+=$11 }END{ for(i in a) print i"\t"a[i]"\tNO" | "sort -n"}' $MANIFEST > ${OUTDIR}/Sum_Coverage.txt
fi

glu util.join -1 ANALYSISID -2 ANALYSISID -j inner ${OUTDIR}/Sum_Coverage.txt ${CASE_FILE} -o ${OUTDIR}/Final_merged_coverage.txt:c=ANALYSISID,STATUS,COV,ADDED_COV,DOWNSAMPLE 
awk -F"\t" '{print $1"\t"$3}' ${OUTDIR}/Sum_Coverage.txt > ${OUTDIR}/../Downsample.txt
