#!/bin/bash
#SBATCH --partition=msc_appbio
#SBATCH --job-name=full_pipeline_wrapper
#SBATCH --output=logs/pipeline_%j.output
#SBATCH --error=logs/pipeline_%j.error
#SBATCH --nodes=1
#SBATCH --time=48:00:00
#SBATCH --mem=4G

#Wrapper for all other scripts to run in one go for ease of access, modularity  
# Define path to scripts
SCRIPT_DIR="scripts"

echo "Beginning RNA-seq Analysis"

# Script 1: Quality Control
echo "Submitting Step 1: Quality Check"
JOB_ID_1=$(sbatch --parsable "$SCRIPT_DIR/0.QualityCheck")
echo "Job ID: $JOB_ID_1"

#Script1.5
echo "Submitting Step 1.5: Build Genome Index"
# This does not depend on QC, so it can run in parallel
JOB_ID_INDEX=$(sbatch --parsable "$SCRIPT_DIR/0.5Index_Builder")
echo "Job ID: $JOB_ID_INDEX"

# Script 2: Alignment (TopHat)
echo "Step 2: Alignment"
# Waits for Quality Check to finish
JOB_ID_2=$(sbatch --parsable --dependency=afterok:$JOB_ID_1 "$SCRIPT_DIR/1.Alignment")
echo "Job ID: $JOB_ID_2 (Waits for $JOB_ID_1)"

# Script 3: Processing (Picard)
echo "Step 3: Processing (Picard)"
JOB_ID_3=$(sbatch --parsable --dependency=afterok:$JOB_ID_2 "$SCRIPT_DIR/2.Processing")
echo "Job ID: $JOB_ID_3 (Waits for $JOB_ID_2)"

# Script 4: Quantification
echo "Step 4: Quantification"
JOB_ID_4=$(sbatch --parsable --dependency=afterok:$JOB_ID_3 "$SCRIPT_DIR/3.Quantification")
echo "Job ID: $JOB_ID_4 (Waits for $JOB_ID_3)"

# Script 5: Differential Expression
echo "Step 5: Differential Expression"
JOB_ID_5=$(sbatch --parsable --dependency=afterok:$JOB_ID_4 "$SCRIPT_DIR/4.Deseq_RNA")
echo "Job ID: $JOB_ID_5 (Waits for $JOB_ID_4)"

echo "All jobs submitted with dependencies. Use 'squeue -u $USER' to monitor progress."
