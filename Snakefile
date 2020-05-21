#!/usr/bin/python

import glob
import sys
import os
from glob import glob
from glob import iglob

configfile: "config.yaml"
outName = os.path.basename(os.path.dirname(config['project']))
ensemble_vcf = config['ensemble_vcf']
bam_location = config['bam_location']

project = config['project']
manifest = config['manifest']
refFile = config['ref']
populationFile = config['population_file']

gender_check_dir = 'gender_check'
postcalling_qc_dir = 'postcalling_qc'
coverage_dir = 'coverage'
contamination_dir = 'bamContamination'
ancestry_check_dir = 'laser'
hgdpDir = 'modules/HGDP'


GROUPS=[]
SAMPLES = []
sampleGroupDict = {}
CONTROLS = ['PLCO', 'ACS', 'LC_IGC', 'EAGLE_IGC', 'CTRL']

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
    

include: 'modules/Snakefile_ancestry_plot'
#include: 'modules/Snakefile_ancestry_plot_by_group'
include: 'modules/Snakefile_contamination_plot'
include: 'modules/Snakefile_coverage_plot'
include: 'modules/Snakefile_duplication_plot'
include: 'modules/Snakefile_exomeCQA_plot'
include: 'modules/Snakefile_gender_plot'
include: 'modules/Snakefile_pre_calling_plot'
include: 'modules/Snakefile_postcalling_plot'
include: 'modules/Snakefile_doc'


rule all:
    input:
        basechange_group = expand(postcalling_qc_dir + '/basechange_{group}.png', group = GROUPS), 
        word_report = 'word_doc/' + outName + '_QC_Report.docx'
