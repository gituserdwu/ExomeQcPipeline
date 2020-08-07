#!/bin/sh

module load python3 sge R/3.4.0 

DATE=$(date +%y%m%d)
mkdir -p logs_${DATE}


snakemake --unlock -s Snakefile_no_report --configfile modules/config_no_report.yaml

sbcmd="qsub -cwd -q {cluster.q} -pe by_node {threads} -o logs_${DATE}/ -e logs_${DATE}/ -V"
qsub -cwd -q seq-calling.q -N run_Snakefile_no_report  -o logs_${DATE}/Snakefile_no_report.stdout -e logs_${DATE}/Snakefile_no_report.stderr -b y "module load python3 sge R/3.4.0 gcc zlib;snakemake -pr -s Snakefile_no_report --keep-going --rerun-incomplete --local-cores 1 --jobs 1000 --configfile modules/config_no_report.yaml --cluster \"$sbcmd\" --cluster-config cluster.yaml --latency-wait 120 all"


