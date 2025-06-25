{% macro generate_h_processing(source, target, pk_fields, compare_fields, dest_columns) -%}
  WITH new_data AS (
    SELECT * FROM {{ source }}
  ),
  
  -- Bring in previous versions of updated records
  with_previous AS (
    SELECT 
      *,
      'new' as _source_type
    FROM new_data
    
    UNION ALL
    
    SELECT 
      *,
      'old' as _source_type
    FROM {{ target }}
    WHERE ({{ pk_fields | join(', ') }}) IN (
      SELECT {{ pk_fields | join(', ') }} FROM new_data
    )
  ),
  
  -- Add row numbers for self-join
  numbered AS (
    SELECT 
      *,
      ROW_NUMBER() OVER (
        PARTITION BY {{ pk_fields | join(', ') }} 
        ORDER BY valid_from DESC
      ) as _rn
    FROM with_previous
  ),
  
  -- Self join to compare old and new
  compared AS (
    SELECT 
      curr.*,
      HASH({{ compare_fields | join(', ') }}) as meta_datahash,
      
      CASE 
        WHEN prev._rn IS NULL THEN TRUE
        WHEN HASH({{ compare_fields | join(', ') }}) != COALESCE(prev.meta_datahash, 0) THEN TRUE
        ELSE FALSE
      END as _is_change,
      
      CASE 
        WHEN prev._rn IS NOT NULL THEN
          OBJECT_CONSTRUCT(
            {%- for field in compare_fields %}
            '{{ field }}', IFF(curr.{{ field }} != prev.{{ field }}, prev.{{ field }}, NULL)
            {%- if not loop.last %},{% endif %}
            {%- endfor %}
          )
        ELSE NULL
      END as meta_changes
      
    FROM numbered curr
    LEFT JOIN numbered prev
      ON {{ pk_fields | map('format_string', 'curr.{} = prev.{}') | join(' AND ') }}
      AND curr._rn = prev._rn + 1
  ),
  
  -- Filter to only changes and add valid_to
  finalized AS (
    SELECT 
      {%- for column in dest_columns -%}
        {%- if column.name not in ['meta_datahash', 'meta_changes', 'meta_processed_at', 'valid_to'] %}
      {{ column.name }},
        {%- endif -%}
      {%- endfor %}
      meta_datahash,
      meta_changes,
      CURRENT_TIMESTAMP() as meta_processed_at,
      LEAD(valid_from, 1, '9999-12-31'::timestamp) OVER (
        PARTITION BY {{ pk_fields | join(', ') }} 
        ORDER BY valid_from
      ) as valid_to
    FROM compared
    WHERE _is_change = TRUE
  )
  
  SELECT * FROM finalized
{%- endmacro %}