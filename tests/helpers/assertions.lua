local M = {}

function M.equals(actual, expected, message)
  if actual ~= expected then
    error(string.format(
      "%s\nExpected: %s\nActual: %s",
      message or "Assertion failed",
      tostring(expected),
      tostring(actual)
    ))
  end
  return true
end

function M.not_equals(actual, expected, message)
  if actual == expected then
    error(string.format(
      "%s\nExpected not: %s\nActual: %s",
      message or "Assertion failed",
      tostring(expected),
      tostring(actual)
    ))
  end
  return true
end

function M.is_true(value, message)
  if value ~= true then
    error(string.format(
      "%s\nExpected: true\nActual: %s",
      message or "Assertion failed",
      tostring(value)
    ))
  end
  return true
end

function M.is_false(value, message)
  if value ~= false then
    error(string.format(
      "%s\nExpected: false\nActual: %s",
      message or "Assertion failed",
      tostring(value)
    ))
  end
  return true
end

function M.is_nil(value, message)
  if value ~= nil then
    error(string.format(
      "%s\nExpected: nil\nActual: %s",
      message or "Assertion failed",
      tostring(value)
    ))
  end
  return true
end

function M.is_not_nil(value, message)
  if value == nil then
    error(string.format(
      "%s\nExpected: not nil\nActual: nil",
      message or "Assertion failed"
    ))
  end
  return true
end

function M.is_type(value, expected_type, message)
  local actual_type = type(value)
  if actual_type ~= expected_type then
    error(string.format(
      "%s\nExpected type: %s\nActual type: %s",
      message or "Assertion failed",
      expected_type,
      actual_type
    ))
  end
  return true
end

function M.table_equals(actual, expected, message)
  local function deep_compare(t1, t2, path)
    path = path or ""
    if type(t1) ~= type(t2) then
      return false, string.format("Type mismatch at %s: %s vs %s", path, type(t1), type(t2))
    end
    if type(t1) ~= 'table' then
      if t1 ~= t2 then
        return false, string.format("Value mismatch at %s: %s vs %s", path, tostring(t1), tostring(t2))
      end
      return true
    end
    for k, v in pairs(t1) do
      local new_path = path == "" and tostring(k) or (path .. "." .. tostring(k))
      local ok, err = deep_compare(v, t2[k], new_path)
      if not ok then
        return false, err
      end
    end
    for k, v in pairs(t2) do
      if t1[k] == nil then
        local new_path = path == "" and tostring(k) or (path .. "." .. tostring(k))
        return false, string.format("Extra key at %s", new_path)
      end
    end
    return true
  end

  local ok, err = deep_compare(actual, expected)
  if not ok then
    error(string.format("%s\n%s", message or "Table comparison failed", err))
  end
  return true
end

function M.contains(tbl, value, message)
  for _, v in ipairs(tbl) do
    if v == value then
      return true
    end
  end
  error(string.format(
    "%s\nTable does not contain: %s",
    message or "Assertion failed",
    tostring(value)
  ))
end

function M.has_key(tbl, key, message)
  if tbl[key] == nil then
    error(string.format(
      "%s\nTable does not have key: %s",
      message or "Assertion failed",
      tostring(key)
    ))
  end
  return true
end

function M.throws(fn, expected_pattern, message)
  local ok, err = pcall(fn)
  if ok then
    error(string.format(
      "%s\nExpected error but function succeeded",
      message or "Assertion failed"
    ))
  end
  if expected_pattern and not string.match(tostring(err), expected_pattern) then
    error(string.format(
      "%s\nExpected error pattern: %s\nActual error: %s",
      message or "Assertion failed",
      expected_pattern,
      tostring(err)
    ))
  end
  return true
end

function M.does_not_throw(fn, message)
  local ok, err = pcall(fn)
  if not ok then
    error(string.format(
      "%s\nUnexpected error: %s",
      message or "Assertion failed",
      tostring(err)
    ))
  end
  return true
end

function M.greater_than(actual, expected, message)
  if not (actual > expected) then
    error(string.format(
      "%s\nExpected %s > %s",
      message or "Assertion failed",
      tostring(actual),
      tostring(expected)
    ))
  end
  return true
end

function M.less_than(actual, expected, message)
  if not (actual < expected) then
    error(string.format(
      "%s\nExpected %s < %s",
      message or "Assertion failed",
      tostring(actual),
      tostring(expected)
    ))
  end
  return true
end

function M.greater_or_equal(actual, expected, message)
  if not (actual >= expected) then
    error(string.format(
      "%s\nExpected %s >= %s",
      message or "Assertion failed",
      tostring(actual),
      tostring(expected)
    ))
  end
  return true
end

function M.less_or_equal(actual, expected, message)
  if not (actual <= expected) then
    error(string.format(
      "%s\nExpected %s <= %s",
      message or "Assertion failed",
      tostring(actual),
      tostring(expected)
    ))
  end
  return true
end

function M.matches(actual, pattern, message)
  if not string.match(tostring(actual), pattern) then
    error(string.format(
      "%s\nExpected pattern: %s\nActual: %s",
      message or "Assertion failed",
      pattern,
      tostring(actual)
    ))
  end
  return true
end

function M.length(tbl, expected_len, message)
  local actual_len = #tbl
  if actual_len ~= expected_len then
    error(string.format(
      "%s\nExpected length: %d\nActual length: %d",
      message or "Assertion failed",
      expected_len,
      actual_len
    ))
  end
  return true
end

return M
