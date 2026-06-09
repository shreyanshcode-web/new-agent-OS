# WorkOS AI - Autonomous Enterprise Operating System

> An AI system that acts as a company's digital workforce, coordinating multiple specialized agents to automate enterprise operations.

## Vision

Instead of employees switching between 20 tools (Email, Slack, Jira, GitHub, Notion, CRM, Analytics), **WorkOS AI agents coordinate everything automatically**.

### Example Workflow
```
Manager: "Launch a marketing campaign for our new AI product next week."

System automatically:
✓ Understands the goal
✓ Creates tasks
✓ Assigns specialized agents (Marketing, Dev, Sales, HR)
✓ Searches company knowledge
✓ Generates content
✓ Schedules meetings
✓ Tracks execution
✓ Reports progress

No manual coordination needed.
```

## Architecture Overview

### 10-Layer System Architecture

```
USER
  ↓
Executive AI Agent (Master Planner)
  ↓
Multi-Agent Orchestrator
  ├── Knowledge Agent
  ├── Task Agent
  └── Analytics Agent
  ↓
Specialized Agents
├── HR Agent (Hiring, Onboarding)
├── Sales Agent (Lead Qualification, CRM)
├── Dev Agent (Code Review, Bug Detection)
└── Marketing Agent (Campaign, Content)
  ↓
Enterprise Memory System
  ├── Email Integration
  ├── CRM Integration
  ├── GitHub Integration
  └── Document Storage
  ↓
Continuous Learning Engine
```

## Core Components

### 1. Executive AI Agent
- Converts high-level goals into actionable subtasks
- Decomposes business objectives
- Manages deadlines and priorities

### 2. Multi-Agent Orchestrator
- Routes tasks to specialized agents
- Resolves conflicts
- Manages dependencies
- Monitors workflow execution
- Ranks tasks by business impact

### 3. Specialized Agents
- **HR Agent**: Resume screening, interview scheduling, employee queries
- **Sales Agent**: Lead qualification, CRM updates, forecasting
- **Dev Agent**: Code analysis, PR reviews, bug detection
- **Marketing Agent**: Campaign creation, SEO, social media

### 4. Enterprise Knowledge Brain
- Unified knowledge graph (PostgreSQL + pgvector)
- Stores employees, projects, documents, meetings, emails
- Enables intelligent reasoning and retrieval

### 5. Hybrid Search System
- BM25 keyword search
- Vector embeddings (pgvector)
- Knowledge graph traversal
- Rank fusion for best results

### 6. Event-Driven Communication
- RabbitMQ event bus
- Asynchronous agent communication
- Event sourcing for audit trail

### 7. Memory System
- **Short-term**: Current session state
- **Long-term**: Projects, conversations, decisions
- **Episodic**: What happened, when, who, outcome

## Tech Stack

- **Language**: Go 1.21+
- **RPC Framework**: gRPC with Protocol Buffers
- **Database**: PostgreSQL with pgvector extension
- **Message Queue**: RabbitMQ
- **LLM Integration**: OpenAI API
- **Logging**: Uber Zap
- **Orchestration**: Kubernetes
- **Containerization**: Docker

## Project Structure

```
workos-ai/
├── cmd/
│   ├── orchestrator/          # Main orchestration service
│   ├── executive-agent/       # Executive agent service
│   ├── hr-agent/              # HR specialized agent
│   ├── sales-agent/           # Sales specialized agent
│   ├── dev-agent/             # Dev specialized agent
│   └── marketing-agent/       # Marketing specialized agent
├── internal/
│   ├── orchestrator/          # Core orchestration logic
│   ├── agents/                # Base agent implementations
│   ├── knowledge/             # Knowledge graph operations
│   ├── events/                # Event bus and handlers
│   └── memory/                # Memory management systems
├── pkg/
│   ├── models/                # Shared data models
│   ├── grpc/                  # gRPC client/server utilities
│   └── database/              # Database connection pools
├── api/
│   └── proto/                 # Protocol buffer definitions
├── deploy/
│   ├── k8s/                   # Kubernetes manifests
│   └── docker/                # Dockerfiles for each service
├── tests/
│   └── integration/           # Integration tests
├── docs/                      # Project documentation
├── go.mod                     # Go module definition
├── Makefile                   # Build automation
├── docker-compose.yml         # Local development stack
└── .env.example               # Environment variable template
```

## Getting Started

### Prerequisites
- Go 1.21+
- Docker & Docker Compose
- PostgreSQL 15+
- RabbitMQ 3.12+
- Protocol Buffer Compiler (protoc)

### Local Development

1. **Clone and setup**
```bash
git clone https://github.com/workos/workos-ai.git
cd workos-ai
cp .env.example .env
```

2. **Start dependencies**
```bash
docker-compose up -d
```

3. **Initialize database**
```bash
make db-migrate
```

4. **Generate gRPC code**
```bash
make proto-generate
```

5. **Build all services**
```bash
make build-all
```

6. **Run orchestrator**
```bash
make run-orchestrator
```

## API Documentation

### gRPC Services

#### ExecutiveAgentService
```proto
service ExecutiveAgent {
  rpc PlanGoal(GoalRequest) returns (PlanResponse);
  rpc GetStatus(StatusRequest) returns (StatusResponse);
  rpc CancelPlan(CancelRequest) returns (Empty);
}
```

#### OrchestratorService
```proto
service Orchestrator {
  rpc SubmitTask(TaskRequest) returns (TaskResponse);
  rpc GetTaskStatus(TaskStatusRequest) returns (TaskStatusResponse);
  rpc ListActiveTasks(Empty) returns (TaskList);
}
```

#### Agent Services (HR, Sales, Dev, Marketing)
```proto
service Agent {
  rpc ExecuteTask(TaskRequest) returns (TaskResult);
  rpc GetCapabilities(Empty) returns (CapabilitiesResponse);
}
```

## Configuration

Create `.env` file from `.env.example`:

```env
# Database
DB_HOST=localhost
DB_PORT=5432
DB_USER=workos
DB_PASSWORD=workos-dev
DB_NAME=workos_ai

# RabbitMQ
RABBITMQ_URL=amqp://guest:guest@localhost:5672/

# OpenAI
OPENAI_API_KEY=sk-...

# Services
ORCHESTRATOR_PORT=50051
EXECUTIVE_AGENT_PORT=50052
HR_AGENT_PORT=50053
SALES_AGENT_PORT=50054
DEV_AGENT_PORT=50055
MARKETING_AGENT_PORT=50056

# Logging
LOG_LEVEL=info
```

## Running Tests

```bash
make test                    # Run all tests
make test-integration        # Integration tests only
make test-coverage          # Coverage report
```

## Deployment

### Local with Docker Compose
```bash
docker-compose up -d
```

### Kubernetes
```bash
kubectl apply -f deploy/k8s/
```

See [deployment guide](docs/DEPLOYMENT.md) for details.

## Development Workflow

### Adding a New Agent

1. Define proto in `api/proto/agents.proto`
2. Generate gRPC code: `make proto-generate`
3. Create `cmd/<agent-name>/main.go`
4. Implement agent logic in `internal/agents/`
5. Add Docker configuration in `deploy/docker/`
6. Add K8s manifest in `deploy/k8s/`

### Running Locally

```bash
# Terminal 1: Start dependencies
docker-compose up -d

# Terminal 2: Executive Agent
go run cmd/executive-agent/main.go

# Terminal 3: Orchestrator
go run cmd/orchestrator/main.go

# Terminal 4: HR Agent
go run cmd/hr-agent/main.go
```

## MVP Features (Week 1-2)

- [x] Executive Agent with goal decomposition
- [x] Multi-agent orchestrator with routing
- [x] Event-driven communication bus
- [x] Knowledge graph with PostgreSQL + pgvector
- [x] Hybrid search system
- [x] Task execution engine
- [x] Memory management (short/long/episodic)
- [x] Autonomous workflow execution
- [x] Explainable decision logging
- [ ] UI Dashboard
- [ ] Advanced learning engine
- [ ] Multi-LLM support

## Architecture Decisions

### Why Go?
- High performance for microservices
- Excellent concurrency model (goroutines)
- Fast compilation and deployment
- Strong typing and memory safety
- Native gRPC support

### Why PostgreSQL + pgvector?
- Rich query capabilities
- Vector search for semantic retrieval
- JSON support for flexible schemas
- ACID compliance
- Strong ecosystem

### Why gRPC?
- High performance binary protocol
- Strong typing with Protocol Buffers
- Built-in streaming support
- Multi-language compatibility
- Native load balancing

### Event-Driven for Agent Communication?
- Loose coupling between agents
- Scalability and resilience
- Natural audit trail
- Easy addition of new agents
- Replay capability

## Contributing

See [CONTRIBUTING.md](docs/CONTRIBUTING.md) for guidelines.

## License

MIT License - See LICENSE file

## Roadmap

### Phase 1: MVP (Week 1-2)
- Core orchestration engine
- 4 specialized agents
- Basic knowledge graph
- Simple memory system

### Phase 2: Advanced (Week 3-4)
- Multi-LLM support
- Advanced learning engine
- Real-time dashboard
- Performance optimizations

### Phase 3: Enterprise (Week 5-8)
- Multi-tenancy
- Advanced security
- Compliance frameworks
- White-label support

## Support

- 📧 Email: support@workos.ai
- 💬 Discord: [Join Community](https://discord.gg/workos)
- 📖 Docs: https://docs.workos.ai
- 🐛 Issues: GitHub Issues

---

**Built for enterprises. Powered by AI. Designed for the future of work.**
