#!/bin/bash
# Demo: How Parallel Connections Work

echo "═══════════════════════════════════════════════════════"
echo "Understanding Parallel Connections"
echo "═══════════════════════════════════════════════════════"
echo ""

# ============================================
# METHOD 1: Sequential (Slow) - One at a time
# ============================================
echo "📍 METHOD 1: SEQUENTIAL (Slow)"
echo "Each request waits for the previous one to finish"
echo ""
echo "Starting 5 sequential requests..."
START=$(date +%s)

for i in {1..5}; do
    echo "  Request $i - starting..."
    curl -s -X POST -d "vote=a" http://${FRONTEND_IP}:80/ > /dev/null
    echo "  Request $i - done!"
done

END=$(date +%s)
DURATION=$((END - START))
echo ""
echo "⏱️  Sequential Duration: ${DURATION} seconds"
echo ""
echo "Timeline:"
echo "  Req1 ▓▓▓▓▓▓ (done, then Req2 starts)"
echo "          Req2 ▓▓▓▓▓▓ (done, then Req3 starts)"
echo "                  Req3 ▓▓▓▓▓▓ (done, then Req4 starts)"
echo "                          Req4 ▓▓▓▓▓▓"
echo "                                  Req5 ▓▓▓▓▓▓"
echo ""
echo "Total time: ${DURATION}s (each waits for previous)"
echo ""
echo "═══════════════════════════════════════════════════════"
echo ""
sleep 2

# ============================================
# METHOD 2: Parallel (Fast) - All at once
# ============================================
echo "📍 METHOD 2: PARALLEL (Fast)"
echo "All requests happen simultaneously!"
echo ""
echo "Starting 5 parallel requests..."
START=$(date +%s)

# The magic command: xargs with -P flag
seq 1 5 | xargs -I{} -P 5 sh -c "echo '  Request {} - starting...' && curl -s -X POST -d 'vote=a' http://${FRONTEND_IP}:80/ > /dev/null && echo '  Request {} - done!'"

END=$(date +%s)
DURATION=$((END - START))
echo ""
echo "⏱️  Parallel Duration: ${DURATION} seconds"
echo ""
echo "Timeline:"
echo "  Req1 ▓▓▓▓▓▓"
echo "  Req2 ▓▓▓▓▓▓  (all running at same time!)"
echo "  Req3 ▓▓▓▓▓▓"
echo "  Req4 ▓▓▓▓▓▓"
echo "  Req5 ▓▓▓▓▓▓"
echo ""
echo "Total time: ${DURATION}s (all requests overlap)"
echo ""
echo "═══════════════════════════════════════════════════════"
echo ""

# ============================================
# EXPLANATION
# ============================================
echo "🎓 HOW IT WORKS:"
echo ""
echo "The key is the 'xargs' command with the -P flag:"
echo ""
echo "  seq 1 100                    → Generate numbers 1 to 100"
echo "  |                            → Pipe to next command"
echo "  xargs -P 25                  → Run with 25 parallel processes"
echo "  sh -c 'curl ...'             → Execute curl for each number"
echo ""
echo "The -P flag tells xargs: 'Run up to 25 processes at once'"
echo ""
echo "═══════════════════════════════════════════════════════"
echo ""
echo "💡 REAL EXAMPLE:"
echo ""
echo "Command: seq 1 100 | xargs -I{} -P 25 sh -c 'curl ...'"
echo ""
echo "What happens:"
echo "  1. Generate 100 numbers (1, 2, 3, ... 100)"
echo "  2. xargs spawns 25 curl processes immediately"
echo "  3. As each finishes, xargs starts the next one"
echo "  4. Always maintains 25 parallel connections"
echo "  5. Until all 100 requests complete"
echo ""
echo "Timeline with 100 requests, 25 parallel:"
echo ""
echo "  Time 0s:  Processes 1-25 running   ▓▓▓▓▓▓"
echo "  Time 2s:  Processes 26-50 running  ▓▓▓▓▓▓"
echo "  Time 4s:  Processes 51-75 running  ▓▓▓▓▓▓"
echo "  Time 6s:  Processes 76-100 running ▓▓▓▓▓▓"
echo ""
echo "  Total time: ~6s (instead of ~60s sequential)"
echo ""
echo "═══════════════════════════════════════════════════════"
