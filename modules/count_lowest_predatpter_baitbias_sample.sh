#!/bin/bash

INPUT=$1
OUTPUT=$2

#PREADATPER
FIRST_LOWEST_BASE_CHANGE=`awk -F"\t" '{print $27"\t"$26}' $INPUT | sort | awk -F"\t" '{print $2}' | uniq -c | awk '{for(i=2;i<=NF;++i)print $i}' | uniq | head -1`
SECOND_LOWEST_BASE_CHANGE=`awk -F"\t" '{print $27"\t"$26}' $INPUT | sort | awk -F"\t" '{print $2}' | uniq -c | awk '{for(i=2;i<=NF;++i)print $i}' | uniq | head -2 |tail -1`
THIRD_LOWEST_BASE_CHANGE=`awk -F"\t" '{print $27"\t"$26}' $INPUT | sort | awk -F"\t" '{print $2}' | uniq -c | awk '{for(i=2;i<=NF;++i)print $i}' | uniq | head -3 |tail -1`

FIRST_LOWEST_SAMPLE_COUNT=`awk -F"\t" '{print $27"\t"$26}' $INPUT | grep ${FIRST_LOWEST_BASE_CHANGE} $INPUT | wc -l`
SECOND_LOWEST_SAMPLE_COUNT=`awk -F"\t" '{print $27"\t"$26}' $INPUT | grep ${SECOND_LOWEST_BASE_CHANGE} $INPUT | wc -l`
THIRD_LOWEST_SAMPLE_COUNT=`awk -F"\t" '{print $27"\t"$26}' $INPUT | grep ${THIRD_LOWEST_BASE_CHANGE} $INPUT | wc -l`

echo -e "Preadapter,${FIRST_LOWEST_BASE_CHANGE},${FIRST_LOWEST_SAMPLE_COUNT},${SECOND_LOWEST_BASE_CHANGE},${SECOND_LOWEST_SAMPLE_COUNT},${THIRD_LOWEST_BASE_CHANGE},${THIRD_LOWEST_SAMPLE_COUNT}" > ${OUTPUT}

#BAITBIAS
FIRST_LOWEST_BASE_CHANGE=`awk -F"\t" '{print $29"\t"$28}' $INPUT | sort | awk -F"\t" '{print $2}' | uniq -c | awk '{for(i=2;i<=NF;++i)print $i}' | uniq | head -1`
SECOND_LOWEST_BASE_CHANGE=`awk -F"\t" '{print $29"\t"$28}' $INPUT | sort | awk -F"\t" '{print $2}' | uniq -c | awk '{for(i=2;i<=NF;++i)print $i}' | uniq | head -2 |tail -1`
THIRD_LOWEST_BASE_CHANGE=`awk -F"\t" '{print $29"\t"$28}' $INPUT | sort | awk -F"\t" '{print $2}' | uniq -c | awk '{for(i=2;i<=NF;++i)print $i}' | uniq | head -3 |tail -1`

FIRST_LOWEST_SAMPLE_COUNT=`awk -F"\t" '{print $29"\t"$28}' $INPUT | grep ${FIRST_LOWEST_BASE_CHANGE} $INPUT | wc -l`
if [[ ${SECOND_LOWEST_BASE_CHANGE} = "*>*" ]]; then
    SECOND_LOWEST_SAMPLE_COUNT=`awk -F"\t" '{print $29"\t"$28}' $INPUT | grep ${SECOND_LOWEST_BASE_CHANGE} $INPUT | wc -l`
else
    SECOND_LOWEST_SAMPLE_COUNT=NA
    SECOND_LOWEST_BASE_CHANGE=NA
fi

if [[ ${THIRD_LOWEST_BASE_CHANGE} = "*>*" ]]; then
    THIRD_LOWEST_SAMPLE_COUNT=`awk -F"\t" '{print $29"\t"$28}' $INPUT | grep ${THIRD_LOWEST_BASE_CHANGE} $INPUT | wc -l`
else
    THIRD_LOWEST_SAMPLE_COUNT=NA
    THIRD_LOWEST_BASE_CHANGE=NA
fi

echo -e "Baitbias,${FIRST_LOWEST_BASE_CHANGE},${FIRST_LOWEST_SAMPLE_COUNT},${SECOND_LOWEST_BASE_CHANGE},${SECOND_LOWEST_SAMPLE_COUNT},${THIRD_LOWEST_BASE_CHANGE},${THIRD_LOWEST_SAMPLE_COUNT}" >> ${OUTPUT}
