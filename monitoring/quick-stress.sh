#!/bin/bash
# Quick Stress Test - Random voting (60% Cats, 40% Dogs)
# Usage: ./quick-stress.sh [votes] [parallel]
# Example: ./quick-stress.sh 100 10

VOTE_URL="http://${FRONTEND_IP}:80"
VOTES=${1:-100}
PARALLEL=${2:-10}

echo "🔥 Quick Stress Test - Random Voting"
echo "Votes: $VOTES | Parallel: $PARALLEL"
echo "Distribution: 60% Cats 🐱, 40% Dogs 🐶"
echo ""
echo "Starting in 3 seconds..."
sleep 3

echo -n "Sending votes: "
START=$(date +%s)

# Random voting: 60% cats (a), 40% dogs (b)
export VOTE_URL
seq 1 ${VOTES} | xargs -I{} -P ${PARALLEL} bash -c '
  RAND=$((RANDOM % 100))
  if [ $RAND -lt 60 ]; then
    VOTE="a"
  else
    VOTE="b"
  fi
  curl -s -X POST -d "vote=$VOTE" "$VOTE_URL"/ > /dev/null 2>&1 && echo -n "."
'

END=$(date +%s)
DURATION=$((END - START))

echo ""
echo ""
echo "✅ Complete!"
echo "Duration: ${DURATION}s"
echo "Rate: $(echo "scale=2; ${VOTES} / ${DURATION}" | bc) votes/sec"
echo ""
echo "📊 Check results at: http://${FRONTEND_IP}:5001"
