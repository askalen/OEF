{% macro format_sql(sql_text) %}
{%- set cleaned = sql_text | trim -%}
{%- set lines = cleaned.split('\n') -%}
{%- set formatted_lines = [] -%}
{%- set indent_tracker = [0] -%}

{%- for line in lines -%}
  {%- set trimmed_line = line | trim -%}
  {%- if trimmed_line != '' -%}
    
    {%- set clean_line = trimmed_line.lstrip('()[]{}.,;:') -%}
    {%- set clean_first_word = clean_line.split()[0] | upper if clean_line.split() else '' -%}
    
    {%- set major_keywords = ['WITH', 'SELECT', 'FROM', 'WHERE', 'JOIN', 'LEFT', 'RIGHT', 'INNER', 'OUTER', 'CROSS', 'UNION', 'INTERSECT', 'EXCEPT', 'ORDER', 'GROUP', 'HAVING', 'LIMIT', 'QUALIFY'] -%}
    {%- set is_major_keyword = clean_first_word in major_keywords or clean_first_word.endswith('JOIN') -%}
    
    {%- if trimmed_line.startswith(')') -%}
      {%- set current_level = indent_tracker.pop() -%}
      {%- set _ = indent_tracker.append(current_level - 1) -%}
    {%- elif is_major_keyword and indent_tracker[0] > 0 -%}
      {%- set current_level = indent_tracker.pop() -%}
      {%- set _ = indent_tracker.append(current_level - 1) -%}
    {%- endif -%}
    
    {%- if ')' in trimmed_line and not trimmed_line.startswith(')') -%}
      {%- set close_parens = trimmed_line.count(')') -%}
      {%- set open_parens = trimmed_line.count('(') -%}
      {%- set net_close = close_parens - open_parens -%}
      {%- if net_close > 0 -%}
        {%- set current_level = indent_tracker.pop() -%}
        {%- set _ = indent_tracker.append(current_level - net_close) -%}
      {%- endif -%}
    {%- endif -%}
    
    {%- set current_indent = '  ' * indent_tracker[0] -%}
    {%- set _ = formatted_lines.append(current_indent + trimmed_line) -%}
    
    {%- if is_major_keyword -%}
      {%- set current_level = indent_tracker.pop() -%}
      {%- set _ = indent_tracker.append(current_level + 1) -%}
    {%- elif 'ON' in trimmed_line.upper() and clean_first_word.endswith('JOIN') -%}
      {%- set current_level = indent_tracker.pop() -%}
      {%- set _ = indent_tracker.append(current_level + 1) -%}
    {%- elif '(' in trimmed_line -%}
      {%- set open_parens = trimmed_line.count('(') -%}
      {%- set close_parens = trimmed_line.count(')') -%}
      {%- set net_open = open_parens - close_parens -%}
      {%- if net_open > 0 -%}
        {%- set current_level = indent_tracker.pop() -%}
        {%- set _ = indent_tracker.append(current_level + net_open) -%}
      {%- endif -%}
    {%- endif -%}
    
  {%- endif -%}
{%- endfor -%}

{{ formatted_lines | join('\n') }}
{%- endmacro %}