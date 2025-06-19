#!/bin/bash

# MCP Add - Add individual MCP servers
# This is a wrapper around manage-mcp.sh for adding specific servers

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
Usage: $0 <servers> [OPTIONS]

Add specific MCP servers from your configuration.

Arguments:
  servers                 Comma-separated list of servers to add

Options:
  -h, --help             Show this help message
  -s, --scope SCOPE      Set installation scope (user or project, default: user)
  -p, --project PATH     Project path (for project scope)
  -c, --config FILE      Path to mcp-servers.json (default: script directory)
  -e, --env FILE         Path to .env file (default: script directory)
  -v, --verbose          Run with verbose output

Examples:
  $0 memory,github                              # Add memory and github servers
  $0 brave-search --scope project --project .   # Add to current project
  $0 sqlite --config ~/custom/config.json       # Use custom config

EOF
}

# Check if servers argument is provided
if [ $# -eq 0 ] || [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
    show_usage
    exit 0
fi

# Get servers list (first argument)
SERVERS="$1"
shift

# Validate servers argument
if [ -z "$SERVERS" ]; then
    print_color "$RED" "Error: No servers specified"
    show_usage
    exit 1
fi

# Pass remaining arguments to manage-mcp.sh
print_color "$YELLOW" "Adding MCP servers: $SERVERS"
echo

"$SCRIPT_DIR/manage-mcp.sh" --mode individual --list "$SERVERS" "$@"