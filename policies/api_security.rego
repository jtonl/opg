package api.security

import rego.v1

# Default deny
default allow := false

# Allow GET requests to /hello endpoint
allow if {
    input.method == "GET"
    input.path == "/hello"
}

# Allow GET requests to /api/status endpoint
allow if {
    input.method == "GET"
    input.path == "/api/status"
}

# Rate limiting policy
default rate_limit_exceeded := false

rate_limit_exceeded if {
    input.request_count > 100
    input.time_window == "minute"
}

# Validate query parameters
query_params_valid if {
    input.query_params.name
    count(input.query_params.name) <= 50
}

query_params_valid if {
    not input.query_params.name
}

# Security headers validation
security_headers_valid if {
    input.headers["user-agent"]
    not contains(input.headers["user-agent"], "bot")
    not contains(input.headers["user-agent"], "crawler")
}

# Complete validation
request_valid if {
    allow
    not rate_limit_exceeded
    query_params_valid
    security_headers_valid
}

# Response with detailed decision
decision = {
    "allow": allow,
    "rate_limit_exceeded": rate_limit_exceeded,
    "query_params_valid": query_params_valid,
    "security_headers_valid": security_headers_valid,
    "request_valid": request_valid,
    "reason": reason
}

reason := "Request allowed" if {
    request_valid
}

reason := "Endpoint not allowed" if {
    not allow
}

reason := "Rate limit exceeded" if {
    allow
    rate_limit_exceeded
}

reason := "Invalid query parameters" if {
    allow
    not rate_limit_exceeded
    not query_params_valid
}

reason := "Security headers validation failed" if {
    allow
    not rate_limit_exceeded
    query_params_valid
    not security_headers_valid
}