#!/bin/bash
# Filename: test_ping_avg.sh

echo "========================================"
echo "Starting ping test (this may take a while)..."
echo "========================================"

# Create a temporary file to store trace_pipe output.
TRACEFILE=$(mktemp)

# Start capturing trace_pipe output in the background.
sudo cat /sys/kernel/debug/tracing/trace_pipe > "$TRACEFILE" &
TRACE_PID=$!

# Give trace_pipe a moment to start.
sleep 1

# Run the ping test 1000 times.
for i in {1..10000}; do
    # Each ping should be blocked by your eBPF program.
    ping -c 1 1.1.1.1 > /dev/null 2>&1
    sleep 0.01
done

# Allow time for any remaining trace output.
sleep 2

# Stop capturing trace_pipe output.
sudo kill $TRACE_PID

# Process the trace output.
TOTAL_TIME=$(grep "lsm: blocking" "$TRACEFILE" | awk -F 'exec time: ' '{print $2}' | awk '{sum += $1} END {print sum}')
COUNT=$(grep "lsm: blocking" "$TRACEFILE" | wc -l)

echo "========================================"
echo "TEST RESULT:"
if [ "$COUNT" -gt 0 ]; then
    AVG=$(echo "scale=2; $TOTAL_TIME / $COUNT" | bc)
    echo "Total tests: $COUNT"
    echo "Total accumulated time: ${TOTAL_TIME} ns"
    echo "Average execution time: ${AVG} ns"
else
    echo "No trace lines matching 'lsm: blocking' were found."
fi
echo "========================================"

# Clean up the temporary file.
rm "$TRACEFILE"
