#!/bin/bash

set -m

f="$(pwd)"

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
                
                ./CapricaCompile.sh "$pwd/$subfolder" bescript.psc "$pwd/$subfolder"
                # Run CapricaCompile.cmd with output folder set to subfolder
                # echo "/C CapricaCompile.cmd  '$subfolder/bescript.psc' '$subfolder'" 
                # CMD "/C CapricaCompile.cmd $SCRIPT $SF" 
                # CMD "/C ./CapricaCompile.cmd  ./$SF/bescript.psc" 
                # CMD "/C CapricaCompile.cmd  $SF/bescript.psc" 
                # CMD "/C CapricaCompile.cmd" 
                # "./CapricaCompile.cmd" "$(cygpath -w "$subfolder/bescript.psc")" "$(cygpath -w ")"


Executing Caprica.exe from cap_directory: "/c/Program Files (x86)/Steam/steamapps/common/Starfield/Data/Scripts/Source/User"
bash: /c/Program Files (x86)/Steam/steamapps/common/Starfield/Data/Scripts/Source/User/Caprica.exe --game starfield --import "C:\Program Files (x86)\Steam\steamapps\common\Starfield\Data\Scripts\Source\Base" --output "/Hazardous ship boarding.mod/permutations/standard" "/Hazardous ship boarding.mod/permutations/standard/bescript.psc": No such file or directory


                # echo "./CapricaCompile.cmd" "$subfolder/bescript.psc" "
            fi
        done
    fi
done
