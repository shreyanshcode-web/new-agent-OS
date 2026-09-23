# WorkOS AI Development Guide

## Quick Start

### 1. Setup Development Environment

```bash
# Clone repository
git clone https://github.com/workos/workos-ai.git
cd workos-ai

# Initialize dev environment (runs setup, builds, and starts dependencies)
make setup-dev
```

### 2. Start Services

**Terminal 1: Dependencies**
```bash
docker-compose up -d
```

**Terminal 2: Executive Agent**
```bash
go run ./cmd/executive-agent/main.go
```

**Terminal 3: Orchestrator**
```bash
go run ./cmd/orchestrator/main.go
```

**Terminal 4: Agents (optional)**
```bash
go run ./cmd/hr-agent/main.go
go run ./cmd/sales-agent/main.go
go run ./cmd/dev-agent/main.go
go run ./cmd/marketing-agent/main.go
```

## Project Structure

```
cmd/                    # Entry points for each service
├── orchestrator/       # Main orchestration service
├── executive-agent/    # Goal planning and decomposition
└── *-agent/           # Specialized agents

internal/              # Core business logic
├── orchestrator/      # Task routing and execution
├── agents/           # Base agent implementations
├── knowledge/        # Knowledge graph operations
├── events/           # Event bus and handlers
└── memory/           # Memory management systems

pkg/                   # Shared utilities
├── models/           # Common data structures
├── grpc/             # gRPC utilities
└── database/         # Database connections

api/proto/            # Protocol buffer definitions
deploy/               # Docker and Kubernetes configs
tests/                # Integration tests
docs/                 # Documentation
```

## Core Concepts

### 1. Orchestrator
The central brain that routes tasks to appropriate agents based on task type and priority.

**Key Methods:**
- `RegisterAgent(agentType, agent)` - Register a new agent
- `SubmitTask(ctx, task)` - Submit task for execution
- `GetActiveTasks()` - List active tasks

### 2. Executive Agent
Converts high-level goals into actionable tasks and decomposition plans.

**Key Methods:**
- `PlanGoal(goal)` - Decompose goal into subtasks
- `GetStatus(planID)` - Check plan execution status

### 3. Specialized Agents
HR, Sales, Dev, Marketing agents handle domain-specific tasks.

**Agent Interface:**
```go
type BaseAgent interface {
    Name() string
    Skills() []string
    MaxConcurrentTasks() int
    ExecuteTask(ctx context.Context, task *Task) (*TaskResult, error)
    CanHandle(taskType string) bool
}
```

### 4. Event Bus
Asynchronous communication between services using RabbitMQ.

**Event Types:**
- `task.created` - New task
- `task.started` - Task execution started
- `task.completed` - Task finished successfully
- `task.failed` - Task failed
- `agent.registered` - Agent joined the system

### 5. Knowledge Graph
PostgreSQL + pgvector for intelligent retrieval.

**Entities:** Employees, Projects, Documents, Meetings, Emails
**Relationships:** Works on, Created, Related to, etc.

### 6. Memory System
Three-tier memory: short-term (1hr), long-term (1yr), episodic (permanent).

## Building Services

### Build All
```bash
make build-all
```

### Build Individual Service
```bash
make build-orchestrator
make build-executive
make build-agents
```

## Testing

```bash
# All tests
make test

# Integration tests
make test-integration

# With coverage
make test-coverage
```

## Adding a New Agent

### 1. Define Proto
Edit `api/proto/workos.proto`:
```proto
service YourAgent {
  rpc ExecuteTask(TaskRequest) returns (TaskResponse);
  rpc GetCapabilities(Empty) returns (CapabilitiesResponse);
}
```

### 2. Generate Code
```bash
make proto-generate
```

### 3. Implement Agent
Create `cmd/your-agent/main.go`:
```go
package main

import (
    "github.com/workos/workos-ai/internal/agents"
)

type YourAgent struct {
    *agents.AbstractAgent
}

func NewYourAgent() *YourAgent {
    return &YourAgent{
        AbstractAgent: agents.NewAbstractAgent(
            "your-agent",
            []string{"skill1", "skill2"},
            5, // max concurrent tasks
        ),
    }
}

func (a *YourAgent) ExecuteTask(ctx context.Context, task *agents.Task) (*agents.TaskResult, error) {
    // Implement task execution logic
    return &agents.TaskResult{
        TaskID: task.ID,
        Status: "success",
        Output: map[string]interface{}{},
    }, nil
}
```

### 4. Create Entry Point
```go
func main() {
    agent := NewYourAgent()
    // Register with orchestrator
}
```

### 5. Add Dockerfile
Create `deploy/docker/Dockerfile.your-agent` following the pattern of existing agents.

### 6. Add K8s Manifest
Add to `deploy/k8s/workos-agents.yaml`.

## Database Queries

### Find Tasks by Agent and Status
```sql
SELECT * FROM tasks 
WHERE assigned_agent = 'hr-agent' AND status = 'in_progress'
ORDER BY priority DESC;
```

### Get Recent Events
```sql
SELECT * FROM events 
ORDER BY created_at DESC 
LIMIT 50;
```

### Search Knowledge Graph
```sql
SELECT * FROM entities 
WHERE search_text @@ to_tsquery('english', 'keyword')
LIMIT 10;
```

### Vector Search (Semantic)
```sql
SELECT * FROM entities 
ORDER BY embeddings <=> $1 
LIMIT 10;
```

## gRPC Testing

### Using grpcurl
```bash
# Install grpcurl
go install github.com/fullstorydev/grpcurl/cmd/grpcurl@latest

# List services
grpcurl -plaintext localhost:50051 list

# Call ExecuteTask
grpcurl -plaintext -d '{}' \
  localhost:50051 \
  workos.api.Orchestrator/SubmitTask
```

## Debugging

### Enable Debug Logging
```bash
export LOG_LEVEL=debug
go run ./cmd/orchestrator/main.go
```

### View Docker Logs
```bash
docker-compose logs -f orchestrator
docker-compose logs -f postgres
docker-compose logs -f rabbitmq
```

### Connect to Database
```bash
docker-compose exec postgres psql -U workos -d workos_ai
```

### Access RabbitMQ Management
```
http://localhost:15672
Username: guest
Password: guest
```

## Performance Optimization

### Connection Pooling
- Adjust `max_open_conns` in database config
- Connection pool size for RabbitMQ

### Caching
- Use Redis for frequently accessed entities
- Cache knowledge graph queries

### Batching
- Batch event publishing
- Batch database inserts

## Security Best Practices

1. **Secrets Management**
   - Use environment variables for sensitive data
   - Rotate API keys regularly
   - Use Kubernetes Secrets for production

2. **Network Security**
   - Enable NetworkPolicy in Kubernetes
   - Use TLS for gRPC communication
   - Authenticate agents

3. **Data Protection**
   - Enable SSL for PostgreSQL
   - Encrypt sensitive fields
   - Audit access logs

## Deployment

### Local Docker Compose
```bash
docker-compose up -d
```

### Kubernetes
```bash
# Create namespace and deploy
kubectl apply -f deploy/k8s/workos-core.yaml
kubectl apply -f deploy/k8s/workos-agents.yaml

# Check status
kubectl get pods -n workos-ai
kubectl get svc -n workos-ai

# View logs
kubectl logs -n workos-ai deployment/orchestrator
```

### CI/CD Pipeline
See `.github/workflows/` for GitHub Actions setup.

## Common Issues

### Issue: Database Connection Refused
**Solution:**
```bash
docker-compose up -d postgres
# Wait for postgres to be ready
docker-compose exec postgres pg_isready
```

### Issue: gRPC Connection Failed
**Solution:**
- Ensure services are running: `make run-all`
- Check service ports: `netstat -an | grep 5005`
- Verify environment variables

### Issue: Out of Memory
**Solution:**
- Increase Docker memory: `docker-compose config | grep mem_limit`
- Reduce worker pool size
- Enable memory profiling

## Performance Monitoring

### Prometheus Metrics
- Add prometheus client library
- Export metrics from each service
- Scrape metrics in Prometheus

### Grafana Dashboards
- Task execution time
- Agent utilization
- Event throughput
- Memory usage

## Contributing

See [CONTRIBUTING.md](../docs/CONTRIBUTING.md)

## Resources

- [Go gRPC Documentation](https://grpc.io/docs/languages/go/)
- [PostgreSQL Documentation](https://www.postgresql.org/docs/)
- [pgvector Documentation](https://github.com/pgvector/pgvector)
- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [RabbitMQ Tutorials](https://www.rabbitmq.com/getstarted.html)
