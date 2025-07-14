#!/bin/bash

# Script to test OPA policies locally

set -e

echo "Testing OPA policies..."

# Test policy syntax
echo "Validating policy syntax..."
opa fmt --diff policies/

# Run policy tests
echo "Running policy tests..."
opa test policies/ test/

# Test API security policy with valid request
echo "Testing API security policy - valid request..."
VALID_REQUEST='{"method": "GET", "path": "/hello", "query_params": {"name": "test"}, "headers": {"user-agent": "Mozilla/5.0"}, "request_count": 10, "time_window": "minute"}'
echo "$VALID_REQUEST" | opa eval -d policies/api_security.rego "data.api.security.decision" --stdin-input --format pretty

# Test API security policy with invalid request
echo "Testing API security policy - invalid request..."
INVALID_REQUEST='{"method": "POST", "path": "/hello", "query_params": {}, "headers": {"user-agent": "bot-crawler"}, "request_count": 150, "time_window": "minute"}'
echo "$INVALID_REQUEST" | opa eval -d policies/api_security.rego "data.api.security.decision" --stdin-input --format pretty

# Test deployment policy - production deployment
echo "Testing deployment policy - production deployment..."
PROD_DEPLOYMENT='{"environment": "production", "branch": "main", "tests_passed": true, "security_scan_passed": true, "code_coverage": 85, "has_security_review": true, "container": {"run_as_non_root": true, "read_only_root_fs": true, "privileged": false}}'
echo "$PROD_DEPLOYMENT" | opa eval -d policies/deployment.rego "data.deployment.security.decision" --stdin-input --format pretty

# Test deployment policy - invalid production deployment
echo "Testing deployment policy - invalid production deployment..."
INVALID_PROD_DEPLOYMENT='{"environment": "production", "branch": "feature/test", "tests_passed": false, "security_scan_passed": false, "code_coverage": 60, "has_security_review": false, "container": {"run_as_non_root": false, "read_only_root_fs": false, "privileged": true}}'
echo "$INVALID_PROD_DEPLOYMENT" | opa eval -d policies/deployment.rego "data.deployment.security.decision" --stdin-input --format pretty

echo "All OPA policy tests completed!"