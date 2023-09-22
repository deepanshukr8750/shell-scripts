#!/bin/bash

# Output file
output_file="biggest_files.txt"

# Find and list the 10 largest files in the file system
find / -type f -exec du -Sh {} + 2>/dev/null | sort -rh | head -n 10 > "$output_file"

echo "10 biggest files in the file system have been saved to $output_file"
