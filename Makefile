# Space Defender Game - Makefile
# Convenient commands for development and deployment

.PHONY: help build run test clean deploy k8s-deploy docker-build docker-run

# Default target
help: ## Show this help message
	@echo "Space Defender Game - Available Commands:"
	@echo "========================================"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

# Development commands
install: ## Install dependencies
	npm install

dev: ## Start development server
	npm run dev

build: ## Build the application
	npm run build

test: ## Run tests
	npm test

lint: ## Run linting
	npm run lint

audit: ## Run security audit
	npm audit

# Docker commands
docker-build: ## Build Docker image
	docker build -t space-defender-game:latest .

docker-run: ## Run Docker container
	docker run -d --name space-defender-game -p 8080:8080 space-defender-game:latest

docker-stop: ## Stop Docker container
	docker stop space-defender-game || true
	docker rm space-defender-game || true

docker-logs: ## Show Docker container logs
	docker logs space-defender-game

docker-shell: ## Get shell access to container
	docker exec -it space-defender-game /bin/sh

# Docker Compose commands
up: ## Start all services with Docker Compose
	docker-compose up -d

down: ## Stop all services
	docker-compose down

logs: ## Show Docker Compose logs
	docker-compose logs -f

restart: ## Restart all services
	docker-compose restart

# Kubernetes commands
k8s-deploy: ## Deploy to Kubernetes
	kubectl apply -f k8s/

k8s-delete: ## Delete from Kubernetes
	kubectl delete -f k8s/

k8s-status: ## Check Kubernetes deployment status
	kubectl get pods,services,ingress -n space-defender

k8s-logs: ## Show Kubernetes pod logs
	kubectl logs -l app=space-defender-game -n space-defender --tail=100

k8s-port-forward: ## Port forward to local machine
	kubectl port-forward service/space-defender-game 8080:80 -n space-defender

# Deployment commands
deploy-dev: ## Deploy to development environment
	./scripts/deploy.sh -e dev

deploy-staging: ## Deploy to staging environment
	./scripts/deploy.sh -e staging

deploy-prod: ## Deploy to production environment
	./scripts/deploy.sh -e prod

# Infrastructure commands
terraform-init: ## Initialize Terraform
	cd terraform && terraform init

terraform-plan: ## Plan Terraform changes
	cd terraform && terraform plan

terraform-apply: ## Apply Terraform changes
	cd terraform && terraform apply

terraform-destroy: ## Destroy Terraform infrastructure
	cd terraform && terraform destroy

# Monitoring commands
monitoring-up: ## Start monitoring stack
	docker-compose --profile monitoring up -d

monitoring-down: ## Stop monitoring stack
	docker-compose --profile monitoring down

# Utility commands
clean: ## Clean up temporary files and containers
	docker system prune -f
	docker volume prune -f
	rm -rf node_modules/.cache
	rm -rf tmp/

health-check: ## Check application health
	@echo "Checking application health..."
	@curl -f http://localhost:8080/health && echo "✅ Application is healthy" || echo "❌ Application is not responding"

load-test: ## Run basic load test
	@echo "Running load test..."
	@if command -v ab >/dev/null 2>&1; then \
		ab -n 100 -c 10 http://localhost:8080/; \
	else \
		echo "Apache Bench (ab) not installed. Install with: apt-get install apache2-utils"; \
	fi

# Security commands
security-scan: ## Run security scans
	@echo "Running security scans..."
	npm audit
	@if command -v trivy >/dev/null 2>&1; then \
		trivy image space-defender-game:latest; \
	else \
		echo "Trivy not installed. Install from: https://github.com/aquasecurity/trivy"; \
	fi

# Git hooks
pre-commit: ## Run pre-commit checks
	npm run lint
	npm test
	docker build -t space-defender-game:test .

# Quick start commands
quick-start: docker-build docker-run ## Quick start with Docker
	@echo "🚀 Space Defender Game is starting..."
	@echo "Wait a few seconds, then open http://localhost:8080"

full-stack: ## Start full development stack
	docker-compose --profile monitoring up -d
	@echo "🚀 Full stack started!"
	@echo "Game: http://localhost:8080"
	@echo "Grafana: http://localhost:3000 (admin/admin123)"
	@echo "Prometheus: http://localhost:9090"

# Environment setup
setup-dev: ## Setup development environment
	@echo "Setting up development environment..."
	npm install
	@echo "✅ Development environment ready!"
	@echo "Run 'make dev' to start development server"

setup-prod: ## Setup production environment
	@echo "Setting up production environment..."
	@echo "1. Configure your Docker registry"
	@echo "2. Set up Kubernetes cluster"
	@echo "3. Configure CI/CD pipeline"
	@echo "4. Run 'make deploy-prod' when ready"

# Status commands
status: ## Show application status
	@echo "Space Defender Game Status:"
	@echo "=========================="
	@echo "Docker containers:"
	@docker ps --filter "name=space-defender" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" || echo "No containers running"
	@echo ""
	@echo "Kubernetes pods:"
	@kubectl get pods -n space-defender 2>/dev/null || echo "No Kubernetes deployment found"

# Documentation
docs: ## Generate documentation
	@echo "📚 Documentation available at:"
	@echo "README.md - Main documentation"
	@echo "Dockerfile - Container configuration"
	@echo "k8s/ - Kubernetes manifests"
	@echo "terraform/ - Infrastructure code"
