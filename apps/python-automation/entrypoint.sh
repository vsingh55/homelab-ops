#!/bin/bash
set -e

# Ensure directory structure exists in the mounted volume
mkdir -p data/input data/output logs

# If samples do not exist, create them
if [ ! -f data/input/sample_run_01.xlsx ]; then
    echo "Sample files not found in mounted volume, generating..."
    python create_samples.py
fi

# Run the requested command
exec "$@"
