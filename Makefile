# MCP Server Manager - Simplified Makefile
# Clean interface to Ansible-based MCP server management
# All operations call unified ansible/manage-mcp.yml playbook

# Configuration defaults (can be overridden)
CONFIG_FILE ?= mcp-servers.json
ENV_FILE ?= .env
SCOPE ?= user
PROJECT ?= .
SSH_HOST ?= localhost
SSH_USER ?= $(USER)

# Color codes for output
GREEN := \033[0;32m
YELLOW := \033[1;33m
RED := \033[0;31m
NC := \033[0m

# Default target
.DEFAULT_GOAL := help

# Help target - shows available commands
.PHONY: help
help:
	@echo "$(GREEN)MCP Server Manager$(NC)"
	@echo "$(YELLOW)━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━$(NC)"
	@echo ""
	@echo "$(GREEN)Usage:$(NC)"
	@echo "  make <target> [OPTION=value ...]"
	@echo ""
	@echo "$(GREEN)Local Operations:$(NC)"
	@echo "  $(YELLOW)list$(NC)          - List all configured MCP servers"
	@echo "  $(YELLOW)sync$(NC)          - Sync all servers from configuration"
	@echo "  $(YELLOW)dry-run$(NC)       - Check configuration without making changes"
	@echo "  $(YELLOW)add$(NC)           - Add specific servers (requires SERVERS=...)"
	@echo "  $(YELLOW)add-all$(NC)       - Add ALL servers from configuration file"
	@echo "  $(YELLOW)remove$(NC)        - Remove specific servers (requires SERVERS=...)"
	@echo "  $(YELLOW)clean$(NC)         - Remove orphaned servers"
	@echo ""
	@echo "$(GREEN)Remote Operations:$(NC)"
	@echo "  $(YELLOW)sync-remote$(NC)   - Sync servers on remote host"
	@echo "  $(YELLOW)add-remote$(NC)    - Add servers on remote host (requires SERVERS=...)"
	@echo "  $(YELLOW)remove-remote$(NC) - Remove servers on remote host (requires SERVERS=...)"
	@echo "  $(YELLOW)list-remote$(NC)   - List servers on remote host"
	@echo ""
	@echo "$(GREEN)Project Operations:$(NC)"
	@echo "  $(YELLOW)project-sync$(NC)  - Sync servers for current project"
	@echo "  $(YELLOW)project-add$(NC)   - Add servers to current project (requires SERVERS=...)"
	@echo "  $(YELLOW)project-remove$(NC) - Remove servers from current project (requires SERVERS=...)"
	@echo "  $(YELLOW)project-list$(NC)  - List servers in current project"
	@echo ""
	@echo "$(GREEN)Options:$(NC)"
	@echo "  SERVERS       - Comma-separated list of servers (for add/remove)"
	@echo "  CONFIG_FILE   - Path to mcp-servers.json (default: $(CONFIG_FILE))"
	@echo "  ENV_FILE      - Path to .env file (default: $(ENV_FILE))"
	@echo "  SCOPE         - Installation scope: user|project (default: $(SCOPE))"
	@echo "  PROJECT       - Project path for project scope (default: $(PROJECT))"
	@echo "  SSH_HOST      - Target hostname/IP for remote operations (default: $(SSH_HOST))"
	@echo "  SSH_USER      - SSH username for remote operations (default: $(SSH_USER))"
	@echo ""
	@echo "$(GREEN)Examples:$(NC)"
	@echo "  make sync                                    # Sync all servers locally"
	@echo "  make add SERVERS=memory,brave-search         # Add specific servers locally"
	@echo "  make add-all                                 # Add ALL servers from config locally"
	@echo "  make remove SERVERS=github                   # Remove a server locally"
	@echo ""
	@echo "  $(GREEN)Remote examples:$(NC)"
	@echo "  make sync-remote SSH_HOST=192.168.1.100 SSH_USER=ubuntu"
	@echo "  make add-remote SERVERS=memory SSH_HOST=server.com SSH_USER=admin"
	@echo ""
	@echo "  $(GREEN)Project examples:$(NC)"
	@echo "  make project-sync                            # Sync for current project"
	@echo "  make project-add SERVERS=memory              # Add to current project"
	@echo ""

# ===== LOCAL OPERATIONS =====

# List current MCP servers locally
.PHONY: list
list:
	@echo "$(YELLOW)Listing MCP servers...$(NC)"
	@ansible-playbook ansible/manage-mcp.yml \
		-i "localhost," \
		-i "localhost," \
		-e "mcp_mode=list" \
		-e "mcp_scope=$(SCOPE)" \
		-e "mcp_project_path=$(PROJECT)" \
		-e "config_file=$(abspath $(CONFIG_FILE))" \
		-e "env_file=$(abspath $(ENV_FILE))" \
		-e "mcp_target_host=$(SSH_HOST)" \
		-e "ansible_user=$(SSH_USER)"

# Sync all servers from configuration locally
.PHONY: sync
sync:
	@echo "$(YELLOW)Syncing all MCP servers from configuration...$(NC)"
	@ansible-playbook ansible/manage-mcp.yml \
		-i "localhost," \
		-e "mcp_mode=sync" \
		-e "mcp_scope=$(SCOPE)" \
		-e "mcp_project_path=$(PROJECT)" \
		-e "config_file=$(abspath $(CONFIG_FILE))" \
		-e "env_file=$(abspath $(ENV_FILE))" \
		-e "mcp_target_host=$(SSH_HOST)" \
		-e "ansible_user=$(SSH_USER)"

# Dry-run to check configuration without making changes
.PHONY: dry-run
dry-run:
	@echo "$(YELLOW)Running dry-run to check configuration...$(NC)"
	@ansible-playbook ansible/manage-mcp.yml \
		-i "localhost," \
		-e "mcp_mode=sync" \
		-e "mcp_scope=$(SCOPE)" \
		-e "mcp_project_path=$(PROJECT)" \
		-e "config_file=$(abspath $(CONFIG_FILE))" \
		-e "env_file=$(abspath $(ENV_FILE))" \
		-e "mcp_target_host=$(SSH_HOST)" \
		-e "ansible_user=$(SSH_USER)" \
		-e "mcp_dry_run=true"

# Add specific servers locally
.PHONY: add
add:
	@if [ -z "$(SERVERS)" ]; then \
		echo "$(RED)Error: SERVERS variable is required$(NC)"; \
		echo "Usage: make add SERVERS=memory,brave-search"; \
		exit 1; \
	fi
	@echo "$(YELLOW)Adding MCP servers: $(SERVERS)$(NC)"
	@ansible-playbook ansible/manage-mcp.yml \
		-i "localhost," \
		-e "mcp_mode=individual" \
		-e "operation_mode=add" \
		-e "mcp_scope=$(SCOPE)" \
		-e "mcp_project_path=$(PROJECT)" \
		-e "mcp_servers_list=$(SERVERS)" \
		-e "config_file=$(abspath $(CONFIG_FILE))" \
		-e "env_file=$(abspath $(ENV_FILE))" \
		-e "mcp_target_host=$(SSH_HOST)" \
		-e "ansible_user=$(SSH_USER)"

# Add ALL servers from configuration locally
.PHONY: add-all
add-all:
	@echo "$(YELLOW)Adding ALL MCP servers from configuration...$(NC)"
	@ansible-playbook ansible/manage-mcp.yml \
		-i "localhost," \
		-e "mcp_mode=all" \
		-e "mcp_scope=$(SCOPE)" \
		-e "mcp_project_path=$(PROJECT)" \
		-e "config_file=$(abspath $(CONFIG_FILE))" \
		-e "env_file=$(abspath $(ENV_FILE))" \
		-e "mcp_target_host=$(SSH_HOST)" \
		-e "ansible_user=$(SSH_USER)"

# Remove specific servers locally
.PHONY: remove
remove:
	@if [ -z "$(SERVERS)" ]; then \
		echo "$(RED)Error: SERVERS variable is required$(NC)"; \
		echo "Usage: make remove SERVERS=github"; \
		exit 1; \
	fi
	@echo "$(YELLOW)Removing MCP servers: $(SERVERS)$(NC)"
	@ansible-playbook ansible/manage-mcp.yml \
		-i "localhost," \
		-e "mcp_mode=individual" \
		-e "operation_mode=remove" \
		-e "mcp_scope=$(SCOPE)" \
		-e "mcp_project_path=$(PROJECT)" \
		-e "mcp_servers_list=$(SERVERS)" \
		-e "config_file=$(abspath $(CONFIG_FILE))" \
		-e "env_file=$(abspath $(ENV_FILE))" \
		-e "mcp_target_host=$(SSH_HOST)" \
		-e "ansible_user=$(SSH_USER)"

# Clean orphaned servers locally
.PHONY: clean
clean:
	@echo "$(YELLOW)Cleaning orphaned servers...$(NC)"
	@ansible-playbook ansible/manage-mcp.yml \
		-i "localhost," \
		-e "mcp_mode=cleanup" \
		-e "mcp_scope=$(SCOPE)" \
		-e "mcp_project_path=$(PROJECT)" \
		-e "config_file=$(abspath $(CONFIG_FILE))" \
		-e "env_file=$(abspath $(ENV_FILE))" \
		-e "mcp_target_host=$(SSH_HOST)" \
		-e "ansible_user=$(SSH_USER)"

# ===== REMOTE OPERATIONS =====

# Sync all servers from configuration on remote host
.PHONY: sync-remote
sync-remote:
	@echo "$(YELLOW)Syncing all MCP servers on remote host $(SSH_HOST)...$(NC)"
	@ansible-playbook ansible/manage-mcp.yml \
		-i "localhost," \
		-e "mcp_mode=sync" \
		-e "mcp_scope=$(SCOPE)" \
		-e "mcp_project_path=$(PROJECT)" \
		-e "config_file=$(abspath $(CONFIG_FILE))" \
		-e "env_file=$(abspath $(ENV_FILE))" \
		-e "mcp_target_host=$(SSH_HOST)" \
		-e "ansible_user=$(SSH_USER)"

# Add specific servers on remote host
.PHONY: add-remote
add-remote:
	@if [ -z "$(SERVERS)" ]; then \
		echo "$(RED)Error: SERVERS variable is required$(NC)"; \
		echo "Usage: make add-remote SERVERS=memory,brave-search SSH_HOST=host"; \
		exit 1; \
	fi
	@echo "$(YELLOW)Adding MCP servers $(SERVERS) on remote host $(SSH_HOST)...$(NC)"
	@ansible-playbook ansible/manage-mcp.yml \
		-i "localhost," \
		-e "mcp_mode=individual" \
		-e "operation_mode=add" \
		-e "mcp_scope=$(SCOPE)" \
		-e "mcp_project_path=$(PROJECT)" \
		-e "mcp_servers_list=$(SERVERS)" \
		-e "config_file=$(abspath $(CONFIG_FILE))" \
		-e "env_file=$(abspath $(ENV_FILE))" \
		-e "mcp_target_host=$(SSH_HOST)" \
		-e "ansible_user=$(SSH_USER)"

# Remove specific servers on remote host
.PHONY: remove-remote
remove-remote:
	@if [ -z "$(SERVERS)" ]; then \
		echo "$(RED)Error: SERVERS variable is required$(NC)"; \
		echo "Usage: make remove-remote SERVERS=github SSH_HOST=host"; \
		exit 1; \
	fi
	@echo "$(YELLOW)Removing MCP servers $(SERVERS) on remote host $(SSH_HOST)...$(NC)"
	@ansible-playbook ansible/manage-mcp.yml \
		-i "localhost," \
		-e "mcp_mode=individual" \
		-e "operation_mode=remove" \
		-e "mcp_scope=$(SCOPE)" \
		-e "mcp_project_path=$(PROJECT)" \
		-e "mcp_servers_list=$(SERVERS)" \
		-e "config_file=$(abspath $(CONFIG_FILE))" \
		-e "env_file=$(abspath $(ENV_FILE))" \
		-e "mcp_target_host=$(SSH_HOST)" \
		-e "ansible_user=$(SSH_USER)"

# List current MCP servers on remote host
.PHONY: list-remote
list-remote:
	@echo "$(YELLOW)Listing MCP servers on remote host $(SSH_HOST)...$(NC)"
	@ansible-playbook ansible/manage-mcp.yml \
		-i "localhost," \
		-e "mcp_mode=list" \
		-e "mcp_scope=$(SCOPE)" \
		-e "mcp_project_path=$(PROJECT)" \
		-e "config_file=$(abspath $(CONFIG_FILE))" \
		-e "env_file=$(abspath $(ENV_FILE))" \
		-e "mcp_target_host=$(SSH_HOST)" \
		-e "ansible_user=$(SSH_USER)"

# ===== PROJECT OPERATIONS =====

# Sync servers for current project
.PHONY: project-sync
project-sync:
	@$(MAKE) sync SCOPE=project PROJECT=$(PROJECT)

# Add servers to current project
.PHONY: project-add
project-add:
	@if [ -z "$(SERVERS)" ]; then \
		echo "$(RED)Error: SERVERS variable is required$(NC)"; \
		echo "Usage: make project-add SERVERS=memory,brave-search"; \
		exit 1; \
	fi
	@$(MAKE) add SCOPE=project PROJECT=$(PROJECT) SERVERS="$(SERVERS)"

# Remove servers from current project
.PHONY: project-remove
project-remove:
	@if [ -z "$(SERVERS)" ]; then \
		echo "$(RED)Error: SERVERS variable is required$(NC)"; \
		echo "Usage: make project-remove SERVERS=github"; \
		exit 1; \
	fi
	@$(MAKE) remove SCOPE=project PROJECT=$(PROJECT) SERVERS="$(SERVERS)"

# List servers in current project
.PHONY: project-list
project-list:
	@$(MAKE) list SCOPE=project PROJECT=$(PROJECT)

# ===== UTILITY OPERATIONS =====

# Check Ansible syntax
.PHONY: check-syntax
check-syntax:
	@echo "$(YELLOW)Checking Ansible playbook syntax...$(NC)"
	@ansible-playbook --syntax-check ansible/manage-mcp.yml -e "mcp_target_host=localhost"

# Test connection to remote host
.PHONY: test-connection
test-connection:
	@echo "$(YELLOW)Testing connection to $(SSH_HOST)...$(NC)"
	@ansible $(SSH_HOST) -u $(SSH_USER) -m ping

# Show current configuration
.PHONY: show-config
show-config:
	@echo "$(YELLOW)Current configuration:$(NC)"
	@echo "  Config file: $(CONFIG_FILE)"
	@echo "  Env file: $(ENV_FILE)"
	@echo "  Scope: $(SCOPE)"
	@echo "  Project: $(PROJECT)"
	@echo "  SSH Host: $(SSH_HOST)"
	@echo "  SSH User: $(SSH_USER)"