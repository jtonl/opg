# OPA Integration Examples

This directory contains practical examples of integrating Open Policy Agent (OPA) with different web servers and architectures.

## Available Examples

### 1. Nginx Integration (`nginx/`)

Demonstrates how to integrate OPA with nginx as a reverse proxy for policy-based access control.

**Features:**
- nginx `auth_request` module for policy validation
- Redis-based rate limiting
- Custom logging with OPA decisions
- Lua scripting for advanced integration
- Docker Compose setup for easy deployment

**Use Cases:**
- API gateway with policy enforcement
- Microservices authorization
- Rate limiting and security headers
- Request filtering and validation

**Quick Start:**
```bash
cd nginx/
docker-compose up -d
./test_endpoints.sh
```

## Architecture Patterns

### 1. Sidecar Pattern (nginx example)

```
┌─────────────┐    ┌─────────────┐    ┌─────────────┐
│   Client    │───▶│   Nginx     │───▶│   PHP App   │
└─────────────┘    │  (Proxy)    │    └─────────────┘
                   │      │      │
                   │      ▼      │
                   │   ┌─────┐   │
                   │   │ OPA │   │
                   │   └─────┘   │
                   └─────────────┘
```

**Benefits:**
- Centralized policy enforcement
- Language-agnostic integration
- Minimal application changes
- Easy to scale and maintain

### 2. Library Pattern (Future Example)

```
┌─────────────┐    ┌─────────────┐
│   Client    │───▶│   PHP App   │
└─────────────┘    │  + OPA SDK  │
                   └─────────────┘
```

**Benefits:**
- Lower latency
- Rich context access
- Application-specific policies
- Better error handling

## Common Integration Patterns

### 1. Request Validation

All examples demonstrate:
- HTTP method and path validation
- Query parameter sanitization
- Header validation (User-Agent, etc.)
- Rate limiting enforcement

### 2. Policy Decision Flow

```
1. Request arrives at proxy/gateway
2. Extract request metadata
3. Format OPA input JSON
4. Query OPA policy endpoint
5. Evaluate policy decision
6. Allow/deny request based on result
7. Log decision for auditing
```

### 3. Error Handling

Common error scenarios:
- OPA service unavailable
- Policy compilation errors
- Invalid input format
- Network timeouts

## Development Guidelines

### Policy Testing

Each example includes:
- Unit tests for policies
- Integration tests for the full stack
- Load testing for performance
- Security testing for edge cases

### Configuration Management

- Environment-specific configurations
- Secret management
- Feature flags for gradual rollout
- Monitoring and alerting setup

### Production Readiness

- SSL/TLS termination
- Health checks and monitoring
- Logging and audit trails
- Performance optimization
- Security hardening

## Future Examples

### Planned Integrations

1. **Apache HTTP Server**
   - mod_auth_openidc integration
   - Policy-based routing
   - Dynamic configuration

2. **API Gateway (Kong/Envoy)**
   - Plugin-based integration
   - Service mesh policies
   - Traffic management

3. **Application Libraries**
   - PHP OPA SDK
   - Python middleware
   - Node.js integration

4. **Kubernetes**
   - Admission controllers
   - Network policies
   - RBAC integration

### Contributing

To add a new example:

1. Create a new directory under `examples/`
2. Include a complete Docker Compose setup
3. Add comprehensive README with:
   - Architecture overview
   - Setup instructions
   - Testing procedures
   - Production considerations
4. Include automated tests
5. Update this main README

## Resources

- [OPA Documentation](https://www.openpolicyagent.org/docs/)
- [Rego Language Guide](https://www.openpolicyagent.org/docs/latest/policy-language/)
- [OPA HTTP API](https://www.openpolicyagent.org/docs/latest/rest-api/)
- [nginx auth_request](http://nginx.org/en/docs/http/ngx_http_auth_request_module.html)

## Support

For questions or issues:
1. Check the example-specific README
2. Review the main project documentation
3. Check OPA community resources
4. Open an issue in the project repository