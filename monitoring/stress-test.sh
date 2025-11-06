#!/bin/bash
# Voting App Stress Test - Test Infrastructure Limits
# Shows system performance under various load levels

VOTE_URL="http://${FRONTEND_IP}:80"
RESULT_URL="http://${FRONTEND_IP}:5001"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Function to submit a single vote
submit_vote() {
    local vote=$1
    curl -s -X POST -d "vote=${vote}" ${VOTE_URL}/ > /dev/null 2>&1
    echo -n "."
}

# Function to get current vote count from database
get_vote_count() {
    ssh db-instance "docker exec postgres psql -U postgres -d postgres -t -c 'SELECT COUNT(*) FROM votes;'" 2>/dev/null | tr -d ' '
}

# Function to monitor system during test
monitor_system() {
    echo ""
    echo -e "${CYAN}📊 Real-time System Stats:${NC}"
    echo "Frontend CPU: $(ssh frontend-instance "top -bn1 | grep 'Cpu(s)' | awk '{print 100-\$8\"%\"}'" 2>/dev/null)"
    echo "Backend CPU:  $(ssh backend-instance "top -bn1 | grep 'Cpu(s)' | awk '{print 100-\$8\"%\"}'" 2>/dev/null)"
}

export -f submit_vote
export VOTE_URL

clear
echo -e "${PURPLE}╔════════════════════════════════════════════════════════╗${NC}"
echo -e "${PURPLE}║         🔥 VOTING APP STRESS TEST 🔥                  ║${NC}"
echo -e "${PURPLE}║    Test Infrastructure Limits & Performance           ║${NC}"
echo -e "${PURPLE}╚════════════════════════════════════════════════════════╝${NC}"
echo ""

# Get initial vote count
echo -e "${CYAN}📊 Getting initial vote count...${NC}"
INITIAL_COUNT=$(get_vote_count)
echo -e "Current votes in database: ${GREEN}${INITIAL_COUNT}${NC}"
echo ""

# Menu
echo -e "${YELLOW}Choose stress test level:${NC}"
echo ""
echo -e "${GREEN}1)${NC} 🟢 LIGHT     - 100 votes in ~10 seconds (10 votes/sec)"
echo -e "${YELLOW}2)${NC} 🟡 MODERATE  - 500 votes in ~25 seconds (20 votes/sec)"
echo -e "${RED}3)${NC} 🔴 HEAVY     - 1000 votes in ~25 seconds (40 votes/sec)"
echo -e "${PURPLE}4)${NC} 💥 EXTREME   - 2000 votes in ~40 seconds (50 votes/sec)"
echo -e "${CYAN}5)${NC} 🚀 INSANE    - 5000 votes as fast as possible (NO LIMIT!)"
echo -e "${BLUE}6)${NC} 🎯 CUSTOM    - Choose your own parameters"
echo ""
echo -e "${CYAN}0)${NC} Cancel"
echo ""
read -p "Enter choice [0-6]: " choice

case $choice in
    1)
        VOTES=100
        PARALLEL=10
        LEVEL="LIGHT 🟢"
        ;;
    2)
        VOTES=500
        PARALLEL=20
        LEVEL="MODERATE 🟡"
        ;;
    3)
        VOTES=1000
        PARALLEL=40
        LEVEL="HEAVY 🔴"
        ;;
    4)
        VOTES=2000
        PARALLEL=50
        LEVEL="EXTREME 💥"
        ;;
    5)
        VOTES=5000
        PARALLEL=100
        LEVEL="INSANE 🚀"
        ;;
    6)
        echo ""
        read -p "Number of votes: " VOTES
        read -p "Parallel requests: " PARALLEL
        LEVEL="CUSTOM 🎯"
        ;;
    0)
        echo "Cancelled."
        exit 0
        ;;
    *)
        echo "Invalid choice"
        exit 1
        ;;
esac

echo ""
echo -e "${PURPLE}═══════════════════════════════════════════════════════${NC}"
echo -e "${YELLOW}Test Configuration:${NC}"
echo -e "  Level: ${LEVEL}"
echo -e "  Total Votes: ${GREEN}${VOTES}${NC}"
echo -e "  Parallel Requests: ${GREEN}${PARALLEL}${NC}"
echo -e "  Target Rate: ~${GREEN}$(( VOTES / (VOTES / PARALLEL / 2) ))${NC} votes/second"
echo -e "${PURPLE}═══════════════════════════════════════════════════════${NC}"
echo ""
echo -e "${CYAN}💡 TIP: Open Grafana now to watch real-time metrics!${NC}"
echo -e "   ${VOTE_URL}:3000/d/voting-app-demo"
echo ""
read -p "Press Enter to start stress test..."

echo ""
echo -e "${RED}🔥 STRESS TEST STARTING... 🔥${NC}"
echo ""

# Start timer
START_TIME=$(date +%s)

# Generate votes - Random voting (60% Cats, 40% Dogs)
echo -e "${YELLOW}Submitting ${VOTES} votes with ${PARALLEL} parallel connections...${NC}"
echo -e "${CYAN}Distribution: 60% Cats 🐱, 40% Dogs 🐶${NC}"
echo -n "Progress: "

# Use GNU parallel if available, otherwise use xargs
export VOTE_URL
if command -v parallel &> /dev/null; then
    # Use GNU parallel for better performance with random voting
    seq 1 ${VOTES} | parallel -j ${PARALLEL} -n0 bash -c '
      RAND=$((RANDOM % 100))
      if [ $RAND -lt 60 ]; then
        VOTE="a"
      else
        VOTE="b"
      fi
      curl -s -X POST -d "vote=$VOTE" "$VOTE_URL"/ > /dev/null 2>&1 && echo -n "."
    '
else
    # Fallback to xargs with random voting
    seq 1 ${VOTES} | xargs -I{} -P ${PARALLEL} bash -c '
      RAND=$((RANDOM % 100))
      if [ $RAND -lt 60 ]; then
        VOTE="a"
      else
        VOTE="b"
      fi
      curl -s -X POST -d "vote=$VOTE" "$VOTE_URL"/ > /dev/null 2>&1 && echo -n "."
    '
fi

# End timer
END_TIME=$(date +%s)
DURATION=$((END_TIME - START_TIME))

echo ""
echo ""
echo -e "${GREEN}✅ Stress test completed!${NC}"
echo ""

# Calculate statistics
VOTES_PER_SEC=$(echo "scale=2; ${VOTES} / ${DURATION}" | bc)

echo -e "${PURPLE}═══════════════════════════════════════════════════════${NC}"
echo -e "${YELLOW}📊 Test Results:${NC}"
echo -e "${PURPLE}═══════════════════════════════════════════════════════${NC}"
echo -e "  Total Votes Sent:     ${GREEN}${VOTES}${NC}"
echo -e "  Duration:             ${GREEN}${DURATION}${NC} seconds"
echo -e "  Throughput:           ${GREEN}${VOTES_PER_SEC}${NC} votes/second"
echo -e "  Parallel Connections: ${GREEN}${PARALLEL}${NC}"
echo -e "${PURPLE}═══════════════════════════════════════════════════════${NC}"
echo ""

# Wait for processing
echo -e "${CYAN}⏳ Waiting 10 seconds for Worker to process votes...${NC}"
for i in {10..1}; do
    echo -ne "   ${i}...\r"
    sleep 1
done
echo ""

# Get final vote count
echo -e "${CYAN}📊 Checking database...${NC}"
FINAL_COUNT=$(get_vote_count)
NEW_VOTES=$((FINAL_COUNT - INITIAL_COUNT))

echo ""
echo -e "${PURPLE}═══════════════════════════════════════════════════════${NC}"
echo -e "${YELLOW}💾 Database Results:${NC}"
echo -e "${PURPLE}═══════════════════════════════════════════════════════${NC}"
echo -e "  Initial Count:  ${GREEN}${INITIAL_COUNT}${NC}"
echo -e "  Final Count:    ${GREEN}${FINAL_COUNT}${NC}"
echo -e "  New Votes:      ${GREEN}${NEW_VOTES}${NC}"
echo -e "  Success Rate:   ${GREEN}$(echo "scale=2; ${NEW_VOTES} * 100 / ${VOTES}" | bc)%${NC}"
echo -e "${PURPLE}═══════════════════════════════════════════════════════${NC}"
echo ""

# Performance analysis
echo -e "${YELLOW}🎯 Performance Analysis:${NC}"
if (( $(echo "${VOTES_PER_SEC} > 30" | bc -l) )); then
    echo -e "  ${GREEN}✅ EXCELLENT${NC} - System handled high load well!"
elif (( $(echo "${VOTES_PER_SEC} > 15" | bc -l) )); then
    echo -e "  ${YELLOW}⚠️  GOOD${NC} - System performed adequately"
else
    echo -e "  ${RED}❌ STRESSED${NC} - System struggled under load"
fi
echo ""

# Show what to check
echo -e "${CYAN}🔍 What to check in Grafana:${NC}"
echo -e "  • Network traffic spike on Frontend"
echo -e "  • CPU usage spike on Backend (Worker processing)"
echo -e "  • Database connections and writes"
echo -e "  • Memory usage patterns"
echo -e "  • System load averages"
echo ""
echo -e "${CYAN}🔗 Quick Links:${NC}"
echo -e "  Vote App:   ${VOTE_URL}"
echo -e "  Results:    ${RESULT_URL}"
echo -e "  Grafana:    http://${FRONTEND_IP}:3000/d/voting-app-demo"
echo -e "  Prometheus: http://${FRONTEND_IP}:9090/targets"
echo ""

# Save results to file
RESULTS_FILE="stress-test-results-$(date +%Y%m%d-%H%M%S).txt"
cat > ${RESULTS_FILE} << EOF
Voting App Stress Test Results
================================
Date: $(date)
Level: ${LEVEL}

Test Parameters:
- Total Votes: ${VOTES}
- Parallel Connections: ${PARALLEL}
- Duration: ${DURATION} seconds
- Throughput: ${VOTES_PER_SEC} votes/second

Database Results:
- Initial Count: ${INITIAL_COUNT}
- Final Count: ${FINAL_COUNT}
- New Votes: ${NEW_VOTES}
- Success Rate: $(echo "scale=2; ${NEW_VOTES} * 100 / ${VOTES}" | bc)%
EOF

echo -e "${GREEN}📝 Results saved to: ${RESULTS_FILE}${NC}"
echo ""
