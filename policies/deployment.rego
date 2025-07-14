package deployment.security

# Default deny
default allow := false

# Validate deployment environment
allow if {
    input.environment in ["development", "staging", "production"]
    input.branch in allowed_branches[input.environment]
}

allowed_branches := {
    "development": ["develop", "feature/*"],
    "staging": ["staging", "release/*"],
    "production": ["main", "master"]
}

# Security checks for production deployments
production_checks_passed if {
    input.environment == "production"
    input.tests_passed == true
    input.security_scan_passed == true
    input.code_coverage >= 80
    input.has_security_review == true
}

production_checks_passed if {
    input.environment != "production"
}

# Validate container security
container_security_valid if {
    input.container.run_as_non_root == true
    input.container.read_only_root_fs == true
    not input.container.privileged
}

# Complete deployment validation
deployment_valid if {
    allow
    production_checks_passed
    container_security_valid
}

# Response with detailed decision
decision := {
    "allow": allow,
    "deployment_valid": deployment_valid,
    "production_checks_passed": production_checks_passed,
    "container_security_valid": container_security_valid,
    "reason": reason
}

reason := "Deployment allowed" if deployment_valid
reason := "Production checks failed" if not production_checks_passed
reason := "Container security validation failed" if not container_security_valid
reason := "Branch not allowed for environment" if not allow