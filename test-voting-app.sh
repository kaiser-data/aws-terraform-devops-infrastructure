#!/bin/bash

# Voting App Test Script
# Tests the deployed voting application end-to-end

FRONTEND_IP="13.124.72.188"
VOTE_URL="http://${FRONTEND_IP}"
RESULT_URL="http://${FRONTEND_IP}:5001"

echo "========================================"
echo "  Voting App E2E Test"
echo "========================================"
echo ""

# Test 1: Check Vote App
echo "Test 1: Checking Vote App..."
VOTE_STATUS=$(curl -s -o /dev/null -w "%{http_code}" ${VOTE_URL})
if [ "$VOTE_STATUS" == "200" ]; then
    echo "✅ Vote app is responding (HTTP $VOTE_STATUS)"
else
    echo "❌ Vote app is not responding (HTTP $VOTE_STATUS)"
fi
echo ""

# Test 2: Check Result App
echo "Test 2: Checking Result App..."
RESULT_STATUS=$(curl -s -o /dev/null -w "%{http_code}" ${RESULT_URL})
if [ "$RESULT_STATUS" == "200" ]; then
    echo "✅ Result app is responding (HTTP $RESULT_STATUS)"
else
    echo "❌ Result app is not responding (HTTP $RESULT_STATUS)"
fi
echo ""

# Test 3: Submit a test vote
echo "Test 3: Submitting test vote for Cats..."
VOTE_RESPONSE=$(curl -s -X POST ${VOTE_URL}/ -d "vote=a" -H "Content-Type: application/x-www-form-urlencoded" -w "%{http_code}")
if [[ $VOTE_RESPONSE == *"200"* ]]; then
    echo "✅ Vote submitted successfully"
else
    echo "⚠️  Vote submission may have issues"
fi
echo ""

# Test 4: Check container health on all tiers
echo "Test 4: Checking container health..."
echo ""
echo "Frontend containers:"
ssh -o StrictHostKeyChecking=no frontend-instance "docker ps --format 'table {{.Names}}\t{{.Status}}'" 2>/dev/null | grep -E "vote|result"
echo ""
echo "Backend containers:"
ssh -o StrictHostKeyChecking=no backend-instance "docker ps --format 'table {{.Names}}\t{{.Status}}'" 2>/dev/null | grep -E "worker|redis"
echo ""
echo "Database containers:"
ssh -o StrictHostKeyChecking=no db-instance "docker ps --format 'table {{.Names}}\t{{.Status}}'" 2>/dev/null | grep postgres
echo ""

echo "========================================"
echo "  Test Summary"
echo "========================================"
echo ""
echo "Vote URL:   ${VOTE_URL}"
echo "Result URL: ${RESULT_URL}"
echo ""
echo "Open these URLs in your browser to test manually!"
echo ""
