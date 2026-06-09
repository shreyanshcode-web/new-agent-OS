.PHONY: help build build-all run run-all test test-coverage clean proto-generate db-migrate docker-build docker-up docker-down

help:
	@echo "WorkOS AI - Build Commands"
	@echo ""
	@echo "Build:"
	@echo "  make build-all              Build all services"
	@echo "  make build-orchestrator     Build orchestrator service"
	@echo "  make build-executive        Build executive agent"
	@echo "  make build-agents           Build all specialized agents"
	@echo ""
	@echo "Development:"
	@echo "  make run-all                Run all services"
	@echo "  make run-orchestrator       Run orchestrator"
	@echo "  make proto-generate         Generate gRPC code from proto files"
	@echo ""
	@echo "Database:"
	@echo "  make db-migrate             Run database migrations"
	@echo "  make db-reset               Reset database"
	@echo ""
	@echo "Testing:"
	@echo "  make test                   Run all tests"
	@echo "  make test-integration       Run integration tests"
	@echo "  make test-coverage          Run tests with coverage"
	@echo ""
	@echo "Docker:"
	@echo "  make docker-build           Build Docker images"
	@echo "  make docker-up              Start docker-compose stack"
	@echo "  make docker-down            Stop docker-compose stack"
	@echo ""
	@echo "Utilities:"
	@echo "  make clean                  Clean build artifacts"
	@echo "  make fmt                    Format all code"
	@echo "  make lint                   Run linter"

# Build targets
build-all: build-orchestrator build-executive build-agents
	@echo "✓ All services built"

build-orchestrator:
	@echo "Building orchestrator..."
	@mkdir -p bin
	@go build -o bin/orchestrator ./cmd/orchestrator

build-executive:
	@echo "Building executive agent..."
	@mkdir -p bin
	@go build -o bin/executive-agent ./cmd/executive-agent

build-agents:
	@echo "Building specialized agents..."
	@mkdir -p bin
	@go build -o bin/hr-agent ./cmd/hr-agent
	@go build -o bin/sales-agent ./cmd/sales-agent
	@go build -o bin/dev-agent ./cmd/dev-agent
	@go build -o bin/marketing-agent ./cmd/marketing-agent

# Run targets
run-all: docker-up
	@echo "Starting all services..."
	@(go run ./cmd/executive-agent/main.go &)
	@(go run ./cmd/orchestrator/main.go &)
	@(go run ./cmd/hr-agent/main.go &)
	@(go run ./cmd/sales-agent/main.go &)
	@(go run ./cmd/dev-agent/main.go &)
	@(go run ./cmd/marketing-agent/main.go &)
	@wait

run-orchestrator: docker-up
	@echo "Starting orchestrator..."
	@go run ./cmd/orchestrator/main.go

# Protocol buffers
proto-generate:
	@echo "Generating gRPC code from proto files..."
	@protoc --go_out=. --go-grpc_out=. ./api/proto/*.proto

# Database
db-migrate:
	@echo "Running database migrations..."
	@go run ./cmd/migration/main.go

db-reset:
	@echo "Resetting database..."
	@docker-compose exec -T postgres psql -U workos -d workos_ai -f /docker-entrypoint-initdb.d/reset.sql

# Testing
test:
	@echo "Running tests..."
	@go test ./...

test-integration:
	@echo "Running integration tests..."
	@go test -tags=integration ./tests/integration/...

test-coverage:
	@echo "Running tests with coverage..."
	@go test -cover ./...

# Code quality
fmt:
	@echo "Formatting code..."
	@go fmt ./...

lint:
	@echo "Running linter..."
	@golangci-lint run ./...

# Docker
docker-build:
	@echo "Building Docker images..."
	@docker-compose build

docker-up:
	@echo "Starting Docker Compose stack..."
	@docker-compose up -d
	@echo "Waiting for services to start..."
	@sleep 5

docker-down:
	@echo "Stopping Docker Compose stack..."
	@docker-compose down

docker-logs:
	@docker-compose logs -f

# Cleanup
clean:
	@echo "Cleaning build artifacts..."
	@rm -rf bin/
	@go clean

setup-dev:
	@echo "Setting up development environment..."
	@cp .env.example .env
	@make proto-generate
	@make docker-build
	@make docker-up
	@make db-migrate
	@echo "✓ Development environment ready"

.DEFAULT_GOAL := help
