# impl.py
from dbt.adapters.snowflake import SnowflakeAdapter
from .connections import (
    OEFSnowflakeConnectionManager,
    global_context,
    enhanced_macro_context
)

class OEFSnowflakeAdapter(SnowflakeAdapter):
    """Snowflake adapter with persistent variable support"""
    
    ConnectionManager = OEFSnowflakeConnectionManager
    
    def __init__(self, config, mp_context):
        super().__init__(config, mp_context)
        print(">>>> OEFSnowflakeAdapter initialized")
        self.set_var = lambda k, v: global_context.set(k, v)
        self.get_var = lambda k, d=None: global_context.get(k, d)  
        self.clear_vars = lambda: global_context.clear()
        self.list_vars = lambda: global_context.keys()
        self._original_macro_context_generator = None
    
    def set_macro_context_generator(self, macro_context_generator):
        print(f">>>> set_macro_context_generator called")
        self._original_macro_context_generator = macro_context_generator
        
        def wrapped_generator(macro, config, resolver, project):
            context = macro_context_generator(macro, config, resolver, project)
            context['set_var'] = self.set_var
            context['get_var'] = self.get_var
            context['clear_vars'] = self.clear_vars
            context['list_vars'] = self.list_vars
            context['global_context'] = global_context
            return context
        
        super().set_macro_context_generator(wrapped_generator)
    
    def set_macro_resolver(self, macro_resolver):
        print(f">>>> set_macro_resolver called")
        super().set_macro_resolver(macro_resolver)
    
    @classmethod
    def type(cls):
        return "oefsnowflake"
    
    def pre_model_hook(self, config):
        global_context.clear()
        return super().pre_model_hook(config)

    def execute_macro(self, macro_name, macro_resolver=None, context_override=None, kwargs=None, manifest=None):
        print(f">>>> execute_macro called: macro_name={macro_name}")
        if kwargs:
            print(f">>>> kwargs: {kwargs}")

        if context_override is None:
            context_override = {}

        if kwargs:
            context_override.update(kwargs)
            context_override['kwargs'] = kwargs

        # Do NOT pass `kwargs` to super().execute_macro()
        # Try oefsnowflake__ macro first
        if not macro_name.startswith(('oefsnowflake__', 'snowflake__')):
            try:
                oef_macro_name = f'oefsnowflake__{macro_name}'
                print(f">>>> Trying macro: {oef_macro_name}")
                return super().execute_macro(
                    macro_name=oef_macro_name,
                    macro_resolver=macro_resolver,
                    project=None,
                    context_override=context_override
                )
            except Exception as e:
                print(f">>>> Failed to find {oef_macro_name}, falling back. Error: {str(e)[:100]}")
        
        if macro_name.startswith('oefsnowflake__'):
            try:
                return super().execute_macro(
                    macro_name=macro_name,
                    macro_resolver=macro_resolver,
                    project=None,
                    context_override=context_override
                )
            except Exception:
                snowflake_macro = macro_name.replace('oefsnowflake__', 'snowflake__')
                print(f">>>> Falling back to {snowflake_macro}")
                return super().execute_macro(
                    macro_name=snowflake_macro,
                    macro_resolver=macro_resolver,
                    project=None,
                    context_override=context_override
                )

        # Default case
        return super().execute_macro(
            macro_name=macro_name,
            macro_resolver=macro_resolver,
            project=None,
            context_override=context_override
        )
