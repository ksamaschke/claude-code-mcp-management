# Ansible MCP Manager - Technical Documentation

This is the Ansible playbook that powers the MCP Server Manager. For most users, we recommend using the [simple installer script](../README.md) in the parent directory.

## Motivation

This tool was created to solve a common problem: **seamlessly copying MCP server configurations between different AI tools**. 

If you're using Claude Desktop, Cursor, Windsurf, or other AI tools with MCP servers, you've probably experienced the frustration of having to manually recreate your server configurations for Claude Code. Instead of editing config files by hand or registering each server individually with `claude mcp add`, this tool lets you:

- **Copy your existing MCP configuration** from Claude Desktop or other tools
- **Use the same JSON format** across all your AI development environments  
- **Bulk configure servers** without repetitive manual commands
- **Maintain consistency** across different tools and projects

Simply export your `mcpServers` configuration from any tool and use it directly with this manager.

## About

This Ansible playbook automates the complete lifecycle of MCP servers including installation, configuration, updates, and cleanup across user and project scopes.

## Features

- **Standard MCP JSON Format**: Uses the same format as Claude Desktop and other AI agents
- **Automated MCP Server Management**: Install, configure, and remove MCP servers
- **Multi-scope Support**: Manage servers at user (global) or project level
- **Environment Variable Support**: Use `${VAR_NAME}` syntax in JSON for secrets
- **Cleanup Functionality**: Remove orphaned servers and clean configuration files
- **Idempotent Operations**: Safe to run multiple times

## Requirements

- Ansible 2.9 or higher
- Claude Desktop installed
- Claude CLI (`claude` command) available in PATH
- Python 3.6+

## Direct Playbook Usage

**Note**: Most users should use the [manage-mcp.sh script](../README.md) in the parent directory for easier installation.

### Prerequisites

- Ansible 2.9 or higher
- Python 3.6+
- Claude CLI installed and in PATH

### Running the Playbook

1. Ensure your configuration files exist in this directory:
   - `mcp-servers.json` - Your MCP server definitions
   - `.env` - Environment variables (optional)

2. Run the playbook:
```bash
ansible-playbook manage-mcp.yml
```

### Advanced Options

```bash
# Install specific servers only
ansible-playbook manage-mcp.yml -e mcp_mode=individual -e mcp_servers_list="github,filesystem"

# Install for project scope
ansible-playbook manage-mcp.yml -e mcp_scope=project -e mcp_project_path=/path/to/project

# Disable cleanup of orphaned servers
ansible-playbook manage-mcp.yml -e mcp_cleanup_orphaned=false

# Verbose output
ansible-playbook manage-mcp.yml -vvv
```

## Configuration Format

The `mcp-servers.json` uses the standard MCP format used by Claude Desktop, Cursor, Windsurf, and other AI tools. This tool supports both the **full format** and **simplified format** for maximum compatibility:

### Full Format (Claude Desktop style)
```json
{
  "mcpServers": {
    "puppeteer": {
      "type": "stdio",
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-puppeteer"],
      "env": {}
    },
    "brave-search": {
      "type": "stdio",
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-brave-search"],
      "env": {
        "BRAVE_API_KEY": "your-api-key-here"
      }
    }
  }
}
```

### Simplified Format (minimal configuration)
```json
{
  "mcpServers": {
    "sequential-thinking": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-sequential-thinking"]
    },
    "Context7": {
      "command": "npx",
      "args": ["-y", "@upstash/context7-mcp@latest"]
    }
  }
}
```

**Note**: When `"type"` is omitted, it defaults to `"stdio"`. Both formats can be mixed in the same configuration file.

### Environment Variable Substitution

Use `${VARIABLE_NAME}` syntax to reference environment variables from `.env`:
- `${GITHUB_TOKEN}` → looks for `GITHUB_TOKEN` in .env
- Variables are automatically converted to lowercase when loaded

## Installation Modes

### Install All Servers
```bash
ansible-playbook manage-mcp.yml
```

### Install Specific Servers
```bash
ansible-playbook manage-mcp.yml -e mcp_mode=individual -e mcp_servers_list="github,filesystem"
```

### Scopes

- **User Scope**: Servers available across all Claude sessions (default)
  ```bash
  ansible-playbook manage-mcp.yml -e mcp_scope=user
  ```

- **Project Scope**: Servers specific to a project directory
  ```bash
  ansible-playbook manage-mcp.yml -e mcp_scope=project -e mcp_project_path=/path/to/project
  ```

## Advanced Options

### Disable Cleanup
```bash
ansible-playbook manage-mcp.yml -e mcp_cleanup_orphaned=false
```

### Keep Specific Servers During Cleanup
```bash
ansible-playbook manage-mcp.yml -e '{"mcp_keep_servers": ["server-to-keep"]}'
```

## Directory Structure

```
ansible/
├── manage-mcp.yml          # Main playbook
├── mcp-servers.json        # Your MCP server definitions (create this)
├── .env                    # Your secrets (optional)
├── ansible.cfg             # Ansible configuration
├── roles/                  # Ansible roles
└── examples/               # Example configurations
```

## Troubleshooting

### Debug Mode
```bash
ansible-playbook manage-mcp.yml -vvv
```

### Common Issues

1. **"claude: command not found"**
   - Ensure Claude CLI is installed and in your PATH

2. **Servers persist after removal**
   - Check both user and project scopes
   - Verify cleanup is enabled (`mcp_cleanup_orphaned: true`)

3. **Environment variables not working**
   - Ensure `.env` file exists in the playbook directory
   - Check variable names match (case-sensitive in .env)

## Contributing

Contributions are welcome! Please visit the [GitHub repository](https://github.com/ksamaschke/claude-code-mcp-management) to report issues, suggest features, or submit pull requests.

## License

MIT License - see [LICENSE](LICENSE) file for details.