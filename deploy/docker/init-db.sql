-- Initialize WorkOS AI database schema
-- This script creates tables for tasks, goals, agents, events, and memory

-- Enable pgvector extension
CREATE EXTENSION IF NOT EXISTS vector;

-- Entities table (for knowledge graph)
CREATE TABLE IF NOT EXISTS entities (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    type VARCHAR(50) NOT NULL,
    name VARCHAR(255) NOT NULL,
    metadata JSONB,
    embeddings VECTOR(1536),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT entity_type_check CHECK (type IN ('employee', 'project', 'document', 'meeting', 'email'))
);

-- Relationships table (for knowledge graph edges)
CREATE TABLE IF NOT EXISTS relationships (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    from_id UUID NOT NULL REFERENCES entities(id) ON DELETE CASCADE,
    to_id UUID NOT NULL REFERENCES entities(id) ON DELETE CASCADE,
    type VARCHAR(100) NOT NULL,
    metadata JSONB,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT no_self_relationships CHECK (from_id != to_id)
);

-- Tasks table
CREATE TABLE IF NOT EXISTS tasks (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title VARCHAR(255) NOT NULL,
    description TEXT,
    assigned_agent VARCHAR(100),
    status VARCHAR(50) DEFAULT 'pending',
    priority INT DEFAULT 5,
    metadata JSONB,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    completed_at TIMESTAMP,
    CONSTRAINT task_status_check CHECK (status IN ('pending', 'in_progress', 'completed', 'failed')),
    CONSTRAINT task_priority_check CHECK (priority >= 1 AND priority <= 10)
);

-- Goals table
CREATE TABLE IF NOT EXISTS goals (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title VARCHAR(255) NOT NULL,
    description TEXT,
    deadline TIMESTAMP,
    status VARCHAR(50) DEFAULT 'planning',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    completed_at TIMESTAMP,
    CONSTRAINT goal_status_check CHECK (status IN ('planning', 'in_progress', 'completed', 'failed'))
);

-- Goal tasks association
CREATE TABLE IF NOT EXISTS goal_tasks (
    goal_id UUID NOT NULL REFERENCES goals(id) ON DELETE CASCADE,
    task_id UUID NOT NULL REFERENCES tasks(id) ON DELETE CASCADE,
    PRIMARY KEY (goal_id, task_id)
);

-- Events table (for event sourcing and audit)
CREATE TABLE IF NOT EXISTS events (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    event_type VARCHAR(100) NOT NULL,
    source VARCHAR(100) NOT NULL,
    payload JSONB,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT event_type_check CHECK (event_type IN (
        'task.created', 'task.started', 'task.completed', 'task.failed',
        'goal.created', 'goal.completed',
        'agent.registered', 'agent.error'
    ))
);

-- Memory table (for episodic and long-term memory)
CREATE TABLE IF NOT EXISTS memory (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    type VARCHAR(50) NOT NULL,
    key VARCHAR(255) NOT NULL,
    value JSONB NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    expires_at TIMESTAMP,
    CONSTRAINT memory_type_check CHECK (type IN ('short_term', 'long_term', 'episodic'))
);

-- Agents registration table
CREATE TABLE IF NOT EXISTS agents (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(100) NOT NULL UNIQUE,
    type VARCHAR(50) NOT NULL,
    capabilities JSONB,
    max_concurrent_tasks INT DEFAULT 1,
    status VARCHAR(50) DEFAULT 'inactive',
    host VARCHAR(255),
    port INT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_heartbeat TIMESTAMP
);

-- Indexes for performance
CREATE INDEX idx_tasks_status ON tasks(status);
CREATE INDEX idx_tasks_agent ON tasks(assigned_agent);
CREATE INDEX idx_tasks_priority ON tasks(priority DESC);
CREATE INDEX idx_goals_status ON goals(status);
CREATE INDEX idx_events_type ON events(event_type);
CREATE INDEX idx_events_source ON events(source);
CREATE INDEX idx_events_created_at ON events(created_at DESC);
CREATE INDEX idx_memory_type ON memory(type);
CREATE INDEX idx_memory_expires_at ON memory(expires_at);
CREATE INDEX idx_entities_type ON entities(type);
CREATE INDEX idx_entities_embeddings ON entities USING ivfflat (embeddings vector_cosine_ops);
CREATE INDEX idx_relationships_from ON relationships(from_id);
CREATE INDEX idx_relationships_to ON relationships(to_id);
CREATE INDEX idx_relationships_type ON relationships(type);

-- Full-text search for entities
ALTER TABLE entities ADD COLUMN IF NOT EXISTS search_text TSVECTOR;
CREATE INDEX idx_entities_search ON entities USING gin(search_text);

-- Function to update search_text and updated_at
CREATE OR REPLACE FUNCTION update_search_text() RETURNS TRIGGER AS $$
BEGIN
    NEW.search_text := to_tsvector('english', COALESCE(NEW.name, '') || ' ' || COALESCE(NEW.type, ''));
    NEW.updated_at := CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to update search_text on insert/update
DROP TRIGGER IF EXISTS entities_search_update ON entities;
CREATE TRIGGER entities_search_update BEFORE INSERT OR UPDATE ON entities
    FOR EACH ROW EXECUTE FUNCTION update_search_text();

-- Function to auto-update updated_at timestamp
CREATE OR REPLACE FUNCTION update_timestamp() RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at := CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply timestamp triggers to tables
DROP TRIGGER IF EXISTS update_tasks_timestamp ON tasks;
CREATE TRIGGER update_tasks_timestamp BEFORE UPDATE ON tasks
    FOR EACH ROW EXECUTE FUNCTION update_timestamp();

DROP TRIGGER IF EXISTS update_goals_timestamp ON goals;
CREATE TRIGGER update_goals_timestamp BEFORE UPDATE ON goals
    FOR EACH ROW EXECUTE FUNCTION update_timestamp();

DROP TRIGGER IF EXISTS update_memory_timestamp ON memory;
CREATE TRIGGER update_memory_timestamp BEFORE UPDATE ON memory
    FOR EACH ROW EXECUTE FUNCTION update_timestamp();

-- Create views for common queries

-- Active tasks view
CREATE OR REPLACE VIEW active_tasks AS
SELECT * FROM tasks WHERE status IN ('pending', 'in_progress')
ORDER BY priority DESC, created_at ASC;

-- Recent events view
CREATE OR REPLACE VIEW recent_events AS
SELECT * FROM events ORDER BY created_at DESC LIMIT 100;

-- Non-expired memory view
CREATE OR REPLACE VIEW active_memory AS
SELECT * FROM memory WHERE expires_at IS NULL OR expires_at > CURRENT_TIMESTAMP;
