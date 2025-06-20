#!/bin/bash

# MCP Remove - Remove MCP servers
# This script removes specific MCP servers using the claude CLI

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

Remove specific MCP servers.

Arguments:
  servers                 Comma-separated list of servers to remove

Options:
  -h, --help             Show this help message
  -s, --scope SCOPE      Set scope (user or project, default: user)
  -p, --project PATH     Project path (for project scope)
  -y, --yes              Skip confirmation prompt
  -v, --verbose          Run with verbose output

Examples:
  $0 github                                   # Remove github server
  $0 memory,sqlite                            # Remove multiple servers
  $0 brave-search --scope project --project . # Remove from current project
  $0 old-server -y                            # Remove without confirmation

EOF
}

# Default values
SCOPE="user"
PROJECT_PATH=""
SKIP_CONFIRM=false
VERBOSE=false

# Check if servers argument is provided
if [ $# -eq 0 ] || [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
    show_usage
    exit 0
fi

# Get servers list (first argument)
SERVERS="$1"
shift

# Parse additional arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -s|--scope)
            SCOPE="$2"
            shift 2
            ;;
        -p|--project)
            PROJECT_PATH="$2"
            shift 2
            ;;
        -y|--yes)
            SKIP_CONFIRM=true
            shift
            ;;
        -v|--verbose)
            VERBOSE=true
            shift
            ;;
        *)
            print_color "$RED" "Unknown option: $1"
            show_usage
            exit 1
            ;;
    esac
done

# Validate servers argument
if [ -z "$SERVERS" ]; then
    print_color "$RED" "Error: No servers specified"
    show_usage
    exit 1
fi

# Validate scope
if [ "$SCOPE" != "user" ] && [ "$SCOPE" != "project" ]; then
    print_color "$RED" "Error: Invalid scope '$SCOPE'. Must be 'user' or 'project'"
    exit 1
fi

# Check if claude CLI is available
if ! command -v claude &> /dev/null; then
    print_color "$RED" "Error: claude CLI not found. Please install Claude Desktop."
    exit 1
fi

# Function to check if server exists
server_exists() {
    local server=$1
    local list_cmd="claude mcp list"
    
    if [ "$SCOPE" = "project" ]; then
        if [ -n "$PROJECT_PATH" ]; then
            cd "$PROJECT_PATH"
        fi
        list_cmd="claude mcp list"
    else
        list_cmd="claude mcp list -s user"
    fi
    
    if $list_cmd 2>/dev/null | grep -q "^$server\s"; then
        return 0
    else
        return 1
    fi
}

# Function to remove a server
remove_server() {
    local server=$1
    local remove_cmd="claude mcp remove $server"
    
    if [ "$SCOPE" = "user" ]; then
        remove_cmd="$remove_cmd -s user"
    fi
    
    if [ "$SCOPE" = "project" ] && [ -n "$PROJECT_PATH" ]; then
        cd "$PROJECT_PATH"
    fi
    
    if $VERBOSE; then
        print_color "$BLUE" "Running: $remove_cmd"
    fi
    
    if $remove_cmd; then
        print_color "$GREEN" "✓ Successfully removed: $server"
        return 0
    else
        print_color "$RED" "✗ Failed to remove: $server"
        return 1
    fi
}

# Convert comma-separated list to array
IFS=',' read -ra SERVER_ARRAY <<< "$SERVERS"

# Check which servers actually exist
print_color "$YELLOW" "Checking servers..."
SERVERS_TO_REMOVE=()
SERVERS_NOT_FOUND=()

for server in "${SERVER_ARRAY[@]}"; do
    server=$(echo "$server" | xargs) # Trim whitespace
    if server_exists "$server"; then
        SERVERS_TO_REMOVE+=("$server")
    else
        SERVERS_NOT_FOUND+=("$server")
    fi
done

# Report servers not found
if [ ${#SERVERS_NOT_FOUND[@]} -gt 0 ]; then
    print_color "$YELLOW" "⚠ Servers not found (skipping):"
    for server in "${SERVERS_NOT_FOUND[@]}"; do
        echo "  - $server"
    done
fi

# Exit if no servers to remove
if [ ${#SERVERS_TO_REMOVE[@]} -eq 0 ]; then
    print_color "$YELLOW" "No servers to remove."
    exit 0
fi

# Show servers to be removed
echo
print_color "$YELLOW" "Servers to remove:"
for server in "${SERVERS_TO_REMOVE[@]}"; do
    echo "  - $server"
done

# Confirmation prompt
if [ "$SKIP_CONFIRM" = false ]; then
    echo
    read -p "Are you sure you want to remove these servers? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_color "$YELLOW" "Operation cancelled."
        exit 0
    fi
fi

# Remove servers
echo
print_color "$YELLOW" "Removing servers..."
FAILED_COUNT=0

for server in "${SERVERS_TO_REMOVE[@]}"; do
    if ! remove_server "$server"; then
        ((FAILED_COUNT++))
    fi
done

# Summary
echo
if [ $FAILED_COUNT -eq 0 ]; then
    print_color "$GREEN" "✓ All servers removed successfully!"
else
    print_color "$YELLOW" "⚠ Completed with $FAILED_COUNT errors"
fi