package agents

import (
	"context"
)

// BaseAgent defines the interface that all agents must implement
type BaseAgent interface {
	// Name returns the agent name
	Name() string

	// Skills returns the list of skills this agent has
	Skills() []string

	// MaxConcurrentTasks returns the maximum concurrent tasks this agent can handle
	MaxConcurrentTasks() int

	// ExecuteTask executes a task
	ExecuteTask(ctx context.Context, task *Task) (*TaskResult, error)

	// CanHandle checks if agent can handle a specific task type
	CanHandle(taskType string) bool
}

// Task represents a unit of work
type Task struct {
	ID          string
	Title       string
	Description string
	Type        string
	Priority    int
	Parameters  map[string]interface{}
	CreatedAt   string
}

// TaskResult represents the result of task execution
type TaskResult struct {
	TaskID   string
	Status   string // success, failed, partial
	Output   map[string]interface{}
	Error    string
	Duration int64 // milliseconds
	Metadata map[string]interface{}
}

// AbstractAgent provides a base implementation
type AbstractAgent struct {
	name                string
	skills              []string
	maxConcurrentTasks  int
	currentRunningTasks int
}

// NewAbstractAgent creates a new abstract agent
func NewAbstractAgent(name string, skills []string, maxConcurrentTasks int) *AbstractAgent {
	return &AbstractAgent{
		name:                name,
		skills:              skills,
		maxConcurrentTasks:  maxConcurrentTasks,
		currentRunningTasks: 0,
	}
}

// Name returns the agent name
func (a *AbstractAgent) Name() string {
	return a.name
}

// Skills returns the agent skills
func (a *AbstractAgent) Skills() []string {
	return a.skills
}

// MaxConcurrentTasks returns max concurrent tasks
func (a *AbstractAgent) MaxConcurrentTasks() int {
	return a.maxConcurrentTasks
}

// CanHandle checks if agent can handle task type
func (a *AbstractAgent) CanHandle(taskType string) bool {
	for _, skill := range a.skills {
		if skill == taskType {
			return true
		}
	}
	return false
}

// ExecuteTask should be overridden by concrete agents
func (a *AbstractAgent) ExecuteTask(ctx context.Context, task *Task) (*TaskResult, error) {
	return &TaskResult{
		TaskID: task.ID,
		Status: "not_implemented",
	}, nil
}
