#!/bin/bash

# MCP Sync - Sync all MCP servers from configuration
# This is a wrapper around manage-mcp.sh for syncing all servers

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Function to print colored output
print_color() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

# Function to show usage
show_usage() {
    cat << EOF
Usage: $0 [OPTIONS]

Sync all MCP servers from your configuration file.
This will add new servers and remove orphaned ones.

Options:
  -h, --help             Show this help message
  -s, --scope SCOPE      Set installation scope (user or project, default: user)
  -p, --project PATH     Project path (for project scope)
  -c, --config FILE      Path to mcp-servers.json (default: script directory)
  -e, --env FILE         Path to .env file (default: script directory)
  -v, --verbose          Run with verbose output
  --no-cleanup           Don't remove orphaned servers

Examples:
  $0                                           # Sync all servers for user
  $0 --scope project --project .               # Sync for current project
  $0 --config ~/custom/config.json             # Use custom config
  $0 --no-cleanup                              # Add new servers only

EOF
}

# Check for help flag
if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
    show_usage
    exit 0
fi

# Pass all arguments to manage-mcp.sh with mode set to 'all'
print_color "$YELLOW" "Syncing all MCP servers from configuration..."
echo

"$SCRIPT_DIR/manage-mcp.sh" --mode all "$@"