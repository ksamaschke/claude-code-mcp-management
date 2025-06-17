#!/bin/bash

# MCP Server Manager - Easy installation script for MCP servers
# This script simplifies the installation of Model Context Protocol servers for Claude

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ANSIBLE_DIR="$SCRIPT_DIR/ansible-mcp-manager"

# Function to print colored output
print_color() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

# Function to print header
print_header() {
    echo
    print_color "$BLUE" "======================================"
    print_color "$BLUE" "     MCP Server Manager for Claude"
    print_color "$BLUE" "======================================"
    echo
}

# Function to check if a command exists
check_command() {
    local cmd=$1
    local name=$2
    local install_msg=$3
    
    if command -v "$cmd" &> /dev/null; then
        print_color "$GREEN" "✓ $name is installed"
        return 0
    else
        print_color "$RED" "✗ $name is not installed"
        if [ -n "$install_msg" ]; then
            echo "  $install_msg"
        fi
        return 1
    fi
}

# Function to check Python package manager
check_python_package_manager() {
    local cmd=$1
    if command -v "$cmd" &> /dev/null; then
        return 0
    fi
    return 1
}

# Function to parse JSON and extract unique commands
get_required_commands() {
    local json_file=$1
    if [ -f "$json_file" ]; then
        # Extract unique command values from mcp-servers.json
        cat "$json_file" | grep -o '"command":\s*"[^"]*"' | sed 's/"command":\s*"//' | sed 's/"$//' | sort -u
    fi
}

# Function to show usage
show_usage() {
    cat << EOF
Usage: $0 [OPTIONS]

Options:
  -h, --help              Show this help message
  -s, --scope SCOPE       Set installation scope (user or project, default: user)
  -m, --mode MODE         Set installation mode (all, individual, default: all)
  -l, --list SERVERS      Comma-separated list of servers (for individual mode)
  -p, --project PATH      Project path (for project scope)
  -c, --check-only        Only check dependencies, don't run installation
  -v, --verbose           Run with verbose output
  --no-cleanup            Don't clean up orphaned servers

Examples:
  $0                                    # Install all servers for user
  $0 --scope project --project .        # Install for current project
  $0 --mode individual --list github    # Install only GitHub server
  $0 --check-only                       # Only check dependencies

EOF
}

# Parse command line arguments
SCOPE="user"
MODE="all"
SERVERS=""
PROJECT_PATH=""
CHECK_ONLY=false
VERBOSE=""
CLEANUP=true

while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_usage
            exit 0
            ;;
        -s|--scope)
            SCOPE="$2"
            shift 2
            ;;
        -m|--mode)
            MODE="$2"
            shift 2
            ;;
        -l|--list)
            SERVERS="$2"
            shift 2
            ;;
        -p|--project)
            PROJECT_PATH="$2"
            shift 2
            ;;
        -c|--check-only)
            CHECK_ONLY=true
            shift
            ;;
        -v|--verbose)
            VERBOSE="-v"
            shift
            ;;
        --no-cleanup)
            CLEANUP=false
            shift
            ;;
        *)
            print_color "$RED" "Unknown option: $1"
            show_usage
            exit 1
            ;;
    esac
done

# Main execution
print_header

# Check for required files
print_color "$YELLOW" "Checking configuration files..."
echo

CONFIG_MISSING=false

if [ ! -f "$SCRIPT_DIR/mcp-servers.json" ]; then
    print_color "$RED" "✗ mcp-servers.json not found in $SCRIPT_DIR"
    echo "  Please create mcp-servers.json with your MCP server definitions"
    echo "  See ansible-mcp-manager/examples/mcp-servers.json for an example"
    CONFIG_MISSING=true
else
    print_color "$GREEN" "✓ mcp-servers.json found"
fi

if [ ! -f "$SCRIPT_DIR/.env" ]; then
    print_color "$YELLOW" "⚠ .env file not found (optional)"
    echo "  Create .env for API keys and secrets if needed"
    echo "  See ansible-mcp-manager/.env.example for an example"
else
    print_color "$GREEN" "✓ .env file found"
fi

if [ "$CONFIG_MISSING" = true ]; then
    echo
    print_color "$RED" "Missing required configuration files. Exiting."
    exit 1
fi

# Check dependencies
echo
print_color "$YELLOW" "Checking required dependencies..."
echo

DEPS_MISSING=false

# Check core dependencies
if ! check_command "ansible-playbook" "Ansible" "Install with: pip install ansible or use your package manager"; then
    DEPS_MISSING=true
fi

if ! check_command "claude" "Claude CLI" "Install Claude Desktop from https://claude.ai/download"; then
    DEPS_MISSING=true
fi

if ! check_command "node" "Node.js" "Install from https://nodejs.org/ or use a version manager like nvm"; then
    DEPS_MISSING=true
fi

# Check for package managers used in mcp-servers.json
echo
print_color "$YELLOW" "Checking package managers used by MCP servers..."
echo

REQUIRED_COMMANDS=$(get_required_commands "$SCRIPT_DIR/mcp-servers.json")

for cmd in $REQUIRED_COMMANDS; do
    case $cmd in
        npx)
            # npx comes with npm/node, already checked
            ;;
        uvx)
            if ! check_command "uvx" "uvx (Python package runner)" "Install with: pip install uv"; then
                DEPS_MISSING=true
            fi
            ;;
        pipx)
            if ! check_command "pipx" "pipx (Python app installer)" "Install with: pip install pipx"; then
                DEPS_MISSING=true
            fi
            ;;
        *)
            # Check if it's a direct command
            if [ "$cmd" != "node" ] && [ "$cmd" != "python" ] && [ "$cmd" != "python3" ]; then
                if ! command -v "$cmd" &> /dev/null; then
                    print_color "$YELLOW" "⚠ Custom command '$cmd' not found in PATH"
                fi
            fi
            ;;
    esac
done

if [ "$DEPS_MISSING" = true ]; then
    echo
    print_color "$RED" "Some dependencies are missing. Please install them before continuing."
    exit 1
fi

if [ "$CHECK_ONLY" = true ]; then
    echo
    print_color "$GREEN" "All dependency checks passed!"
    exit 0
fi

# Copy configuration files to ansible directory
echo
print_color "$YELLOW" "Preparing configuration..."

cp "$SCRIPT_DIR/mcp-servers.json" "$ANSIBLE_DIR/"
if [ -f "$SCRIPT_DIR/.env" ]; then
    cp "$SCRIPT_DIR/.env" "$ANSIBLE_DIR/"
fi

# Build ansible-playbook command
ANSIBLE_CMD="ansible-playbook $ANSIBLE_DIR/manage-mcp.yml"

# Add options
ANSIBLE_CMD="$ANSIBLE_CMD -e mcp_scope=$SCOPE"
ANSIBLE_CMD="$ANSIBLE_CMD -e mcp_mode=$MODE"

if [ -n "$SERVERS" ]; then
    ANSIBLE_CMD="$ANSIBLE_CMD -e mcp_servers_list=$SERVERS"
fi

if [ "$SCOPE" = "project" ] && [ -n "$PROJECT_PATH" ]; then
    ANSIBLE_CMD="$ANSIBLE_CMD -e mcp_project_path=$PROJECT_PATH"
elif [ "$SCOPE" = "project" ] && [ -z "$PROJECT_PATH" ]; then
    ANSIBLE_CMD="$ANSIBLE_CMD -e mcp_project_path=$SCRIPT_DIR"
fi

if [ "$CLEANUP" = false ]; then
    ANSIBLE_CMD="$ANSIBLE_CMD -e mcp_cleanup_orphaned=false"
fi

if [ -n "$VERBOSE" ]; then
    ANSIBLE_CMD="$ANSIBLE_CMD $VERBOSE"
fi

# Run the playbook
echo
print_color "$YELLOW" "Running MCP server installation..."
print_color "$BLUE" "Command: $ANSIBLE_CMD"
echo

cd "$ANSIBLE_DIR"
eval $ANSIBLE_CMD

# Show completion message
if [ $? -eq 0 ]; then
    echo
    print_color "$GREEN" "✓ MCP server installation completed successfully!"
    echo
    echo "To verify your installation, run:"
    echo "  claude mcp list"
    echo
    echo "To start using Claude with your MCP servers:"
    echo "  claude"
else
    echo
    print_color "$RED" "✗ Installation failed. Please check the error messages above."
    exit 1
fi