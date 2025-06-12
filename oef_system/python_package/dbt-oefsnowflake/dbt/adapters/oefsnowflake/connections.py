# connections.py
from dbt.adapters.snowflake.connections import (
    SnowflakeConnectionManager,
    SnowflakeCredentials
)

# Create a proper storage class instead of using a dict directly
class PersistentStorage:
    def __init__(self):
        self._storage = {}
    
    def set(self, key, value):
        self._storage[key] = value
        return ''  # Return empty string for Jinja
    
    def get(self, key, default=None):
        return self._storage.get(key, default)
    
    def clear(self):
        self._storage.clear()
        return ''
    
    def keys(self):
        return list(self._storage.keys())

# Create the global storage instance
global_context = PersistentStorage()

def enhanced_macro_context(macro, config, manifest, package_name=None):
    """Enhanced macro context with persistent variables"""
    def get_var(key, default=None):
        """Get a persistent variable with optional default"""
        return global_context.get(key, default)
    
    def set_var(key, value):
        """Set a persistent variable"""
        global_context.set(key, value)
        return ''  # dbt macros need a return value
    
    def clear_vars():
        """Clear all persistent variables"""
        global_context.clear()
        return ''
    
    def list_vars():
        """List persistent variable keys (for debugging)"""
        return global_context.keys()
    
    # Create the base context
    context = {
        'set_var': set_var,
        'get_var': get_var,
        'clear_vars': clear_vars,
        'list_vars': list_vars,
        'global_context': global_context,  # Also expose the object directly
    }
    
    # Add any additional context from the macro's config
    if hasattr(macro, 'context'):
        context.update(macro.context)
    
    return context

class OEFSnowflakeCredentials(SnowflakeCredentials):
    @property
    def type(self):
        return "oefsnowflake"

class OEFSnowflakeConnectionManager(SnowflakeConnectionManager):
    TYPE = "oefsnowflake"