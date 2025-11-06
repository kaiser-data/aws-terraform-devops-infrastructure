#!/bin/bash
# Vote for Dogs - Send specific votes for option B
# Usage: ./vote-dogs.sh [votes] [parallel]
# Example: ./vote-dogs.sh 1000 40

VOTE_URL="http://3.36.116.222:80"
VOTES=${1:-1000}
PARALLEL=${2:-40}

echo "🐶 Voting for DOGS!"
echo "Votes: $VOTES | Parallel: $PARALLEL"
echo ""
echo "Starting in 3 seconds..."
sleep 3

echo -n "Sending dog votes: "
START=$(date +%s)

export VOTE_URL
seq 1 ${VOTES} | xargs -I{} -P ${PARALLEL} bash -c '
  curl -s -X POST -d "vote=b" "$VOTE_URL"/ > /dev/null 2>&1 && echo -n "."
'

END=$(date +%s)
DURATION=$((END - START))

echo ""
echo ""
echo "✅ Complete!"
echo "Duration: ${DURATION}s"
echo "Rate: $(echo "scale=2; ${VOTES} / ${DURATION}" | bc) votes/sec"
echo ""
echo "🐶 All votes for DOGS!"
echo "📊 Check results at: http://3.36.116.222:5001"
