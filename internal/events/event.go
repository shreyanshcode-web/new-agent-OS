package events

import (
	"context"
	"encoding/json"
	"time"
)

// EventType represents the type of event
type EventType string

const (
	TaskCreated     EventType = "task.created"
	TaskStarted     EventType = "task.started"
	TaskCompleted   EventType = "task.completed"
	TaskFailed      EventType = "task.failed"
	GoalCreated     EventType = "goal.created"
	GoalCompleted   EventType = "goal.completed"
	AgentRegistered EventType = "agent.registered"
	AgentError      EventType = "agent.error"
)

// Event represents a domain event
type Event struct {
	ID        string                 `json:"id"`
	Type      EventType              `json:"type"`
	Timestamp time.Time              `json:"timestamp"`
	Source    string                 `json:"source"` // orchestrator, executive-agent, hr-agent, etc.
	Payload   map[string]interface{} `json:"payload"`
}

// EventBus interface for publishing and subscribing to events
type EventBus interface {
	Publish(ctx context.Context, event *Event) error
	Subscribe(ctx context.Context, eventType EventType, handler EventHandler) error
	Unsubscribe(ctx context.Context, eventType EventType, handler EventHandler) error
}

// EventHandler is a function that handles events
type EventHandler func(ctx context.Context, event *Event) error

// EventStore persists events for replay and audit
type EventStore interface {
	Store(ctx context.Context, event *Event) error
	GetEventsByType(ctx context.Context, eventType EventType) ([]*Event, error)
	GetEventsBySource(ctx context.Context, source string) ([]*Event, error)
}

// NewEvent creates a new event
func NewEvent(eventType EventType, source string, payload map[string]interface{}) *Event {
	return &Event{
		ID:        generateEventID(),
		Type:      eventType,
		Timestamp: time.Now(),
		Source:    source,
		Payload:   payload,
	}
}

// ToJSON converts event to JSON
func (e *Event) ToJSON() ([]byte, error) {
	return json.Marshal(e)
}

// FromJSON creates an event from JSON
func FromJSON(data []byte) (*Event, error) {
	var event Event
	if err := json.Unmarshal(data, &event); err != nil {
		return nil, err
	}
	return &event, nil
}

func generateEventID() string {
	// TODO: Generate unique event ID (UUID)
	return ""
}
