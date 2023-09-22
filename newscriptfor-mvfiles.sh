#!/bin/bash

diramit="/home/ubuntu/files2"
dirsumit="home/ubuntu/files1"
deletion_time=360  # Time in seconds after which diramit will be deleted


mv "$diramit"/* "$dirsumit"


sleep $deletion_time

rm -r "$diramit"
