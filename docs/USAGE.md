# MCP Server Manager - Detailed Usage Guide

## Table of Contents

1. [Overview](#overview)
2. [Installation](#installation)
3. [Configuration](#configuration)
4. [Basic Usage](#basic-usage)
5. [Project Management](#project-management)
6. [Advanced Features](#advanced-features)
7. [Script Reference](#script-reference)
8. [Makefile Reference](#makefile-reference)
9. [Troubleshooting](#troubleshooting)
10. [Best Practices](#best-practices)

## Overview

The MCP Server Manager provides a modular, flexible system for managing Model Context Protocol (MCP) servers in Claude Code. It supports both user-level (global) and project-level server configurations.

### Key Features

- **Modular Design**: Separate scripts for different operations
- **Makefile Interface**: Simple commands for common tasks
- **Flexible Configuration**: External config files with custom locations
- **Environment Variable Support**: Secure API key management
- **Project Scope**: Manage servers per-project or globally
- **Batch Operations**: Add/remove multiple servers at once
- **JSON-Based**: Uses `claude mcp add-json` for reliable server configuration

## Installation

### Prerequisites

1. **Claude Desktop** with the `claude` CLI tool
2. **Node.js** (v16 or higher) and npm
3. **Python 3** with pip
4. **Ansible** (2.9 or higher)

### Initial Setup

```bash
# 1. Clone or download this repository
git clone <repository-url>
cd claude-code-mcps

# 2. Install Ansible if not already installed
pip install ansible

# 3. Verify dependencies
make check

# 4. Create your configuration
cp mcp-servers.json.example mcp-servers.json
# Edit mcp-servers.json with your desired servers

# 5. Create .env file for API keys (if needed)
touch .env
# Add your API keys to .env

# 6. Install all servers
make add-all
```

## Configuration

### mcp-servers.json Structure

The configuration file uses the same format as Claude Desktop:

```json
{
  "mcpServers": {
    "server-name": {
      "type": "stdio",
      "command": "command-to-run",
      "args": ["arg1", "arg2"],
      "env": {
        "ENV_VAR": "value",
        "API_KEY": "${VARIABLE_FROM_ENV}"
      }
    }
  }
}
```

### Environment Variables

The `.env` file should contain sensitive data:

```bash
# API Keys
BRAVE_API_KEY=BSA-xxxxxxxxxxxxx
GITHUB_TOKEN=ghp_xxxxxxxxxxxxx
ANTHROPIC_API_KEY=sk-ant-xxxxxxxxxxxxx

# Custom variables
MY_CUSTOM_VAR=value
DATABASE_URL=postgresql://...
```

### Variable Substitution

Use `${VARIABLE_NAME}` in your JSON configuration to reference environment variables:

```json
{
  "mcpServers": {
    "brave-search": {
      "command": "npx",
      "args": ["@modelcontextprotocol/server-brave-search"],
      "env": {
        "BRAVE_API_KEY": "${BRAVE_API_KEY}"
      }
    }
  }
}
```

## Basic Usage

### List Current Servers

```bash
# List user-level servers
make list

# List project-level servers
make project-list
```

### Add Servers

```bash
# Add ALL servers from configuration
make add-all

# Add specific servers
make add SERVERS=memory,brave-search

# Add to current project
make project-add SERVERS=github
```

### Remove Servers

```bash
# Remove specific servers
make remove SERVERS=old-server

# Remove from project
make project-remove SERVERS=github
```

### Dry-Run Mode

```bash
# Preview what changes will be made without applying them
make dry-run

# Dry-run with custom files
make dry-run CONFIG_FILE=/path/to/config.json ENV_FILE=/path/to/.env

# Dry-run for project scope
make dry-run SCOPE=project PROJECT=/path/to/project
```

The dry-run will show:
- Current installation status of each server
- Environment variable resolution (✓ Resolved or ✗ NOT RESOLVED)
- Which servers will be installed, skipped, or removed
- API keys are shown partially masked for security

### Sync Configuration

```bash
# Sync all servers (adds new, removes orphaned)
make sync

# Sync for current project
make project-sync
```

## Project Management

### Project-Specific Servers

Install servers that are only available within a specific project:

```bash
# Method 1: Using project-specific targets
cd /path/to/project
make project-sync

# Method 2: Specifying project path
make sync SCOPE=project PROJECT=/path/to/project

# Method 3: Using scripts directly
./manage-mcp.sh --scope project --project /path/to/project
```

### Multiple Projects

Manage different server sets for different projects:

```bash
# Project A: Development tools
make add-all SCOPE=project PROJECT=/projects/web-app \
  CONFIG_FILE=configs/dev-servers.json

# Project B: Data science tools
make add-all SCOPE=project PROJECT=/projects/ml-model \
  CONFIG_FILE=configs/ml-servers.json
```

## Advanced Features

### JSON-Based Server Installation

The tool uses Claude Code's `add-json` command internally. When you run any add operation, it:

1. Reads your `mcp-servers.json` configuration
2. Substitutes environment variables from `.env`
3. Creates temporary JSON files for each server
4. Uses `claude mcp add-json` to install the server
5. Cleans up temporary files

This approach is more reliable than command-line arguments and supports complex configurations.

### Custom Configuration Locations

```bash
# Use configuration from another directory
make sync CONFIG_FILE=/shared/configs/mcp-servers.json

# Use different environment file
make add-all ENV_FILE=/secure/secrets/.env

# Combine custom locations
make sync \
  CONFIG_FILE=/configs/production.json \
  ENV_FILE=/secrets/prod.env \
  SCOPE=project \
  PROJECT=/apps/production
```

### Selective Operations

```bash
# Add only specific servers from a large config
make add SERVERS=memory,github,sqlite

# Remove multiple servers at once
make remove SERVERS=old-v1,old-v2,deprecated-api
```

### Cleanup Operations

```bash
# Remove orphaned servers (not in config)
make clean

# Project-specific cleanup
make project-clean
```

## Script Reference

### manage-mcp.sh

The main management script with full control:

```bash
./manage-mcp.sh [OPTIONS]

Options:
  -h, --help              Show help message
  -s, --scope SCOPE       Set scope (user or project)
  -m, --mode MODE         Set mode (all, individual)
  -l, --list SERVERS      Comma-separated server list
  -p, --project PATH      Project path
  -c, --check-only        Only check dependencies
  -v, --verbose           Verbose output
  --config FILE           Path to mcp-servers.json
  --env FILE              Path to .env file
  --no-cleanup            Don't remove orphaned servers
```

### mcp-add.sh

Add specific servers:

```bash
./mcp-add.sh <servers> [OPTIONS]

Examples:
  ./mcp-add.sh memory,github
  ./mcp-add.sh sqlite --scope project --project .
```

### mcp-remove.sh

Remove specific servers:

```bash
./mcp-remove.sh <servers> [OPTIONS]

Options:
  -y, --yes               Skip confirmation
  -s, --scope SCOPE       Set scope
  -p, --project PATH      Project path
```

### mcp-sync.sh

Sync all servers from configuration:

```bash
./mcp-sync.sh [OPTIONS]

Examples:
  ./mcp-sync.sh
  ./mcp-sync.sh --config custom.json --no-cleanup
```

## Makefile Reference

### Global Targets

| Target | Description | Example |
|--------|-------------|---------|
| `help` | Show available commands | `make help` |
| `list` | List current servers | `make list` |
| `sync` | Sync all servers | `make sync` |
| `add` | Add specific servers | `make add SERVERS=memory` |
| `add-all` | Add ALL servers from config | `make add-all` |
| `remove` | Remove servers | `make remove SERVERS=github` |
| `clean` | Remove orphaned servers | `make clean` |
| `check` | Check dependencies | `make check` |
| `show-config` | Display current config | `make show-config` |

### Project-Specific Targets

| Target | Description | Example |
|--------|-------------|---------|
| `project-list` | List project servers | `make project-list` |
| `project-sync` | Sync project servers | `make project-sync` |
| `project-add` | Add to project | `make project-add SERVERS=memory` |
| `project-add-all` | Add all to project | `make project-add-all` |
| `project-remove` | Remove from project | `make project-remove SERVERS=github` |
| `project-clean` | Clean project servers | `make project-clean` |

### Variables

All targets accept these variables:

- `CONFIG_FILE` - Path to configuration (default: `mcp-servers.json`)
- `ENV_FILE` - Path to environment file (default: `.env`)
- `SCOPE` - Installation scope: `user` or `project` (default: `user`)
- `PROJECT` - Project directory (default: `.`)
- `SERVERS` - Comma-separated server list (for add/remove)

## Troubleshooting

### Common Issues

#### 1. "Command not found" errors

```bash
# Check if Claude CLI is installed
which claude

# Check Node.js installation
node --version
npm --version

# Check Ansible installation
ansible --version
```

#### 2. Configuration file not found

```bash
# Verify file exists
ls -la mcp-servers.json

# Check file is valid JSON
python -m json.tool mcp-servers.json
```

#### 3. API key errors

```bash
# Check .env file exists and has correct permissions
ls -la .env
chmod 600 .env

# Verify variables are set
grep BRAVE_API_KEY .env
```

#### 4. Server installation fails

```bash
# Run with verbose mode
./manage-mcp.sh -v --mode individual --list problematic-server

# Check server logs
claude mcp list
```

#### 5. Missing Python package runner (uvx)

If you get an error about `uvx` not being installed:

```bash
# On systems with externally-managed Python environments (Ubuntu 23.04+)
# Create a virtual environment in the project directory
python3 -m venv .venv
source .venv/bin/activate
pip install uv

# Then retry your MCP server installation
make add-all
```

Note: Some MCP servers require `uvx` (part of the `uv` Python package) to run Python-based servers. If you encounter this dependency issue, the virtual environment approach above should resolve it.

### Debug Mode

Enable verbose output for detailed troubleshooting:

```bash
# Makefile with verbose
make sync CONFIG_FILE=test.json ENV_FILE=test.env

# Scripts with verbose
./manage-mcp.sh -v --config test.json
```

## Best Practices

### 1. Configuration Management

- Keep separate configs for different environments
- Use version control for configuration files
- Never commit `.env` files to Git

```bash
# .gitignore
.env
.env.*
*-secrets.json
```

### 2. Project Organization

```
my-project/
├── .mcp/
│   ├── servers.json    # Project-specific servers
│   └── .env            # Project-specific secrets
├── Makefile            # Include MCP targets
└── src/
```

### 3. Security

- Use environment variables for all sensitive data
- Set appropriate file permissions:

```bash
chmod 600 .env
chmod 644 mcp-servers.json
```

### 4. Maintenance

- Regularly run `make clean` to remove orphaned servers
- Keep server configurations up to date
- Test configurations in development before production

### 5. Integration

Include MCP management in your project's Makefile:

```makefile
# Include in your project Makefile
MCP_DIR := /path/to/mcp-manager

.PHONY: dev-setup
dev-setup:
	$(MAKE) -C $(MCP_DIR) project-sync \
	  CONFIG_FILE=$(PWD)/.mcp/servers.json \
	  PROJECT=$(PWD)
```

## Examples

### Development Environment Setup

```bash
# Create development configuration
cat > dev-servers.json << EOF
{
  "mcpServers": {
    "github": {
      "command": "npx",
      "args": ["@modelcontextprotocol/server-github"],
      "env": { "GITHUB_TOKEN": "\${GITHUB_TOKEN}" }
    },
    "sqlite": {
      "command": "npx",
      "args": ["@modelcontextprotocol/server-sqlite"],
      "env": {}
    }
  }
}
EOF

# Install for development
make add-all CONFIG_FILE=dev-servers.json
```

### CI/CD Integration

```yaml
# GitHub Actions example
- name: Setup MCP Servers
  run: |
    make check
    make add-all \
      CONFIG_FILE=ci-servers.json \
      ENV_FILE=.env.ci
```

### Multi-User Setup

```bash
# Admin installs global servers
sudo -E make sync SCOPE=user

# Individual users add project-specific servers
make project-add-all PROJECT=~/my-project
```