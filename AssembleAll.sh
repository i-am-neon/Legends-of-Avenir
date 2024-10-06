#!/bin/bash

# If Clean.gba does not exist, throw an error
if [ ! -f "Clean.gba" ]; then
  echo "Clean.gba not found. Please place a clean ROM in the same directory as this script."
  exit 1
fi

currDir="$(cd "$(dirname "$0")" && pwd)"

echo "-----------------------------------"
echo "Assembling assets... Please wait..."
echo "-----------------------------------"

# Trap SIGINT (Ctrl+C) and kill all background processes
trap 'kill 0' SIGINT

# Assemble autogenerated definitions in parallel
echo "Assembling autogenerated definitions..."
cd "$currDir"
./AssembleDefs.sh &

# Assemble graphics in parallel
echo "Assembling graphics..."
cd "$currDir"
./AssembleGraphics.sh &

# Assemble tables in parallel
echo "Assembling tables..."
cd "$currDir"
./AssembleTables.sh &

# Assemble text in parallel
echo "Assembling text..."
cd "$currDir"
./AssembleText.sh &

# Assemble music in parallel
echo "Assembling music..."
cd "$currDir"
./AssembleMusic.sh noRefs &

# Assemble maps in parallel
echo "Assembling maps..."
cd "$currDir"
./AssembleMaps.sh &

# Wait for all parallel jobs to finish
wait

# Make animations
cd "$currDir"
echo "Making animations..."
# ./MAKEAnims.sh noPause
wine cmd /c MAKEAnims.bat noPause

# Final make
cd "$currDir"
echo "Final make..."
./MAKEHACK.sh noPause noSaveCopy
# wine cmd /c MAKEHACK.bat noPause noSaveCopy
