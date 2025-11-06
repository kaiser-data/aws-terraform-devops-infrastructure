#!/bin/bash
# Quick Test Script for Presentation Day
# Tests current deployment status

set +e  # Don't exit on errors, we want to see all results

echo "================================================"
echo "🧪 VOTING APP - QUICK HEALTH CHECK"
echo "================================================"
echo ""

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# IPs
FRONTEND_IP="3.36.116.222"
BACKEND_IP="10.0.2.75"
DATABASE_IP="10.0.2.115"

echo "📍 Infrastructure IPs:"
echo "   Frontend:  $FRONTEND_IP (public)"
echo "   Backend:   $BACKEND_IP (private)"
echo "   Database:  $DATABASE_IP (private)"
echo ""

# Test 1: SSH Connectivity
echo "================================================"
echo "TEST 1: SSH Connectivity"
echo "================================================"

echo -n "Frontend SSH: "
if ssh -o ConnectTimeout=5 -o StrictHostKeyChecking=no frontend-instance "echo 'OK'" 2>/dev/null; then
    echo -e "${GREEN}✅ Connected${NC}"
else
    echo -e "${RED}❌ Failed${NC}"
fi

echo -n "Backend SSH:  "
if ssh -o ConnectTimeout=5 -o StrictHostKeyChecking=no backend-instance "echo 'OK'" 2>/dev/null; then
    echo -e "${GREEN}✅ Connected${NC}"
else
    echo -e "${RED}❌ Failed${NC}"
fi

echo -n "Database SSH: "
if ssh -o ConnectTimeout=5 -o StrictHostKeyChecking=no db-instance "echo 'OK'" 2>/dev/null; then
    echo -e "${GREEN}✅ Connected${NC}"
else
    echo -e "${RED}❌ Failed${NC}"
fi
echo ""

# Test 2: Docker Status
echo "================================================"
echo "TEST 2: Docker Installation"
echo "================================================"

echo -n "Frontend Docker: "
DOCKER_VERSION=$(ssh -o ConnectTimeout=5 frontend-instance "docker --version 2>/dev/null" 2>/dev/null)
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Installed ($DOCKER_VERSION)${NC}"
else
    echo -e "${RED}❌ Not installed${NC}"
fi

echo -n "Backend Docker:  "
DOCKER_VERSION=$(ssh -o ConnectTimeout=5 backend-instance "docker --version 2>/dev/null" 2>/dev/null)
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Installed ($DOCKER_VERSION)${NC}"
else
    echo -e "${RED}❌ Not installed${NC}"
fi

echo -n "Database Docker: "
DOCKER_VERSION=$(ssh -o ConnectTimeout=5 db-instance "docker --version 2>/dev/null" 2>/dev/null)
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Installed ($DOCKER_VERSION)${NC}"
else
    echo -e "${RED}❌ Not installed${NC}"
fi
echo ""

# Test 3: Running Containers
echo "================================================"
echo "TEST 3: Running Containers"
echo "================================================"

echo "Frontend containers:"
ssh frontend-instance "docker ps --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}' 2>/dev/null" 2>/dev/null || echo -e "${RED}  ❌ Cannot check containers${NC}"
echo ""

echo "Backend containers:"
ssh backend-instance "docker ps --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}' 2>/dev/null" 2>/dev/null || echo -e "${RED}  ❌ Cannot check containers${NC}"
echo ""

echo "Database containers:"
ssh db-instance "docker ps --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}' 2>/dev/null" 2>/dev/null || echo -e "${RED}  ❌ Cannot check containers${NC}"
echo ""

# Test 4: Web Application Accessibility
echo "================================================"
echo "TEST 4: Web Application Access"
echo "================================================"

echo -n "Vote App (port 80):   "
HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout 5 http://$FRONTEND_IP:80 2>/dev/null)
if [ "$HTTP_STATUS" = "200" ]; then
    echo -e "${GREEN}✅ Accessible (HTTP $HTTP_STATUS)${NC}"
else
    echo -e "${RED}❌ Not accessible (HTTP $HTTP_STATUS)${NC}"
fi

echo -n "Result App (port 5001): "
HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout 5 http://$FRONTEND_IP:5001 2>/dev/null)
if [ "$HTTP_STATUS" = "200" ]; then
    echo -e "${GREEN}✅ Accessible (HTTP $HTTP_STATUS)${NC}"
else
    echo -e "${RED}❌ Not accessible (HTTP $HTTP_STATUS)${NC}"
fi
echo ""

# Test 5: Redis Connectivity
echo "================================================"
echo "TEST 5: Service Connectivity (from Frontend)"
echo "================================================"

echo -n "Redis connectivity (Backend): "
REDIS_TEST=$(ssh frontend-instance "timeout 2 bash -c '</dev/tcp/$BACKEND_IP/6379' 2>/dev/null && echo 'OK'" 2>/dev/null)
if [ "$REDIS_TEST" = "OK" ]; then
    echo -e "${GREEN}✅ Reachable${NC}"
else
    echo -e "${RED}❌ Not reachable${NC}"
fi

echo -n "PostgreSQL connectivity (Database): "
POSTGRES_TEST=$(ssh frontend-instance "timeout 2 bash -c '</dev/tcp/$DATABASE_IP/5432' 2>/dev/null && echo 'OK'" 2>/dev/null)
if [ "$POSTGRES_TEST" = "OK" ]; then
    echo -e "${GREEN}✅ Reachable${NC}"
else
    echo -e "${RED}❌ Not reachable${NC}"
fi
echo ""

# Summary
echo "================================================"
echo "📊 QUICK ACCESS LINKS"
echo "================================================"
echo "Vote App:   http://$FRONTEND_IP:80"
echo "Result App: http://$FRONTEND_IP:5001"
echo ""
echo "================================================"
echo "🔍 DETAILED LOGS (if needed)"
echo "================================================"
echo "cd ansible"
echo "ansible-playbook playbooks/check-logs.yml"
echo ""
