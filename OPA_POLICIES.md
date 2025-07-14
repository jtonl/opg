# Open Policy Agent (OPA) Policies Documentation

This document provides comprehensive documentation for the OPA policies implemented in this project, covering API security validation and deployment policies.

## Table of Contents

1. [Overview](#overview)
2. [Policy Structure](#policy-structure)
3. [API Security Policy](#api-security-policy)
4. [Deployment Policy](#deployment-policy)
5. [Policy Testing](#policy-testing)
6. [Integration with CI/CD](#integration-with-cicd)
7. [Runtime Policy Enforcement](#runtime-policy-enforcement)
8. [Policy Development Guidelines](#policy-development-guidelines)
9. [Troubleshooting](#troubleshooting)

## Overview

Open Policy Agent (OPA) is an open-source general-purpose policy engine that provides a unified toolset for policy authoring, distribution, and enforcement. In this project, OPA is used to:

- **API Security**: Validate incoming API requests against security policies
- **Deployment Security**: Enforce deployment rules and security requirements
- **Runtime Enforcement**: Provide real-time policy decisions during application runtime

### Key Benefits

- **Policy as Code**: All policies are version-controlled and testable
- **Separation of Concerns**: Business logic is separate from policy decisions
- **Consistent Enforcement**: Same policies used across development, testing, and production
- **Auditability**: Clear policy decisions with detailed reasoning
- **Flexibility**: Easy to update policies without changing application code

## Policy Structure

All policies are written in Rego, OPA's policy language. The project follows these structural conventions:

```
policies/
├── api_security.rego       # API request validation
└── deployment.rego         # Deployment validation

test/
└── api_security_test.rego  # Policy unit tests
```

### Rego Language Basics

Rego is a declarative language designed for expressing policies over complex hierarchical data structures. Key concepts:

- **Rules**: Define conditions that must be met
- **Data**: Input data and static policy data
- **Queries**: Requests for policy decisions
- **Packages**: Namespace for organizing policies

## API Security Policy

### File: `policies/api_security.rego`

This policy validates incoming API requests against security rules.

#### Package Declaration
```rego
package api.security
```

#### Core Rules

##### 1. Default Deny
```rego
default allow = false
```
- **Purpose**: Implements a security-first approach where all requests are denied by default
- **Impact**: Only explicitly allowed requests will pass validation

##### 2. Endpoint Authorization
```rego
allow {
    input.method == "GET"
    input.path == "/hello"
}

allow {
    input.method == "GET"
    input.path == "/api/status"
}
```
- **Purpose**: Defines which HTTP methods and paths are allowed
- **Current Rules**:
  - `GET /hello` - Hello world endpoint
  - `GET /api/status` - Health check endpoint
- **Extension**: Add new rules for additional endpoints

##### 3. Rate Limiting
```rego
default rate_limit_exceeded = false

rate_limit_exceeded {
    input.request_count > 100
    input.time_window == "minute"
}
```
- **Purpose**: Prevents abuse by limiting requests per time window
- **Configuration**: 100 requests per minute (configurable)
- **Implementation**: Requires external system to track request counts

##### 4. Query Parameter Validation
```rego
query_params_valid {
    input.query_params.name
    count(input.query_params.name) <= 50
}

query_params_valid {
    not input.query_params.name
}
```
- **Purpose**: Validates query parameters for security
- **Rules**:
  - `name` parameter must be ≤ 50 characters if present
  - Request is valid if `name` parameter is absent
- **Security**: Prevents injection attacks through oversized parameters

##### 5. Security Headers Validation
```rego
security_headers_valid {
    input.headers["user-agent"]
    not contains(input.headers["user-agent"], "bot")
    not contains(input.headers["user-agent"], "crawler")
}
```
- **Purpose**: Validates HTTP headers for security indicators
- **Rules**:
  - `User-Agent` header must be present
  - Must not contain "bot" or "crawler" (basic bot detection)
- **Enhancement**: Can be extended for more sophisticated bot detection

##### 6. Complete Request Validation
```rego
request_valid {
    allow
    not rate_limit_exceeded
    query_params_valid
    security_headers_valid
}
```
- **Purpose**: Combines all validation rules
- **Logic**: Request is valid only if ALL conditions are met

##### 7. Policy Decision Response
```rego
decision = {
    "allow": allow,
    "rate_limit_exceeded": rate_limit_exceeded,
    "query_params_valid": query_params_valid,
    "security_headers_valid": security_headers_valid,
    "request_valid": request_valid,
    "reason": reason
}
```
- **Purpose**: Provides detailed decision information
- **Use Case**: Enables debugging and audit logging

#### Input Data Structure

The policy expects input data in the following format:

```json
{
    "method": "GET",
    "path": "/hello",
    "query_params": {
        "name": "World"
    },
    "headers": {
        "user-agent": "Mozilla/5.0 (compatible; browser)"
    },
    "request_count": 10,
    "time_window": "minute"
}
```

#### Example Policy Decisions

**Valid Request:**
```json
{
    "allow": true,
    "rate_limit_exceeded": false,
    "query_params_valid": true,
    "security_headers_valid": true,
    "request_valid": true,
    "reason": "Request allowed"
}
```

**Invalid Request (Rate Limited):**
```json
{
    "allow": true,
    "rate_limit_exceeded": true,
    "query_params_valid": true,
    "security_headers_valid": true,
    "request_valid": false,
    "reason": "Rate limit exceeded"
}
```

## Deployment Policy

### File: `policies/deployment.rego`

This policy validates deployment requests against security and operational requirements.

#### Package Declaration
```rego
package deployment.security
```

#### Core Rules

##### 1. Default Deny
```rego
default allow = false
```
- **Purpose**: Prevents unauthorized deployments
- **Impact**: Only explicitly approved deployments proceed

##### 2. Environment and Branch Validation
```rego
allow {
    allowed_environments[input.environment]
    allowed_branches[input.environment][_] == input.branch
}

allowed_environments = {
    "development": true,
    "staging": true,
    "production": true
}

allowed_branches = {
    "development": ["develop", "feature/test"],
    "staging": ["staging", "release/test"],
    "production": ["main", "master"]
}
```
- **Purpose**: Enforces branch-based deployment restrictions
- **Rules**:
  - `development`: Only from `develop` or `feature/test` branches
  - `staging`: Only from `staging` or `release/test` branches
  - `production`: Only from `main` or `master` branches
- **Security**: Prevents accidental production deployments from feature branches

##### 3. Production Deployment Checks
```rego
production_checks_passed {
    input.environment == "production"
    input.tests_passed == true
    input.security_scan_passed == true
    input.code_coverage >= 80
    input.has_security_review == true
}

production_checks_passed {
    input.environment != "production"
}
```
- **Purpose**: Enforces additional requirements for production deployments
- **Requirements**:
  - All tests must pass
  - Security scan must pass
  - Code coverage must be ≥ 80%
  - Security review must be completed
- **Non-Production**: These checks are automatically passed for non-production environments

##### 4. Container Security Validation
```rego
container_security_valid {
    input.container.run_as_non_root == true
    input.container.read_only_root_fs == true
    not input.container.privileged
}
```
- **Purpose**: Enforces container security best practices
- **Requirements**:
  - Container must run as non-root user
  - Root filesystem must be read-only
  - Container must not run in privileged mode
- **Security**: Follows principle of least privilege

##### 5. Complete Deployment Validation
```rego
deployment_valid {
    allow
    production_checks_passed
    container_security_valid
}
```
- **Purpose**: Combines all deployment validation rules
- **Logic**: Deployment is valid only if ALL conditions are met

#### Input Data Structure

The policy expects input data in the following format:

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

#### Example Policy Decisions

**Valid Production Deployment:**
```json
{
    "allow": true,
    "deployment_valid": true,
    "production_checks_passed": true,
    "container_security_valid": true,
    "reason": "Deployment allowed"
}
```

**Invalid Production Deployment (Security Checks Failed):**
```json
{
    "allow": true,
    "deployment_valid": false,
    "production_checks_passed": false,
    "container_security_valid": true,
    "reason": "Production checks failed"
}
```

## Policy Testing

### File: `test/api_security_test.rego`

Comprehensive test suite for API security policies.

#### Test Structure

Each test follows the pattern:
```rego
test_<scenario_name> {
    <rule_name> with input as <test_data>
}
```

#### Test Cases

##### 1. Positive Tests
- `test_allow_hello_get`: Validates GET /hello endpoint
- `test_allow_status_get`: Validates GET /api/status endpoint
- `test_query_params_valid`: Validates proper query parameters
- `test_security_headers_valid`: Validates proper security headers

##### 2. Negative Tests
- `test_deny_hello_post`: Validates POST method denial
- `test_deny_unknown_endpoint`: Validates unknown endpoint denial
- `test_query_params_invalid_long`: Validates long parameter rejection
- `test_security_headers_invalid_bot`: Validates bot detection

##### 3. Rate Limiting Tests
- `test_rate_limit_exceeded`: Validates rate limit enforcement

#### Running Tests

```bash
# Run all policy tests
opa test policies/ test/

# Run specific test file
opa test test/api_security_test.rego

# Run with verbose output
opa test -v policies/ test/
```

#### Test Output Example

```
PASS: 9/9
test/api_security_test.rego:
  test_allow_hello_get: PASS (1.2ms)
  test_allow_status_get: PASS (1.1ms)
  test_deny_hello_post: PASS (1.0ms)
  test_deny_unknown_endpoint: PASS (1.0ms)
  test_rate_limit_exceeded: PASS (1.1ms)
  test_query_params_valid: PASS (1.0ms)
  test_query_params_invalid_long: PASS (1.2ms)
  test_security_headers_valid: PASS (1.1ms)
  test_security_headers_invalid_bot: PASS (1.0ms)
```

## Integration with CI/CD

### GitHub Actions Workflow

The OPA policies are integrated into the CI/CD pipeline at multiple stages:

#### 1. Policy Testing Job
```yaml
opa-policy-test:
  runs-on: ubuntu-latest
  steps:
  - uses: actions/checkout@v4
  - name: Setup OPA
    uses: open-policy-agent/setup-opa@v2
    with:
      version: ${{ env.OPA_VERSION }}
  - name: Test OPA policies
    run: opa test policies/ test/
  - name: Validate policy syntax
    run: opa fmt --diff policies/
```

#### 2. Security Validation Job
```yaml
security-validation:
  runs-on: ubuntu-latest
  needs: [test, opa-policy-test]
  steps:
  - name: Test API security policies
    run: |
      echo '{"method": "GET", "path": "/hello", ...}' | \
      opa eval -d policies/api_security.rego "data.api.security.decision" --input-stdin
```

#### 3. Deployment Validation Job
```yaml
deploy:
  runs-on: ubuntu-latest
  steps:
  - name: Validate deployment with OPA
    run: |
      DECISION=$(echo "$DEPLOYMENT_DATA" | opa eval -d policies/deployment.rego "data.deployment.security.decision" --input-stdin --format raw)
      
      if [ "$(echo "$DECISION" | jq -r '.deployment_valid')" != "true" ]; then
        echo "Deployment validation failed"
        exit 1
      fi
```

#### 4. Runtime Policy Server Job
```yaml
runtime-policy-server:
  runs-on: ubuntu-latest
  steps:
  - name: Start OPA server with policies
    run: |
      opa run --server --addr=0.0.0.0:8181 policies/ &
      sleep 3
  - name: Test runtime policy enforcement
    run: |
      curl -X POST http://localhost:8181/v1/data/api/security/decision \
        -H "Content-Type: application/json" \
        -d '{"input": {...}}'
```

### Policy Decision Points

1. **Pre-deployment**: Validate deployment parameters
2. **Runtime**: Validate API requests in real-time
3. **Post-deployment**: Verify policy compliance

## Runtime Policy Enforcement

### OPA Server Setup

Start OPA server with policies:
```bash
opa run --server --addr=0.0.0.0:8181 policies/
```

### API Endpoints

#### Policy Query Endpoint
```
POST /v1/data/api/security/decision
Content-Type: application/json

{
    "input": {
        "method": "GET",
        "path": "/hello",
        "query_params": {"name": "World"},
        "headers": {"user-agent": "Mozilla/5.0"},
        "request_count": 10,
        "time_window": "minute"
    }
}
```

#### Response Format
```json
{
    "result": {
        "allow": true,
        "rate_limit_exceeded": false,
        "query_params_valid": true,
        "security_headers_valid": true,
        "request_valid": true,
        "reason": "Request allowed"
    }
}
```

### Integration with Applications

#### PHP Integration Example
```php
function validateRequest($method, $path, $params, $headers, $requestCount) {
    $input = [
        'method' => $method,
        'path' => $path,
        'query_params' => $params,
        'headers' => $headers,
        'request_count' => $requestCount,
        'time_window' => 'minute'
    ];
    
    $response = file_get_contents('http://opa:8181/v1/data/api/security/decision', false, stream_context_create([
        'http' => [
            'method' => 'POST',
            'header' => 'Content-Type: application/json',
            'content' => json_encode(['input' => $input])
        ]
    ]));
    
    $decision = json_decode($response, true);
    return $decision['result']['request_valid'];
}
```

## Policy Development Guidelines

### 1. Security First Approach
- Always use `default allow = false`
- Explicitly define allowed actions
- Implement defense in depth

### 2. Policy Organization
- Use descriptive package names
- Group related rules together
- Document policy intent with comments

### 3. Testing Requirements
- Write tests for all policy rules
- Include both positive and negative test cases
- Test edge cases and error conditions

### 4. Performance Considerations
- Avoid complex computations in policies
- Use efficient data structures
- Consider caching for frequently accessed data

### 5. Maintainability
- Use descriptive rule names
- Keep policies focused and single-purpose
- Version control all policy changes

### 6. Documentation Standards
- Document input data structure
- Provide example queries and responses
- Explain policy decisions and reasoning

## Troubleshooting

### Common Issues

#### 1. Policy Parse Errors
**Symptom**: `rego_parse_error: unexpected token`
**Solution**: Check Rego syntax, ensure compatibility with OPA version

#### 2. Policy Evaluation Errors
**Symptom**: `evaluation_error: undefined`
**Solution**: Verify input data structure matches policy expectations

#### 3. Performance Issues
**Symptom**: Slow policy evaluation
**Solution**: Optimize policy logic, consider data indexing

#### 4. Test Failures
**Symptom**: Policy tests fail unexpectedly
**Solution**: Check test data format, verify policy logic

### Debugging Commands

```bash
# Test policy syntax
opa fmt --diff policies/

# Evaluate policy with debug output
opa eval -d policies/ "data.api.security.allow" -I --explain=debug

# Run specific test
opa test test/api_security_test.rego::test_allow_hello_get

# Check policy coverage
opa test --coverage policies/ test/
```

### Logging and Monitoring

#### Enable OPA Server Logging
```bash
opa run --server --log-level=debug --log-format=json policies/
```

#### Monitor Policy Decisions
```bash
# Watch policy decisions
curl -X POST http://localhost:8181/v1/data/api/security/decision \
  -H "Content-Type: application/json" \
  -d '{"input": {...}}' \
  -v
```

### Best Practices for Production

1. **Monitor Policy Performance**: Track evaluation times
2. **Log Policy Decisions**: Maintain audit trail
3. **Version Control**: Track policy changes
4. **Gradual Rollout**: Test policies in staging first
5. **Fallback Strategy**: Define behavior for policy failures

## Conclusion

This comprehensive OPA policy implementation provides:

- **Robust Security**: Multi-layered validation for API and deployment security
- **Flexibility**: Easy to extend and modify policies
- **Observability**: Detailed policy decisions and reasoning
- **Integration**: Seamless CI/CD and runtime integration
- **Testing**: Comprehensive test coverage for reliability

The policies follow security best practices and provide a solid foundation for policy-based access control in modern applications.