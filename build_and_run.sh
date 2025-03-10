#!/bin/bash
set -e

# --- Compilation using Docker ---
echo "Compiling lsm-block..."
docker run -it -v "$(pwd)/lsm-block/:/src/" ghcr.io/eunomia-bpf/ecc-$(uname -m):latest

echo "Compiling lsm-connect..."
docker run -it -v "$(pwd)/lsm-connect/:/src/" ghcr.io/eunomia-bpf/ecc-$(uname -m):latest

# --- Testing lsm-block ---
echo "========================================"
echo "Running lsm-block with ecli and testing..."
echo "========================================"
cd ./lsm-block/

# Launch ecli in the background and capture its PID.
sudo ecli run package.json &
ECLI_PID=$!
echo "ecli started (PID: $ECLI_PID)"

# Allow time for the eBPF program to load.
sleep 2

# Run the ping test that automates the ping test and computes average execution time.
bash ../test_ping_avg.sh

# Terminate the ecli process after testing.
echo "Terminating ecli for lsm-block..."
sudo kill $ECLI_PID

# Return to the root directory.
cd ..

# --- Testing lsm-connect ---
echo "========================================"
echo "Running lsm-connect with ecli and testing..."
echo "========================================"
cd ./lsm-connect/

sudo ecli run package.json &
ECLI_PID=$!
echo "ecli started (PID: $ECLI_PID)"

sleep 2

bash ../test_ping_avg.sh

echo "Terminating ecli for lsm-connect..."
sudo kill $ECLI_PID

# Return to the root directory.
cd ..

echo "========================================"
echo "Build and test completed."
echo "========================================"
