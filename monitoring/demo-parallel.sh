#!/bin/bash
# Simple demo: Sequential vs Parallel

echo "=== DEMO: Sequential vs Parallel ==="
echo ""
echo "Test: 10 votes to show the difference"
echo ""

# Sequential
echo "1️⃣  SEQUENTIAL (one at a time):"
START=$(date +%s)
for i in {1..10}; do
    curl -s -X POST -d "vote=a" http://3.36.116.222:80/ > /dev/null
    echo -n "▓"
done
END=$(date +%s)
SEQ_TIME=$((END - START))
echo ""
echo "   Time: ${SEQ_TIME} seconds"
echo ""

sleep 2

# Parallel
echo "2️⃣  PARALLEL (10 at once with -P 10):"
START=$(date +%s)
seq 1 10 | xargs -I{} -P 10 sh -c "curl -s -X POST -d 'vote=a' http://3.36.116.222:80/ > /dev/null && echo -n '▓'"
END=$(date +%s)
PAR_TIME=$((END - START))
echo ""
echo "   Time: ${PAR_TIME} seconds"
echo ""

# Summary
echo "═══════════════════════════════════"
echo "📊 RESULTS:"
echo "   Sequential: ${SEQ_TIME}s"
echo "   Parallel:   ${PAR_TIME}s"
echo "   Speedup:    $((SEQ_TIME / PAR_TIME))x faster!"
echo "═══════════════════════════════════"
