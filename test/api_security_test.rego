package api.security

import rego.v1

# Test allow for valid GET request to /hello
test_allow_hello_get if {
    allow with input as {
        "method": "GET",
        "path": "/hello"
    }
}

# Test allow for valid GET request to /api/status
test_allow_status_get if {
    allow with input as {
        "method": "GET",
        "path": "/api/status"
    }
}

# Test deny for POST request to /hello
test_deny_hello_post if {
    not allow with input as {
        "method": "POST",
        "path": "/hello"
    }
}

# Test deny for unknown endpoint
test_deny_unknown_endpoint if {
    not allow with input as {
        "method": "GET",
        "path": "/unknown"
    }
}

# Test rate limiting
test_rate_limit_exceeded if {
    rate_limit_exceeded with input as {
        "request_count": 150,
        "time_window": "minute"
    }
}

# Test query parameter validation
test_query_params_valid if {
    query_params_valid with input as {
        "query_params": {
            "name": "test"
        }
    }
}

# Test query parameter validation with long name
test_query_params_invalid_long if {
    not query_params_valid with input as {
        "query_params": {
            "name": "this_is_a_very_long_name_that_exceeds_the_limit_of_fifty_characters"
        }
    }
}

# Test security headers validation
test_security_headers_valid if {
    security_headers_valid with input as {
        "headers": {
            "user-agent": "Mozilla/5.0 (compatible; browser)"
        }
    }
}

# Test security headers validation with bot
test_security_headers_invalid_bot if {
    not security_headers_valid with input as {
        "headers": {
            "user-agent": "bot-crawler"
        }
    }
}