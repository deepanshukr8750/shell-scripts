#!/bin/bash

# Set the threshold values
cpu_threshold=80  # Expressed as percentage
mem_threshold=80  # Expressed as percentage
disk_threshold=80 # Expressed as percentage

# Function to send an alert
send_alert() {
    local message=$1    
    echo "ALERT: $message"
    # Add code to send an alert via email, SMS, or any other means here
}

# Function to check CPU usage
check_cpu_usage() {
    local cpu_usage=$(top -bn1 | grep "Cpu(s)" | awk '{print $2 + $4}')
    echo "CPU Usage: $cpu_usage%"
    if (( $(bc <<< "$cpu_usage > $cpu_threshold") )); then
        send_alert "CPU usage exceeds threshold ($cpu_threshold%)"
    fi
}

# Function to check memory usage
check_memory_usage() {
    local memory_usage=$(free -m | awk '/Mem/ { printf("%.2f"), $3/$2 * 100 }')
    echo "Memory Usage: $memory_usage%"
    if (( $(bc <<< "$memory_usage > $mem_threshold") )); then
        send_alert "Memory usage exceeds threshold ($mem_threshold%)"
    fi
}

# Function to check disk usage
check_disk_usage() {
    local disk_usage=$(df -h | awk '$NF=="/" {printf("%s"), $5}' | sed 's/%//')
    echo "Disk Usage: $disk_usage%"
    if (( $(bc <<< "$disk_usage > $disk_threshold") )); then
        send_alert "Disk usage exceeds threshold ($disk_threshold%)"
    fi
}

# Output file
output_file="system_usage.txt"

# Clear the output file
> "$output_file"

# Run the checks and write the output to the file
{
    echo "System Usage"
    echo "-------------------"
    check_cpu_usage
    check_memory_usage
    check_disk_usage
} >> "$output_file"
