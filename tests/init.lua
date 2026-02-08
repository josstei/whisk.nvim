local base_path = debug.getinfo(1, "S").source:match("@(.*/)")
package.path = base_path .. "../lua/?.lua;" ..
               base_path .. "../lua/?/init.lua;" ..
               base_path .. "?.lua;" ..
               base_path .. "?/init.lua;" ..
               package.path

local runner = require('tests.runner')
local mocks = require('tests.mocks')

mocks.setup()

require('tests.unit.config.defaults_spec')
require('tests.unit.config.validation_spec')
require('tests.unit.config.management_spec')
require('tests.unit.config_spec')

require('tests.unit.context.builder_spec')
require('tests.unit.context.Context_spec')

require('tests.unit.engine.pool_spec')
require('tests.unit.engine.loop_spec')
require('tests.unit.engine.lifecycle_spec')
require('tests.unit.engine.orchestrator_spec')

require('tests.unit.registry.motions_spec')
require('tests.unit.registry.traits_spec')
require('tests.unit.registry.keymaps_spec')
require('tests.unit.registry.builtin_spec')

require('tests.unit.calculators.basic_spec')
require('tests.unit.calculators.line_spec')
require('tests.unit.calculators.scroll_spec')
require('tests.unit.calculators.word_spec')
require('tests.unit.calculators.find_spec')
require('tests.unit.calculators.text_object_spec')
require('tests.unit.calculators.search_spec')

require('tests.unit.utils.visual_spec')

require('tests.unit.trail.highlights_spec')

require('tests.unit.performance_spec')

require('tests.unit.shims.cursor_keymaps_spec')
require('tests.unit.shims.scroll_keymaps_spec')

require('tests.unit.init_spec')

require('tests.integration.context_lifecycle_spec')

local success = runner.run()

mocks.teardown()

os.exit(success and 0 or 1)
