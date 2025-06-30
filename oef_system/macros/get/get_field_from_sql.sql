{% macro get_fields_from_sql(sql_content) %}
{%- if execute -%}

  {#- Initialize tracking variables -#}
  {%- set lines = sql_content.split('\n') -%}
  {%- set fields = [] -%}
  {%- set in_final_select = false -%}
  {%- set paren_depth = 0 -%}
  {%- set last_select_line = -1 -%}
  
  {#- First pass: Find the last SELECT statement not in parentheses -#}
  {%- for line in lines -%}
    {%- set line_upper = line.upper() -%}
    {%- set line_stripped = line.strip() -%}
    
    {#- Track parentheses depth -#}
    {%- set paren_depth = paren_depth + line.count('(') - line.count(')') -%}
    
    {#- Look for SELECT at depth 0 (not in subquery) -#}
    {%- if paren_depth == 0 and ' SELECT ' in ' ' ~ line_upper ~ ' ' -%}
      {%- set last_select_line = loop.index0 -%}
    {%- endif -%}
  {%- endfor -%}
  
  {#- Second pass: Extract fields from the final SELECT -#}
  {%- set in_select_clause = false -%}
  {%- set jinja_warnings = [] -%}
  
  {%- for line in lines -%}
    {%- if loop.index0 >= last_select_line -%}
      {%- set line_stripped = line.strip() -%}
      {%- set line_upper = line_stripped.upper() -%}
      
      {#- Start processing after finding SELECT -#}
      {%- if not in_select_clause and ' SELECT ' in ' ' ~ line_upper ~ ' ' -%}
        {%- set in_select_clause = true -%}
        {#- Handle same-line fields after SELECT -#}
        {%- set after_select = line.split('SELECT', 1)[-1] if 'SELECT' in line.upper() else line.split('select', 1)[-1] -%}
        {%- if after_select.strip() and not after_select.strip().startswith('--') -%}
          {%- set line_stripped = after_select.strip() -%}
        {%- else -%}
          {%- set line_stripped = '' -%}
        {%- endif -%}
      {%- endif -%}
      
      {#- Stop at next SQL clause -#}
      {%- if in_select_clause -%}
        {%- set stop_words = ['FROM ', 'WHERE ', 'GROUP BY', 'HAVING ', 'ORDER BY', 'LIMIT ', 'UNION ', 'INTERSECT ', 'EXCEPT '] -%}
        {%- set should_stop = false -%}
        {%- for stop_word in stop_words -%}
          {%- if line_upper.startswith(stop_word) -%}
            {%- set should_stop = true -%}
          {%- endif -%}
        {%- endfor -%}
        
        {%- if should_stop -%}
          {%- set in_select_clause = false -%}
        {%- endif -%}
      {%- endif -%}
      
      {#- Process fields in SELECT clause -#}
      {%- if in_select_clause and line_stripped and not line_stripped.startswith('--') -%}
        
        {#- Check for Jinja templating -#}
        {%- if '{{' in line_stripped or '{%' in line_stripped or '{#' in line_stripped -%}
          {%- do jinja_warnings.append("Line " ~ (loop.index0 + 1) ~ ": " ~ line_stripped) -%}
        {%- else -%}
          
          {#- Extract field name/alias -#}
          {#- Remove trailing comma if present -#}
          {%- set line_clean = line_stripped.rstrip(',').strip() -%}
          
          {#- Skip empty lines -#}
          {%- if line_clean -%}
            {#- Check for alias with AS -#}
            {%- if ' AS ' in line_clean.upper() -%}
              {#- Get everything after the last AS -#}
              {%- set parts = line_clean.upper().split(' AS ') -%}
              {%- set field_name = line_clean[line_clean.upper().rfind(' AS ') + 4:].strip() -%}
            {%- else -%}
              {#- Get the last word (handling expressions) -#}
              {%- set words = line_clean.split() -%}
              {%- if words -%}
                {%- set field_name = words[-1] -%}
              {%- else -%}
                {%- set field_name = line_clean -%}
              {%- endif -%}
            {%- endif -%}
            
            {#- Clean up field name -#}
            {%- set field_name = field_name.strip().strip('"').strip("'").strip('`') -%}
            
            {#- Add to fields list if not empty -#}
            {%- if field_name and field_name not in fields -%}
              {%- do fields.append(field_name) -%}
            {%- endif -%}
          {%- endif -%}
          
        {%- endif -%}
      {%- endif -%}
    {%- endif -%}
  {%- endfor -%}
  
  {#- Log warnings if Jinja detected -#}
  {%- if jinja_warnings -%}
    {{ log("WARNING: Jinja templating detected in final SELECT clause:", info=true) }}
    {%- for warning in jinja_warnings -%}
      {{ log("  " ~ warning, info=true) }}
    {%- endfor -%}
    {{ log("  Final SELECT must have static field names. Move dynamic logic into CTEs.", info=true) }}
  {%- endif -%}
  
  {#- Log parsed fields for debugging -#}
  {{ log("  Parsed " ~ fields|length ~ " fields from SQL", info=true) }}
  {%- if fields|length > 0 -%}
    {{ log("    Fields: " ~ fields|join(', '), info=true) }}
  {%- endif -%}
  
  {{ return(fields) }}

{%- endif -%}
{% endmacro %}