# Sequential Thinking Tool

This tool wraps the official MCP Sequential Thinking server to provide dynamic and reflective problem-solving capabilities within the Language Operator ecosystem.

## Overview

The Sequential Thinking tool facilitates a structured, step-by-step thinking process for complex analysis and problem-solving. It allows agents to break down problems, revise their understanding, and explore alternative reasoning paths dynamically.

## Features

- **Dynamic reasoning**: Start with initial estimates and adjust as understanding deepens
- **Revision capabilities**: Question and revise previous thoughts 
- **Branching logic**: Explore alternative paths of reasoning
- **Adaptive planning**: Adjust total thought count as complexity becomes clear
- **Hypothesis testing**: Generate and verify solution hypotheses
- **Context maintenance**: Keep track of reasoning across multiple steps

## MCP Tools

### `sequential_thinking`

Facilitates a detailed, step-by-step thinking process for problem-solving and analysis.

**Parameters:**
- `thought` (string): The current thinking step
- `nextThoughtNeeded` (boolean): Whether another thought step is needed
- `thoughtNumber` (integer): Current thought number
- `totalThoughts` (integer): Estimated total thoughts needed
- `isRevision` (boolean, optional): Whether this revises previous thinking
- `revisesThought` (integer, optional): Which thought is being reconsidered  
- `branchFromThought` (integer, optional): Branching point thought number
- `branchId` (string, optional): Branch identifier
- `needsMoreThoughts` (boolean, optional): If more thoughts are needed

**Returns:**
- Structured thinking progress with thought tracking
- Branch management for alternative reasoning paths
- Completion status and next step guidance

## Use Cases

Perfect for:
- Breaking down complex problems into manageable steps
- Planning and design with room for revision  
- Analysis that might need course correction
- Problems where the full scope isn't initially clear
- Multi-step solutions requiring context maintenance
- Filtering out irrelevant information during reasoning
- Hypothesis-driven problem solving

## Architecture

This tool is a simple wrapper around the official MCP Sequential Thinking server:
- **Base Image**: `mcp/sequentialthinking:latest`
- **Protocol**: HTTP-based MCP server on port 80
- **Dependencies**: None (pure reasoning tool)
- **Storage**: Stateless (thoughts maintained in session context)

## Integration

Agents can use this tool to:
1. Structure complex reasoning processes
2. Maintain coherent thinking across multiple steps
3. Revise and refine understanding as problems evolve
4. Explore alternative solution paths
5. Generate and test hypotheses systematically

The tool integrates seamlessly with Language Operator agents through the standard MCP protocol, providing sophisticated reasoning capabilities without external dependencies.