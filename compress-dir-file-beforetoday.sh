#!/bin/bash

# Set the directory path
directory="/opt/wildfly_log"

# Navigate to the directory
cd "$directory" || exit

# Get today's date in YYYYMMDD format
today=$(date +"%Y%m%d")

# Gzip all files in the directory except those modified today
find . -maxdepth 1 -type f ! -newermt "$today" -exec gzip {} \;

# Delete original files (not the gzipped ones) excluding today's files
find . -maxdepth 1 -type f ! -newermt "$today" ! -name "*.gz" -exec rm {} \;

