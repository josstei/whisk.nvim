local M = {}

local traits = {}

function M.register(definition)
  local id = definition.id
  traits[id] = {
    id = id,
    apply = definition.apply,
    on_start = definition.on_start,
    on_complete = definition.on_complete,
  }
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

function M.all()
  return traits
end

function M.clear()
  traits = {}
end

return M
