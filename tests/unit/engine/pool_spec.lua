local runner = require('tests.runner')
local assert = require('tests.helpers.assertions')
local mocks = require('tests.mocks')

local describe, it, before_each = runner.describe, runner.it, runner.before_each

describe('engine/pool', function()
  local pool

  before_each(function()
    mocks.setup()
    mocks.clear_package_cache()
    pool = require('luxmotion.engine.pool')
    pool.clear()
  end)

  it('exports all required functions', function()
    assert.is_type(pool.acquire, 'function')
    assert.is_type(pool.release, 'function')
    assert.is_type(pool.get_stats, 'function')
    assert.is_type(pool.clear, 'function')
  end)

  it('acquire returns a table', function()
    local obj = pool.acquire()
    assert.is_not_nil(obj)
    assert.is_type(obj, 'table')
  end)

  it('acquire returns object with expected fields', function()
    local obj = pool.acquire()
    assert.is_not_nil(obj.start_time)
    assert.is_not_nil(obj.duration_ns)
    assert.equals(obj.start_time, 0)
    assert.equals(obj.duration_ns, 0)
  end)

  it('acquire returns fresh object when pool is empty', function()
    pool.clear()
    local stats = pool.get_stats()
    assert.equals(stats.pool_size, 0)

    local obj = pool.acquire()
    assert.is_not_nil(obj)
  end)

  it('release adds object back to pool', function()
    pool.clear()
    local obj = pool.acquire()
    pool.release(obj)

    local stats = pool.get_stats()
    assert.equals(stats.pool_size, 1)
  end)

  it('acquire reuses released object', function()
    pool.clear()
    local obj1 = pool.acquire()
    obj1.test_marker = 'unique'
    pool.release(obj1)

    local obj2 = pool.acquire()
    assert.equals(obj2.start_time, 0)
    assert.equals(obj2.duration_ns, 0)
  end)

  it('release resets object fields', function()
    local obj = pool.acquire()
    obj.start_time = 12345
    obj.duration_ns = 99999
    obj.context = { foo = 'bar' }
    obj.result = { baz = 'qux' }
    obj.traits = { 'cursor' }
    obj.on_complete = function() end

    pool.release(obj)
    local obj2 = pool.acquire()

    assert.equals(obj2.start_time, 0)
    assert.equals(obj2.duration_ns, 0)
    assert.is_nil(obj2.context)
    assert.is_nil(obj2.result)
    assert.is_nil(obj2.traits)
    assert.is_nil(obj2.on_complete)
  end)

  it('pool respects max size', function()
    pool.clear()
    local objects = {}
    for i = 1, 15 do
      table.insert(objects, pool.acquire())
    end

    for _, obj in ipairs(objects) do
      pool.release(obj)
    end

    local stats = pool.get_stats()
    assert.less_or_equal(stats.pool_size, stats.max_pool_size)
    assert.equals(stats.max_pool_size, 10)
  end)

  it('get_stats returns pool_size and max_pool_size', function()
    pool.clear()
    local stats = pool.get_stats()
    assert.is_type(stats.pool_size, 'number')
    assert.is_type(stats.max_pool_size, 'number')
    assert.equals(stats.pool_size, 0)
    assert.equals(stats.max_pool_size, 10)
  end)

  it('clear empties the pool', function()
    local obj = pool.acquire()
    pool.release(obj)
    pool.release(pool.acquire())
    pool.release(pool.acquire())

    pool.clear()
    local stats = pool.get_stats()
    assert.equals(stats.pool_size, 0)
  end)

  it('multiple acquire calls return different objects', function()
    pool.clear()
    local obj1 = pool.acquire()
    local obj2 = pool.acquire()
    local obj3 = pool.acquire()

    obj1.marker = 1
    obj2.marker = 2
    obj3.marker = 3

    assert.equals(obj1.marker, 1)
    assert.equals(obj2.marker, 2)
    assert.equals(obj3.marker, 3)
  end)

  it('release requires valid animation object', function()
    assert.throws(function()
      pool.release(nil)
    end)
  end)

  it('pool size increases with releases', function()
    pool.clear()

    pool.release(pool.acquire())
    assert.equals(pool.get_stats().pool_size, 1)

    pool.release(pool.acquire())
    assert.equals(pool.get_stats().pool_size, 1)

    local obj1 = pool.acquire()
    local obj2 = pool.acquire()
    pool.release(obj1)
    pool.release(obj2)
    assert.equals(pool.get_stats().pool_size, 2)
  end)

  it('pool size decreases with acquires', function()
    pool.clear()
    local obj1 = pool.acquire()
    local obj2 = pool.acquire()
    pool.release(obj1)
    pool.release(obj2)
    assert.equals(pool.get_stats().pool_size, 2)

    pool.acquire()
    assert.equals(pool.get_stats().pool_size, 1)

    pool.acquire()
    assert.equals(pool.get_stats().pool_size, 0)
  end)
end)
