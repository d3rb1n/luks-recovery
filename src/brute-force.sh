#!/bin/bash

# Function to display the help message
display_help() {
    echo "Usage: $0 -d DEVICE [-u URL] [-n] [-s] [-h]"
    echo
    echo "  -d DEVICE  The device to check (e.g., /dev/nvme0n1p3)."
    echo "  -u URL     The ntfy.sh URL to send notifications (e.g., ntfy.sh/my_notification_channel)."
    echo "  -n         Disable notifications to ntfy.sh."
    echo "  -s         Disable text-to-speech (espeak)."
    echo "  -h         Display this help message."
    exit 1
}

# Default values for device, URL, and options
DEVICE=""
URL=""
NOTIFY=true
SPEAK=true

# Parse command-line options
while getopts "d:u:nsh" opt; do
    case ${opt} in
        d )
            DEVICE=$OPTARG
            ;;
        u )
            URL=$OPTARG
            ;;
        n )
            NOTIFY=false
            ;;
        s )
            SPEAK=false
            ;;
        h )
            display_help
            ;;
        \? )
            echo "Invalid option: -$OPTARG" >&2
            display_help
            ;;
        : )
            echo "Invalid option: -$OPTARG requires an argument" >&2
            display_help
            ;;
    esac
done
shift $((OPTIND -1))

# Check if DEVICE is set
if [ -z "$DEVICE" ]; then
    echo "Error: DEVICE is required." >&2
    display_help
fi

# Validate the device
if [ ! -b "$DEVICE" ]; then
    echo "Error: DEVICE '$DEVICE' is not a valid block device." >&2
    exit 1
fi

# Function to handle notifications
notify() {
    local title="$1"
    local message="$2"
    local tag="$3"

    if $NOTIFY && [ -n "$URL" ]; then
        curl -H "t: $title" -d "$message" -H "Tags: $tag" "$URL"
    fi
}

# Function to handle text-to-speech
speak() {
    local message="$1"
    if $SPEAK; then
        echo "$message" | espeak 2> /dev/null
    fi
}

# Check if the script is running as root or with sudo
if [ "$EUID" -ne 0 ]; then
    echo "This script must be run as root or with sudo."
    exit 1
fi

# Initial notification if enabled
notify "LUKS Recovery" "Script started." "green_circle"

# Function to handle SIGINT (CTRL+C)
cleanup() {
    echo -e "\nScript interrupted. Exiting..."
    notify "LUKS Recovery" "Script cancelled." "red_circle"
    speak "Brute force cancelled."
    exit 1
}

# Trap SIGINT (CTRL+C) and call the cleanup function
trap cleanup SIGINT

index=1  # Initialize the counter

# # (Optionally) Clear the confirmed-no.txt file before starting
# > confirmed-no.txt

# Read passphrases from the file and check them
while IFS= read -r passphrase; do
    echo "Checking passphrase #$index: $passphrase"
    echo "$passphrase" | cryptsetup luksOpen "$DEVICE" my_luks_volume --test-passphrase
    
    if [ $? -eq 0 ]; then
        echo -e "\n\nPASSPHRASE FOUND: $passphrase"
        speak "LUKS password found!"
        notify "LUKS Recovery" "Passphrase found!" "green_circle"
        echo $passphrase > ./password.txt
        break
    else
        # Append the failed passphrase to confirmed-no.txt
        echo "$passphrase" >> confirmed-no.txt
    fi

    index=$((index + 1))  # Increment the counter
done < wordlist.txt

echo "Brute force complete."
speak "Brute force complete."
notify "LUKS Recovery" "Script complete." "green_circle"
