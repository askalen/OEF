{% macro debug_graph(target_name=none, expand_columns=false) %}
  {{ print("=== GRAPH DEBUG ===") }}
  
  {% if target_name %}
    {# Search for specific model or source #}
    {% set ns = namespace(found=false) %}
    
    {% for node_id, node in graph.nodes.items() %}
      {% if target_name in node_id %}
        {{ _print_node_details(node_id, node, "MODEL", expand_columns) }}
        {% set ns.found = true %}
      {% endif %}
    {% endfor %}
    
    {% for source_id, source in graph.sources.items() %}
      {% if target_name in source_id %}
        {{ _print_source_details(source_id, source, "SOURCE", expand_columns) }}
        {% set ns.found = true %}
      {% endif %}
    {% endfor %}
    
    {% if not ns.found %}
      {{ print("No model or source found containing: " ~ target_name) }}
    {% endif %}
    
  {% else %}
    {# Show everything #}
    {{ print("=== MODELS ===") }}
    {% for node_id, node in graph.nodes.items() %}
      {{ _print_node_details(node_id, node, "", expand_columns) }}
    {% endfor %}
    
    {{ print("=== SOURCES ===") }}
    {% for source_id, source in graph.sources.items() %}
      {{ _print_source_details(source_id, source, "", expand_columns) }}
    {% endfor %}
    
    {{ print("=== SUMMARY ===") }}
    {{ print("Total models: " ~ graph.nodes.keys() | length) }}
    {{ print("Total sources: " ~ graph.sources.keys() | length) }}
  {% endif %}
{% endmacro %}

{% macro _print_node_details(node_id, node, header_type="", expand_columns=false) %}
  {% if header_type %}
    {{ print("=== " ~ header_type ~ ": " ~ node.name ~ " ===") }}
  {% endif %}
  {{ print("ID: " ~ node_id) }}
  {{ print("  Name: " ~ node.name) }}
  {{ print("  Type: " ~ node.resource_type) }}
  {{ print("  Config:") }}
  {% for key in node.config.keys() | sort %}
    {{ print("    " ~ key ~ ": " ~ node.config[key]) }}
  {% endfor %}
  {{ print("  Meta: " ~ node.meta) }}
  {{ print("  Tags: " ~ node.tags) }}
  {% if expand_columns and node.columns %}
    {{ print("  Columns:") }}
    {% for column_name, column_info in node.columns.items() %}
      {{ print("    " ~ column_name ~ ":") }}
      {% for key in column_info.keys() | sort %}
        {% set value = column_info[key] %}
        {% if _has_content(value) %}
          {{ print("      " ~ key ~ ": " ~ value) }}
        {% endif %}
      {% endfor %}
    {% endfor %}
  {% elif expand_columns %}
    {{ print("  Columns: No column definitions found") }}
  {% endif %}
  {% if not header_type %}{{ print("---") }}{% endif %}
{% endmacro %}

{% macro _print_source_details(source_id, source, header_type="", expand_columns=false) %}
  {% if header_type %}
    {{ print("=== " ~ header_type ~ ": " ~ source.name ~ " ===") }}
  {% endif %}
  {{ print("ID: " ~ source_id) }}
  {{ print("  Name: " ~ source.name) }}
  {{ print("  Source: " ~ source.source_name) }}
  {% if expand_columns and source.columns %}
    {{ print("  Columns:") }}
    {% for column_name, column_info in source.columns.items() %}
      {{ print("    " ~ column_name ~ ":") }}
      {% for key in column_info.keys() | sort %}
        {% set value = column_info[key] %}
        {% if _has_content(value) %}
          {{ print("      " ~ key ~ ": " ~ value) }}
        {% endif %}
      {% endfor %}
    {% endfor %}
  {% elif expand_columns %}
    {{ print("  Columns: No column definitions found") }}
  {% elif source.columns %}
    {{ print("  Columns: " ~ source.columns.keys() | list) }}
  {% else %}
    {{ print("  Columns: No column definitions found") }}
  {% endif %}
  {% if not header_type %}{{ print("---") }}{% endif %}
{% endmacro %}

{% macro _has_content(value) %}
  {% if value is none %}
    {{ return(false) }}
  {% elif value is string and value | trim == "" %}
    {{ return(false) }}
  {% elif value is iterable and value is not string and value | length == 0 %}
    {{ return(false) }}
  {% elif value is mapping and value | length == 0 %}
    {{ return(false) }}
  {% else %}
    {{ return(true) }}
  {% endif %}
{% endmacro %}