# Makefile for nginx + OPA example

.PHONY: help build up down logs test clean

help: ## Show this help message
	@echo "Available commands:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-15s\033[0m %s\n", $$1, $$2}'

build: ## Build all containers
	docker-compose build

up: ## Start all services
	docker-compose up -d
	@echo "Services started. Waiting for readiness..."
	@sleep 10
	@echo "Services should be ready at:"
	@echo "  - Application: http://localhost"
	@echo "  - OPA Admin: http://localhost:8080"

down: ## Stop all services
	docker-compose down

logs: ## Show logs for all services
	docker-compose logs -f

logs-nginx: ## Show nginx logs only
	docker-compose logs -f nginx

logs-opa: ## Show OPA logs only
	docker-compose logs -f opa

test: ## Run integration tests
	@echo "Running integration tests..."
	@./test_endpoints.sh

test-manual: ## Instructions for manual testing
	@echo "Manual testing commands:"
	@echo ""
	@echo "# Valid request:"
	@echo 'curl -H "User-Agent: Mozilla/5.0" "http://localhost/hello?name=World"'
	@echo ""
	@echo "# Invalid method:"
	@echo 'curl -X POST "http://localhost/hello"'
	@echo ""
	@echo "# Bot detection:"
	@echo 'curl -H "User-Agent: bot-crawler" "http://localhost/hello"'
	@echo ""
	@echo "# Rate limiting test:"
	@echo 'for i in {1..110}; do curl "http://localhost/hello?name=Test$$i"; done'

clean: ## Clean up containers and volumes
	docker-compose down -v
	docker-compose rm -f
	docker system prune -f

status: ## Show service status
	docker-compose ps

restart: ## Restart all services
	docker-compose restart

restart-nginx: ## Restart nginx only
	docker-compose restart nginx

debug-nginx: ## Debug nginx configuration
	docker-compose exec nginx nginx -t
	docker-compose exec nginx nginx -s reload

debug-opa: ## Test OPA directly
	@echo "Testing OPA directly:"
	@curl -X POST http://localhost:8080/v1/data/api/security/decision \
		-H "Content-Type: application/json" \
		-d '{"input": {"method": "GET", "path": "/hello", "query_params": {"name": "test"}, "headers": {"user-agent": "Mozilla/5.0"}, "request_count": 1, "time_window": "minute"}}' \
		| jq .

debug-redis: ## Check Redis keys
	docker-compose exec redis redis-cli keys "*"

monitor: ## Monitor Redis operations
	docker-compose exec redis redis-cli monitor

install-deps: ## Install development dependencies
	@echo "Installing development dependencies..."
	@which jq > /dev/null || echo "Please install jq for JSON processing"
	@which curl > /dev/null || echo "Please install curl for testing"

dev-setup: build up ## Setup development environment
	@echo "Development environment ready!"
	@echo "Run 'make test' to verify everything is working"