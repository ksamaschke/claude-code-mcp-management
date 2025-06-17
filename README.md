# MCP Server Manager for Claude

Easy installation and management of Model Context Protocol (MCP) servers for Claude Desktop.

## 🚀 Quick Start

1. **Create your configuration file** `mcp-servers.json`:
```json
{
  "mcpServers": {
    "github": {
      "type": "stdio",
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-github"],
      "env": {
        "GITHUB_PERSONAL_ACCESS_TOKEN": "${GITHUB_PAT}"
      }
    }
  }
}
```

2. **Create `.env` file** (optional, for API keys):
```bash
GITHUB_PAT=your_github_token_here
BRAVE_API_KEY=your_brave_api_key_here
```

3. **Run the installer**:
```bash
./manage-mcp.sh
```

That's it! Your MCP servers are now installed and ready to use with Claude.

## 📋 Prerequisites

The installer will check for these automatically:
- Claude Desktop installed
- Node.js and npm
- Ansible
- Any package managers used by your MCP servers (e.g., uvx for Python servers)

## 🎯 Usage Examples

### Install all servers (default)
```bash
./manage-mcp.sh
```

### Install specific servers only
```bash
./manage-mcp.sh --mode individual --list github,filesystem
```

### Install for a specific project
```bash
./manage-mcp.sh --scope project --project /path/to/project
```

### Check dependencies without installing
```bash
./manage-mcp.sh --check-only
```

### Get help
```bash
./manage-mcp.sh --help
```

## 📁 Configuration

### mcp-servers.json

This file defines your MCP servers using the standard format from Claude Desktop:

```json
{
  "mcpServers": {
    "server-name": {
      "type": "stdio",
      "command": "command-to-run",
      "args": ["arg1", "arg2"],
      "env": {
        "ENV_VAR": "value",
        "API_KEY": "${VARIABLE_FROM_ENV_FILE}"
      }
    }
  }
}
```

### Environment Variables

Use `${VARIABLE_NAME}` syntax in `mcp-servers.json` to reference variables from your `.env` file:
- `${GITHUB_PAT}` in JSON → reads `GITHUB_PAT` from `.env`
- Variables are automatically substituted during installation

## 🛠️ Advanced Usage

For more control over the installation process, see the [Ansible Playbook Documentation](ansible-mcp-manager/README.md).

## 📚 Available MCP Servers

Popular MCP servers you can add:
- **github** - GitHub API integration
- **filesystem** - Local file system access  
- **brave-search** - Web search via Brave
- **sqlite** - SQLite database operations
- **gitlab** - GitLab API integration
- **memory** - Persistent memory across conversations
- **puppeteer** - Browser automation

See [examples](ansible-mcp-manager/examples/) for more configuration examples.

## 🔧 Troubleshooting

If installation fails:
1. Run `./manage-mcp.sh --check-only` to verify dependencies
2. Check that your `mcp-servers.json` is valid JSON
3. Ensure API keys in `.env` are correct
4. Run with `--verbose` flag for detailed output

## 📄 License

MIT License - see [LICENSE](ansible-mcp-manager/LICENSE) file for details.