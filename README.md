# MCP Server Manager for Claude Code

A flexible, modular system for managing Model Context Protocol (MCP) servers in Claude Code. This tool simplifies the installation, configuration, and management of MCP servers across user and project scopes.

## 🚀 Quick Start

### Local Configuration
```bash
# 1. Check dependencies
make check

# 2. Create your configuration (use the example as template)
cp mcp-servers.json.example mcp-servers.json
# Edit mcp-servers.json with your servers

# 3. Create .env file for API keys (optional)
echo "BRAVE_API_KEY=your-api-key-here" > .env

# 4. Sync all servers locally
make sync

# Or add ALL servers from your config at once
make add-all
```

### Remote Configuration
```bash
# Configure MCP servers on a remote machine
make sync SSH_HOST=192.168.1.100 SSH_USER=ubuntu

# Use custom SSH key
make sync SSH_HOST=server.com SSH_USER=admin SSH_KEY_FILE=~/.ssh/mykey.pem

# Add all servers to remote Claude CLI
make add-all SSH_HOST=192.168.1.100 SSH_USER=ubuntu
```

## 📋 Prerequisites

- **Claude Desktop** with `claude` CLI installed
- **Node.js** and npm
- **Python 3** with pip
- **Ansible** (`pip install ansible`)

## 🎯 Common Tasks

### Using the Makefile (Recommended)

```bash
# List current MCP servers
make list

# Sync all servers from configuration
make sync

# Dry-run to verify configuration without making changes
make dry-run

# Add ALL servers from configuration
make add-all

# Add specific servers
make add SERVERS=memory,brave-search

# Remove servers
make remove SERVERS=github

# Clean up orphaned servers
make clean

# Show help
make help
```

### Project-Specific Operations

```bash
# List servers in current project
make project-list

# Sync servers for current project
make project-sync

# Add ALL servers to current project
make project-add-all

# Add specific servers to project
make project-add SERVERS=memory

# Remove servers from project
make project-remove SERVERS=github

# Or specify a different project
make sync SCOPE=project PROJECT=/path/to/project
```

### Using Scripts Directly

```bash
# Sync all servers
./mcp-sync.sh

# Add individual servers
./mcp-add.sh memory,brave-search

# Remove servers
./mcp-remove.sh github

# With custom configuration files
./mcp-sync.sh --config /path/to/config.json --env /path/to/.env
./mcp-add.sh memory --config ~/configs/mcp.json
./mcp-remove.sh github --scope project --project .

# Full control with main script
./manage-mcp.sh --config my-config.json --env my-env --scope project --project /path/to/project
```

## 📁 Configuration

### mcp-servers.json

Create your MCP server configuration based on the example:

```json
{
  "mcpServers": {
    "memory": {
      "type": "stdio",
      "command": "npx",
      "args": ["@modelcontextprotocol/server-memory"],
      "env": {}
    },
    "brave-search": {
      "command": "npx",
      "args": ["@modelcontextprotocol/server-brave-search"],
      "env": {
        "BRAVE_API_KEY": "${BRAVE_API_KEY}"
      }
    },
    "sequential-thinking": {
      "command": "npx",
      "args": ["@modelcontextprotocol/server-sequential-thinking"],
      "env": {}
    }
  }
}
```

### Environment Variables

Create a `.env` file for sensitive data:

```bash
BRAVE_API_KEY=your-api-key-here
GITHUB_TOKEN=your-github-token
ANTHROPIC_API_KEY=your-api-key
```

Variables are referenced in `mcp-servers.json` using `${VARIABLE_NAME}` syntax.

### Using External Configuration Files

If your `mcp-servers.json` and `.env` files are located outside this directory, specify their paths:

```bash
# Using custom file locations
make sync CONFIG_FILE=/path/to/your/mcp-servers.json ENV_FILE=/path/to/your/.env
make add-all CONFIG_FILE=~/configs/mcp-servers.json ENV_FILE=~/configs/.env
make dry-run CONFIG_FILE=../shared/mcp-config.json

# All commands support custom file paths
make project-sync CONFIG_FILE=/external/config.json ENV_FILE=/external/.env
```

## 🔧 Advanced Usage

### Dry-Run Mode

Before making any changes, you can use dry-run mode to verify your configuration:

```bash
# Check what will be installed/configured
make dry-run

# With custom configuration files
make dry-run CONFIG_FILE=/path/to/config.json ENV_FILE=/path/to/.env
```

The dry-run will show:
- Which servers will be installed or skipped
- Environment variable resolution status
- Any missing API keys or configuration issues
- A complete summary of the planned changes

This is especially useful for:
- Verifying API keys are properly configured in your `.env` file
- Checking which servers are already installed
- Ensuring environment variables are correctly mapped
- Testing configuration changes before applying them

### Custom Configuration Locations

```bash
# Use custom config and env files
make sync CONFIG_FILE=/path/to/config.json ENV_FILE=/path/to/.env

# Or with scripts
./manage-mcp.sh --config /path/to/config.json --env /path/to/.env
```

### Selective Server Management

```bash
# Add only specific servers
make add SERVERS=memory,github,brave-search

# Remove multiple servers
make remove SERVERS=old-server1,old-server2
```

### Makefile Variables

All Makefile targets support these variables:

- `CONFIG_FILE` - Path to mcp-servers.json (default: `mcp-servers.json`)
- `ENV_FILE` - Path to .env file (default: `.env`)
- `SCOPE` - Installation scope: `user` or `project` (default: `user`)
- `PROJECT` - Project path for project scope (default: `.`)
- `SERVERS` - Comma-separated list of servers (for add/remove operations)

### VM Deployment Variables

For deploying to remote VMs, these additional variables are supported:

- `VM` - Direct SSH format (user@hostname)
- `HOST` - Target hostname/IP (uses SSH_USER from config)
- `GROUP` - VM group name from Ansible inventory
- `SSH_USER` - SSH username (overrides .env and inventory)
- `SSH_KEY_FILE` - SSH private key path (overrides .env and inventory)
- `SSH_PORT` - SSH port (overrides .env and inventory)
- `DEPLOY_DIR` - Target deployment directory (default: `/opt/mcp-manager`)

## 🌐 Remote MCP Configuration

Configure MCP servers on remote machines without deploying the tool itself. The tool runs locally and connects to remote Claude CLI installations via SSH.

### SSH Configuration

All MCP commands support remote execution using SSH parameters:

- `SSH_HOST` - Target hostname or IP address
- `SSH_USER` - SSH username for remote connection
- `SSH_KEY_FILE` - Path to SSH private key (optional)

### Remote Configuration Examples

```bash
# Basic remote configuration
make sync SSH_HOST=192.168.1.100 SSH_USER=ubuntu

# With custom SSH key
make add-all SSH_HOST=server.example.com SSH_USER=admin SSH_KEY_FILE=~/.ssh/production.pem

# Remote dry-run with custom config
make dry-run SSH_HOST=192.168.1.100 SSH_USER=ubuntu CONFIG_FILE=~/production-mcp.json

# Add specific servers remotely
make add SERVERS=memory,brave-search SSH_HOST=192.168.1.100 SSH_USER=ubuntu

# List remote MCP servers
make list SSH_HOST=192.168.1.100 SSH_USER=ubuntu
```

### Prerequisites for Remote Configuration

- SSH access to the target machine
- Claude CLI installed on the remote machine
- Proper PATH configuration for Claude CLI on remote machine

## 🚀 VM Deployment

Deploy the MCP Manager to remote VMs with flexible SSH configuration hierarchy.

### SSH Configuration Priority (Highest → Lowest)

1. **Command Parameters** - Direct overrides
2. **.env File** - Default SSH settings 
3. **Ansible Inventory** - Per-host/group configuration

### Single VM Deployment

```bash
# Direct SSH format
make deploy-vm VM=user@server1.example.com

# Use .env SSH defaults
make deploy-vm HOST=192.168.1.100

# Override SSH settings
make deploy-vm HOST=server1 SSH_USER=admin SSH_KEY_FILE=~/.ssh/prod.pem SSH_PORT=2222
```

### Multiple VM Deployment

```bash
# Set up inventory first: ansible/inventory/hosts.yml
make deploy-group GROUP=production
make deploy-group GROUP=staging 
make deploy-all  # Deploy to all VMs
```

### SSH Configuration Examples

**.env file:**
```bash
SSH_USER=ubuntu
SSH_KEY_FILE=~/.ssh/default-key.pem
SSH_PORT=22
DEPLOY_DIR=/opt/mcp-manager
```

**ansible/inventory/hosts.yml:**
```yaml
production:
  vars:
    ansible_user: prod-user
    ansible_ssh_private_key_file: ~/.ssh/prod-key.pem
  hosts:
    server1:
      ansible_host: 192.168.1.100
```

## 📚 Documentation

- [Detailed Usage Guide](docs/USAGE.md) - Comprehensive documentation
- [Ansible Technical Docs](ansible/README.md) - For advanced users
- [Example Configuration](mcp-servers.json.example) - Template for your configuration

## 🏗️ Architecture

```
.
├── docs/                      # Documentation
│   ├── CLAUDE.md             # Claude Code integration guide
│   ├── USAGE.md              # Detailed usage documentation
│   └── CONTRIBUTING.md       # Contribution guidelines
├── scripts/                   # Management scripts
│   ├── manage-mcp.sh         # Main management script
│   ├── mcp-add.sh            # Add individual servers
│   ├── mcp-remove.sh         # Remove servers
│   └── mcp-sync.sh           # Sync all servers
├── ansible/                   # VM deployment automation
│   ├── deploy.yml            # Deployment playbook
│   ├── manage-mcp.yml        # MCP server management playbook
│   └── inventory/            # VM inventory and SSH config
├── Makefile                   # Easy command interface
├── mcp-servers.json.example   # Example configuration
├── .env.example              # Environment variables template
└── README.md                 # This file
```

### Flexible Configuration

The tool **does not require** configuration files to be in any specific location:

- **Default behavior**: Looks for `mcp-servers.json` and `.env` in the script directory
- **Custom locations**: Use `--config` and `--env` parameters to specify any path
- **No hardcoded paths**: The Ansible playbook accepts file locations as parameters
- **Project flexibility**: Keep different configurations for different projects

### JSON-Based Installation

This tool uses Claude Code's `mcp add-json` command for reliable server installation:

- **JSON configuration**: Servers are defined in standard MCP JSON format
- **Batch installation**: Multiple servers can be configured from a single JSON file
- **Environment variables**: Securely injected from `.env` file
- **Validation**: JSON structure is validated before installation

## 🤝 Contributing

Contributions are welcome! Please read the [contributing guidelines](docs/CONTRIBUTING.md) before submitting PRs.

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🐛 Troubleshooting

If you encounter issues:

1. Run `make check` to verify dependencies
2. Check that your `mcp-servers.json` is valid JSON
3. Ensure API keys in `.env` are correct
4. Run with verbose mode: `./manage-mcp.sh -v ...`
5. Check Claude Code logs: `claude mcp list`

For more help, see the [troubleshooting section](USAGE.md#troubleshooting) in the usage guide.