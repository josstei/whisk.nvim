local M = {}

local TEST_TIMEOUT_MS = 10000
local RUN_TIMEOUT_MS = 180000

local suites = {}
local defining = nil
local queue = {}
local active = nil
local last_suite = nil

local results = {
  passed = 0,
  failed = 0,
  failures = {},
}

local function write(text)
  io.write(text)
  io.flush()
end

function M.describe(name, fn)
  defining = { name = name, tests = {}, before_each = nil }
  table.insert(suites, defining)
  fn()
  defining = nil
end

function M.before_each(fn)
  defining.before_each = fn
end

function M.it(name, fn)
  table.insert(defining.tests, { name = name, fn = fn })
end

function M.record_load_error(spec, err)
  results.failed = results.failed + 1
  table.insert(results.failures, { suite = spec, name = "<load>", err = tostring(err) })
  write("\n! failed to load " .. spec .. ": " .. tostring(err) .. "\n")
end

local run_next

local function finish_active(ok, err)
  local record = active
  if not record then
    return
  end
  active = nil
  if ok then
    results.passed = results.passed + 1
    write("  + " .. record.name .. "\n")
  else
    results.failed = results.failed + 1
    table.insert(results.failures, { suite = record.suite, name = record.name, err = tostring(err) })
    write("  - " .. record.name .. " [FAILED]\n")
  end
  vim.schedule(run_next)
end

local function step(record)
  if active ~= record then
    return
  end
  local ok, err = coroutine.resume(record.co)
  if not ok then
    finish_active(false, debug.traceback(record.co, err))
  elseif coroutine.status(record.co) == "dead" then
    finish_active(true)
  end
end

local function current_record()
  local record = active
  if not record or coroutine.running() ~= record.co then
    error("async harness helpers must be called inside it()", 3)
  end
  return record
end

function M.sleep(ms)
  local record = current_record()
  vim.defer_fn(function()
    step(record)
  end, ms)
  coroutine.yield()
end

function M.input(keys)
  local record = current_record()
  vim.api.nvim_input(keys)
  vim.schedule(function()
    step(record)
  end)
  coroutine.yield()
end

function M.wait_until(predicate, timeout_ms, message)
  local deadline = vim.uv.hrtime() + (timeout_ms or 2000) * 1000000
  while not predicate() do
    if vim.uv.hrtime() > deadline then
      error(message or "wait_until timed out", 2)
    end
    M.sleep(5)
  end
end

function M.settle()
  local loop = require("whisk.engine.loop")
  M.wait_until(function()
    return loop.get_active_count() == 0
  end, 5000, "animations did not settle")
end

function M.run()
  for _, suite in ipairs(suites) do
    for _, test in ipairs(suite.tests) do
      table.insert(queue, { suite = suite, test = test })
    end
  end

  vim.defer_fn(function()
    write("\n! integration run exceeded " .. RUN_TIMEOUT_MS .. "ms\n")
    vim.cmd("cquit 2")
  end, RUN_TIMEOUT_MS)

  run_next()
end

run_next = function()
  local entry = table.remove(queue, 1)
  if not entry then
    M.finish()
    return
  end

  if entry.suite ~= last_suite then
    last_suite = entry.suite
    write("\n" .. entry.suite.name .. "\n")
  end

  local record = { suite = entry.suite.name, name = entry.test.name }
  record.co = coroutine.create(function()
    if entry.suite.before_each then
      entry.suite.before_each()
    end
    entry.test.fn()
  end)
  active = record

  vim.defer_fn(function()
    if active == record then
      finish_active(false, "timed out after " .. TEST_TIMEOUT_MS .. "ms")
    end
  end, TEST_TIMEOUT_MS)

  step(record)
end

function M.finish()
  write("\n" .. string.rep("=", 60) .. "\n")
  write(string.format("Integration results: %d passed, %d failed\n", results.passed, results.failed))
  for i, failure in ipairs(results.failures) do
    write(string.format("\n%d) %s > %s\n   %s\n", i, failure.suite, failure.name, failure.err))
  end
  if results.failed > 0 then
    vim.cmd("cquit 1")
  else
    vim.cmd("qall!")
  end
end

local assert = {}

function assert.equals(actual, expected, message)
  if actual ~= expected then
    error(string.format("%s\nExpected: %s\nActual: %s", message or "values differ", vim.inspect(expected), vim.inspect(actual)), 2)
  end
end

function assert.is_true(value, message)
  if value ~= true then
    error(string.format("%s\nExpected: true\nActual: %s", message or "expected true", vim.inspect(value)), 2)
  end
end

M.assert = assert

return M
