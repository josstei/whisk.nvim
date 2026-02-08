local M = {}

local traits = {}
local state = {}

function M.register(definition)
  local id = definition.id
  traits[id] = {
    id = id,
    apply = definition.apply,
    on_start = definition.on_start,
    on_complete = definition.on_complete,
  }
  state[id] = false
end

function M.is_animating(trait_id)
  return state[trait_id] == true
end

function M.set_animating(trait_id, value)
  state[trait_id] = value
end

function M.get(trait_id)
  return traits[trait_id]
end

function M.apply_frame(trait_id, context, result, progress)
  local trait = traits[trait_id]
  if trait and trait.apply then
    trait.apply(context, result, progress)
  end
end

function M.invoke_start(trait_id, context)
  local trait = traits[trait_id]
  if trait and trait.on_start then
    trait.on_start(context)
  end
end

function M.invoke_complete(trait_id, context)
  local trait = traits[trait_id]
  if trait and trait.on_complete then
    trait.on_complete(context)
  end
end

function M.all()
  return traits
end

function M.reset()
  for id, _ in pairs(state) do
    state[id] = false
  end
end

function M.clear()
  traits = {}
  state = {}
end

return M
