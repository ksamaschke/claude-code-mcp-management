#!/usr/bin/python
# Custom filter for dynamic variable substitution

import re

class FilterModule(object):
    def filters(self):
        return {
            'substitute_vars': self.substitute_vars
        }
    
    def substitute_vars(self, text, all_vars):
        """Replace ${VAR_NAME} with corresponding value from all_vars"""
        if not isinstance(text, str):
            return text
            
        # Find all ${VARIABLE} patterns
        pattern = r'\$\{([^}]+)\}'
        matches = re.findall(pattern, text)
        
        result = text
        for var_name in matches:
            # Special case for HOME
            if var_name == 'HOME' and 'ansible_env' in all_vars:
                result = result.replace(f'${{{var_name}}}', all_vars['ansible_env'].get('HOME', ''))
                continue
                
            # Check lowercase version
            if var_name.lower() in all_vars:
                result = result.replace(f'${{{var_name}}}', str(all_vars[var_name.lower()]))
            # Check exact match
            elif var_name in all_vars:
                result = result.replace(f'${{{var_name}}}', str(all_vars[var_name]))
                
        return result