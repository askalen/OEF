{{ config(
  _initial_date = '2020-01-01',
  _delta_limit = 20,
  tags = [],
  unique_key = ['test2','test4']
) }}

SELECT test,
test2,
test3 as test4,
hereWEgo,
meta_buttsnart,
anotherOne
FROM whatever