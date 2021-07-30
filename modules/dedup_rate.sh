#!/bin/sh
. /etc/profile.d/modules.sh;
module load python/2.7.5 glu

MANIFEST=$1
OUTDIR=$2

NF=$(awk -F"," '{print NF}' $MANIFEST)

for i in $(awk -F"," '{if(NR>1){print $3"="$6"="$4"="$5"="$13}}' $MANIFEST); do 
	FLOWCELL=$(echo $i | cut -d= -f1);CGFID=$(echo $i | cut -d= -f2); 
	LANE=$(echo $i | cut -d= -f3);INDEX=$(echo $i | cut -d= -f4);
	SUBJECT=$(echo $i | cut -d= -f5);
	FLOWCELL_REPORT=$(find /CGF/Sequencing/Illumina/*Seq/PostRun_Analysis/Reports/ -name "*${FLOWCELL}*.txt")

	if [[ -f $FLOWCELL_REPORT ]]; then
		DUP_RATE=`grep "$CGFID" $FLOWCELL_REPORT | grep "$INDEX" | awk -F"\t" -v lane=$LANE '{if($3==lane){print $13}}'`; 
		PCR_DUP_READS=`grep "$CGFID" $FLOWCELL_REPORT | grep "$INDEX" | awk -F"\t" -v lane=$LANE '{if($3==lane){print $9}}'`;
		OPTICAL_DUP_READS=`grep "$CGFID" $FLOWCELL_REPORT | grep "$INDEX" | awk -F"\t" -v lane=$LANE '{if($3==lane){print $11}}'`;
		TOTAL_READS=`grep "$CGFID" $FLOWCELL_REPORT | grep "$INDEX" | awk -F"\t" -v lane=$LANE '{if($3==lane){print $7}}'`;
		DUP_READS=`echo "$PCR_DUP_READS + $OPTICAL_DUP_READS" | bc -l | xargs -I {} printf "%5.0f" {}`
	else
	#set the sample with no flowcell report found to be 0 at the moment
		#DUP_RATE=0
		#TOTAL_READS=0
		#DUP_READS=0
		echo "No flowcell report?!"
		exit 1
	fi	
	echo -e $SUBJECT"\t"$DUP_RATE"\t"$TOTAL_READS"\t"$DUP_READS;
done > ${OUTDIR}/lane_dup_rate_tmp.txt

awk -F"\t" '{if($1 in array){array[$1]=array[$1]"\t"$2} else {array[$1]=$2}} END {for (i in array) {print i"\t"array[i]}}' ${OUTDIR}/lane_dup_rate_tmp.txt | sort > ${OUTDIR}/lane_dup_rate.txt
awk -F"\t" '{if($1 in array){array[$1]=array[$1]"\t"$3} else {array[$1]=$3}} END {for (i in array) {print i"\t"array[i]}}' ${OUTDIR}/lane_dup_rate_tmp.txt  | sort > ${OUTDIR}/lane_total_reads.txt
awk -F"\t" '{if($1 in array){array[$1]=array[$1]"\t"$4} else {array[$1]=$4}} END {for (i in array) {print i"\t"array[i]}}' ${OUTDIR}/lane_dup_rate_tmp.txt  | sort > ${OUTDIR}/lane_dup_reads.txt


for i in `awk -F"\t" '{print $1}' ${OUTDIR}/lane_dup_rate.txt | sort | uniq`; do 
	#MERGE_LOG=`ls -ltr /DCEG/Projects/Exome/SequencingData/variant_scripts/logs/GATK/patch_build_bam_*/_build_bam_*${i}*.stderr | awk '{if ($5 != 0) print $9}'| tail -1`;  #nowadays we have empty stderr files
	
	TOTAL_READS=`grep ${i} ${OUTDIR}/lane_total_reads.txt | awk '{sum=0; for (i=2;i<=NF;i++)sum+=$i; print sum}'`; 
	LANE_NUM=`grep ${i} ${OUTDIR}/lane_total_reads.txt | awk '{print NF-1}' `
	PRIMARY_DUPLICATE_READS=`grep ${i} ${OUTDIR}/lane_dup_reads.txt | awk '{sum=0; for (i=2;i<=NF;i++) sum+=$i; print sum}'`; 
	DEDUP_LOG=$(ls /DCEG/Projects/Exome/SequencingData/variant_scripts/logs/GATK/*/*/patch_build_bam_*/_build_bam_*${i}*.stderr | head -1)
	if [[ -f ${DEDUP_LOG} ]]; then
	    SECONDARY_DUPLICATE_READS=`grep "records as duplicates" /DCEG/Projects/Exome/SequencingData/variant_scripts/logs/GATK/*/*/patch_build_bam_*/_build_bam_*${i}*.stderr | tail -1|cut -d" " -f3`
	else
		SECONDARY_DUPLICATE_READS=0
	fi
	TOTAL_PERCENT_DUP=`echo "(${PRIMARY_DUPLICATE_READS} + ${SECONDARY_DUPLICATE_READS})/$TOTAL_READS" |bc -l |xargs printf "%5.4f"`
	SECONDARY_PERCENT_DUP=`echo "${SECONDARY_DUPLICATE_READS}/$TOTAL_READS" |bc -l |xargs printf "%5.4f"`
	#OPTICAL_DUPLICATE_READS=`grep "optical duplicate clusters" $MERGE_LOG |cut -d" " -f3`
	#PERCENT_OPTICAL_DUPLICATE=`echo $OPTICAL_DUPLICATE_READS/$TOTAL_READS |bc -l |xargs printf "%5.4f"`
	echo -e $i"\t"${LANE_NUM}"\t"${TOTAL_PERCENT_DUP}"\t"${SECONDARY_PERCENT_DUP}
done > ${OUTDIR}/subject_dup_rate.txt


##trying to combine the lane and subject level dedup rated horizontally, but paste will automatically file 0 in the empty lane dup rate columns for samples with fewer lanes.
cut -f2- ${OUTDIR}/lane_dup_rate.txt | paste ${OUTDIR}/subject_dup_rate.txt - > ${OUTDIR}/merged_dup_rate.txt

#rm ${OUTDIR}/lane_dup_rate_tmp.txt 
# #also adding sum of all lanes dup rates and subject dup rate to reflect total duplicated rate for external report
# awk 'NR>1{x=0;for(i=2;i<=NF;i++)x+=$i;print $1"\t"NF-2"\t"x}' ${OUTDIR}/merged_dup_rate.txt > ${OUTDIR}/merged_dup_rate_external.txt

# if [[ $NF == 15 ]]; then
	# echo -e "ANALYSISID\tLANE_NUMBER\tTOTAL_DUP_RATE\tDOWNSAMPLE" >> ${OUTDIR}/merged_dup_rate_external_tmp.txt
	# for i in $(awk -F"\t" 'NR>1{print $1"-"$2}' ${OUTDIR}/../Downsample.txt);do 
		# SAMPLE=$(echo $i | cut -d- -f1);DOWN=$(echo $i | cut -d- -f2); 

		# awk -F"\t"  -v sample=$SAMPLE down=$DOWN '{if ($1==sample){print $0"\t"down}}' ${OUTDIR}/merged_dup_rate_external.txt >> ${OUTDIR}/merged_dup_rate_external_tmp.txt
    # done
# else 
    # awk -F"\t" 'BEGIN{print "ANALYSISID\tLANE_NUMBER\tTOTAL_DUP_RATE\tDOWNSAMPLE"} {print $0"\tNO"}' ${OUTDIR}/merged_dup_rate_external.txt >> ${OUTDIR}/merged_dup_rate_external_tmp.txt
# fi
# mv ${OUTDIR}/merged_dup_rate_external_tmp.txt ${OUTDIR}/merged_dup_rate_external.txt

