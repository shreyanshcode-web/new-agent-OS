<!-- Copilot customization for WorkOS AI project -->

## WorkOS AI - Autonomous Enterprise Operating System

This is the main development workspace for **WorkOS AI**, a sophisticated multi-agent system that automates enterprise operations using Go, gRPC, PostgreSQL, and event-driven architecture.

### Key Project Characteristics

- **Language**: Go 1.21+
- **RPC Framework**: gRPC + Protocol Buffers
- **Database**: PostgreSQL 15 with pgvector for vector search
- **Message Queue**: RabbitMQ for event-driven communication
- **Orchestration**: Kubernetes-ready microservices
- **Architecture**: Multi-agent system with executive planner and specialized agents

### Core Services

1. **Orchestrator** (Port 50051) - Central task routing and execution engine
2. **Executive Agent** (Port 50052) - Goal decomposition and planning
3. **HR Agent** (Port 50053) - Hiring, onboarding, employee management
4. **Sales Agent** (Port 50054) - Lead qualification, CRM, forecasting
5. **Dev Agent** (Port 50055) - Code review, PR analysis, bug detection
6. **Marketing Agent** (Port 50056) - Campaign creation, content generation

### Quick Commands

```bash
# Initial setup
make setup-dev              # Complete environment setup

# Development
make run-all               # Start all services locally
docker-compose up -d       # Start dependencies only

# Building
make build-all             # Build all services
make proto-generate        # Generate gRPC code from proto files

# Testing
make test                  # Run all tests
make test-integration      # Integration tests only

# Kubernetes
kubectl apply -f deploy/k8s/workos-core.yaml    # Deploy core services
kubectl apply -f deploy/k8s/workos-agents.yaml  # Deploy agents
```

### Directory Structure

```
cmd/          - Service entry points
internal/     - Core business logic (orchestrator, agents, knowledge, events, memory)
pkg/          - Shared utilities (models, gRPC, database)
api/proto/    - Protocol buffer definitions
deploy/       - Docker and Kubernetes configurations
tests/        - Integration tests
docs/         - Development and deployment guides
```

### Key Files to Know

- **[README.md](README.md)** - Project overview and vision
- **[docs/DEVELOPMENT.md](docs/DEVELOPMENT.md)** - Development guide
- **[docs/DEPLOYMENT.md](docs/DEPLOYMENT.md)** - Kubernetes deployment guide
- **[Makefile](Makefile)** - Build automation
- **[docker-compose.yml](docker-compose.yml)** - Local dev stack
- **[deploy/k8s/workos-core.yaml](deploy/k8s/workos-core.yaml)** - Core K8s manifests

### Getting Started

1. **Read**: Start with [README.md](README.md) for architecture overview
2. **Setup**: Run `make setup-dev` to initialize environment
3. **Develop**: Follow [docs/DEVELOPMENT.md](docs/DEVELOPMENT.md)
4. **Deploy**: Use [docs/DEPLOYMENT.md](docs/DEPLOYMENT.md) for K8s

### Development Tips

- All Go services use gRPC over the specified ports (50051-50056)
- PostgreSQL includes pgvector for semantic vector search
- RabbitMQ manages asynchronous event communication
- Add new agents by following the pattern in `cmd/` and `internal/agents/`
- Configuration via `.env` file (copy from `.env.example`)

### Common Issues

| Issue | Solution |
|-------|----------|
| Port already in use | Check `netstat -an` or change port in `.env` |
| DB connection failed | Ensure `docker-compose up -d` && `make db-migrate` |
| gRPC connection refused | Verify service is running on correct port |
| Proto compilation error | Run `make proto-generate` after proto changes |

### Architecture Decision Log

- **Go + gRPC**: High performance, strong typing, excellent concurrency
- **PostgreSQL + pgvector**: Vector search for knowledge retrieval within SQL
- **RabbitMQ**: Loose coupling, event replay, natural audit trail
- **Kubernetes**: Production-ready, auto-scaling, cloud-agnostic
- **Event-driven**: Asynchronous communication, system resilience

### Next Steps for MVP (Week 1-2)

1. Implement proto definitions ✓
2. Build core orchestrator service
3. Implement executive agent with goal decomposition
4. Build specialized agents (HR, Sales, Dev, Marketing)
5. Set up RabbitMQ event bus integration
6. Implement knowledge graph queries
7. Create integration tests
8. Deploy to Kubernetes

### Resources

- [gRPC Go Docs](https://grpc.io/docs/languages/go/)
- [PostgreSQL Documentation](https://www.postgresql.org/docs/)
- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [RabbitMQ Documentation](https://www.rabbitmq.com/documentation.html)

---

**For detailed information on adding new agents, check [docs/DEVELOPMENT.md](docs/DEVELOPMENT.md#adding-a-new-agent).**
