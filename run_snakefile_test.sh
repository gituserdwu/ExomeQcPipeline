#!/bin/sh

module load python3 sge R

DATE=$(date +%y%m%d)
mkdir -p logs_${DATE}


snakemake --unlock  

sbcmd="qsub -cwd -q {cluster.q} -pe by_node {threads} -o logs_${DATE}/ -e logs_${DATE}/ -V"
qsub -cwd -q long.q -N run_Snakefile  -o logs_${DATE}/Snakefile.stdout -e logs_${DATE}/Snakefile.stderr -b y "module load python3 sge R gcc zlib;snakemake -pr --keep-going --rerun-incomplete --local-cores 1 --jobs 1000 --configfile modules/config.yaml --cluster \"$sbcmd\" --cluster-config cluster.yaml --latency-wait 120 all"


