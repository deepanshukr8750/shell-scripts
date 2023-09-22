#!/bin/bash

# Shell script for find keyword (which is given by the user) in partuculer file


read -p "Enter the directory path: " directory


read -p "Enter the keyword: " keyword


echo "Searching for files containing '$keyword' in '$directory'..."

# Find files and display results
find "$directory" -type f -exec grep -l "$keyword" {} + 2>/dev/null | while IFS= read -r file; 
do
 
  echo "Here is a File which contain $keyword keyword: $(basename $file)"
done

echo "Search completed."
