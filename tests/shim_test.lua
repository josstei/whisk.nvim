local function test_shims()
  local results = {}
  local function log(msg, ok)
    table.insert(results, { msg = msg, ok = ok })
  end

  local orchestrator_calls = {}
  local original_execute

  local function setup_mock()
    require("luxmotion").setup()
    local orchestrator = require("luxmotion.engine.orchestrator")
    original_execute = orchestrator.execute
    orchestrator.execute = function(motion_id, input)
      table.insert(orchestrator_calls, { motion_id = motion_id, input = input })
    end
  end

  local function teardown_mock()
    local orchestrator = require("luxmotion.engine.orchestrator")
    orchestrator.execute = original_execute
    orchestrator_calls = {}
  end

  local function assert_call(expected_id, expected_input, test_name)
    local last = orchestrator_calls[#orchestrator_calls]
    if not last then
      log(test_name .. ": no orchestrator call made", false)
      return false
    end
    if last.motion_id ~= expected_id then
      log(test_name .. ": expected motion_id '" .. expected_id .. "', got '" .. tostring(last.motion_id) .. "'", false)
      return false
    end
    for k, v in pairs(expected_input) do
      if last.input[k] ~= v then
        log(test_name .. ": expected input." .. k .. "='" .. tostring(v) .. "', got '" .. tostring(last.input[k]) .. "'", false)
        return false
      end
    end
    log(test_name, true)
    return true
  end

  setup_mock()

  local cursor_keymaps = require("luxmotion.cursor.keymaps")

  cursor_keymaps.smooth_move("j", 5)
  assert_call("basic_j", { count = 5, direction = "j" }, "cursor.smooth_move('j', 5)")

  cursor_keymaps.smooth_move("k", 1)
  assert_call("basic_k", { count = 1, direction = "k" }, "cursor.smooth_move('k', 1)")

  cursor_keymaps.smooth_move("h", 3)
  assert_call("basic_h", { count = 3, direction = "h" }, "cursor.smooth_move('h', 3)")

  cursor_keymaps.smooth_move("l", 2)
  assert_call("basic_l", { count = 2, direction = "l" }, "cursor.smooth_move('l', 2)")

  cursor_keymaps.smooth_move("0", 1)
  assert_call("basic_0", { count = 1, direction = "0" }, "cursor.smooth_move('0', 1)")

  cursor_keymaps.smooth_move("$", 1)
  assert_call("basic_$", { count = 1, direction = "$" }, "cursor.smooth_move('$', 1)")

  cursor_keymaps.smooth_word_move("w", 3)
  assert_call("word_w", { count = 3, direction = "w" }, "cursor.smooth_word_move('w', 3)")

  cursor_keymaps.smooth_word_move("b", 2)
  assert_call("word_b", { count = 2, direction = "b" }, "cursor.smooth_word_move('b', 2)")

  cursor_keymaps.smooth_word_move("e", 1)
  assert_call("word_e", { count = 1, direction = "e" }, "cursor.smooth_word_move('e', 1)")

  cursor_keymaps.smooth_word_move("W", 1)
  assert_call("word_W", { count = 1, direction = "W" }, "cursor.smooth_word_move('W', 1)")

  cursor_keymaps.smooth_find_move("f", "x", 1)
  assert_call("find_f", { char = "x", count = 1, direction = "f" }, "cursor.smooth_find_move('f', 'x', 1)")

  cursor_keymaps.smooth_find_move("F", "a", 2)
  assert_call("find_F", { char = "a", count = 2, direction = "F" }, "cursor.smooth_find_move('F', 'a', 2)")

  cursor_keymaps.smooth_find_move("t", "b", 1)
  assert_call("find_t", { char = "b", count = 1, direction = "t" }, "cursor.smooth_find_move('t', 'b', 1)")

  cursor_keymaps.smooth_find_move("T", "c", 1)
  assert_call("find_T", { char = "c", count = 1, direction = "T" }, "cursor.smooth_find_move('T', 'c', 1)")

  cursor_keymaps.smooth_text_object_move("{", 1)
  assert_call("text_object_{", { count = 1, direction = "{" }, "cursor.smooth_text_object_move('{', 1)")

  cursor_keymaps.smooth_text_object_move("}", 2)
  assert_call("text_object_}", { count = 2, direction = "}" }, "cursor.smooth_text_object_move('}', 2)")

  cursor_keymaps.smooth_text_object_move("%", 1)
  assert_call("text_object_%", { count = 1, direction = "%" }, "cursor.smooth_text_object_move('%', 1)")

  cursor_keymaps.smooth_line_move("gg", 10)
  assert_call("line_gg", { count = 10, direction = "gg" }, "cursor.smooth_line_move('gg', 10)")

  cursor_keymaps.smooth_line_move("G", 50)
  assert_call("line_G", { count = 50, direction = "G" }, "cursor.smooth_line_move('G', 50)")

  cursor_keymaps.smooth_line_move("|", 5)
  assert_call("line_|", { count = 5, direction = "|" }, "cursor.smooth_line_move('|', 5)")

  cursor_keymaps.smooth_search_move("n", 1)
  assert_call("search_n", { count = 1, direction = "n" }, "cursor.smooth_search_move('n', 1)")

  cursor_keymaps.smooth_search_move("N", 2)
  assert_call("search_N", { count = 2, direction = "N" }, "cursor.smooth_search_move('N', 2)")

  cursor_keymaps.smooth_screen_line_move("gj", 1)
  assert_call("screen_gj", { count = 1, direction = "gj" }, "cursor.smooth_screen_line_move('gj', 1)")

  cursor_keymaps.smooth_screen_line_move("gk", 3)
  assert_call("screen_gk", { count = 3, direction = "gk" }, "cursor.smooth_screen_line_move('gk', 3)")

  local scroll_keymaps = require("luxmotion.scroll.keymaps")

  scroll_keymaps.smooth_scroll("ctrl_d", 1)
  assert_call("scroll_ctrl_d", { count = 1, direction = "ctrl_d" }, "scroll.smooth_scroll('ctrl_d', 1)")

  scroll_keymaps.smooth_scroll("ctrl_u", 2)
  assert_call("scroll_ctrl_u", { count = 2, direction = "ctrl_u" }, "scroll.smooth_scroll('ctrl_u', 2)")

  scroll_keymaps.smooth_scroll("ctrl_f", 1)
  assert_call("scroll_ctrl_f", { count = 1, direction = "ctrl_f" }, "scroll.smooth_scroll('ctrl_f', 1)")

  scroll_keymaps.smooth_scroll("ctrl_b", 1)
  assert_call("scroll_ctrl_b", { count = 1, direction = "ctrl_b" }, "scroll.smooth_scroll('ctrl_b', 1)")

  scroll_keymaps.visual_smooth_scroll("ctrl_d", 3)
  assert_call("scroll_ctrl_d", { count = 3, direction = "ctrl_d" }, "scroll.visual_smooth_scroll('ctrl_d', 3)")

  scroll_keymaps.smooth_position("zz")
  assert_call("position_zz", { direction = "zz" }, "scroll.smooth_position('zz')")

  scroll_keymaps.smooth_position("zt")
  assert_call("position_zt", { direction = "zt" }, "scroll.smooth_position('zt')")

  scroll_keymaps.smooth_position("zb")
  assert_call("position_zb", { direction = "zb" }, "scroll.smooth_position('zb')")

  local setup_ok = pcall(cursor_keymaps.setup_keymaps)
  log("cursor.setup_keymaps() no-op", setup_ok)

  setup_ok = pcall(scroll_keymaps.setup_keymaps)
  log("scroll.setup_keymaps() no-op", setup_ok)

  teardown_mock()

  local passed = 0
  local failed = 0
  print("\n=== Backwards Compatibility Shim Tests ===\n")
  for _, r in ipairs(results) do
    if r.ok then
      print("✓ " .. r.msg)
      passed = passed + 1
    else
      print("✗ " .. r.msg)
      failed = failed + 1
    end
  end
  print("\n" .. passed .. " passed, " .. failed .. " failed")

  if failed > 0 then
    vim.cmd("cquit 1")
  end
end

test_shims()
