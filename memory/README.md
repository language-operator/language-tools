# Knowledge Graph Memory Tool

This tool wraps the official MCP Memory server to provide persistent knowledge graph capabilities within the Language Operator ecosystem. It enables agents to remember and recall information across conversations using a structured entity-relationship model.

## Overview

The Memory tool implements a persistent knowledge graph stored as a JSONL file. It allows agents to build and maintain memory about users, relationships, events, and observations over time.

## Features

- **Entity management**: Create and track people, organizations, events, and concepts
- **Relationship mapping**: Define directed connections between entities
- **Observation storage**: Record discrete facts and insights about entities  
- **Persistent memory**: JSONL file storage that survives restarts
- **Search capabilities**: Query across entity names, types, and observations
- **Graph operations**: Read entire graph or specific node subsets

## Core Concepts

### Entities
Primary nodes with unique names, types, and associated observations:
```json
{
  "name": "John_Smith",
  "entityType": "person", 
  "observations": ["Speaks fluent Spanish", "Prefers morning meetings"]
}
```

### Relations
Directed connections between entities in active voice:
```json
{
  "from": "John_Smith",
  "to": "Anthropic",
  "relationType": "works_at"
}
```

### Observations
Atomic facts stored as strings attached to entities:
- One fact per observation
- Independently addable/removable
- Searchable content

## MCP Tools

### Entity Management
- **`create_entities`**: Create multiple new entities with types and observations
- **`delete_entities`**: Remove entities and cascading relations
- **`add_observations`**: Add new facts to existing entities
- **`delete_observations`**: Remove specific observations from entities

### Relationship Management  
- **`create_relations`**: Create directed relationships between entities
- **`delete_relations`**: Remove specific relationships from the graph

### Query Operations
- **`read_graph`**: Retrieve the complete knowledge graph
- **`search_nodes`**: Find entities by name, type, or observation content
- **`open_nodes`**: Get specific entities and their interconnections

## Use Cases

Perfect for:
- **User profiling**: Track preferences, goals, and behaviors across sessions
- **Relationship mapping**: Model personal and professional networks
- **Context retention**: Maintain conversation history and insights
- **Project tracking**: Remember ongoing work and commitments
- **Learning adaptation**: Adjust responses based on accumulated knowledge

## Architecture

This tool wraps the official MCP Memory server:
- **Base Image**: `mcp/memory:latest`
- **Storage**: JSONL file at `/app/dist/memory.jsonl`
- **Deployment**: Sidecar mode with persistent volume
- **Protocol**: HTTP-based MCP server on port 80

## Integration

Agents can use this tool to:

1. **Initialize memory**: Create user entity and basic profile
2. **Accumulate knowledge**: Add observations about preferences and behaviors
3. **Build relationships**: Map connections between people and organizations
4. **Query context**: Search for relevant information before responding
5. **Update understanding**: Modify or correct previous observations

The memory persists across agent restarts and conversations, enabling true continuity and personalization over time.

## Storage Requirements

- Persistent volume required for memory retention
- JSONL format for efficient append operations
- Backward compatibility with legacy JSON format
- Configurable storage path via environment variables