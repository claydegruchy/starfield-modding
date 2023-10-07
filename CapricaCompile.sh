#!/bin/bash

# Print the 1st command line parameter passed to the script
echo $1

# Set variables
IMPORT="C:\Program Files (x86)\Steam\steamapps\common\Starfield\Data\Scripts\Source\Base"
OUTPUT="C:\Program Files (x86)\Steam\steamapps\common\Starfield\Data\Scripts"
SCRIPTPATH="C:\Program Files (x86)\Steam\steamapps\common\Starfield\Data\Scripts\Source\User"
SCRIPTNAME="SKK_ConsoleUtilityScript.psc"

# Change the current working directory to SCRIPTPATH
cd "$SCRIPTPATH"

# Check if the first command line parameter is provided
if [ -z "$1" ]; then
  echo "No parameter provided."
else
  echo "A param has been passed in 1: '$1'"
  SCRIPTNAME="$1"
  echo "SCRIPTNAME: \"$SCRIPTNAME\""
fi

# Check if the second command line parameter is provided
if [ -z "$2" ]; then
  echo "No parameter provided."
else
  echo "A param has been passed in 2: '$2'"
  OUTPUT="$2"
  echo "OUTPUT: \"$OUTPUT\""
fi

# Print information
clear
echo "****************************************************************"
echo "Caprica Starfield DEBUG compile 002"
echo

# Check if SCRIPTNAME is empty
if [ -z "$SCRIPTNAME" ]; then
  echo "Enter SCRIPTFILE Name (include.psc): "
  read SCRIPTNAME
  echo
fi

# Compile
SCRIPTFILE="$SCRIPTPATH/$SCRIPTNAME"

echo "IMPORT:     \"$IMPORT\""
echo "OUTPUT:     \"$OUTPUT\""
echo "SCRIPTPATH: \"$SCRIPTPATH\""
echo "SCRIPTNAME: \"$SCRIPTNAME\""
echo "SCRIPTFILE: \"$SCRIPTFILE\""
echo

# Execute Caprica.exe
./Caprica.exe --game starfield --import "$IMPORT" --output "$OUTPUT" "$SCRIPTFILE"

# End
echo
