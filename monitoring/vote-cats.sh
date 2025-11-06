#!/bin/bash
# Vote for Cats - Send specific votes for option A
# Usage: ./vote-cats.sh [votes] [parallel]
# Example: ./vote-cats.sh 1000 40

VOTE_URL="http://${FRONTEND_IP}:80"
VOTES=${1:-1000}
PARALLEL=${2:-40}

echo "🐱 Voting for CATS!"
echo "Votes: $VOTES | Parallel: $PARALLEL"
echo ""
echo "Starting in 3 seconds..."
sleep 3

echo -n "Sending cat votes: "
START=$(date +%s)

export VOTE_URL
seq 1 ${VOTES} | xargs -I{} -P ${PARALLEL} bash -c '
  curl -s -X POST -d "vote=a" "$VOTE_URL"/ > /dev/null 2>&1 && echo -n "."
'

END=$(date +%s)
DURATION=$((END - START))

echo ""
echo ""
echo "✅ Complete!"
echo "Duration: ${DURATION}s"
echo "Rate: $(echo "scale=2; ${VOTES} / ${DURATION}" | bc) votes/sec"
echo ""
echo "🐱 All votes for CATS!"
echo "📊 Check results at: http://${FRONTEND_IP}:5001"
