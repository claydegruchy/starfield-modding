#!/bin/bash

# Set variables
IMPORT="C:\Program Files (x86)\Steam\steamapps\common\Starfield\Data\Scripts\Source\Base"
OUTPUT="C:\Program Files (x86)\Steam\steamapps\common\Starfield\Data\Scripts"
SCRIPTPATH="C:\Program Files (x86)\Steam\steamapps\common\Starfield\Data\Scripts\Source\User"
SCRIPTNAME="SKK_ConsoleUtilityScript.psc"


# Check if the first command line parameter is provided
if [ -z "$1" ]; then
  echo "No parameter provided."
else
  echo "A param has been passed in 1: '$1'"
  SCRIPTPATH="$1"
  echo "# Updating SCRIPTPATH: \"$SCRIPTPATH\""
fi

cap_directory=$(pwd)

# # Change the current working directory to SCRIPTPATH
cd "$SCRIPTPATH"



# Check if the second command line parameter is provided
if [ -z "$2" ]; then
  echo "No parameter provided."
else
  echo "A param has been passed in 1: '$2'"
  SCRIPTNAME="$2"
  echo "# Updating SCRIPTNAME: \"$SCRIPTNAME\""
fi

# Check if the third command line parameter is provided
if [ -z "$3" ]; then
  echo "No parameter provided."
else
  echo "A param has been passed in 2: '$3'"
  OUTPUT="$3"
  echo "# Updating OUTPUT: \"$OUTPUT\""
fi

# Print information
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

# Execute Caprica.exe from cap_directory
echo "Executing Caprica.exe from cap_directory: \"$cap_directory\""
full_path="$cap_directory/Caprica.exe --game starfield --import \"$IMPORT\" --output \"$OUTPUT\" \"$SCRIPTFILE\""
# Caprica.exe --game starfield --import "$IMPORT" --output "$OUTPUT" "$SCRIPTFILE"
if [ -f "$full_path" ]; then
  # Run the file
  bash "$full_path"
else






# End
echo
