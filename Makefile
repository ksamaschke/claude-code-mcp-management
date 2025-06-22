# MCP Server Manager - Simplified Interface
# Ansible-based MCP server management with clean user interface

# Configuration defaults
CONFIG_FILE ?= mcp-servers.json
ENV_FILE ?= .env
SCOPE ?= user
PROJECT ?= .
SSH_HOST ?= localhost
SSH_USER ?= $(USER)

# Colors for output
GREEN := \033[0;32m
YELLOW := \033[1;33m
NC := \033[0m

.DEFAULT_GOAL := help

# Core user interface - essential commands only
.PHONY: help
help:
	@echo "$(GREEN)MCP Server Manager$(NC)"
	@echo ""
	@echo "$(GREEN)Core Commands:$(NC)"
	@echo "  $(YELLOW)list$(NC)        - List installed servers"
	@echo "  $(YELLOW)sync$(NC)        - Sync all servers from config"
	@echo "  $(YELLOW)add$(NC)         - Add servers (SERVERS=name1,name2)"
	@echo "  $(YELLOW)remove$(NC)      - Remove servers (SERVERS=name1,name2)"
	@echo "  $(YELLOW)clean$(NC)       - Remove orphaned servers"
	@echo "  $(YELLOW)dry-run$(NC)     - Preview changes without applying"
	@echo ""
	@echo "$(GREEN)Project Commands:$(NC)"
	@echo "  $(YELLOW)project-sync$(NC) - Sync project servers"
	@echo "  $(YELLOW)project-add$(NC)  - Add to project (SERVERS=...)"
	@echo ""
	@echo "$(GREEN)Remote Commands:$(NC)"
	@echo "  $(YELLOW)sync-remote$(NC)  - Sync on remote (SSH_HOST=ip SSH_USER=user)"
	@echo "  $(YELLOW)add-remote$(NC)   - Add on remote (SERVERS=... SSH_HOST=ip)"
	@echo ""
	@echo "$(GREEN)Utility:$(NC)"
	@echo "  $(YELLOW)show-config$(NC)  - Display current configuration"
	@echo "  $(YELLOW)help-advanced$(NC) - Show all commands and options"
	@echo ""
	@echo "$(GREEN)Examples:$(NC)"
	@echo "  make add SERVERS=memory,github"
	@echo "  make sync-remote SSH_HOST=server.com SSH_USER=admin"

# Advanced help - complete command reference
.PHONY: help-advanced
help-advanced:
	@echo "$(GREEN)MCP Server Manager - Advanced Usage$(NC)"
	@echo ""
	@echo "$(GREEN)All Commands:$(NC)"
	@echo "  $(YELLOW)list$(NC)             - List installed servers"
	@echo "  $(YELLOW)sync$(NC)             - Sync all servers from configuration"
	@echo "  $(YELLOW)dry-run$(NC)          - Preview changes without applying"
	@echo "  $(YELLOW)add$(NC)              - Add specific servers (SERVERS=...)"
	@echo "  $(YELLOW)add-all$(NC)          - Add ALL servers from config"
	@echo "  $(YELLOW)remove$(NC)           - Remove specific servers (SERVERS=...)"
	@echo "  $(YELLOW)clean$(NC)            - Remove orphaned servers"
	@echo "  $(YELLOW)project-sync$(NC)     - Sync servers for current project"
	@echo "  $(YELLOW)project-add$(NC)      - Add servers to project (SERVERS=...)"
	@echo "  $(YELLOW)project-remove$(NC)   - Remove servers from project (SERVERS=...)"
	@echo "  $(YELLOW)project-list$(NC)     - List project servers"
	@echo "  $(YELLOW)sync-remote$(NC)      - Sync servers on remote host"
	@echo "  $(YELLOW)add-remote$(NC)       - Add servers on remote (SERVERS=...)"
	@echo "  $(YELLOW)remove-remote$(NC)    - Remove servers on remote (SERVERS=...)"
	@echo "  $(YELLOW)list-remote$(NC)      - List servers on remote host"
	@echo "  $(YELLOW)check-syntax$(NC)     - Validate Ansible playbook"
	@echo "  $(YELLOW)test-connection$(NC)  - Test SSH connectivity"
	@echo "  $(YELLOW)show-config$(NC)      - Display current configuration"
	@echo ""
	@echo "$(GREEN)Variables:$(NC)"
	@echo "  SERVERS       - Comma-separated server list"
	@echo "  CONFIG_FILE   - Path to mcp-servers.json (default: $(CONFIG_FILE))"
	@echo "  ENV_FILE      - Path to .env file (default: $(ENV_FILE))"
	@echo "  SCOPE         - user|project (default: $(SCOPE))"
	@echo "  PROJECT       - Project path (default: $(PROJECT))"
	@echo "  SSH_HOST      - Target hostname/IP (default: $(SSH_HOST))"
	@echo "  SSH_USER      - SSH username (default: $(SSH_USER))"
	@echo ""
	@echo "$(GREEN)Examples:$(NC)"
	@echo "  make sync CONFIG_FILE=custom.json"
	@echo "  make add SERVERS=memory,github SCOPE=project"
	@echo "  make sync-remote SSH_HOST=192.168.1.100 SSH_USER=ubuntu"
	@echo "  make project-add SERVERS=brave-search PROJECT=/path/to/project"
	@echo ""
	@echo "$(GREEN)Documentation:$(NC)"
	@echo "  docs/INSTALLATION.md  - Installation guide"
	@echo "  docs/CONFIGURATION.md - Configuration reference"
	@echo "  docs/ADVANCED.md      - Ansible usage guide"

# Core commands
.PHONY: list sync add remove clean dry-run
list:
	@ansible-playbook ansible/manage-mcp.yml \
		-e "mode=all" \
		-e "operation_mode=list" \
		-e "config_file=$(CONFIG_FILE)" \
		-e "env_file=$(ENV_FILE)" \
		-e "mcp_target_host=$(SSH_HOST)" \
		-e "ansible_user=$(SSH_USER)"

sync:
	@ansible-playbook ansible/manage-mcp.yml \
		-e "mode=all" \
		-e "operation_mode=sync" \
		-e "config_file=$(CONFIG_FILE)" \
		-e "env_file=$(ENV_FILE)" \
		-e "mcp_target_host=$(SSH_HOST)" \
		-e "ansible_user=$(SSH_USER)"

add:
	@test -n "$(SERVERS)" || (echo "Error: SERVERS parameter required"; exit 1)
	@ansible-playbook ansible/manage-mcp.yml \
		-e "mode=individual" \
		-e "operation_mode=add" \
		-e "servers=$(SERVERS)" \
		-e "config_file=$(CONFIG_FILE)" \
		-e "env_file=$(ENV_FILE)" \
		-e "mcp_target_host=$(SSH_HOST)" \
		-e "ansible_user=$(SSH_USER)"

remove:
	@test -n "$(SERVERS)" || (echo "Error: SERVERS parameter required"; exit 1)
	@ansible-playbook ansible/manage-mcp.yml \
		-e "mode=individual" \
		-e "operation_mode=remove" \
		-e "servers=$(SERVERS)" \
		-e "config_file=$(CONFIG_FILE)" \
		-e "env_file=$(ENV_FILE)" \
		-e "mcp_target_host=$(SSH_HOST)" \
		-e "ansible_user=$(SSH_USER)"

clean:
	@ansible-playbook ansible/manage-mcp.yml \
		-e "mode=all" \
		-e "operation_mode=clean" \
		-e "config_file=$(CONFIG_FILE)" \
		-e "env_file=$(ENV_FILE)" \
		-e "mcp_target_host=$(SSH_HOST)" \
		-e "ansible_user=$(SSH_USER)"

dry-run:
	@ansible-playbook ansible/manage-mcp.yml \
		-e "mode=all" \
		-e "operation_mode=sync" \
		-e "dry_run=true" \
		-e "config_file=$(CONFIG_FILE)" \
		-e "env_file=$(ENV_FILE)" \
		-e "mcp_target_host=$(SSH_HOST)" \
		-e "ansible_user=$(SSH_USER)"

# Project commands
.PHONY: project-sync project-add
project-sync:
	@ansible-playbook ansible/manage-mcp.yml \
		-e "mode=all" \
		-e "operation_mode=sync" \
		-e "scope=project" \
		-e "project_path=$(PROJECT)" \
		-e "config_file=$(CONFIG_FILE)" \
		-e "env_file=$(ENV_FILE)" \
		-e "mcp_target_host=$(SSH_HOST)" \
		-e "ansible_user=$(SSH_USER)"

project-add:
	@test -n "$(SERVERS)" || (echo "Error: SERVERS parameter required"; exit 1)
	@ansible-playbook ansible/manage-mcp.yml \
		-e "mode=individual" \
		-e "operation_mode=add" \
		-e "scope=project" \
		-e "project_path=$(PROJECT)" \
		-e "servers=$(SERVERS)" \
		-e "config_file=$(CONFIG_FILE)" \
		-e "env_file=$(ENV_FILE)" \
		-e "mcp_target_host=$(SSH_HOST)" \
		-e "ansible_user=$(SSH_USER)"

# Remote commands
.PHONY: sync-remote add-remote
sync-remote:
	@test "$(SSH_HOST)" != "localhost" || (echo "Error: SSH_HOST parameter required for remote operations"; exit 1)
	@ansible-playbook ansible/manage-mcp.yml \
		-e "mode=all" \
		-e "operation_mode=sync" \
		-e "config_file=$(CONFIG_FILE)" \
		-e "env_file=$(ENV_FILE)" \
		-e "mcp_target_host=$(SSH_HOST)" \
		-e "ansible_user=$(SSH_USER)"

add-remote:
	@test -n "$(SERVERS)" || (echo "Error: SERVERS parameter required"; exit 1)
	@test "$(SSH_HOST)" != "localhost" || (echo "Error: SSH_HOST parameter required for remote operations"; exit 1)
	@ansible-playbook ansible/manage-mcp.yml \
		-e "mode=individual" \
		-e "operation_mode=add" \
		-e "servers=$(SERVERS)" \
		-e "config_file=$(CONFIG_FILE)" \
		-e "env_file=$(ENV_FILE)" \
		-e "mcp_target_host=$(SSH_HOST)" \
		-e "ansible_user=$(SSH_USER)"

# Advanced commands (available but not in main help)
.PHONY: add-all project-remove project-list remove-remote list-remote check-syntax test-connection
add-all:
	@ansible-playbook ansible/manage-mcp.yml \
		-e "mode=all" \
		-e "operation_mode=add" \
		-e "config_file=$(CONFIG_FILE)" \
		-e "env_file=$(ENV_FILE)" \
		-e "mcp_target_host=$(SSH_HOST)" \
		-e "ansible_user=$(SSH_USER)"

project-remove:
	@test -n "$(SERVERS)" || (echo "Error: SERVERS parameter required"; exit 1)
	@ansible-playbook ansible/manage-mcp.yml \
		-e "mode=individual" \
		-e "operation_mode=remove" \
		-e "scope=project" \
		-e "project_path=$(PROJECT)" \
		-e "servers=$(SERVERS)" \
		-e "config_file=$(CONFIG_FILE)" \
		-e "env_file=$(ENV_FILE)" \
		-e "mcp_target_host=$(SSH_HOST)" \
		-e "ansible_user=$(SSH_USER)"

project-list:
	@ansible-playbook ansible/manage-mcp.yml \
		-e "mode=all" \
		-e "operation_mode=list" \
		-e "scope=project" \
		-e "project_path=$(PROJECT)" \
		-e "config_file=$(CONFIG_FILE)" \
		-e "env_file=$(ENV_FILE)" \
		-e "mcp_target_host=$(SSH_HOST)" \
		-e "ansible_user=$(SSH_USER)"

remove-remote:
	@test -n "$(SERVERS)" || (echo "Error: SERVERS parameter required"; exit 1)
	@test "$(SSH_HOST)" != "localhost" || (echo "Error: SSH_HOST parameter required for remote operations"; exit 1)
	@ansible-playbook ansible/manage-mcp.yml \
		-e "mode=individual" \
		-e "operation_mode=remove" \
		-e "servers=$(SERVERS)" \
		-e "config_file=$(CONFIG_FILE)" \
		-e "env_file=$(ENV_FILE)" \
		-e "mcp_target_host=$(SSH_HOST)" \
		-e "ansible_user=$(SSH_USER)"

list-remote:
	@test "$(SSH_HOST)" != "localhost" || (echo "Error: SSH_HOST parameter required for remote operations"; exit 1)
	@ansible-playbook ansible/manage-mcp.yml \
		-e "mode=all" \
		-e "operation_mode=list" \
		-e "config_file=$(CONFIG_FILE)" \
		-e "env_file=$(ENV_FILE)" \
		-e "mcp_target_host=$(SSH_HOST)" \
		-e "ansible_user=$(SSH_USER)"

check-syntax:
	@ansible-playbook --syntax-check ansible/manage-mcp.yml

test-connection:
	@test "$(SSH_HOST)" != "localhost" || (echo "Error: SSH_HOST parameter required"; exit 1)
	@ansible $(SSH_HOST) -u $(SSH_USER) -m ping

# Utility commands
.PHONY: show-config
show-config:
	@echo "$(YELLOW)Configuration:$(NC)"
	@echo "  Config: $(CONFIG_FILE)"
	@echo "  Env: $(ENV_FILE)"
	@echo "  Scope: $(SCOPE)"
	@echo "  Project: $(PROJECT)"
	@echo "  SSH: $(SSH_USER)@$(SSH_HOST)"