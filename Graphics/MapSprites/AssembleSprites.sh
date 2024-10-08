#!/bin/bash

# Calls png2dmp from the tools_dir passed as an argument for all .png files in folder & subfolders
# Does not call png2dmp for files where the existing .dmp file is newer than the .png file

# Check if the tools directory is passed as an argument
if [ -z "$1" ]; then
  echo "Usage: $0 <tools_dir>"
  exit 1
fi

tools_dir="$1"
png2dmp="$tools_dir/Png2Dmp"

# Define the pattern to search for PNG files
FILE_MATCH="*.png"
script_dir="$(dirname "$0")"

# Create cache directory if it doesn't exist
[ ! -d "$script_dir/cache" ] && mkdir "$script_dir/cache"

# Find all .png files recursively
find "$script_dir" -type f -name "$FILE_MATCH" -print0 | while IFS= read -r -d '' F; do
  SHOULD_COMPILE=0
  # Get the directory, basename, and filename
  dir="$(dirname "$F")"
  basename="$(basename "$F")"
  filename="${basename%.*}"

  # Construct the DUMP_FILE path in the cache directory
  DUMP_FILE="$dir/cache/${filename}.dmp"

  # Check if the DUMP_FILE needs to be recompiled
  if [ -e "$DUMP_FILE" ]; then
    # Compare modification times
    if [ "$F" -nt "$DUMP_FILE" ]; then
      SHOULD_COMPILE=1
    fi
  else
    SHOULD_COMPILE=1
  fi

  # If the .png file is newer than the .dmp or the .dmp file doesn't exist
  if [ "$SHOULD_COMPILE" -eq 1 ]; then
    echo "Assembling \"$basename\"..."

    # Run png2dmp with the --lz77 option and store the output in the cache directory
    "$png2dmp" "$F" --lz77 -o "$DUMP_FILE"
  fi
done

echo "Assembling Sprites Complete"
