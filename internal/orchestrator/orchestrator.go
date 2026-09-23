package orchestrator

import (
	"context"
	"sync"

	"github.com/workos/workos-ai/internal/agents"
	"github.com/workos/workos-ai/internal/events"
	"github.com/workos/workos-ai/internal/memory"
)

// Orchestrator coordinates task execution across multiple agents
type Orchestrator struct {
	mu           sync.RWMutex
	agents       map[string]agents.BaseAgent
	taskQueue    chan *agents.Task
	eventBus     events.EventBus
	memorySystem *memory.MemorySystem
	activeTasks  map[string]*agents.Task
	maxQueueSize int
}

// NewOrchestrator creates a new orchestrator
func NewOrchestrator(eventBus events.EventBus, maxQueueSize int) *Orchestrator {
	return &Orchestrator{
		agents:       make(map[string]agents.BaseAgent),
		taskQueue:    make(chan *agents.Task, maxQueueSize),
		eventBus:     eventBus,
		memorySystem: memory.NewMemorySystem(),
		activeTasks:  make(map[string]*agents.Task),
		maxQueueSize: maxQueueSize,
	}
}

// RegisterAgent registers a new agent with the orchestrator
func (o *Orchestrator) RegisterAgent(agentType string, agent agents.BaseAgent) error {
	o.mu.Lock()
	defer o.mu.Unlock()

	o.agents[agentType] = agent

	// Emit agent registered event
	event := events.NewEvent(events.AgentRegistered, "orchestrator", map[string]interface{}{
		"agent_type": agentType,
		"agent_name": agent.Name(),
		"skills":     agent.Skills(),
	})
	o.eventBus.Publish(context.Background(), event)

	return nil
}

// SubmitTask submits a task for execution
func (o *Orchestrator) SubmitTask(ctx context.Context, task *agents.Task) error {
	o.mu.Lock()
	o.activeTasks[task.ID] = task
	o.mu.Unlock()

	// Route task to appropriate agent
	agent := o.selectAgent(task)
	if agent == nil {
		// Emit task failed event
		event := events.NewEvent(events.TaskFailed, "orchestrator", map[string]interface{}{
			"task_id": task.ID,
			"reason":  "No suitable agent found",
		})
		o.eventBus.Publish(ctx, event)
		return nil
	}

	// Emit task created event
	createEvent := events.NewEvent(events.TaskCreated, "orchestrator", map[string]interface{}{
		"task_id":  task.ID,
		"title":    task.Title,
		"agent":    agent.Name(),
		"priority": task.Priority,
	})
	o.eventBus.Publish(ctx, createEvent)

	// Execute task
	go func() {
		// Emit task started event
		startEvent := events.NewEvent(events.TaskStarted, "orchestrator", map[string]interface{}{
			"task_id": task.ID,
		})
		o.eventBus.Publish(context.Background(), startEvent)

		// Execute the task
		result, err := agent.ExecuteTask(ctx, task)

		if err != nil || result.Status == "failed" {
			// Emit task failed event
			failEvent := events.NewEvent(events.TaskFailed, "orchestrator", map[string]interface{}{
				"task_id": task.ID,
				"error":   err.Error(),
			})
			o.eventBus.Publish(context.Background(), failEvent)
		} else {
			// Emit task completed event
			completeEvent := events.NewEvent(events.TaskCompleted, "orchestrator", map[string]interface{}{
				"task_id": task.ID,
				"result":  result.Output,
			})
			o.eventBus.Publish(context.Background(), completeEvent)
		}

		// Clean up active task
		o.mu.Lock()
		delete(o.activeTasks, task.ID)
		o.mu.Unlock()
	}()

	return nil
}

// GetActiveTasks returns all active tasks
func (o *Orchestrator) GetActiveTasks() []*agents.Task {
	o.mu.RLock()
	defer o.mu.RUnlock()

	tasks := make([]*agents.Task, 0, len(o.activeTasks))
	for _, task := range o.activeTasks {
		tasks = append(tasks, task)
	}
	return tasks
}

// selectAgent selects the best agent for a task
func (o *Orchestrator) selectAgent(task *agents.Task) agents.BaseAgent {
	o.mu.RLock()
	defer o.mu.RUnlock()

	// Find agent that can handle the task
	for _, agent := range o.agents {
		if agent.CanHandle(task.Type) {
			return agent
		}
	}
	return nil
}

// GetMemorySystem returns the memory system
func (o *Orchestrator) GetMemorySystem() *memory.MemorySystem {
	return o.memorySystem
}
