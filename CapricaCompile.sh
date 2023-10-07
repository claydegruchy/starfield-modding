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
# cd "$SCRIPTPATH"



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
SCRIPTFILE="$cap_directory/$SCRIPTPATH/$SCRIPTNAME"
OUTFILE="$cap_directory/$SCRIPTPATH/"

echo "IMPORT:     \"$IMPORT\""
echo "OUTPUT:     \"$OUTPUT\""
echo "OUTFILE: \"$OUTFILE\""
echo "SCRIPTPATH: \"$SCRIPTPATH\""
echo "SCRIPTNAME: \"$SCRIPTNAME\""
echo "SCRIPTFILE: \"$SCRIPTFILE\""
echo "CURRENT PATH: $(pwd)"

# check if SCRIPTFILE exists
if [ -f "$SCRIPTFILE" ]; then
  echo "File \"$SCRIPTFILE\" exists."
else
  echo "File \"$SCRIPTFILE\" does not exist."
  exit 1
fi

# copy bescript.psc to the current directory
echo "Copying \"$SCRIPTFILE\" to the current directory."
cp "$SCRIPTFILE" .

# check if bescript.psc exists
if [ -f "$SCRIPTNAME" ]; then
  echo "File \"$SCRIPTNAME\" exists."
else
  echo "File \"$SCRIPTNAME\" does not exist."
  exit 1
fi


# create folder at location $OUTPUT/Data/scripts
echo "Creating folder at location \"$OUTPUT/Data/scripts\""

# check if folder exists
if [ -d "$OUTPUT/Data/scripts" ]; then
  echo "Folder \"$OUTPUT/Data/scripts\" exists."
else
  echo "Folder \"$OUTPUT/Data/scripts\" does not exist."
  mkdir -p "$OUTPUT/Data/scripts"
fi

OUTPUT_DATA_FOLDER="$OUTPUT/Data/scripts"



# run
./Caprica.exe --game starfield --import "$IMPORT" --output "$OUTPUT_DATA_FOLDER" "$SCRIPTNAME"

# create zip file containing the data folder
echo "Creating zip file containing the data folder."
powershell Compress-Archive "$OUTPUT/Data/" "$OUTPUT.zip"

# delete bescript.psc from the current directory
echo "Deleting \"$SCRIPTNAME\" from the current directory."
rm "$SCRIPTNAME"



# Execute Caprica.exe from cap_directory
# echo "Executing Caprica.exe from cap_directory: \"$cap_directory\""
# full_path="$cap_directory/Caprica.exe --game starfield --import \"$IMPORT\" --output \"$OUTFILE\" \"$SCRIPTFILE\""
# # Caprica.exe --game starfield --import "$IMPORT" --output "$OUTPUT" "$SCRIPTFILE"
# bash "$full_path"





# End
echo
