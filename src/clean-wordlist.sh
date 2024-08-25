#!/bin/bash

# Check if both files exist
if [ ! -f wordlist.txt ]; then
    echo "Error: wordlist.txt not found."
    exit 1
fi

if [ ! -f confirmed-no.txt ]; then
    echo "Error: confirmed-no.txt not found."
    exit 1
fi

# Use grep to filter out lines from wordlist.txt that exist in confirmed-no.txt
grep -Fxv -f confirmed-no.txt wordlist.txt > wordlist_filtered.txt

# Replace the original wordlist.txt with the filtered one
mv wordlist_filtered.txt wordlist.txt

echo "Lines removed. Updated wordlist.txt."
