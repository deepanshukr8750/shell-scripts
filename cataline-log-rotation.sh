#!/bin/bash

log_file="/opt/tomcat/apache-tomcat-9.0.30/logs/catalina.out"
current_date_time=$(date +'%Y%m%d')
output_file="/opt/tomcat/apache-tomcat-9.0.30/logs/catalina.out-$current_date_time.gz"

# Check if the log file exists and is a regular file
if [ -f "$log_file" ]; then
    # Process the log file line by line and compress the data
    while IFS= read -r line; do
        echo "$line"
    done < "$log_file" | gzip > "$output_file"

    # Clear the old file data by truncating it
    > "$log_file"
else
    echo "Log file $log_file does not exist or is not a regular file."
fi


