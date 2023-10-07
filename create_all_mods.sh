#!/bin/bash

# Loop through folders with ".mod" in their name
for folder in *mod*; do
    if [ -d "$folder" ]; then
        echo "Processing folder: $folder"
        
        # Run create_permutations.sh script
        sh create_permutations.sh -t "$folder/bescript.psc" -d "$folder/config" -o "$folder/permutations" -b "$folder/defaults.yaml"
        
        # Loop through folders in permutations folder
        for subfolder in "$folder/permutations"/*; do
            if [ -d "$subfolder" ]; then
                echo "Compiling bescript.psc in: $subfolder"
                
                # Run CapricaCompile.cmd with output folder set to subfolder
                # "./CapricaCompile.cmd" "$subfolder/bescript.psc" "$subfolder_name"
                echo "$subfolder/bescript.psc" "$subfolder_name"
            fi
        done
    fi
done
