# MCP Server Manager

Command-line tool for managing MCP servers in Claude Code. Supports user and project-level server installation and configuration.

## Quick Start

```bash
# Create configuration from template
cp mcp-servers.json.example mcp-servers.json

# Add servers to user scope
make add SERVERS=memory,brave-search

# Sync all configured servers
make sync

# List installed servers
make list
```

## Requirements

- Claude CLI installed (`npm install -g @anthropic-ai/claude-code`)
- Python 3.8+ with Ansible (`pip install ansible`)
- Node.js 18+ (for Claude CLI)

## Installation

1. Clone this repository
2. Install Ansible: `pip install ansible`
3. Verify Claude CLI: `claude --version`

## Basic Usage

### Server Management

```bash
# Add specific servers
make add SERVERS=memory,github

# Remove servers  
make remove SERVERS=memory

# List all servers
make list

# Sync from configuration file
make sync
```

### Project-Level Operations

```bash
# Add servers to current project
make project-add SERVERS=github

# List project servers
make project-list

# Sync project servers
make project-sync
```

### Remote Operations

```bash
# Configure servers on remote host
make sync-remote SSH_HOST=192.168.1.100 SSH_USER=ubuntu

# Add servers to remote Claude CLI
make add-remote SERVERS=memory SSH_HOST=server.example.com SSH_USER=admin
```

## Configuration

### Server Configuration

Edit `mcp-servers.json` to define available servers:

```json
{
  "memory": {
    "command": "npx",
    "args": ["-y", "@anthropic-ai/mcp-server-memory"],
    "env": {}
  },
  "github": {
    "command": "npx",
    "args": ["-y", "@anthropic-ai/mcp-server-github"],
    "env": {
      "GITHUB_PERSONAL_ACCESS_TOKEN": "${GITHUB_TOKEN}"
    }
  }
}
```

### Environment Variables

Create `.env` file for API keys and secrets:

```bash
GITHUB_TOKEN=ghp_your_token_here
BRAVE_API_KEY=your_brave_key_here
```

Variables in server configurations use `${VAR_NAME}` syntax for substitution.

## Commands

| Command | Description |
|---------|-------------|
| `list` | List installed servers |
| `add` | Add servers (SERVERS=name1,name2) |
| `remove` | Remove servers (SERVERS=name1,name2) |
| `sync` | Sync all servers from config |
| `clean` | Remove orphaned servers |
| `project-list` | List project servers |
| `project-add` | Add servers to project |
| `project-sync` | Sync project servers |
| `dry-run` | Preview changes without applying |

## Advanced Usage

For complex scenarios, use Ansible directly:

```bash
# Custom configuration file
ansible-playbook ansible/manage-mcp.yml -e "config_file=my-config.json"

# Specific operation with custom parameters
ansible-playbook ansible/manage-mcp.yml \
  -e "mode=individual" \
  -e "operation_mode=add" \
  -e "servers=memory,github"
```

See `docs/ADVANCED.md` for complete Ansible documentation.

## Configuration Files

- `mcp-servers.json` - Server definitions and configurations
- `.env` - Environment variables and API keys (optional)
- `ansible/group_vars/all.yml` - Default Ansible variables

## Examples

See `ansible/examples/` for sample configurations:
- `mcp-servers.json` - Example server definitions
- `secrets.yml.example` - Environment variable template

## Documentation

- [Advanced Usage](docs/ADVANCED.md) - Direct Ansible usage
- [Configuration Guide](docs/CONFIGURATION.md) - Detailed configuration options
- [Contributing](docs/CONTRIBUTING.md) - Development guidelines

## License

MIT License - see LICENSE file for details.