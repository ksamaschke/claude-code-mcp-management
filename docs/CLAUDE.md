# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

### Development and Testing
- `make check` - Check all dependencies (Claude CLI, Node.js, Python, Ansible)
- `make dry-run` - Preview configuration changes without applying them
- `make setup` - Quick setup: check dependencies and run initial sync

### MCP Server Management
- `make list` - List currently installed MCP servers
- `make sync` - Sync all servers from configuration (add new, remove orphaned)
- `make add-all` - Add ALL servers from mcp-servers.json
- `make add SERVERS=name1,name2` - Add specific servers
- `make remove SERVERS=name1,name2` - Remove specific servers
- `make clean` - Remove orphaned servers not in configuration

### Project-Specific Commands
- `make project-list` - List servers in current project
- `make project-sync` - Sync servers for current project
- `make project-add SERVERS=name1,name2` - Add servers to current project
- `make project-remove SERVERS=name1,name2` - Remove servers from current project

### Configuration Management
- `make show-config` - Display current configuration settings
- All commands accept variables: CONFIG_FILE, ENV_FILE, SCOPE, PROJECT

### Using External Configuration Files
When your `mcp-servers.json` and `.env` files are stored outside this directory:
- `make sync CONFIG_FILE=/path/to/mcp-servers.json ENV_FILE=/path/to/.env`
- `make add-all CONFIG_FILE=~/configs/mcp-servers.json`

## Architecture

This is an MCP (Model Context Protocol) server management system with a layered architecture:

### Core Components
1. **Shell Scripts Layer** - Direct management scripts:
   - `manage-mcp.sh` - Main orchestration script with full options
   - `mcp-add.sh` - Add specific servers
   - `mcp-remove.sh` - Remove servers
   - `mcp-sync.sh` - Sync all servers from configuration

2. **Makefile Interface** - User-friendly command wrapper that calls shell scripts with appropriate parameters

3. **Ansible Automation** - Located in `ansible/`:
   - Handles complex logic for server installation, configuration, and cleanup
   - Uses `claude mcp add-json` for reliable server installation
   - Manages both user-scope (global) and project-scope installations

### Configuration System
- **mcp-servers.json** - MCP server definitions in standard JSON format (compatible with Claude Desktop)
- **.env** - Environment variables for API keys and secrets
- **Variable substitution** - Uses `${VARIABLE_NAME}` syntax to inject environment variables into server configurations

### Installation Modes
- **User scope** - Servers available globally across all Claude sessions
- **Project scope** - Servers specific to individual project directories
- **Batch operations** - Add/remove multiple servers simultaneously
- **JSON-based installation** - Uses Claude Code's `add-json` command for reliable configuration

### Key Features
- **Idempotent operations** - Safe to run multiple times
- **Cleanup functionality** - Automatically removes orphaned servers
- **Flexible configuration** - Supports custom file locations
- **Multi-environment support** - Different configurations for different projects
- **Environment variable injection** - Secure handling of API keys

## Development Workflow

1. **Configuration**: Create/edit `mcp-servers.json` with desired MCP servers
2. **Environment Setup**: Add API keys to `.env` file
3. **Dependency Check**: Run `make check` to verify all tools are installed
4. **Preview Changes**: Use `make dry-run` to see what will be installed/removed
5. **Installation**: Use `make add-all` or `make sync` to install servers
6. **Project-Specific**: Use `make project-*` commands for project-scoped servers

## Key Architecture Patterns

### JSON-First Approach
The system uses Claude Code's `mcp add-json` command rather than command-line arguments, creating temporary JSON files for each server configuration. This provides better reliability and supports complex server configurations.

### Dual-Scope Management
Servers can be installed at user level (available everywhere) or project level (available only in specific directories). The system manages both scopes independently.

### Configuration Flexibility
No hardcoded file paths - all configuration locations can be customized via command-line parameters or Makefile variables.