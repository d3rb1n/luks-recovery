#!/bin/bash

# Clear the output file before starting
> wordlist.txt

# Read prefixes from source1.txt
while IFS= read -r prefix || [ -n "$prefix" ]; do
    # Read middles from source2.txt
    while IFS= read -r middle || [ -n "$middle" ]; do
        # Read suffixes from source3.txt
        while IFS= read -r suffix || [ -n "$suffix" ]; do
            echo "${prefix}${middle}${suffix}" >> wordlist.txt
        done < source1.txt
    done < source2.txt
done < source3.txt

echo "Done."
