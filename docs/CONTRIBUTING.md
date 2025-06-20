# Contributing to Ansible MCP Installer

Thank you for your interest in contributing to Ansible MCP Installer! This document provides guidelines for contributing to the project.

## Code of Conduct

Please be respectful and constructive in all interactions. We aim to maintain a welcoming environment for all contributors.

## How to Contribute

### Reporting Issues

1. Check existing issues to avoid duplicates
2. Use a clear, descriptive title
3. Include:
   - Ansible version (`ansible --version`)
   - Claude CLI version (`claude --version`)
   - Operating system
   - Complete error messages
   - Steps to reproduce

### Suggesting Features

1. Check if the feature has been requested
2. Explain the use case
3. Provide examples if possible

### Submitting Changes

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Make your changes
4. Test thoroughly
5. Commit with clear messages
6. Push to your branch
7. Open a Pull Request

## Development Guidelines

### Ansible Best Practices

- Use meaningful task names
- Make tasks idempotent
- Use `changed_when` and `failed_when` appropriately
- Document complex logic with comments
- Follow [Ansible Best Practices](https://docs.ansible.com/ansible/latest/user_guide/playbooks_best_practices.html)

### Code Style

- YAML files: 2-space indentation
- Line length: 120 characters maximum
- Use `---` at the start of YAML files
- Quote strings containing special characters

### Testing

Before submitting:

1. Test with minimal configuration
2. Test all installation modes (all, group, individual)
3. Test both scopes (user, project)
4. Verify cleanup functionality
5. Check idempotency (run twice, ensure no unexpected changes)

Example test commands:
```bash
# Test syntax
ansible-playbook manage-mcp.yml --syntax-check

# Test with check mode
ansible-playbook manage-mcp.yml -e @config.yml --check

# Test different modes
ansible-playbook manage-mcp.yml -e @config.yml -e mcp_mode=all
ansible-playbook manage-mcp.yml -e @config.yml -e mcp_mode=group -e mcp_group=development
```

### Documentation

- Update README.md if adding features
- Document new variables in defaults/main.yml
- Add examples for complex features
- Keep documentation concise and clear

## Pull Request Process

1. Update documentation as needed
2. Add entries to examples/ if introducing new patterns
3. Ensure all tests pass
4. Update the README.md with details of changes if applicable
5. PR title should clearly describe the change
6. Link related issues in the PR description

## Adding New MCP Servers

When adding support for new MCP servers:

1. Add server definition to group_vars/all.yml
2. Include all required configuration options
3. Document any required environment variables in .env.example
4. Add to appropriate server groups
5. Test the installation process
6. Update examples if needed

Example:
```yaml
new_server:
  enabled: false  # Default to disabled
  type: stdio
  command: npx
  args:
    - -y
    - "@org/new-mcp-server"
  requires_env:
    - NEW_SERVER_API_KEY
  env:
    NEW_SERVER_API_KEY: "{{ new_server_key | default('') }}"
```

## Questions?

Feel free to open an issue for clarification on any contribution guidelines.