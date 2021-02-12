#!/bin/sh

REPORT=$1
#DIR=/CGF/Bioinformatics/Production/Wen/20180911_snakemake_coverage_tools/ExomeQcPipeline
POST_CALL_DIR=$2
#CACO=1

echo -e "SAMPLE\tTOTAL\tTI\tTV\tRATIO\tCACO" > ${POST_CALL_DIR}/titv.txt
for i in $(awk '{if(NR > 1) {print $1}}' ${REPORT} | sort | uniq);do 
	TI=$(grep $i ${REPORT} | grep "A>G\|C>T\|G>A\|T>C" | awk '{print $3+$4+$5+$6+$7+$8+$9+$10+$11+$12+$13}' | paste -sd+ - | bc);
	TV=$(grep $i  ${REPORT} | grep "A>C\|A>T\|C>A\|C>G\|G>C\|G>T\|T>A\|T>G" | awk '{print $3+$4+$5+$6+$7+$8+$9+$10+$11+$12+$13}' | paste -sd+ - | bc);
	RATIO=`echo "${TI}/${TV}"| bc -l | xargs -I {} printf "%5.4f" {}`; 
	TOTAL=`echo "${TI}+${TV}"| bc -l | xargs -I {} printf "%5.0f" {}`;
    if [[ $i == CTRL* ]] || [[ $i == ACS* ]] || [[ $i == EAGLE* ]] || [[ $i == PLCO* ]];then 
		CACO=2
	else
		CACO=1	
	fi	
	echo -e "${i}\t${TOTAL}\t${TI}\t${TV}\t${RATIO}\t${CACO}";
done >> ${POST_CALL_DIR}/titv.txt

echo -e "GROUP\tBASE\t0-90\t90-400\t400-2400\t2400-6000\t6000-12000\t12000-20000\t20000-36000\t36000-60000\t60000-100000\t100000-1600000\t>1600000" > ${POST_CALL_DIR}/basechange_all.txt
for i in $(awk '{if (NR >1 ) {print $1}}' ${REPORT} | cut -f1 -d_ | sort |uniq ); do 
	#echo -e "BASE\t0-90\t90-400\t400-2400\t2400-6000\t6000-12000\t12000-20000\t20000-36000\t36000-60000\t60000-100000\t100000-1600000\t>1600000" > ${POST_CALL_DIR}/basechange_${i}.txt
	for j in 'A>G' 'C>T' 'G>A' 'T>C' 'A>C' 'A>T' 'C>A' 'C>G' 'G>C' 'G>T' 'T>A' 'T>G'; do
		grep ^"$i" ${REPORT} | grep $j | awk -v BASECHANGE="$j" -v GROUP="$i" 'BEGIN {t1=t2=t3=t4=t5=t6=t7=t8=t9=t10=t11=0} {t1+=$3; t2+=$4; t3+=$5; t4+=$6;t5+=$7;t6+=$8;t7+=$9;t8+=$10;t9+=$11;t10+=$12;t11+=$13} END {print GROUP"\t"BASECHANGE"\t"t1/NR"\t"t2/NR"\t"t3/NR"\t"t4/NR"\t"t5/NR"\t"t6/NR"\t"t7/NR"\t"t8/NR"\t"t9/NR"\t"t10/NR"\t"t11/NR }'>> ${POST_CALL_DIR}/basechange_all.txt 
	done
done

awk -F"\t" 'BEGIN{print "SAMPLE\tA>C\tA>G\tA>T\tC>A\tC>G\tC>T\tG>A\tG>C\tG>T\tT>A\tT>C\tT>G"} {if($1 in array){array[$1]=array[$1]"\t"$3} else {array[$1]=$3}} END {for (i in array) {print i"\t"array[i]}}' ${REPORT} > ${POST_CALL_DIR}/low_qual_basechange_tmp.txt

(head -n 1 ${POST_CALL_DIR}/low_qual_basechange_tmp.txt && tail -n +2 ${POST_CALL_DIR}/low_qual_basechange_tmp.txt | sort ) > ${POST_CALL_DIR}/low_qual_basechange.txt
rm ${POST_CALL_DIR}/low_qual_basechange_tmp.txt


