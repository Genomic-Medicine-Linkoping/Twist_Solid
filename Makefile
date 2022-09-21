.ONESHELL:
SHELL = /bin/bash
.SHELLFLAGS := -e -o pipefail -c
.DELETE_ON_ERROR:
MAKEFLAGS += --warn-undefined-variables
MAKEFLAGS += --no-builtin-rules

# The conda env definition file "requirements.yml" is located in the project's root directory
CURRENT_CONDA_ENV_NAME = 20220920_0.2.3-validation_Twist_Solid
ACTIVATE_CONDA = source $$(conda info --base)/etc/profile.d/conda.sh
CONDA_ACTIVATE = $(ACTIVATE_CONDA) ; conda activate ; conda activate $(CURRENT_CONDA_ENV_NAME)

CPUS = 92
ARGS = --rerun-incomplete

.PHONY: \
all \
create_inputs \
run \
clean \
collection \
archive \
help

REPORT = report.html

SAMPLE_NAME = LI-VAL-13_20_BRCA_EXONS

RESULTS = \
fusions \
prealignment \
alignment \
qc \
snv_indels \
genefuse.json \
annotation \
bam_dna \
biomarker \
cnv_sv \
gvcf_dna \
results \
logs


SAMPLE_DATA = \
samples.tsv \
units.tsv

RESULTS_DIR = $(SAMPLE_NAME)

FASTQ_INPUT_DIR = /data/Twist_Solid/DNA/input
STORAGE = /archive/Twist_Solid/DNA/results

MAIN_SMK = workflow/Snakefile

all: run collection archive

## run: Run the main pipeline
run:
	$(CONDA_ACTIVATE)
	export SINGULARITY_LOCALCACHEDIR=/data/Twist_Solid/cache_dir
	snakemake --cores $(CPUS) \
	--use-singularity \
	--singularity-args "--cleanenv --bind /data/Twist_Solid/ --bind /data/reference_genomes/" \
	-s $(MAIN_SMK) \
	--configfile config/config.yaml \
	$(ARGS)

## create_inputs: Create input metadata files based on files residing in a given fastq-file directory
create_inputs:
	$(CONDA_ACTIVATE)
	hydra-genetics create-input-files \
	-d $(FASTQ_INPUT_DIR) \
	--force \
	--sample-type T

## update_env: Update conda environment to the latest version defined by env.yml file
update_env:
	$(ACTIVATE_CONDA)
	mamba env update --file env.yml

## hydra_help: Produce help message for hydra-genetics utility
hydra_help:
	$(CONDA_ACTIVATE)
	hydra-genetics create-input-files --help

## clean: Remove all the latest results
clean:
	rm --verbose --recursive --force $(RESULTS)

## report: Make snakemake report
report:
	$(CONDA_ACTIVATE)
	snakemake \
	--cores $(CPUS) \
	--report $(REPORT) \
	-s $(MAIN_SMK) \
	--configfile config/config.yaml

## collection: Collect all results from the last run into own directory
collection:
	mkdir -p $(RESULTS_DIR)
	mv $(RESULTS) $(RESULTS_DIR)
	cp $(SAMPLE_DATA) $(RESULTS_DIR)
	cp Makefile $(RESULTS_DIR)
	cp env.yml $(RESULTS_DIR)

## archive: Move to larger storage location and create a symbolic link to it
archive:
	mv --verbose $(RESULTS_DIR) $(STORAGE)

## help: Show this message
help:
	@grep '^##' ./Makefile
