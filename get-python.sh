#!/bin/bash

# Define the URL of the file to download
FILE_URL="https://github.com/Randy420Marsh/cpython/releases/download/v3.10.12/Python-3.10.12.tar.xz"
# Define the expected SHA256 checksum of the file
EXPECTED_CHECKSUM="56f5e51514453bfa04035c896d5d40059e3d558004cb846934e15746fa2aa86d"

# Define the local file name (adjust as needed)
LOCAL_FILE="Python-3.10.12.tar.xz"

# Function to check if the file exists and matches the expected checksum
function verify_file {
    if [[ -f "$LOCAL_FILE" ]]; then
        echo "Local file exists. Verifying checksum..."
        local_checksum=$(sha256sum "$LOCAL_FILE" | awk '{print $1}')
        if [[ "$local_checksum" == "$EXPECTED_CHECKSUM" ]]; then
            echo "Checksum verified. File is valid."
            tar -xf Python-3.10.12.tar.xz
            return 0
        else
            echo "Checksum mismatch. Redownloading the file."
            rm Python-3.10.12.tar.xz
            return 1
        fi
    fi
    return 1
}

# Check if the file exists and matches the checksum
if verify_file; then
    echo "Using the existing file."
    tar -xf Python-3.10.12.tar.xz
else
    # Download the file since it either doesn't exist or checksum mismatched
    echo "Downloading the file..."
    if ! wget --no-check-certificate "$FILE_URL" -O "$LOCAL_FILE"; then
        echo "Failed to download the file."
        exit 1
    fi

    # Verify the downloaded file's checksum
    if ! verify_file; then
        echo "Checksum verification failed. Please check the downloaded file manually."
        exit 1
    fi
fi
