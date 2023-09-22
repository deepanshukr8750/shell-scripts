#!/bin/bash
ls -lt data.txt | awk '{print $6, $7, $8}'
