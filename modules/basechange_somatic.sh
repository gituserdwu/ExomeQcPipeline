#!/bin/sh

OUT_TXT=$1
shift
VAF_TXT=$1
shift
VCF_LIST=$*
array[0]="A"
array[1]="T"
array[2]="C"
array[3]="G"
#VCF_DIR=$(dirname $OUT_TXT)
#cd $VCF_DIR
FIRST=true
# for f in *WES_passed.vcf.gz; do
HEADER="FileName"
module load vcftools zlib
touch $VAF_TXT
#for f in *germline_sSNV_4callers.vcf; do
for f in $VCF_LIST; do
#for f in *germline_sSNV_4callers.vcf; do
# for f in raw_variants_merged.vcf; do
#  OUTPUT=`basename $f _passed.vcf.gz_l_out
  echo $f
#  OUTPUT=`basename $f _bqsr_final_out_passed.vcf`
#  OUTPUT=`basename $f _intersect.recode.vcf`
  OUTPUT=`basename $f _passed.vcf`
#  CMD="vcftools --vcf $f --out ${VCF_DIR}/${OUTPUT}_in_intersection --bed $BED_FILE --recode --keep-INFO-all"
#  echo $CMD
#  eval $CMD
  if [[ $? -ne 0 ]]; then
     echo "Error: vcftools is failed"
     exit 1
  fi
#  f=${VCF_DIR}/${OUTPUT}_in_intersection.recode.vcf

########################
# Write VAF RD txt file
cat $f | \
awk '

BEGIN{
	FS="\t"
	OFS="\t"
}

{
if ( $1 !~ "#" && $7 ~ ";PASS" ) { 
	REF=$4
	ALT=$5	
	INFO=$8
	split(INFO, INFO_TOKENS, ";")
	SAMPLE=$10
	split(SAMPLE, SAMPLE_TOKENS, ":")
	
	TOKEN_COUNT=length(INFO_TOKENS)

	for (IDX = 1; IDX <= TOKEN_COUNT; IDX++)	{
		if (INFO_TOKENS[IDX] ~ /^Tumor_AF/ ) {
			AF = INFO_TOKENS[IDX]

			gsub(/Tumor_AF=/, "", INFO_TOKENS[IDX])
			VAF = INFO_TOKENS[IDX]
		}
		if (INFO_TOKENS[IDX] ~ "^Tumor_DP*") {
			
			DP = INFO_TOKENS[IDX]
			gsub(/Tumor_DP=/, "", INFO_TOKENS[IDX])
			RD = INFO_TOKENS[IDX]
		}
	}
	if ( length(REF) ==1 && length(ALT) ==1 ) {
		printf("%s\t%s\t%s>%s\t%d\t%f\n", $1,$2,REF,ALT,RD,VAF)
	}
}
}' >> $VAF_TXT

##############################
# Write base change file
for i in "${array[@]}"
do
 for j in "${array[@]}"
 do
   if [[ $i != $j ]]; then
     if [[ $f == *"gz" ]]; then
#        echo "zcat $f | awk -F\"\t\" -v r=$i -v a=$j '\$4==r && \$5==a {print}' | wc -l"
        COUNT=`zcat $f | awk -F"\t" -v r=$i -v a=$j '$1!~/^#/ && $4==r && $5==a && ($7 ~ "PASS" ) {print}' | wc -l` 
#        COUNT=`zcat $f | awk -F"\t" -v r=$i -v a=$j '$1!~/^#/ && $4==r && $5==a {print}' | wc -l` 
     else
#        COUNT=`awk -F"\t" -v r=$i -v a=$j '($7=="PASS" || $7=="LowQual") && $4==r && $5==a {print}' $f | wc -l`
#        echo "awk -F\"\t\" -v r=$i -v a=$j '\$4==r && \$5==a {print}' $f | wc -l"
        #COUNT=`awk -F"\t" -v r=$i -v a=$j '$1!~/^#/ && $4==r && $5==a && ($7=="PASS" || $7=="LowQual"){print}' $f | wc -l`
        COUNT=`awk -F"\t" -v r=$i -v a=$j '$1!~/^#/ && $4==r && $5==a {print}' $f | wc -l`
     fi
     HEADER=`echo -e $HEADER"\t"$i">"$j`
     OUTPUT=`echo -e $OUTPUT"\t"$COUNT`
   fi
 done
done
HEADER=`echo -e $HEADER"\tIndels"`
if [[ $f == *"gz" ]]; then
#        echo "zcat $f | awk -F"\t" '\$1!~/^#/ && (length(\$4)>1 || length(\$5)>1) {print}' | wc -l"
        COUNT=`zcat $f | awk -F"\t" '$1!~/^#/ && (length($4)>1 || length($5)>1) && ($7=="PASS" || $7=="LowQual") {print}' | wc -l`
 #       COUNT=`zcat $f | awk -F"\t" '$1!~/^#/ && (length($4)>1 || length($5)>1) {print}' | wc -l`
else
#        COUNT=`awk -F"\t" -v r=$i -v a=$j '($7=="PASS" || $7=="LowQual") && $4==r && $5==a {print}' $f | wc -l`
        #COUNT=`awk -F"\t" '$1!~/^#/ && (length($4)>1 || length($5)>1) && ($7=="PASS" || $7=="LowQual") {print}' $f | wc -l`
        COUNT=`awk -F"\t" '$1!~/^#/ && (length($4)>1 || length($5)>1) {print}' $f | wc -l`
fi
OUTPUT=`echo -e $OUTPUT"\t"$COUNT`

# HEADER=`echo -e $HEADER"\tTI\tTV\tRATIO"`
# TI=`echo $OUTPUT | awk '{print $4+$6+$9+$11}'`
# TV=`echo $OUTPUT | awk '{print $2+$3+$5+$7+$8+$10+$12+$13}'`
# RATIO=`echo "${TI}/${TV}"| bc -l | xargs -I {} printf "%5.4f" {}`
# OUTPUT=`echo -e $OUTPUT"\t"$TI"\t"$TV"\t"$RATIO`

if [[ $FIRST == "true" ]]; then
  echo $HEADER | awk -F' ' '{for (i=1;i<NF;i++) printf("%s\t",$i); printf $NF"\n";}' > $OUT_TXT
  FIRST=false
fi
echo $OUTPUT | awk -F' ' '{for (i=1;i<NF;i++) printf("%s\t",$i); printf $NF"\n";}' >> $OUT_TXT
# fi
done
