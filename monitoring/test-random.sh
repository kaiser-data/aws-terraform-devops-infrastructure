#!/bin/bash
# Test random voting logic

VOTE_URL="http://${FRONTEND_IP}:80"
CATS=0
DOGS=0

echo "Testing random voting logic with 20 samples..."
echo ""

for i in {1..20}; do
  RAND=$((RANDOM % 100))
  if [ $RAND -lt 60 ]; then
    VOTE="a"
    CATS=$((CATS + 1))
    echo -n "🐱"
  else
    VOTE="b"
    DOGS=$((DOGS + 1))
    echo -n "🐶"
  fi
done

echo ""
echo ""
echo "Results:"
echo "Cats: $CATS ($(echo "scale=1; $CATS * 100 / 20" | bc)%)"
echo "Dogs: $DOGS ($(echo "scale=1; $DOGS * 100 / 20" | bc)%)"
echo ""

if [ $DOGS -gt 0 ]; then
  echo "✅ Random voting logic is working! Both cats and dogs present."
else
  echo "❌ Only cats - random logic broken"
fi
