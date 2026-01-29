local M = {}

local results = {
  passed = 0,
  failed = 0,
  skipped = 0,
  errors = {},
  suites = {},
}

local current_suite = nil
local current_test = nil

local function reset_results()
  results = {
    passed = 0,
    failed = 0,
    skipped = 0,
    errors = {},
    suites = {},
  }
end

function M.describe(name, fn)
  current_suite = {
    name = name,
    tests = {},
    before_each = nil,
    after_each = nil,
    before_all = nil,
    after_all = nil,
  }
  table.insert(results.suites, current_suite)

  fn()

  current_suite = nil
end

function M.it(name, fn)
  if not current_suite then
    error("it() must be called inside describe()")
  end
  table.insert(current_suite.tests, {
    name = name,
    fn = fn,
    skip = false,
  })
end

function M.xit(name, fn)
  if not current_suite then
    error("xit() must be called inside describe()")
  end
  table.insert(current_suite.tests, {
    name = name,
    fn = fn,
    skip = true,
  })
end

function M.before_each(fn)
  if current_suite then
    current_suite.before_each = fn
  end
end

function M.after_each(fn)
  if current_suite then
    current_suite.after_each = fn
  end
end

function M.before_all(fn)
  if current_suite then
    current_suite.before_all = fn
  end
end

function M.after_all(fn)
  if current_suite then
    current_suite.after_all = fn
  end
end

local function run_test(suite, test)
  current_test = test.name

  if test.skip then
    results.skipped = results.skipped + 1
    io.write("  - " .. test.name .. " [SKIPPED]\n")
    return
  end

  local ok, err

  if suite.before_each then
    ok, err = pcall(suite.before_each)
    if not ok then
      results.failed = results.failed + 1
      table.insert(results.errors, {
        suite = suite.name,
        test = test.name,
        phase = "before_each",
        error = tostring(err),
      })
      io.write("  - " .. test.name .. " [FAILED in before_each]\n")
      return
    end
  end

  ok, err = pcall(test.fn)

  if suite.after_each then
    local after_ok, after_err = pcall(suite.after_each)
    if not after_ok then
      io.write("    Warning: after_each failed: " .. tostring(after_err) .. "\n")
    end
  end

  if ok then
    results.passed = results.passed + 1
    io.write("  + " .. test.name .. "\n")
  else
    results.failed = results.failed + 1
    table.insert(results.errors, {
      suite = suite.name,
      test = test.name,
      phase = "test",
      error = tostring(err),
    })
    io.write("  - " .. test.name .. " [FAILED]\n")
  end

  current_test = nil
end

local function run_suite(suite)
  io.write("\n" .. suite.name .. "\n")
  io.write(string.rep("-", #suite.name) .. "\n")

  if suite.before_all then
    local ok, err = pcall(suite.before_all)
    if not ok then
      io.write("  Suite setup failed: " .. tostring(err) .. "\n")
      for _, test in ipairs(suite.tests) do
        results.failed = results.failed + 1
        table.insert(results.errors, {
          suite = suite.name,
          test = test.name,
          phase = "before_all",
          error = tostring(err),
        })
      end
      return
    end
  end

  for _, test in ipairs(suite.tests) do
    run_test(suite, test)
  end

  if suite.after_all then
    local ok, err = pcall(suite.after_all)
    if not ok then
      io.write("  Suite teardown warning: " .. tostring(err) .. "\n")
    end
  end
end

function M.run()
  io.write("\n" .. string.rep("=", 60) .. "\n")
  io.write("Running Tests\n")
  io.write(string.rep("=", 60) .. "\n")

  for _, suite in ipairs(results.suites) do
    run_suite(suite)
  end

  io.write("\n" .. string.rep("=", 60) .. "\n")
  io.write("Results\n")
  io.write(string.rep("=", 60) .. "\n")
  io.write(string.format("Passed:  %d\n", results.passed))
  io.write(string.format("Failed:  %d\n", results.failed))
  io.write(string.format("Skipped: %d\n", results.skipped))
  io.write(string.format("Total:   %d\n", results.passed + results.failed + results.skipped))

  if #results.errors > 0 then
    io.write("\n" .. string.rep("-", 60) .. "\n")
    io.write("Failures:\n")
    io.write(string.rep("-", 60) .. "\n")
    for i, err in ipairs(results.errors) do
      io.write(string.format("\n%d) %s > %s\n", i, err.suite, err.test))
      io.write("   Phase: " .. err.phase .. "\n")
      io.write("   Error: " .. err.error .. "\n")
    end
  end

  local total = results.passed + results.failed + results.skipped
  local coverage = total > 0 and (results.passed / total * 100) or 0
  io.write(string.format("\nPass rate: %.1f%%\n", coverage))

  return results.failed == 0
end

function M.get_results()
  return results
end

function M.reset()
  reset_results()
end

return M
