{% macro process_posthook() %}
UPDATE meta.model
SET
  effective_to = $oef_delta_to,
  processed_at = sysdate(),
  locked_run_id = null,
  locked_at = null
{% endmacro %}