#!/bin/bash

read -p "Enter a path of file:  " file_path



# using wc command to count number of lines
number_of_lines=$(wc --lines < $file_path)

# using wc command to count number of words
number_of_words=$(wc --word < $file_path)

# Displaying number of lines and number of words
echo "Number of lines: $number_of_lines"
echo "Number of words: $number_of_words"