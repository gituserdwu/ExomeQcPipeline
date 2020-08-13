## Introduction of ExomeQcPipeline

ExomeQcPipeline can be excuted in two modes: germline mode and somatic mode. Difference between the two modes is 
1. somatic mode contains exclusive modules of bam-matcher to check tumor normal pairs.
2. somatic mode post calling qc contains only base change check; germline mode post calling qc contains total filtered variant count, ti/tv ratio and base change check. 

Also the pipeline has two branches: report generation branch and non report generation branch:
1. report generation branch: will automaticlly generate all modules according to somatic/germline setting in the config.yaml file. Output report will be in word_doc folder.
2. non report generation branch: will run any module set as TRUE in config_no_report.yaml file. Output table and figure will be in the subfolder of the particular module.

## Input Requirement:

__None report branch:__
- Fill the config file modules/config_no_report.yaml
  - Bam-matcher_check: fill pair.txt if set TRUE
  - Coverage_check: fill pre-calling qc report if set TRUE
  - exomeCQA_check: fill exomCQA_gene and exomCQA_exon if set TRUE
  - pre_calling_check: fill pre-calling qc report TRUE
  - postcalling_check: fill ensemble_dir TRUE

__Report branch:__
- Fill all items in modules/config.yaml

## How to run:

__None report branch:__
1. Create ExomeQcPipeline folder under build directory and download this repo to the ExomeQcPipeline folder
2. Modify all parameters in `modules/config_no_report.yaml`
3. run `sh run_snakefile_no_report.sh`

__Report branch:__
1. Create ExomeQcPipeline folder under build directory and download this repo to the ExomeQcPipeline folder
2. Modify all parameters in `modules/config.yaml`
3. run `sh run_snakefile_report.sh`

## Test dataset:

__germline:__
  - 72 Giab controls sample testing build: /DCEG/Projects/Exome/builds/build_germline_pipeline_V3_testing/QC/
  `mv test/config_germline_example.yaml modules/config.yaml`
  `mv test/config_no_report_germline_example.yaml modules/config_no_report.yaml`

__somatic:__
  - Breast cancer tumor normal buildL /DCEG/Projects/Exome/builds/build_SR0443-004_somatic_UMI_25938/QC/
  `mv test/config_somatic_example.yaml modules/config.yaml`
  `mv test/config_no_report_somatic_example.yaml modules/config_no_report.yaml`

## Possible errors:

1, Error in dyn.load(file, DLLpath = DLLpath, ...) : unable to load shared object '/mnt/nfs/gigantor/ifs/DCEG/Home/luow2/R/x86_64-pc-linux-gnu-library/3.4/farver/libs/farver.so':
   run `module unload gcc/4.8.4`
   
2, Doc report generated but figures are all unviewable. 
   run `chmod -R 775 ExomeQcPipeline`   



