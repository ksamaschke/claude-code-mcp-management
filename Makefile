# MCP Server Manager Makefile
# Simplifies common MCP server management tasks

# Default configuration file locations
CONFIG_FILE ?= mcp-servers.json
ENV_FILE ?= .env
SCOPE ?= user
PROJECT ?= .

# Color codes for output
GREEN := \033[0;32m
YELLOW := \033[1;33m
RED := \033[0;31m
NC := \033[0m # No Color

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
	@echo "$(GREEN)Targets:$(NC)"
	@echo "  $(YELLOW)list$(NC)          - List all configured MCP servers"
	@echo "  $(YELLOW)sync$(NC)          - Sync all servers from configuration"
	@echo "  $(YELLOW)dry-run$(NC)       - Check configuration without making changes"
	@echo "  $(YELLOW)add$(NC)           - Add specific servers (requires SERVERS=...)"
	@echo "  $(YELLOW)add-all$(NC)       - Add ALL servers from configuration file"
	@echo "  $(YELLOW)remove$(NC)        - Remove specific servers (requires SERVERS=...)"
	@echo "  $(YELLOW)check$(NC)         - Check dependencies only"
	@echo "  $(YELLOW)clean$(NC)         - Remove orphaned servers"
	@echo "  $(YELLOW)help$(NC)          - Show this help message"
	@echo ""
	@echo "$(GREEN)Project-specific targets:$(NC)"
	@echo "  $(YELLOW)project-list$(NC)  - List servers in current project"
	@echo "  $(YELLOW)project-sync$(NC)  - Sync servers for current project"
	@echo "  $(YELLOW)project-add$(NC)   - Add servers to current project"
	@echo "  $(YELLOW)project-clean$(NC) - Clean orphaned servers in project"
	@echo ""
	@echo "$(GREEN)Options:$(NC)"
	@echo "  SERVERS       - Comma-separated list of servers (for add/remove)"
	@echo "  CONFIG_FILE   - Path to mcp-servers.json (default: $(CONFIG_FILE))"
	@echo "  ENV_FILE      - Path to .env file (default: $(ENV_FILE))"
	@echo "  SCOPE         - Installation scope: user|project (default: $(SCOPE))"
	@echo "  PROJECT       - Project path for project scope (default: $(PROJECT))"
	@echo ""
	@echo "$(GREEN)Examples:$(NC)"
	@echo "  make sync                                    # Sync all servers"
	@echo "  make add SERVERS=memory,brave-search         # Add specific servers"
	@echo "  make add-all                                 # Add ALL servers from config"
	@echo "  make remove SERVERS=github                   # Remove a server"
	@echo "  make list                                    # List current servers"
	@echo ""
	@echo "  $(GREEN)Project-specific examples:$(NC)"
	@echo "  make project-sync                            # Sync for current project"
	@echo "  make project-add SERVERS=memory              # Add to current project"
	@echo "  make sync SCOPE=project PROJECT=/my/project  # Sync for specific project"
	@echo ""

# List current MCP servers
.PHONY: list
list:
	@echo "$(YELLOW)Current MCP servers:$(NC)"
	@if [ "$(SCOPE)" = "project" ]; then \
		cd $(PROJECT) && claude mcp list; \
	else \
		claude mcp list -s user; \
	fi

# Sync all servers from configuration
.PHONY: sync
sync:
	@echo "$(YELLOW)Syncing all MCP servers from configuration...$(NC)"
	@./mcp-sync.sh --config "$(CONFIG_FILE)" --env "$(ENV_FILE)" --scope "$(SCOPE)" $(if $(filter project,$(SCOPE)),--project "$(PROJECT)")

# Dry-run to check configuration without making changes
.PHONY: dry-run
dry-run:
	@echo "$(YELLOW)Running dry-run to check configuration...$(NC)"
	@ansible-playbook ansible-mcp-manager/manage-mcp.yml \
		-e mcp_scope="$(SCOPE)" \
		-e mcp_mode=all \
		-e mcp_config_file="$(abspath $(CONFIG_FILE))" \
		-e mcp_env_file="$(abspath $(ENV_FILE))" \
		-e mcp_dry_run=true

# Add specific servers
.PHONY: add
add:
	@if [ -z "$(SERVERS)" ]; then \
		echo "$(RED)Error: SERVERS variable is required$(NC)"; \
		echo "Usage: make add SERVERS=memory,brave-search"; \
		exit 1; \
	fi
	@echo "$(YELLOW)Adding MCP servers: $(SERVERS)$(NC)"
	@./mcp-add.sh "$(SERVERS)" --config "$(CONFIG_FILE)" --env "$(ENV_FILE)" --scope "$(SCOPE)" $(if $(filter project,$(SCOPE)),--project "$(PROJECT)")

# Add ALL servers from configuration
.PHONY: add-all
add-all:
	@echo "$(YELLOW)Adding ALL MCP servers from configuration...$(NC)"
	@if [ -f "$(CONFIG_FILE)" ]; then \
		SERVERS=$$(cat "$(CONFIG_FILE)" | grep -E '"[^"]+"\s*:\s*\{' | sed 's/.*"\([^"]*\)".*/\1/' | tr '\n' ',' | sed 's/,$$//'); \
		if [ -z "$$SERVERS" ]; then \
			echo "$(RED)No servers found in configuration file$(NC)"; \
			exit 1; \
		fi; \
		echo "$(GREEN)Found servers: $$SERVERS$(NC)"; \
		./mcp-add.sh "$$SERVERS" --config "$(CONFIG_FILE)" --env "$(ENV_FILE)" --scope "$(SCOPE)" $(if $(filter project,$(SCOPE)),--project "$(PROJECT)"); \
	else \
		echo "$(RED)Configuration file not found: $(CONFIG_FILE)$(NC)"; \
		exit 1; \
	fi

# Remove specific servers
.PHONY: remove
remove:
	@if [ -z "$(SERVERS)" ]; then \
		echo "$(RED)Error: SERVERS variable is required$(NC)"; \
		echo "Usage: make remove SERVERS=github"; \
		exit 1; \
	fi
	@echo "$(YELLOW)Removing MCP servers: $(SERVERS)$(NC)"
	@./mcp-remove.sh "$(SERVERS)" -y --scope "$(SCOPE)" $(if $(filter project,$(SCOPE)),--project "$(PROJECT)")

# Check dependencies only
.PHONY: check
check:
	@echo "$(YELLOW)Checking dependencies...$(NC)"
	@./manage-mcp.sh --check-only --config "$(CONFIG_FILE)"

# Clean orphaned servers
.PHONY: clean
clean:
	@echo "$(YELLOW)Cleaning orphaned servers...$(NC)"
	@./manage-mcp.sh --mode all --config "$(CONFIG_FILE)" --env "$(ENV_FILE)" --scope "$(SCOPE)" $(if $(filter project,$(SCOPE)),--project "$(PROJECT)")

# Install dependencies (helpful for initial setup)
.PHONY: install-deps
install-deps:
	@echo "$(YELLOW)Installing required dependencies...$(NC)"
	@echo "$(GREEN)Installing Ansible...$(NC)"
	@pip install ansible
	@echo ""
	@echo "$(GREEN)Checking other dependencies:$(NC)"
	@./manage-mcp.sh --check-only

# Quick setup - check deps and sync if all good
.PHONY: setup
setup: check
	@echo ""
	@echo "$(GREEN)Dependencies look good! Running initial sync...$(NC)"
	@$(MAKE) sync

# Show current configuration
.PHONY: show-config
show-config:
	@echo "$(YELLOW)Current configuration:$(NC)"
	@echo "  Config file: $(CONFIG_FILE)"
	@echo "  Env file: $(ENV_FILE)"
	@echo "  Scope: $(SCOPE)"
	@if [ "$(SCOPE)" = "project" ]; then \
		echo "  Project: $(PROJECT)"; \
	fi
	@echo ""
	@if [ -f "$(CONFIG_FILE)" ]; then \
		echo "$(GREEN)MCP servers in configuration:$(NC)"; \
		cat "$(CONFIG_FILE)" | grep -E '"[^"]+"\s*:\s*\{' | sed 's/.*"\([^"]*\)".*/  - \1/'; \
	else \
		echo "$(RED)Configuration file not found: $(CONFIG_FILE)$(NC)"; \
	fi

# ===== PROJECT-SPECIFIC TARGETS =====
# These are convenience targets that automatically set SCOPE=project

# List servers in current project
.PHONY: project-list
project-list:
	@$(MAKE) list SCOPE=project PROJECT=$(PROJECT)

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

# Add ALL servers to current project
.PHONY: project-add-all
project-add-all:
	@$(MAKE) add-all SCOPE=project PROJECT=$(PROJECT)

# Remove servers from current project
.PHONY: project-remove
project-remove:
	@if [ -z "$(SERVERS)" ]; then \
		echo "$(RED)Error: SERVERS variable is required$(NC)"; \
		echo "Usage: make project-remove SERVERS=github"; \
		exit 1; \
	fi
	@$(MAKE) remove SCOPE=project PROJECT=$(PROJECT) SERVERS="$(SERVERS)"

# Clean orphaned servers in current project
.PHONY: project-clean
project-clean:
	@$(MAKE) clean SCOPE=project PROJECT=$(PROJECT)

# Show config for project scope
.PHONY: project-config
project-config:
	@$(MAKE) show-config SCOPE=project PROJECT=$(PROJECT)