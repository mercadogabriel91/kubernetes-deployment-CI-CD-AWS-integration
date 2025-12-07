#!/bin/bash

# Test script for local development
# Make sure both services are running before testing

echo "Testing Main API and Auxiliary Service"
echo "=========================================="
echo ""

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

MAIN_API_URL="http://localhost:3000"
AUX_SERVICE_URL="http://localhost:3001"

# Test Auxiliary Service Health
echo "1. Testing Auxiliary Service Health..."
response=$(curl -s -o /dev/null -w "%{http_code}" $AUX_SERVICE_URL/health)
if [ "$response" == "200" ]; then
    echo -e "${GREEN}[OK] Auxiliary Service is healthy${NC}"
else
    echo -e "${RED}[ERROR] Auxiliary Service is not responding (HTTP $response)${NC}"
    echo "   Make sure Auxiliary Service is running on port 3001"
    exit 1
fi

# Test Main API Health
echo ""
echo "2. Testing Main API Health..."
response=$(curl -s -o /dev/null -w "%{http_code}" $MAIN_API_URL/health)
if [ "$response" == "200" ]; then
    echo -e "${GREEN}[OK] Main API is healthy${NC}"
else
    echo -e "${RED}[ERROR] Main API is not responding (HTTP $response)${NC}"
    echo "   Make sure Main API is running on port 3000"
    exit 1
fi

# Test Auxiliary Service Version
echo ""
echo "3. Testing Auxiliary Service Version..."
curl -s $AUX_SERVICE_URL/version | python3 -m json.tool

# Test Main API - List Buckets
echo ""
echo "4. Testing Main API - List Buckets..."
echo "   GET $MAIN_API_URL/buckets"
curl -s $MAIN_API_URL/buckets | python3 -m json.tool

# Test Main API - List Parameters
echo ""
echo "5. Testing Main API - List Parameters..."
echo "   GET $MAIN_API_URL/parameters"
curl -s $MAIN_API_URL/parameters | python3 -m json.tool

# Test Main API - Get Specific Parameter (if exists)
echo ""
echo "6. Testing Main API - Get Parameter..."
echo "   GET $MAIN_API_URL/parameters/kantox-challenge/app-version"
curl -s $MAIN_API_URL/parameters/kantox-challenge/app-version | python3 -m json.tool

echo ""
echo "=========================================="
echo -e "${GREEN}[OK] All tests completed!${NC}"

