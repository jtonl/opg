# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a demonstration project showing how to integrate Open Policy Agent (OPA) with a simple PHP API in a GitHub Actions CI/CD pipeline. The project implements policy-as-code for both API request validation and deployment security.

## Architecture

The project has a dual-layer architecture:

1. **Application Layer**: Simple PHP API (`public/index.php`) with basic routing that serves two endpoints:
   - `GET /hello?name=World` - Returns JSON hello message
   - `GET /api/status` - Returns health status

2. **Policy Layer**: OPA policies written in Rego that validate:
   - API requests (`policies/api_security.rego`) - method/path authorization, rate limiting, query params, security headers
   - Deployments (`policies/deployment.rego`) - environment/branch restrictions, production security checks, container security

The policies follow a "default deny" security model and provide detailed decision reasoning. Both layers are integrated in the CI/CD pipeline for testing and runtime enforcement.

## Key Commands

### Development
```bash
# Start the PHP application
php -S localhost:8000 -t public

# Test API endpoints
curl http://localhost:8000/hello?name=World
curl http://localhost:8000/api/status
```

### OPA Policy Development
```bash
# Test all policies
opa test policies/ test/

# Validate policy syntax
opa fmt --diff policies/

# Test specific policy with input
echo '{"method": "GET", "path": "/hello", "query_params": {"name": "test"}, "headers": {"user-agent": "Mozilla/5.0"}, "request_count": 10, "time_window": "minute"}' | opa eval -d policies/api_security.rego "data.api.security.decision" -I

# Run local OPA test script
./scripts/test-opa.sh
```

### Docker Development
```bash
# Start application with OPA server
docker-compose up

# OPA server runs on port 8181
curl -X POST http://localhost:8181/v1/data/api/security/decision -H "Content-Type: application/json" -d '{"input": {...}}'
```

## Important Technical Details

### OPA Version Compatibility
- Uses OPA 0.57.0 (specified in GitHub Actions)
- Policies use older Rego syntax (no `import rego.v1`, `=` instead of `:=`, rule conditions in body)
- Use `-I` flag instead of `--input-stdin` for policy evaluation

### Policy Input Structure
API Security Policy expects:
```json
{
  "method": "GET",
  "path": "/hello",
  "query_params": {"name": "value"},
  "headers": {"user-agent": "value"},
  "request_count": 10,
  "time_window": "minute"
}
```

Deployment Policy expects:
```json
{
  "environment": "production",
  "branch": "main",
  "tests_passed": true,
  "security_scan_passed": true,
  "code_coverage": 85,
  "has_security_review": true,
  "container": {
    "run_as_non_root": true,
    "read_only_root_fs": true,
    "privileged": false
  }
}
```

### CI/CD Pipeline Structure
The GitHub Actions workflow has 5 jobs that run in sequence:
1. `test` - Tests PHP application endpoints
2. `opa-policy-test` - Tests OPA policies and syntax
3. `security-validation` - Tests policies against live application
4. `deploy` - Validates deployment with OPA and builds container
5. `runtime-policy-server` - Starts OPA server for runtime enforcement (production only)

### Branch and Environment Restrictions
- `development`: `develop`, `feature/test` branches
- `staging`: `staging`, `release/test` branches  
- `production`: `main`, `master` branches

Production deployments require additional security checks (tests passed, security scan, 80%+ code coverage, security review).