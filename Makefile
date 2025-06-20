# MCP Server Manager Makefile
# Simplifies common MCP server management tasks

# Default configuration file locations
CONFIG_FILE ?= mcp-servers.json
ENV_FILE ?= .env
SCOPE ?= user
PROJECT ?= .

# SSH and deployment configuration (can be overridden)
SSH_USER ?= $(shell [ -f "$(ENV_FILE)" ] && grep "^SSH_USER=" "$(ENV_FILE)" | cut -d'=' -f2 || echo "ubuntu")
SSH_KEY_FILE ?= $(shell [ -f "$(ENV_FILE)" ] && grep "^SSH_KEY_FILE=" "$(ENV_FILE)" | cut -d'=' -f2 || echo "~/.ssh/id_rsa")
SSH_PORT ?= $(shell [ -f "$(ENV_FILE)" ] && grep "^SSH_PORT=" "$(ENV_FILE)" | cut -d'=' -f2 || echo "22")
SSH_OPTIONS ?= $(shell [ -f "$(ENV_FILE)" ] && grep "^SSH_OPTIONS=" "$(ENV_FILE)" | cut -d'=' -f2- || echo "-o StrictHostKeyChecking=no")
DEPLOY_DIR ?= $(shell [ -f "$(ENV_FILE)" ] && grep "^DEPLOY_DIR=" "$(ENV_FILE)" | cut -d'=' -f2 || echo "/opt/mcp-manager")
ANSIBLE_INVENTORY ?= $(shell [ -f "$(ENV_FILE)" ] && grep "^ANSIBLE_INVENTORY=" "$(ENV_FILE)" | cut -d'=' -f2 || echo "ansible/inventory/hosts.yml")

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
	@echo "$(GREEN)Deployment targets:$(NC)"
	@echo "  $(YELLOW)deploy-vm$(NC)     - Deploy to single VM (VM=user@host or HOST=ip)"
	@echo "  $(YELLOW)deploy-group$(NC)  - Deploy to VM group (requires GROUP=groupname)"
	@echo "  $(YELLOW)deploy-all$(NC)    - Deploy to all VMs in inventory"
	@echo "  $(YELLOW)create-deploy-playbook$(NC) - Create/recreate Ansible deployment playbook"
	@echo ""
	@echo "$(GREEN)Options:$(NC)"
	@echo "  SERVERS       - Comma-separated list of servers (for add/remove)"
	@echo "  CONFIG_FILE   - Path to mcp-servers.json (default: $(CONFIG_FILE))"
	@echo "  ENV_FILE      - Path to .env file (default: $(ENV_FILE))"
	@echo "  SCOPE         - Installation scope: user|project (default: $(SCOPE))"
	@echo "  PROJECT       - Project path for project scope (default: $(PROJECT))"
	@echo "  VM            - Target VM for deployment (user@hostname)"
	@echo "  HOST          - Target hostname/IP (uses SSH_USER from config)"
	@echo "  GROUP         - VM group name from inventory"
	@echo "  SSH_USER      - SSH username (overrides .env and inventory)"
	@echo "  SSH_KEY_FILE  - SSH private key path (overrides .env and inventory)"
	@echo "  SSH_PORT      - SSH port (overrides .env and inventory)"
	@echo "  DEPLOY_DIR    - Target deployment directory (default: /opt/mcp-manager)"
	@echo ""
	@echo "$(GREEN)Examples:$(NC)"
	@echo "  make sync                                    # Sync all servers"
	@echo "  make add SERVERS=memory,brave-search         # Add specific servers"
	@echo "  make add-all                                 # Add ALL servers from config"
	@echo "  make remove SERVERS=github                   # Remove a server"
	@echo "  make list                                    # List current servers"
	@echo ""
	@echo "  $(GREEN)Using external config files:$(NC)"
	@echo "  make sync CONFIG_FILE=/path/to/config.json ENV_FILE=/path/to/.env"
	@echo "  make add-all CONFIG_FILE=~/mcp-servers.json"
	@echo ""
	@echo "  $(GREEN)Project-specific examples:$(NC)"
	@echo "  make project-sync                            # Sync for current project"
	@echo "  make project-add SERVERS=memory              # Add to current project"
	@echo "  make sync SCOPE=project PROJECT=/my/project  # Sync for specific project"
	@echo ""
	@echo "  $(GREEN)Deployment examples:$(NC)"
	@echo "  make deploy-vm VM=user@server1.example.com   # Direct SSH format"
	@echo "  make deploy-vm HOST=192.168.1.100            # Use .env SSH config"
	@echo "  make deploy-vm HOST=server1 SSH_USER=admin SSH_KEY_FILE=~/.ssh/prod.pem"
	@echo "  make deploy-group GROUP=production           # Deploy to production group"
	@echo "  make deploy-all                              # Deploy to all VMs"
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
	@./scripts/mcp-sync.sh --config "$(CONFIG_FILE)" --env "$(ENV_FILE)" --scope "$(SCOPE)" $(if $(filter project,$(SCOPE)),--project "$(PROJECT)")

# Dry-run to check configuration without making changes
.PHONY: dry-run
dry-run:
	@echo "$(YELLOW)Running dry-run to check configuration...$(NC)"
	@ansible-playbook ansible/manage-mcp.yml \
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
	@./scripts/mcp-add.sh "$(SERVERS)" --config "$(CONFIG_FILE)" --env "$(ENV_FILE)" --scope "$(SCOPE)" $(if $(filter project,$(SCOPE)),--project "$(PROJECT)")

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
		./scripts/mcp-add.sh "$$SERVERS" --config "$(CONFIG_FILE)" --env "$(ENV_FILE)" --scope "$(SCOPE)" $(if $(filter project,$(SCOPE)),--project "$(PROJECT)"); \
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
	@./scripts/mcp-remove.sh "$(SERVERS)" -y --scope "$(SCOPE)" $(if $(filter project,$(SCOPE)),--project "$(PROJECT)")

# Check dependencies only
.PHONY: check
check:
	@echo "$(YELLOW)Checking dependencies...$(NC)"
	@./scripts/manage-mcp.sh --check-only --config "$(CONFIG_FILE)"

# Clean orphaned servers
.PHONY: clean
clean:
	@echo "$(YELLOW)Cleaning orphaned servers...$(NC)"
	@./scripts/manage-mcp.sh --mode all --config "$(CONFIG_FILE)" --env "$(ENV_FILE)" --scope "$(SCOPE)" $(if $(filter project,$(SCOPE)),--project "$(PROJECT)")

# Install dependencies (helpful for initial setup)
.PHONY: install-deps
install-deps:
	@echo "$(YELLOW)Installing required dependencies...$(NC)"
	@echo "$(GREEN)Installing Ansible...$(NC)"
	@pip install ansible
	@echo ""
	@echo "$(GREEN)Checking other dependencies:$(NC)"
	@./scripts/manage-mcp.sh --check-only

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

# ===== DEPLOYMENT TARGETS =====
# Deploy the MCP manager to remote VMs

# Deploy to single VM (supports parameter hierarchy)
.PHONY: deploy-vm
deploy-vm:
	@if [ -z "$(VM)" ] && [ -z "$(HOST)" ]; then \
		echo "$(RED)Error: VM or HOST variable is required$(NC)"; \
		echo "Usage: make deploy-vm VM=user@hostname"; \
		echo "   or: make deploy-vm HOST=hostname [SSH_USER=user] [SSH_KEY_FILE=path]"; \
		exit 1; \
	fi
	@if [ -n "$(VM)" ]; then \
		TARGET="$(VM)"; \
	else \
		TARGET="$(SSH_USER)@$(HOST)"; \
	fi; \
	SSH_OPTS="$(SSH_OPTIONS)"; \
	if [ -n "$(SSH_KEY_FILE)" ] && [ "$(SSH_KEY_FILE)" != "~/.ssh/id_rsa" ]; then \
		SSH_OPTS="$$SSH_OPTS -i $(SSH_KEY_FILE)"; \
	fi; \
	if [ "$(SSH_PORT)" != "22" ]; then \
		SSH_OPTS="$$SSH_OPTS -p $(SSH_PORT)"; \
	fi; \
	echo "$(YELLOW)Deploying MCP Manager to $$TARGET...$(NC)"; \
	echo "$(GREEN)SSH Config: User=$(SSH_USER), Key=$(SSH_KEY_FILE), Port=$(SSH_PORT)$(NC)"; \
	echo "$(GREEN)Step 1: Copying files...$(NC)"; \
	rsync -avz --exclude='.git' --exclude='__pycache__' --exclude='*.pyc' -e "ssh $$SSH_OPTS" . $$TARGET:$(DEPLOY_DIR)/; \
	echo "$(GREEN)Step 2: Setting up dependencies...$(NC)"; \
	ssh $$SSH_OPTS $$TARGET "cd $(DEPLOY_DIR) && make check || echo 'Dependencies check completed'"; \
	echo "$(GREEN)Deployment to $$TARGET completed!$(NC)"

# Deploy to VM group using Ansible
.PHONY: deploy-group
deploy-group:
	@if [ -z "$(GROUP)" ]; then \
		echo "$(RED)Error: GROUP variable is required$(NC)"; \
		echo "Usage: make deploy-group GROUP=production"; \
		exit 1; \
	fi
	@echo "$(YELLOW)Deploying to VM group: $(GROUP)...$(NC)"
	@echo "$(GREEN)Using inventory: $(ANSIBLE_INVENTORY)$(NC)"
	@if [ ! -f "ansible/deploy.yml" ]; then \
		echo "$(RED)Error: ansible/deploy.yml not found. Run 'make create-deploy-playbook' first.$(NC)"; \
		exit 1; \
	fi
	@ansible-playbook -i $(ANSIBLE_INVENTORY) ansible/deploy.yml --limit $(GROUP) \
		-e "mcp_install_dir=$(DEPLOY_DIR)" \
		-e "ssh_user=$(SSH_USER)" \
		-e "ssh_key_file=$(SSH_KEY_FILE)" \
		-e "ssh_port=$(SSH_PORT)"

# Deploy to all VMs in inventory
.PHONY: deploy-all
deploy-all:
	@echo "$(YELLOW)Deploying to all VMs in inventory...$(NC)"
	@echo "$(GREEN)Using inventory: $(ANSIBLE_INVENTORY)$(NC)"
	@if [ ! -f "ansible/deploy.yml" ]; then \
		echo "$(RED)Error: ansible/deploy.yml not found. Run 'make create-deploy-playbook' first.$(NC)"; \
		exit 1; \
	fi
	@ansible-playbook -i $(ANSIBLE_INVENTORY) ansible/deploy.yml \
		-e "mcp_install_dir=$(DEPLOY_DIR)" \
		-e "ssh_user=$(SSH_USER)" \
		-e "ssh_key_file=$(SSH_KEY_FILE)" \
		-e "ssh_port=$(SSH_PORT)"

# Create deployment playbook
.PHONY: create-deploy-playbook
create-deploy-playbook:
	@echo "$(YELLOW)Creating Ansible deployment playbook...$(NC)"
	@echo "---" > ansible/deploy.yml
	@echo "- name: Deploy MCP Manager to VMs" >> ansible/deploy.yml
	@echo "  hosts: all" >> ansible/deploy.yml
	@echo "  become: yes" >> ansible/deploy.yml
	@echo "  vars:" >> ansible/deploy.yml
	@echo "    mcp_install_dir: /opt/mcp-manager" >> ansible/deploy.yml
	@echo "  tasks:" >> ansible/deploy.yml
	@echo "    - name: Create MCP manager directory" >> ansible/deploy.yml
	@echo "      file:" >> ansible/deploy.yml
	@echo "        path: \"{{ mcp_install_dir }}\"" >> ansible/deploy.yml
	@echo "        state: directory" >> ansible/deploy.yml
	@echo "        mode: '0755'" >> ansible/deploy.yml
	@echo "" >> ansible/deploy.yml
	@echo "    - name: Copy MCP manager files" >> ansible/deploy.yml
	@echo "      synchronize:" >> ansible/deploy.yml
	@echo "        src: ../" >> ansible/deploy.yml
	@echo "        dest: \"{{ mcp_install_dir }}/\"" >> ansible/deploy.yml
	@echo "        delete: yes" >> ansible/deploy.yml
	@echo "        rsync_opts:" >> ansible/deploy.yml
	@echo "          - \"--exclude=.git\"" >> ansible/deploy.yml
	@echo "          - \"--exclude=__pycache__\"" >> ansible/deploy.yml
	@echo "          - \"--exclude=*.pyc\"" >> ansible/deploy.yml
	@echo "" >> ansible/deploy.yml
	@echo "    - name: Make scripts executable" >> ansible/deploy.yml
	@echo "      file:" >> ansible/deploy.yml
	@echo "        path: \"{{ mcp_install_dir }}/scripts/{{ item }}\"" >> ansible/deploy.yml
	@echo "        mode: '0755'" >> ansible/deploy.yml
	@echo "      loop:" >> ansible/deploy.yml
	@echo "        - manage-mcp.sh" >> ansible/deploy.yml
	@echo "        - mcp-add.sh" >> ansible/deploy.yml
	@echo "        - mcp-remove.sh" >> ansible/deploy.yml
	@echo "        - mcp-sync.sh" >> ansible/deploy.yml
	@echo "" >> ansible/deploy.yml
	@echo "    - name: Check dependencies" >> ansible/deploy.yml
	@echo "      shell: cd \"{{ mcp_install_dir }}\" && make check" >> ansible/deploy.yml
	@echo "      register: dep_check" >> ansible/deploy.yml
	@echo "      ignore_errors: yes" >> ansible/deploy.yml
	@echo "" >> ansible/deploy.yml
	@echo "    - name: Show dependency check results" >> ansible/deploy.yml
	@echo "      debug:" >> ansible/deploy.yml
	@echo "        var: dep_check.stdout_lines" >> ansible/deploy.yml
	@echo "$(GREEN)Deployment playbook created at ansible/deploy.yml$(NC)"