# Simple PHP API with Open Policy Agent (OPA) Integration

This example demonstrates how to integrate Open Policy Agent (OPA) with a minimal PHP API application in a GitHub Actions CI/CD workflow. Uses OPA 1.6.0 with modern Rego v1 syntax.

## Project Structure

```
├── .github/workflows/ci-cd.yml    # GitHub Actions workflow with OPA integration
├── composer.json                  # PHP dependencies (minimal)
├── public/index.php              # Simple PHP API application
├── policies/
│   ├── api_security.rego        # API security policies
│   └── deployment.rego          # Deployment policies
├── test/
│   └── api_security_test.rego   # OPA policy tests
├── scripts/
│   └── test-opa.sh              # Local OPA testing script
├── examples/
│   └── nginx/                   # nginx + OPA integration example
└── docker-compose.yml           # Docker setup with OPA
```

## API Endpoints

- `GET /hello?name=World` - Returns a JSON hello message
- `GET /api/status` - Returns API health status

## OPA Policies

### API Security Policy (`policies/api_security.rego`)

Validates:
- HTTP method and path authorization
- Rate limiting (max 100 requests per minute)
- Query parameter validation
- Security headers validation

### Deployment Policy (`policies/deployment.rego`)

Validates:
- Environment-specific branch restrictions
- Production deployment requirements
- Container security settings

## GitHub Actions Workflow

The workflow includes several jobs:

1. **test** - Runs PHP application tests
2. **opa-policy-test** - Tests OPA policies and validates syntax
3. **security-validation** - Tests API security policies against live application
4. **deploy** - Validates deployment with OPA policies and deploys (runs on `master` and `develop` branches)
5. **runtime-policy-server** - Starts OPA server for runtime policy enforcement (production only on `master` branch)

**Branch Configuration**: Workflow triggers on `master` and `develop` branches, with `master` → production and `develop` → development.

## Getting Started

1. **Install dependencies (optional):**
   ```bash
   composer install
   ```

2. **Start the application:**
   ```bash
   php -S localhost:8000 -t public
   ```

3. **Test the API:**
   ```bash
   curl http://localhost:8000/hello?name=World
   curl http://localhost:8000/api/status
   ```

4. **Install OPA (for local testing):**
   ```bash
   curl -L -o opa https://github.com/open-policy-agent/opa/releases/latest/download/opa_linux_amd64_static
   chmod +x opa
   sudo mv opa /usr/local/bin/
   ```

5. **Test OPA policies:**
   ```bash
   opa test policies/ test/
   ```

6. **Test API security policy:**
   ```bash
   echo '{"method": "GET", "path": "/hello", "query_params": {"name": "test"}, "headers": {"user-agent": "Mozilla/5.0"}, "request_count": 10, "time_window": "minute"}' | \
   opa eval -d policies/api_security.rego "data.api.security.decision" --stdin-input
   ```

## OPA Integration Benefits

1. **Policy as Code** - Security and deployment policies are versioned and tested
2. **Modern Syntax** - Uses OPA 1.6.0 with Rego v1 syntax for better maintainability
3. **Consistent Enforcement** - Same policies used in CI/CD and runtime
4. **Separation of Concerns** - Business logic separate from policy decisions
5. **Auditability** - Clear policy decisions and reasoning
6. **Flexibility** - Easy to update policies without code changes

## CI/CD Flow

1. Code push triggers workflow (on `master` or `develop` branches)
2. Application tests run
3. OPA policies are tested with modern Rego v1 syntax
4. Security validation against live application
5. Deployment validation with OPA
6. Container build and deployment (branch-specific environments)
7. Runtime policy server setup (production only on `master` branch)

## Security Features

- Non-root container execution
- Read-only root filesystem
- Rate limiting enforcement
- Input validation
- Security header validation
- Branch-based deployment restrictions

## Environment Variables

No environment variables required for the simple PHP implementation.

## Examples

### nginx Integration

The `examples/nginx/` directory contains a complete nginx + OPA integration example with:
- nginx as reverse proxy with policy enforcement
- Redis-based rate limiting
- Custom logging and monitoring
- Docker Compose setup

```bash
cd examples/nginx/
make dev-setup
make test
```

## Additional Documentation

- **OPA_POLICIES.md** - Comprehensive documentation of all OPA policies, syntax, and usage
- **CLAUDE.md** - Development guidance for working with this codebase
- **examples/README.md** - Overview of integration examples and patterns