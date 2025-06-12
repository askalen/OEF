-- models/test/test_persistent_vars.sql

{{
  config(
    pre_hook=[
      "{{ debug_adapter() }}",
      "{{ set_var('test_key', 'test_value') }}",
      "{{ set_var('counter', 1) }}"
    ]
  )
}}

select 
    '{{ get_var("test_key", "default_value") }}' as stored_value,
    {{ get_var("counter", 0) }} as counter_value,
    '{{ list_vars() }}' as all_variables,
    current_timestamp() as run_time