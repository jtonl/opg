# Nginx + OPA Integration Example

This example demonstrates how to integrate Open Policy Agent (OPA) with nginx as a reverse proxy, providing policy-based access control for API endpoints.

## Architecture

```
Client Request
      ↓
   [Nginx]
      ↓
 [OPA Policy Check] ← [Rate Limiting (Redis)]
      ↓
   [PHP App]
```

## Features

- **nginx as Reverse Proxy**: Routes requests and enforces policies
- **OPA Integration**: Uses nginx `auth_request` module for policy validation
- **Rate Limiting**: Implements request counting with Redis
- **Logging**: Comprehensive logging of policy decisions
- **Health Checks**: Bypass OPA for health check endpoints
- **Admin Interface**: OPA admin interface for development (port 8080)

## Components

### 1. nginx Configuration (`nginx.conf`)

- **Upstream Servers**: PHP app and OPA server
- **Rate Limiting**: 100 requests per minute per IP
- **Auth Request**: Subrequest to OPA for authorization
- **Custom Logging**: Includes OPA decision and reason
- **Security Headers**: Adds OPA decision headers to responses

### 2. OPA Policy Integration

Uses the same policies from the main project:
- `api_security.rego` - API request validation
- `deployment.rego` - Deployment validation

### 3. Lua Script (`lua/opa_auth.lua`)

Advanced OPA integration with:
- Redis-based rate limiting
- JSON request/response handling
- Error handling and logging
- Custom OPA input formatting

### 4. Docker Compose Setup

Services:
- **nginx**: Reverse proxy with OPA integration
- **app**: PHP application (same as main project)
- **opa**: OPA server with policies
- **redis**: Request counter for rate limiting

## Quick Start

1. **Start the services:**
   ```bash
   cd examples/nginx
   docker-compose up -d
   ```

2. **Run tests:**
   ```bash
   ./test_endpoints.sh
   ```

3. **Check logs:**
   ```bash
   docker-compose logs nginx
   ```

## Configuration Details

### Rate Limiting

nginx implements rate limiting with a 100 requests per minute limit:
```nginx
limit_req_zone $binary_remote_addr zone=api_rate_limit:10m rate=100r/m;
limit_req zone=api_rate_limit burst=10 nodelay;
```

### OPA Authorization Flow

1. Client makes request to `/hello` or `/api/*`
2. nginx makes subrequest to `/opa_auth` 
3. OPA evaluates policy with request data
4. nginx allows/denies based on OPA response
5. Request is proxied to PHP app if allowed

### Custom Logging

nginx logs include OPA decision information:
```
192.168.1.100 - - [14/Jul/2025:10:30:45 +0000] "GET /hello?name=World HTTP/1.1" 200 85 "-" "Mozilla/5.0" opa_decision="true" opa_reason="Request allowed"
```

## API Endpoints

### Application Endpoints
- `GET /hello?name=World` - Hello world endpoint
- `GET /api/status` - Health check endpoint

### Administrative Endpoints
- `GET /health` - nginx health check (bypasses OPA)
- `http://localhost:8080/` - OPA admin interface

## Testing

### Manual Testing

```bash
# Valid request
curl -H "User-Agent: Mozilla/5.0" "http://localhost/hello?name=World"

# Invalid method
curl -X POST "http://localhost/hello"

# Bot detection
curl -H "User-Agent: bot-crawler" "http://localhost/hello"

# Rate limiting test
for i in {1..110}; do curl "http://localhost/hello?name=Test$i"; done
```

### Automated Testing

Run the included test script:
```bash
./test_endpoints.sh
```

## Advanced Features

### Lua Integration

For more complex scenarios, the Lua script provides:
- Redis-based request counting
- Custom OPA input formatting
- Enhanced error handling
- Flexible policy integration

### Monitoring

Monitor the system with:
```bash
# nginx access logs
docker-compose logs nginx

# OPA decision logs
docker-compose logs opa

# Application logs
docker-compose logs app

# Redis operations
docker-compose exec redis redis-cli monitor
```

### Security Headers

nginx adds security headers to all responses:
- `X-OPA-Decision`: Policy decision result
- `X-OPA-Reason`: Reason for decision

## Production Considerations

1. **SSL/TLS**: Add SSL termination at nginx
2. **Security**: Remove OPA admin interface in production
3. **Monitoring**: Add health checks and metrics
4. **Scaling**: Use nginx upstream for load balancing
5. **Caching**: Implement response caching where appropriate

## Troubleshooting

### Common Issues

1. **OPA Service Unavailable**
   - Check if OPA container is running
   - Verify network connectivity

2. **Rate Limiting Not Working**
   - Ensure Redis is running
   - Check nginx rate limiting configuration

3. **Policy Not Applied**
   - Verify policy files are mounted correctly
   - Check OPA logs for policy compilation errors

### Debug Commands

```bash
# Check service status
docker-compose ps

# View nginx configuration
docker-compose exec nginx nginx -t

# Test OPA directly
curl -X POST http://localhost:8080/v1/data/api/security/decision \
  -H "Content-Type: application/json" \
  -d '{"input": {"method": "GET", "path": "/hello"}}'

# Check Redis keys
docker-compose exec redis redis-cli keys "*"
```

## Integration with CI/CD

This nginx setup can be integrated into the main CI/CD pipeline:

1. **Testing**: Include nginx integration tests
2. **Deployment**: Deploy nginx configuration alongside application
3. **Monitoring**: Add nginx metrics to monitoring stack
4. **Security**: Validate nginx configuration in policy tests

## Extending the Example

### Adding New Policies

1. Create new policy files in `/policies`
2. Update nginx configuration to call new policies
3. Add corresponding tests

### Custom Rate Limiting

Modify the Lua script to implement:
- Per-user rate limiting
- Different limits for different endpoints
- Burst handling policies

### Enhanced Logging

Add structured logging with:
- Request IDs
- User context
- Performance metrics
- Security events