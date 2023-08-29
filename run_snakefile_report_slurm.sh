#!/bin/sh

module load python3/3.10.2 singularity slurm R 

DATE=$(date +%y%m%d)
mkdir -p logs_${DATE}


snakemake --unlock  

sbcmd="sbatch --time=8:00:00 --mem=64g --cpus-per-task={threads} --output=logs_${DATE}/snakejob_%j.out"

echo "#!/bin/sh" > logs_${DATE}/run_snakefile_slurm.sbatch

echo "module load python3/3.10.2 singularity slurm R; snakemake -pr -s Snakefile_slurm --use-singularity --singularity-args \"--bind /DCEG,/scratch\" --keep-going --rerun-incomplete --local-cores 1 --jobs 1000 --configfile modules_slurm/config.yaml --cluster \"$sbcmd\" --cluster-config cluster_slurm.yaml --latency-wait 120" >> logs_${DATE}/run_snakefile_slurm.sbatch

#qsub -cwd -q all.q -N run_Snakefile  -o logs_${DATE}/Snakefile.stdout -e logs_${DATE}/Snakefile.stderr -b y "module load python3 sge R/3.4.3 gcc zlib;snakemake -pr --keep-going --rerun-incomplete --local-cores 1 --jobs 1000 --configfile modules/config.yaml --cluster \"$sbcmd\" --cluster-config cluster.yaml --latency-wait 120 all"


