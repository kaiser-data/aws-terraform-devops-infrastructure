#!/bin/bash
# Generate demo voting activity for presentation

VOTE_URL="http://${FRONTEND_IP}:80"
RESULT_URL="http://${FRONTEND_IP}:5001"

echo "🗳️  Generating demo voting activity..."
echo ""
echo "This will:"
echo "  - Submit 50 votes (mix of Cats and Dogs)"
echo "  - Show real-time metrics in Grafana"
echo "  - Demonstrate data flow through all tiers"
echo ""
read -p "Press Enter to start voting..."

# Send 50 votes
for i in {1..50}; do
    # Alternate between cats and dogs with some randomness
    if [ $((i % 3)) -eq 0 ]; then
        VOTE="b"  # Dogs
        CHOICE="Dogs 🐕"
    else
        VOTE="a"  # Cats
        CHOICE="Cats 🐱"
    fi

    echo "Vote #$i: $CHOICE"

    curl -s -X POST \
        -d "vote=${VOTE}" \
        ${VOTE_URL} > /dev/null

    # Small delay to see activity in real-time
    sleep 0.2
done

echo ""
echo "✅ Voting complete! 50 votes submitted"
echo ""
echo "📊 Check the results:"
echo "   Vote App:   ${VOTE_URL}"
echo "   Result App: ${RESULT_URL}"
echo ""
echo "📈 View metrics in Grafana:"
echo "   http://${FRONTEND_IP}:3000/d/voting-app-demo"
echo ""
echo "You should see:"
echo "  ✅ Network traffic spike on Frontend"
echo "  ✅ CPU activity on Backend (Worker processing)"
echo "  ✅ Database writes on Database tier"
