local M = {}

local valid_easing_types = {
  ["linear"] = true,
  ["ease-in"] = true,
  ["ease-out"] = true,
  ["ease-in-out"] = true,
}

local function validate_trail(trail, category_name)
  if not trail then
    return
  end

  if trail.enabled ~= nil and type(trail.enabled) ~= "boolean" then
    error(category_name .. ".trail.enabled must be a boolean")
  end

  if trail.color ~= nil then
    if type(trail.color) ~= "string" then
      error(category_name .. ".trail.color must be a string ('auto' or a 6-digit hex like '#FF0000')")
    end
    if trail.color ~= "auto" and not trail.color:match("^#%x%x%x%x%x%x$") then
      error(category_name .. ".trail.color must be 'auto' or a 6-digit hex string (e.g. '#FF0000')")
    end
  end

  if trail.segments ~= nil then
    if type(trail.segments) ~= "number" or trail.segments ~= math.floor(trail.segments) or trail.segments < 2 or trail.segments > 12 then
      error(category_name .. ".trail.segments must be an integer between 2 and 12")
    end
  end
end

function M.validate_config(config)
  if not config then
    return true
  end
  
  if config.cursor then
    if config.cursor.duration and (type(config.cursor.duration) ~= "number" or config.cursor.duration < 0) then
      error("cursor.duration must be a positive number")
    end
    
    if config.cursor.easing and not valid_easing_types[config.cursor.easing] then
      error("cursor.easing must be one of: linear, ease-in, ease-out, ease-in-out")
    end
    
    if config.cursor.enabled and type(config.cursor.enabled) ~= "boolean" then
      error("cursor.enabled must be a boolean")
    end

    validate_trail(config.cursor.trail, "cursor")
  end
  
  if config.scroll then
    if config.scroll.duration and (type(config.scroll.duration) ~= "number" or config.scroll.duration < 0) then
      error("scroll.duration must be a positive number")
    end
    
    if config.scroll.easing and not valid_easing_types[config.scroll.easing] then
      error("scroll.easing must be one of: linear, ease-in, ease-out, ease-in-out")
    end
    
    if config.scroll.enabled and type(config.scroll.enabled) ~= "boolean" then
      error("scroll.enabled must be a boolean")
    end

    validate_trail(config.scroll.trail, "scroll")
  end
  
  if config.keymaps then
    if config.keymaps.cursor and type(config.keymaps.cursor) ~= "boolean" then
      error("keymaps.cursor must be a boolean")
    end
    
    if config.keymaps.scroll and type(config.keymaps.scroll) ~= "boolean" then
      error("keymaps.scroll must be a boolean")
    end
  end
  
  return true
end

return M