#!/bin/bash                               
#$ -l rmem=10G
#$ -l h_rt=24:00:00                      
#$ -M n.bulgakova@sheffield.ac.uk
#$ -m bea

cd /data/md1nbu/Density/EB1DN

module load apps/matlab            

matlab -nodesktop -r ‘actin_cluster_v1’