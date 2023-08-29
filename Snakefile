#!/usr/bin/python

import glob
import sys
import os
from glob import glob
from glob import iglob

configfile: "modules/config.yaml"
outName = os.path.basename(os.path.dirname(config['project']))
ensemble_vcf = config['ensemble_vcf']
bam_location = config['bam_location']
ensemble_dir = config['ensemble_dir']

project = config['project']
manifest = config['manifest']
refFile = config['ref']
populationFile = config['population_file']
bedFile = config['capturekit']
precallingReport = config['precalling_report']
#exomeCQAgeneReport = config['exomCQA_gene']
#exomeCQAexonReport = config['exomCQA_exon']

gender_check_dir = 'gender_check'
postcalling_qc_dir = 'postcalling_qc'
coverage_dir = 'coverage'
contamination_dir = 'bamContamination'
ancestry_check_dir = 'ancestry'
exomeCQA_dir = 'exomeCQA'
hgdpDir = 'modules/HGDP'
deduplication_dir = 'deduplication'
precalling_dir = 'precalling_qc'
relatedness_dir = 'relatedness'
fastqc_dir = 'fastqc'

GROUPS=[]
SAMPLES = []
sampleGroupDict = {}
CONTROLS = ['PLCO', 'ACS', 'LC_IGC', 'EAGLE_IGC', 'CTRL', '_Normal']

include: "modules/Snakemake_utils"

########################
#Germline call

with open(manifest) as f:
    next(f)
    for line in f:
        (group, analysisid) = [line.split(',')[i] for i in [6,12]] #with list index [6,11,12], it will throw error "list indices must be integers or slices, not tuple". Need to explicitly specify by the loop, because you cannot index list
        sample = group + "_" + analysisid
        if (sample not in SAMPLES):
            SAMPLES.append(sample)
            sampleGroupDict[sample] = group        
            if group not in GROUPS:            
                GROUPS.append(group)	
                
def getBam(wildcards):
    (group) = sampleGroupDict[wildcards.sample]
    return (glob(bam_location + '/' + group + '/' + wildcards.sample + '.bam')) #Why have to use glob instead of using the string

#print(SAMPLES)

def getReport(wildcards):
    return glob(project + '/*coverage_report*.txt')
	
	
#for bam_subdir in glob(bam_location + '/*/'):
#    GROUPS.append(os.path.basename(bam_subdir.strip('/')))

########################
#Somatic pair call

if config['MODE'] == 'somatic': 

    pair_manifest = config['pairs']
    bamMatcher_dir = 'bamMatcher'
    bamMatcherExe = config['BamMatcher']

    SAMPLES = []
    tumorDict = {}
    normalDict = {}

    with open(pair_manifest) as f:
        for line in f:
            (tumor, normal, vcf) = line.split()
            sample = os.path.basename(vcf)[:-4]
            SAMPLES.append(os.path.basename(vcf)[:-4])
            tumorName = os.path.basename(tumor)[:-4]
            normalName = os.path.basename(normal)[:-4]
            tumorDict[sample] = (tumor)
            normalDict[sample] = (normal)

    def get_tumor(wildcards):
        (file) = tumorDict[wildcards.sample]
        return file

    def get_normal(wildcards):
        (file) = normalDict[wildcards.sample]
        return file     

    pair_manifest = config['pairs']
    bamMatcher_dir = 'bamMatcher'
    bamMatcherExe = config['BamMatcher']
    include: 'modules/Snakefile_bam_matcher'
    
#launch all rules    
#include: 'modules/Snakefile_ancestry_plot'
#include: 'modules/Snakefile_ancestry_plot_by_group'
include: 'modules/Snakefile_contamination_plot'
include: 'modules/Snakefile_coverage_plot'
include: 'modules/Snakefile_duplication_plot'
#include: 'modules/Snakefile_fastqc'   

if not config['MODE'] == 'wgs':
    include: 'modules/Snakefile_exomeCQA_plot'
    #include: 'modules/Snakefile_ancestry_plot_laser'
else:
    include: 'modules/Snakefile_ancestry_plot_fastNGSadmix'
    
#include: 'modules/Snakefile_gender_plot'
include: 'modules/Snakefile_pre_calling_plot'

if config['MODE'] == 'somatic' or 'tumor_only':
    include: 'modules/Snakefile_postcalling_plot_somatic'
    include: 'modules/Snakefile_ancestry_plot_laser'
else:    
    include: 'modules/Snakefile_relatedness'
    include: 'modules/Snakefile_postcalling_plot'

include: 'modules/Snakefile_doc'
    
rule all:
    input:
        bamMatcher_dir + '/bam_matcher_report_all.txt' if config['MODE'] == 'somatic' else [],
        basechange_group = expand(postcalling_qc_dir + '/basechange_{group}.png', group = GROUPS) if config['MODE'] == 'wgs' or config['MODE'] == 'wes' else [], 
        word_report = 'word_doc/' + outName + '_QC_Report.docx'
