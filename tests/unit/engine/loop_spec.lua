local runner = require('tests.runner')
local assert = require('tests.helpers.assertions')
local mocks = require('tests.mocks')

local describe, it, before_each, after_each = runner.describe, runner.it, runner.before_each, runner.after_each

describe('engine/loop', function()
  local loop
  local traits
  local builder

  local function numbered(count)
    local lines = {}
    for i = 1, count do
      lines[i] = 'line ' .. i
    end
    return lines
  end

  local function commit_and_start(target_line, duration, trait_ids)
    local context = builder.build({})
    local result = { cursor = { line = target_line, col = 0 } }
    for _, trait_id in ipairs(trait_ids or { 'cursor' }) do
      traits.apply_frame(trait_id, context, result, 1.0)
    end
    loop.start({
      context = context,
      result = result,
      traits = trait_ids or { 'cursor' },
      duration = duration or 150,
      easing = 'linear',
    })
    return context
  end

  local function count_pairs(tbl)
    local count = 0
    for _ in pairs(tbl) do
      count = count + 1
    end
    return count
  end

  local function run_deferred_from(index)
    local calls = mocks.get_deferred_calls()
    local ran = 0
    while calls[index + ran] and ran < 50 do
      calls[index + ran].fn()
      ran = ran + 1
    end
    return ran
  end

  before_each(function()
    mocks.setup()
    mocks.clear_package_cache()
    mocks.set_buffer_content(numbered(20))
    mocks.set_cursor(1, 0)
    mocks.set_window_size(40, 120)
    mocks.set_topline(1)

    traits = require('whisk.registry.traits')
    builder = require('whisk.context.builder')
    loop = require('whisk.engine.loop')
    traits.clear()
    require('whisk.registry.builtin').register_traits()
  end)

  after_each(function()
    loop.complete_all()
  end)

  it('start keeps the committed position and schedules no frame before SafeState', function()
    commit_and_start(5)

    assert.equals(mocks.get_cursor()[1], 5)
    assert.equals(loop.get_active_count(), 1)
    assert.equals(#mocks.get_deferred_calls(), 0)
    assert.is_false(loop.is_running())
  end)

  it('SafeState rewinds to the start position and schedules one frame', function()
    commit_and_start(5)

    mocks.trigger_autocmd('SafeState')

    assert.equals(mocks.get_cursor()[1], 1)
    assert.equals(#mocks.get_deferred_calls(), 1)
    assert.is_true(loop.is_running())
  end)

  it('frames move through intermediate lines and end on the committed position', function()
    commit_and_start(20, 1000)
    mocks.trigger_autocmd('SafeState')

    mocks.execute_deferred(1)
    local first_frame_line = mocks.get_cursor()[1]
    assert.is_true(first_frame_line > 1 and first_frame_line < 20, 'first frame landed on line ' .. first_frame_line)

    run_deferred_from(2)

    assert.equals(mocks.get_cursor()[1], 20)
    assert.equals(loop.get_active_count(), 0)
    assert.is_false(loop.is_running())
  end)

  it('a key press finishes a running animation on the committed position', function()
    commit_and_start(20, 1000)
    mocks.set_topline(7)
    mocks.trigger_autocmd('SafeState')
    mocks.execute_deferred(1)
    assert.is_true(mocks.get_cursor()[1] < 20)

    mocks.press_key()

    assert.equals(mocks.get_cursor()[1], 20)
    assert.equals(mocks.get_fn_state().topline, 7)
    assert.equals(loop.get_active_count(), 0)
  end)

  it('a replay that finishes on its own lands on the view that was current at SafeState', function()
    commit_and_start(20, 1000)
    mocks.set_topline(9)
    mocks.trigger_autocmd('SafeState')
    assert.equals(mocks.get_fn_state().topline, 1)

    run_deferred_from(1)

    assert.equals(mocks.get_cursor()[1], 20)
    assert.equals(mocks.get_fn_state().topline, 9)
  end)

  it('hooks are released after a replay finishes on its own', function()
    commit_and_start(5, 150)
    mocks.trigger_autocmd('SafeState')

    run_deferred_from(1)

    assert.equals(loop.get_active_count(), 0)
    assert.equals(count_pairs(mocks.get_on_key_listeners()), 0)
    assert.equals(mocks.count_autocmds('SafeState'), 0)
  end)

  it('an animation queued while another replays waits for the next SafeState', function()
    commit_and_start(20, 1000)
    mocks.trigger_autocmd('SafeState')
    assert.equals(mocks.count_autocmds('SafeState'), 0)

    local second = builder.build({})
    loop.start({ context = second, result = { cursor = { line = 10, col = 0 } }, traits = { 'cursor' }, duration = 1000, easing = 'linear' })

    assert.equals(mocks.count_autocmds('SafeState'), 1)
  end)

  it('a frame tick left over from a finished replay leaves a new pending animation untouched', function()
    commit_and_start(20, 1000)
    mocks.trigger_autocmd('SafeState')
    loop.complete_all()
    commit_and_start(1, 1000)

    mocks.execute_deferred(1)

    assert.equals(loop.get_active_count(), 1)
    assert.equals(mocks.get_cursor()[1], 1)
    mocks.trigger_autocmd('SafeState')
    assert.equals(mocks.get_cursor()[1], 20)
  end)

  it('a key press before SafeState drops the pending animation without moving the cursor', function()
    commit_and_start(5)

    mocks.press_key()
    mocks.trigger_autocmd('SafeState')

    assert.equals(mocks.get_cursor()[1], 5)
    assert.equals(loop.get_active_count(), 0)
    assert.equals(#mocks.get_deferred_calls(), 0)
  end)

  it('SafeState drops an animation whose committed cursor was moved by someone else', function()
    commit_and_start(5)
    mocks.set_cursor(3, 0)

    mocks.trigger_autocmd('SafeState')

    assert.equals(mocks.get_cursor()[1], 3)
    assert.equals(loop.get_active_count(), 0)
    assert.equals(#mocks.get_deferred_calls(), 0)
  end)

  it('SafeState drops an animation whose buffer changed since the commit', function()
    commit_and_start(5)
    mocks.set_changedtick(2)

    mocks.trigger_autocmd('SafeState')

    assert.equals(mocks.get_cursor()[1], 5)
    assert.equals(loop.get_active_count(), 0)
  end)

  it('key and SafeState hooks exist only while animations are queued', function()
    assert.equals(count_pairs(mocks.get_on_key_listeners()), 0)
    assert.equals(mocks.count_autocmds('SafeState'), 0)

    commit_and_start(5)
    assert.equals(count_pairs(mocks.get_on_key_listeners()), 1)
    assert.equals(mocks.count_autocmds('SafeState'), 1)

    loop.complete_all()
    assert.equals(count_pairs(mocks.get_on_key_listeners()), 0)
    assert.equals(mocks.count_autocmds('SafeState'), 0)
  end)

  it('a failing trait during a key press is reported instead of raised', function()
    traits.register({
      id = 'broken',
      apply = function(_, _, progress)
        if progress == 1.0 then
          error('trait exploded')
        end
      end,
    })
    loop.start({ context = builder.build({}), result = { cursor = { line = 5, col = 0 } }, traits = { 'broken' }, duration = 1000, easing = 'linear' })
    mocks.trigger_autocmd('SafeState')

    assert.does_not_throw(function()
      mocks.press_key()
    end)

    assert.equals(#mocks.get_notifications(), 0, 'reporting inside on_key would show a message before the key runs')
    mocks.run_scheduled()
    local notifications = mocks.get_notifications()
    assert.equals(#notifications, 1)
    assert.matches(notifications[1].msg, 'trait exploded')
    assert.equals(loop.get_active_count(), 0)
  end)

  it('a trait failing on an intermediate frame lands the replay and reports the error', function()
    traits.register({
      id = 'fails_mid_frame',
      apply = function(_, _, progress)
        if progress > 0 and progress < 1 then
          error('frame exploded')
        end
      end,
    })
    commit_and_start(20, 1000, { 'cursor', 'fails_mid_frame' })
    mocks.trigger_autocmd('SafeState')
    assert.equals(mocks.get_cursor()[1], 1)

    assert.does_not_throw(function()
      mocks.execute_deferred(1)
    end)

    assert.equals(mocks.get_cursor()[1], 20)
    assert.equals(loop.get_active_count(), 0)
    assert.equals(count_pairs(mocks.get_on_key_listeners()), 0)
    mocks.run_scheduled()
    local notifications = mocks.get_notifications()
    assert.equals(#notifications, 1)
    assert.matches(notifications[1].msg, 'frame exploded')
  end)

  it('a frame already scheduled before complete_all is reused instead of starting a second chain', function()
    commit_and_start(20, 1000)
    mocks.trigger_autocmd('SafeState')
    assert.equals(#mocks.get_deferred_calls(), 1)

    loop.complete_all()
    mocks.set_cursor(20, 0)
    commit_and_start(1, 1000)
    mocks.trigger_autocmd('SafeState')

    assert.equals(#mocks.get_deferred_calls(), 1)
  end)

  it('complete_for_buffer finishes a running animation on the committed position', function()
    commit_and_start(20, 1000)
    mocks.trigger_autocmd('SafeState')
    mocks.execute_deferred(1)

    loop.complete_for_buffer(1)

    assert.equals(mocks.get_cursor()[1], 20)
    assert.equals(loop.get_active_count(), 0)
  end)

  it('complete_for_window leaves animations of other windows queued', function()
    commit_and_start(5)
    mocks.set_window_buffer(1001, 1)
    local other = require('whisk.context.Context').new(1, 1001)
    other.cursor = { line = 5, col = 0 }
    other.viewport = { topline = 1 }
    loop.start({ context = other, result = { cursor = { line = 9, col = 0 } }, traits = { 'cursor' }, duration = 150, easing = 'linear' })

    loop.complete_for_window(1000)

    assert.equals(loop.get_active_count(), 1)
  end)

  it('an animation whose window closed mid-flight is dropped without writing', function()
    commit_and_start(20, 1000)
    mocks.trigger_autocmd('SafeState')
    mocks.execute_deferred(1)
    local line_before = mocks.get_cursor()[1]

    mocks.close_window(1000)
    run_deferred_from(2)

    assert.equals(mocks.get_cursor()[1], line_before)
    assert.equals(loop.get_active_count(), 0)
  end)

  it('a zero-duration animation lands on the committed position on its first frame', function()
    commit_and_start(5, 0)
    mocks.trigger_autocmd('SafeState')

    mocks.execute_deferred(1)

    assert.equals(mocks.get_cursor()[1], 5)
    assert.equals(loop.get_active_count(), 0)
  end)

  it('get_easing returns linear for unknown and nil types', function()
    assert.equals(loop.get_easing('unknown')(0.5), 0.5)
    assert.equals(loop.get_easing(nil)(0.5), 0.5)
  end)

  it('easing curves have their documented shapes', function()
    assert.equals(loop.get_easing('linear')(0.5), 0.5)
    assert.equals(loop.get_easing('ease-in')(0.5), 0.25)
    assert.equals(loop.get_easing('ease-out')(0.5), 0.75)
    assert.equals(loop.get_easing('ease-in-out')(0.5), 0.5)
    assert.less_than(loop.get_easing('ease-in-out')(0.25), 0.25)
    assert.greater_than(loop.get_easing('ease-in-out')(0.75), 0.75)
    for _, name in ipairs({ 'linear', 'ease-in', 'ease-out', 'ease-in-out' }) do
      assert.equals(loop.get_easing(name)(0), 0, name .. ' must start at 0')
      assert.equals(loop.get_easing(name)(1), 1, name .. ' must end at 1')
    end
  end)
end)
