package memory

import (
	"sync"
	"time"
)

// MemoryType represents the type of memory
type MemoryType string

const (
	ShortTermMemory MemoryType = "short_term"
	LongTermMemory  MemoryType = "long_term"
	EpisodicMemory  MemoryType = "episodic"
)

// MemoryEntry represents a piece of information stored in memory
type MemoryEntry struct {
	ID        string
	Type      MemoryType
	Key       string
	Value     interface{}
	CreatedAt time.Time
	UpdatedAt time.Time
	ExpiresAt *time.Time
}

// MemorySystem manages all memory types
type MemorySystem struct {
	mu      sync.RWMutex
	entries map[string]*MemoryEntry
}

// NewMemorySystem creates a new memory system
func NewMemorySystem() *MemorySystem {
	return &MemorySystem{
		entries: make(map[string]*MemoryEntry),
	}
}

// Store stores information in memory
func (ms *MemorySystem) Store(key string, value interface{}, memType MemoryType) *MemoryEntry {
	ms.mu.Lock()
	defer ms.mu.Unlock()

	var expiresAt *time.Time
	now := time.Now()

	// Set expiration based on memory type
	switch memType {
	case ShortTermMemory:
		exp := now.Add(1 * time.Hour)
		expiresAt = &exp
	case LongTermMemory:
		exp := now.Add(365 * 24 * time.Hour)
		expiresAt = &exp
	case EpisodicMemory:
		// No expiration for episodic memory
	}

	entry := &MemoryEntry{
		ID:        generateMemoryID(),
		Type:      memType,
		Key:       key,
		Value:     value,
		CreatedAt: now,
		UpdatedAt: now,
		ExpiresAt: expiresAt,
	}

	ms.entries[entry.ID] = entry
	return entry
}

// Recall retrieves information from memory
func (ms *MemorySystem) Recall(key string) interface{} {
	ms.mu.RLock()
	defer ms.mu.RUnlock()

	for _, entry := range ms.entries {
		if entry.Key == key && !entry.IsExpired() {
			return entry.Value
		}
	}
	return nil
}

// RecallAll returns all non-expired memories
func (ms *MemorySystem) RecallAll(memType MemoryType) []*MemoryEntry {
	ms.mu.RLock()
	defer ms.mu.RUnlock()

	var result []*MemoryEntry
	for _, entry := range ms.entries {
		if entry.Type == memType && !entry.IsExpired() {
			result = append(result, entry)
		}
	}
	return result
}

// Forget removes a memory entry
func (ms *MemorySystem) Forget(id string) {
	ms.mu.Lock()
	defer ms.mu.Unlock()
	delete(ms.entries, id)
}

// ForgetExpired removes all expired entries
func (ms *MemorySystem) ForgetExpired() {
	ms.mu.Lock()
	defer ms.mu.Unlock()

	for id, entry := range ms.entries {
		if entry.IsExpired() {
			delete(ms.entries, id)
		}
	}
}

// IsExpired checks if an entry has expired
func (me *MemoryEntry) IsExpired() bool {
	if me.ExpiresAt == nil {
		return false
	}
	return time.Now().After(*me.ExpiresAt)
}

func generateMemoryID() string {
	// TODO: Generate unique memory ID
	return ""
}
