#!/bin/bash

set -m

# Loop through folders with ".mod" in their name
for folder in *mod*; do
    if [ -d "$folder" ]; then
        echo "Processing folder: $folder"
        
        # Run create_permutations.sh script
        # sh create_permutations.sh -t "$folder/bescript.psc" -d "$folder/config" -o "$folder/permutations" -b "$folder/defaults.yaml"
        
        # Loop through folders in permutations folder
        for subfolder in "$folder/permutations"/*; do
            if [ -d "$subfolder" ]; then
                echo "Compiling bescript.psc in: $subfolder"
                SF=$(printf '%q' "$subfolder")

                echo subfolder: "$subfolder"
                echo SF: "$SF"
                
                # Run CapricaCompile.cmd with output folder set to subfolder
                echo "/C ./CapricaCompile.cmd  ./$SF/bescript.psc" 
                # CMD "/C ./CapricaCompile.cmd  ./$SF/bescript.psc" 
                CMD "/C CapricaCompile.cmd" 
                # "./CapricaCompile.cmd" "$(cygpath -w "$subfolder/bescript.psc")" "$(cygpath -w ")"

                # echo "./CapricaCompile.cmd" "$subfolder/bescript.psc" "
            fi
        done
    fi
done
