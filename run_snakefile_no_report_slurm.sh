#!/bin/sh

module load python3/3.10.2 singularity slurm R

DATE=$(date +%y%m%d)
mkdir -p logs_${DATE}


snakemake --unlock -s Snakefile_no_report --configfile modules/config.yaml

#sbcmd="qsub -cwd -q {cluster.q} -pe by_node {threads} -o logs_${DATE}/ -e logs_${DATE}/ -V"
sbcmd="sbatch --time=8:00:00 --mem=64g --partition=bigmemq --cpus-per-task={threads} --output=logs_${DATE}/snakejob_%j.out"

#qsub -cwd -q seq-calling.q -N run_Snakefile_no_report  -o logs_${DATE}/Snakefile_no_report.stdout -e logs_${DATE}/Snakefile_no_report.stderr -b y "module load python3 sge R/3.4.0 gcc zlib;snakemake -pr -s Snakefile_no_report --keep-going --rerun-incomplete --local-cores 1 --jobs 1000 --configfile modules/config.yaml --cluster \"$sbcmd\" --cluster-config cluster.yaml --latency-wait 120 all"

echo "#!/bin/sh" > logs_${DATE}/run_snakefile_no_report_slurm.sbatch

echo "module load python3/3.10.2 singularity slurm R; snakemake -pr -s Snakefile_no_report_slurm --use-singularity --singularity-args \"--bind /DCEG,/scratch\" --keep-going --rerun-incomplete --local-cores 1 --jobs 1000 --configfile modules_slurm/config.yaml --cluster \"$sbcmd\" --cluster-config cluster_slurm.yaml --latency-wait 120" >> logs_${DATE}/run_snakefile_no_report_slurm.sbatch

sbatch --output=logs_${DATE}/run_snakefile_no_report_slurm.out --error=logs_${DATE}/run_snakefile_no_report_slurm.err logs_${DATE}/run_snakefile_no_report_slurm.sbatch

