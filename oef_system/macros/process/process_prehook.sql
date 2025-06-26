{% macro process_prehook() %}
{%- if execute -%}

  {# ========================================
     STEP 1: LOG MODEL START
     ======================================== #}
  {{ log("", info=true) }}
  {{ log("Running model: " ~ this.name, info=true) }}

  {# ========================================
     STEP 2: GET MODEL CONFIGURATION
     ======================================== #}
  {%- set model_configs = get_model_configs() -%}
  {%- set is_src_table = this.name.startswith('src_') or model_configs.upstreams.sources|length > 0 -%}
  {%- set table_type = model_configs.type -%}
  
  {# ========================================
     STEP 3: SET LOCK
     ======================================== #}
  {{ set_model_meta_lock() }}
  
  {# ========================================
     STEP 4: GET MODEL METADATA
     Includes lock verification
     ======================================== #}
  {%- set model_meta = get_model_meta() -%}
  
  {# ========================================
     STEP 5: CHECK PROCESSING CONDITIONS
     ======================================== #}
  {# Check if lock was acquired or if existing lock is stale #}
  {%- set has_lock = model_meta.current_state.lock_id == invocation_id -%}
  {%- set lock_is_stale = false -%}
  {%- set timeout_minutes = var('lock_timeout_minutes', 30) -%}

  {%- if not has_lock and model_meta.current_state.lock_id is not none -%}
    {# Check if the lock is stale #}
    {%- set check_stale_query %}
      SELECT locked_at < DATEADD('minute', -{{ timeout_minutes }}, CURRENT_TIMESTAMP()) as is_stale
      FROM meta.model
      WHERE model_name = '{{ this.name }}'
        AND locked_run_id IS NOT NULL
    {%- endset %}
    
    {%- set stale_results = run_query(check_stale_query) -%}
    {%- if stale_results and stale_results.rows|length > 0 -%}
      {%- set lock_is_stale = stale_results.rows[0][0] -%}
    {%- endif -%}
    
    {%- if lock_is_stale -%}
      {{ log("  Found stale lock, clearing and retrying...", info=true) }}
      {{ operation_clear_lock(force=true) }}
      {{ set_model_meta_lock() }}
      {# Re-get metadata after clearing stale lock #}
      {%- set model_meta = get_model_meta() -%}
      {%- set has_lock = model_meta.current_state.lock_id == invocation_id -%}
    {%- endif -%}
  {%- endif -%}

  {%- if not has_lock -%}
    {{ log("  Processing lock active, skipping table", info=true) }}
    {%- do var('oef_should_process', false) -%}
    {%- do var('oef_delta_from', none) -%}
    {%- do var('oef_delta_to', none) -%}
    {%- do var('oef_data_min', none) -%}
    {%- do var('oef_backfilling', false) -%}
    {{ return('') }}
  {%- endif -%}
  
  {# ========================================
     STEP 6: CALCULATE DELTAS
     ======================================== #}
  {# Determine delta_from #}
  {%- if model_meta.current_state.is_first_run -%}
    {%- set data_begin = model_configs.configs._initial_date or '1900-01-01' -%}
    {%- set delta_from = data_begin -%}
  {%- else -%}
    {%- if is_src_table -%}
      {%- if model_meta.current_state.last_process_time -%}
        {%- set delta_from = model_meta.current_state.last_process_time -%}
      {%- elif model_meta.current_state.last_data_time -%}
        {%- set delta_from = model_meta.current_state.last_data_time -%}
      {%- else -%}
        {%- set delta_from = '1900-01-01' -%}
      {%- endif -%}
    {%- else -%}
      {%- if model_meta.current_state.last_data_time -%}
        {%- set delta_from = model_meta.current_state.last_data_time -%}
      {%- elif model_meta.current_state.last_effective_time -%}
        {%- set delta_from = model_meta.current_state.last_effective_time -%}
      {%- else -%}
        {%- set delta_from = '1900-01-01' -%}
      {%- endif -%}
    {%- endif -%}
  {%- endif -%}
  
  {# Determine delta_to #}
  {%- if is_src_table -%}
    {# SRC tables: use delta_limit or max future date #}
    {%- set delta_limit = model_configs.configs._delta_limit -%}
    {%- if delta_limit -%}
      {%- set delta_to = "DATEADD('day', " ~ delta_limit ~ ", '" ~ delta_from ~ "'::timestamp)" -%}
    {%- else -%}
      {%- set delta_to = '9999-12-31' -%}
    {%- endif -%}
    {%- set is_backfilling = false -%}
  {%- else -%}
    {# Non-SRC tables: use minimum upstream effective_to #}
    {%- set upstream_names = model_meta.upstream_states.table_names -%}
    {%- set upstream_times = model_meta.upstream_states.effective_times -%}
    {%- if upstream_times and upstream_times | length > 0 -%}
      {# Log upstream tables for visibility #}
      {{ log("  Upstream tables:", info=true) }}
      {%- for i in range(upstream_names|length) -%}
        {%- if upstream_names[i] -%}
          {{ log("    " ~ upstream_names[i] ~ ": " ~ upstream_times[i], info=true) }}
        {%- endif -%}
      {%- endfor -%}
      
      {# Find minimum non-null upstream time #}
      {%- set min_upstream_time = none -%}
      {%- for time in upstream_times -%}
        {%- if time and (not min_upstream_time or time < min_upstream_time) -%}
          {%- set min_upstream_time = time -%}
        {%- endif -%}
      {%- endfor -%}
      
      {%- if not min_upstream_time -%}
        {{ log("  No upstream tables have progressed. Skipping.", info=true) }}
        {%- do var('oef_should_process', false) -%}
        {%- do var('oef_delta_from', none) -%}
        {%- do var('oef_delta_to', none) -%}
        {%- do var('oef_data_min', none) -%}
        {%- do var('oef_backfilling', false) -%}
        {{ return('') }}
      {%- endif -%}
      
      {# Apply delta_limit if configured #}
      {%- set delta_limit = model_configs.configs._delta_limit -%}
      {%- if delta_limit -%}
        {%- set limited_delta_to = "DATEADD('day', " ~ delta_limit ~ ", '" ~ delta_from ~ "'::timestamp)" -%}
        {%- if limited_delta_to < min_upstream_time -%}
          {%- set delta_to = limited_delta_to -%}
          {%- set is_backfilling = true -%}
        {%- else -%}
          {%- set delta_to = min_upstream_time -%}
          {%- set is_backfilling = false -%}
        {%- endif -%}
      {%- else -%}
        {%- set delta_to = min_upstream_time -%}
        {%- set is_backfilling = false -%}
      {%- endif -%}
    {%- else -%}
      {{ log("  No upstream dependencies found. Skipping.", info=true) }}
      {%- do var('oef_should_process', false) -%}
      {%- do var('oef_delta_from', none) -%}
      {%- do var('oef_delta_to', none) -%}
      {%- do var('oef_data_min', none) -%}
      {%- do var('oef_backfilling', false) -%}
      {{ return('') }}
    {%- endif -%}
  {%- endif -%}
  
  {# Check if delta window is valid #}
  {%- if delta_to <= delta_from -%}
    {{ log("  Delta window is empty. Nothing to process.", info=true) }}
    {%- do var('oef_should_process', false) -%}
    {%- do var('oef_delta_from', delta_from) -%}
    {%- do var('oef_delta_to', delta_to) -%}
    {%- do var('oef_data_min', none) -%}
    {%- do var('oef_backfilling', false) -%}
    {{ return('') }}
  {%- endif -%}
  
  {# Calculate data_min #}
  {%- if is_src_table -%}
    {%- set data_min = model_meta.current_state.last_data_time or delta_from -%}
  {%- else -%}
    {%- set data_min = delta_from -%}
  {%- endif -%}
  
  {# ========================================
     STEP 7: LOGGING
     ======================================== #}
  {{ log("  delta_from: " ~ delta_from, info=true) }}
  {{ log("  delta_to: " ~ delta_to, info=true) }}
  {{ log("  data_min: " ~ data_min, info=true) }}
  {%- if is_backfilling -%}
  {{ log("  backfilling: true", info=true) }}
  {%- endif -%}
  
  {# ========================================
     STEP 8: HANDLE ROLLBACK
     ======================================== #}
  {%- set rollback_days = model_configs.configs._rollback_days -%}
  
  {%- if rollback_days is not none and not model_meta.current_state.is_first_run -%}
    {%- if rollback_days == 0 -%}
      {{ log("  Rolling back to effective_to: " ~ model_meta.current_state.last_effective_time, info=true) }}
      {% set rollback_result = operation_rollback_table(this.name, model_meta.current_state.last_effective_time, false, false, true) %}
    {%- else -%}
      {%- set rollback_date = "DATEADD('day', -" ~ rollback_days ~ ", '" ~ delta_from ~ "'::timestamp)" -%}
      {{ log("  Rolling back " ~ rollback_days ~ " days from delta_from", info=true) }}
      {% set rollback_result = operation_rollback_table(this.name, rollback_date, false, false, true) %}
    {%- endif -%}
  {%- endif -%}
  
  {# ========================================
     STEP 9: SET VARIABLES FOR MODEL
     ======================================== #}
  {%- do var('oef_should_process', true) -%}
  {%- do var('oef_delta_from', delta_from) -%}
  {%- do var('oef_delta_to', delta_to) -%}
  {%- do var('oef_data_min', data_min) -%}
  {%- do var('oef_backfilling', is_backfilling) -%}
  {{ return('') }}

{%- endif -%}
{% endmacro %}