#!/bin/bash

# Test script for nginx + OPA integration
set -e

echo "Testing nginx + OPA integration..."
echo "=================================="

BASE_URL="http://localhost"

# Wait for services to be ready
echo "Waiting for services to start..."
sleep 5

# Test 1: Health check (should bypass OPA)
echo "1. Testing health check endpoint..."
curl -s -w "Status: %{http_code}\n" $BASE_URL/health

# Test 2: Valid request to /hello
echo -e "\n2. Testing valid request to /hello..."
curl -s -w "Status: %{http_code}\n" \
  -H "User-Agent: Mozilla/5.0 (compatible; test)" \
  "$BASE_URL/hello?name=World"

# Test 3: Valid request to /api/status
echo -e "\n3. Testing valid request to /api/status..."
curl -s -w "Status: %{http_code}\n" \
  -H "User-Agent: Mozilla/5.0 (compatible; test)" \
  "$BASE_URL/api/status"

# Test 4: Invalid method (POST to /hello)
echo -e "\n4. Testing invalid method (POST to /hello)..."
curl -s -w "Status: %{http_code}\n" \
  -X POST \
  -H "User-Agent: Mozilla/5.0 (compatible; test)" \
  "$BASE_URL/hello"

# Test 5: Bot user agent (should be blocked)
echo -e "\n5. Testing bot user agent..."
curl -s -w "Status: %{http_code}\n" \
  -H "User-Agent: bot-crawler" \
  "$BASE_URL/hello?name=World"

# Test 6: Invalid endpoint
echo -e "\n6. Testing invalid endpoint..."
curl -s -w "Status: %{http_code}\n" \
  -H "User-Agent: Mozilla/5.0 (compatible; test)" \
  "$BASE_URL/invalid"

# Test 7: Rate limiting (make multiple requests quickly)
echo -e "\n7. Testing rate limiting..."
for i in {1..5}; do
  echo "Request $i:"
  curl -s -w "Status: %{http_code}\n" \
    -H "User-Agent: Mozilla/5.0 (compatible; test)" \
    "$BASE_URL/hello?name=Test$i"
done

# Test 8: OPA admin interface (development only)
echo -e "\n8. Testing OPA admin interface..."
curl -s -w "Status: %{http_code}\n" \
  "$BASE_URL:8080/v1/data/api/security/decision" \
  -X POST \
  -H "Content-Type: application/json" \
  -d '{"input": {"method": "GET", "path": "/hello", "query_params": {"name": "test"}, "headers": {"user-agent": "Mozilla/5.0"}, "request_count": 1, "time_window": "minute"}}'

echo -e "\n=================================="
echo "All tests completed!"
echo "Check the logs with: docker-compose logs nginx"