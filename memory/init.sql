-- =============================================================================
-- WOW AI — PostgreSQL + pgvector Memory Schema
-- =============================================================================
-- This initializes the database with all tables needed for:
-- 1. Agent memory (vectorized semantic search)
-- 2. Agent state tracking
-- 3. Task management
-- 4. Audit logging
-- 5. DND queue
-- =============================================================================

-- Enable pgvector extension
CREATE EXTENSION IF NOT EXISTS vector;
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- =============================================================================
-- 1. AGENT MEMORY — Vectorized semantic storage
-- =============================================================================
CREATE TABLE IF NOT EXISTS agent_memory (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    agent_name VARCHAR(100) NOT NULL,
    project_name VARCHAR(255),
    memory_type VARCHAR(50) NOT NULL CHECK (memory_type IN (
        'decision', 'design', 'implementation', 'test_result',
        'deployment', 'research', 'error', 'pattern', 'feedback'
    )),
    content TEXT NOT NULL,
    embedding vector(768),           -- nomic-embed-text dimension
    metadata JSONB DEFAULT '{}',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    is_active BOOLEAN DEFAULT TRUE
);

-- Index for fast vector similarity search
CREATE INDEX IF NOT EXISTS idx_memory_embedding
    ON agent_memory USING ivfflat (embedding vector_cosine_ops)
    WITH (lists = 100);

-- Index for filtering by agent and project
CREATE INDEX IF NOT EXISTS idx_memory_agent ON agent_memory(agent_name);
CREATE INDEX IF NOT EXISTS idx_memory_project ON agent_memory(project_name);
CREATE INDEX IF NOT EXISTS idx_memory_type ON agent_memory(memory_type);
CREATE INDEX IF NOT EXISTS idx_memory_active ON agent_memory(is_active);

-- =============================================================================
-- 2. AGENT STATE — Track active agents and their status
-- =============================================================================
CREATE TABLE IF NOT EXISTS agent_state (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    agent_name VARCHAR(100) NOT NULL,
    parent_agent VARCHAR(100),
    status VARCHAR(50) NOT NULL CHECK (status IN (
        'initializing', 'running', 'paused', 'completed',
        'failed', 'terminated', 'respawning'
    )),
    current_task TEXT,
    model VARCHAR(255),
    spawn_depth INTEGER DEFAULT 0,
    started_at TIMESTAMPTZ DEFAULT NOW(),
    last_heartbeat TIMESTAMPTZ DEFAULT NOW(),
    completed_at TIMESTAMPTZ,
    exit_code INTEGER,
    exit_reason TEXT,
    metadata JSONB DEFAULT '{}'
);

CREATE INDEX IF NOT EXISTS idx_agent_status ON agent_state(status);
CREATE INDEX IF NOT EXISTS idx_agent_name ON agent_state(agent_name);
CREATE INDEX IF NOT EXISTS idx_agent_parent ON agent_state(parent_agent);

-- =============================================================================
-- 3. TASKS — Task tracking and delegation
-- =============================================================================
CREATE TABLE IF NOT EXISTS tasks (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    project_name VARCHAR(255) NOT NULL,
    title VARCHAR(500) NOT NULL,
    description TEXT,
    status VARCHAR(50) NOT NULL CHECK (status IN (
        'pending', 'assigned', 'in_progress', 'blocked',
        'review', 'completed', 'failed', 'cancelled'
    )),
    priority VARCHAR(20) DEFAULT 'medium' CHECK (priority IN (
        'critical', 'high', 'medium', 'low'
    )),
    assigned_agent VARCHAR(100),
    parent_task_id UUID REFERENCES tasks(id),
    progress_percent INTEGER DEFAULT 0 CHECK (progress_percent BETWEEN 0 AND 100),
    result TEXT,
    error TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    started_at TIMESTAMPTZ,
    completed_at TIMESTAMPTZ,
    metadata JSONB DEFAULT '{}'
);

CREATE INDEX IF NOT EXISTS idx_task_status ON tasks(status);
CREATE INDEX IF NOT EXISTS idx_task_project ON tasks(project_name);
CREATE INDEX IF NOT EXISTS idx_task_agent ON tasks(assigned_agent);
CREATE INDEX IF NOT EXISTS idx_task_parent ON tasks(parent_task_id);

-- =============================================================================
-- 4. AUDIT LOG — Complete audit trail of agent actions
-- =============================================================================
CREATE TABLE IF NOT EXISTS audit_log (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    event_type VARCHAR(100) NOT NULL,
    agent_name VARCHAR(100),
    project_name VARCHAR(255),
    action TEXT NOT NULL,
    details JSONB DEFAULT '{}',
    severity VARCHAR(20) DEFAULT 'info' CHECK (severity IN (
        'debug', 'info', 'warn', 'error', 'critical'
    )),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_audit_event ON audit_log(event_type);
CREATE INDEX IF NOT EXISTS idx_audit_agent ON audit_log(agent_name);
CREATE INDEX IF NOT EXISTS idx_audit_severity ON audit_log(severity);
CREATE INDEX IF NOT EXISTS idx_audit_time ON audit_log(created_at DESC);

-- =============================================================================
-- 5. DND QUEUE — Messages queued during Do Not Disturb
-- =============================================================================
CREATE TABLE IF NOT EXISTS dnd_queue (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    source_agent VARCHAR(100) NOT NULL,
    project_name VARCHAR(255),
    priority VARCHAR(20) DEFAULT 'medium' CHECK (priority IN (
        'critical', 'high', 'medium', 'low'
    )),
    message TEXT NOT NULL,
    channel VARCHAR(50) DEFAULT 'telegram',
    queued_at TIMESTAMPTZ DEFAULT NOW(),
    delivered_at TIMESTAMPTZ,
    is_delivered BOOLEAN DEFAULT FALSE
);

CREATE INDEX IF NOT EXISTS idx_dnd_delivered ON dnd_queue(is_delivered);
CREATE INDEX IF NOT EXISTS idx_dnd_priority ON dnd_queue(priority);

-- =============================================================================
-- 6. PROJECTS — Project tracking
-- =============================================================================
CREATE TABLE IF NOT EXISTS projects (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(255) NOT NULL UNIQUE,
    description TEXT,
    status VARCHAR(50) DEFAULT 'active' CHECK (status IN (
        'planning', 'active', 'paused', 'completed', 'archived'
    )),
    tech_stack JSONB DEFAULT '[]',
    github_repo VARCHAR(500),
    deployment_url VARCHAR(500),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    completed_at TIMESTAMPTZ,
    metadata JSONB DEFAULT '{}'
);

CREATE INDEX IF NOT EXISTS idx_project_status ON projects(status);

-- =============================================================================
-- 7. HITL REQUESTS — Human-in-the-Loop approval tracking
-- =============================================================================
CREATE TABLE IF NOT EXISTS hitl_requests (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    agent_name VARCHAR(100) NOT NULL,
    project_name VARCHAR(255),
    action_type VARCHAR(100) NOT NULL,
    description TEXT NOT NULL,
    risk_level VARCHAR(20) DEFAULT 'medium',
    status VARCHAR(50) DEFAULT 'pending' CHECK (status IN (
        'pending', 'approved', 'denied', 'expired'
    )),
    requested_at TIMESTAMPTZ DEFAULT NOW(),
    responded_at TIMESTAMPTZ,
    responded_by VARCHAR(255),
    response_message TEXT,
    timeout_hours INTEGER DEFAULT 24,
    on_timeout VARCHAR(50) DEFAULT 'deny'
);

CREATE INDEX IF NOT EXISTS idx_hitl_status ON hitl_requests(status);

-- =============================================================================
-- HELPER FUNCTIONS
-- =============================================================================

-- Function to search memory by semantic similarity
CREATE OR REPLACE FUNCTION search_memory(
    query_embedding vector(768),
    match_threshold FLOAT DEFAULT 0.7,
    match_count INT DEFAULT 10,
    filter_agent VARCHAR DEFAULT NULL,
    filter_project VARCHAR DEFAULT NULL
)
RETURNS TABLE (
    id UUID,
    agent_name VARCHAR,
    project_name VARCHAR,
    memory_type VARCHAR,
    content TEXT,
    similarity FLOAT,
    created_at TIMESTAMPTZ
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT
        m.id,
        m.agent_name,
        m.project_name,
        m.memory_type,
        m.content,
        1 - (m.embedding <=> query_embedding) AS similarity,
        m.created_at
    FROM agent_memory m
    WHERE m.is_active = TRUE
        AND (filter_agent IS NULL OR m.agent_name = filter_agent)
        AND (filter_project IS NULL OR m.project_name = filter_project)
        AND 1 - (m.embedding <=> query_embedding) > match_threshold
    ORDER BY m.embedding <=> query_embedding
    LIMIT match_count;
END;
$$;

-- Function to clean up stale agent states
CREATE OR REPLACE FUNCTION cleanup_stale_agents(stale_threshold INTERVAL DEFAULT '2 hours')
RETURNS INTEGER
LANGUAGE plpgsql
AS $$
DECLARE
    affected INTEGER;
BEGIN
    UPDATE agent_state
    SET status = 'failed',
        exit_reason = 'Stale: no heartbeat for ' || stale_threshold::TEXT,
        completed_at = NOW()
    WHERE status IN ('running', 'initializing')
        AND last_heartbeat < NOW() - stale_threshold;

    GET DIAGNOSTICS affected = ROW_COUNT;
    RETURN affected;
END;
$$;
