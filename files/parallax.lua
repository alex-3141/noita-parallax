Inject = dofile_once("mods/noita-parallax/files/inject.lua")

SetContent = ModTextFileSetContent
GetContent = ModTextFileGetContent

local function getLayerById(id)
  for i, layer in ipairs(Parallax.layers) do
    if layer.id == id then
      return layer
    end
  end
  return nil
end

local function lerp(a, b, t)
  return a + (b - a) * t
end

-- LERP
local function lerpColor(a, b, t)
  local r = lerp(a[1], b[1], t)
  local g = lerp(a[2], b[2], t)
  local b = lerp(a[3], b[3], t)
  return {r/255, g/255, b/255}
end

-- Smoothstep
local function smoothstep(a, b, t)
  t = t * t * (3.0 - 2.0 * t)
  return lerpColor(a, b, t)
end

local function getDynamicColor(colors, time)
  local cyclelength = 0
  for i, color in ipairs(colors) do
    cyclelength = cyclelength + color.d
  end

  local t = time % cyclelength
  local i = 1
  while t > colors[i].d do
    t = t - colors[i].d
    i = i + 1
  end

  if colors[i].i == Parallax.INTERP.SMOOTHSTEP then
    return smoothstep(colors[i].c, colors[i % #colors + 1].c, t / colors[i].d)
  elseif colors[i].i == Parallax.INTERP.NONE then
    return colors[i].c
  else
    return lerpColor(colors[i].c, colors[i % #colors + 1].c, t / colors[i].d)
  end
end

local function getSkyGradientColors(time)
  local sky = Parallax.sky
  local colors1 = sky.gradient_dynamic_colors[1]
  local colors2 = sky.gradient_dynamic_colors[2]

  local color1 = getDynamicColor(colors1, time)
  local color2 = getDynamicColor(colors2, time)

  return color1, color2
end

local function getSkyColor(index, time)
  -- Allow for negative indexes to count from the end
  if index < 0 then
    index = #Parallax.sky.dynamic_colors + index + 1
  end
  if index > #Parallax.sky.dynamic_colors then
    index = #Parallax.sky.dynamic_colors
  end
  if index < 1 then return {0, 0, 0} end
  local colors = Parallax.sky.dynamic_colors[index]
  return getDynamicColor(colors, time)
end

local function pushUniforms(time)
  local error_msg = ""
  local setUniform = GameSetPostFxParameter

  setUniform( "parallax_world_state", time % 1, Parallax.enabled, 0.0, 0.0)
  
  for i, layer in ipairs(Parallax.layers) do

    -- Use a metatable to supply default values for missing keys
    local mt = {
      __index = function(t, key)
        return Parallax.layer_defaults[key]
      end
    }

    setmetatable(layer, mt)

    local layer_error = false

    -- Unintended indexes should be made highly visible
    local sky_index = layer.sky_index
    local alpha_index = layer.alpha_index

    if layer.sky_source == Parallax.SKY_SOURCE.DYNAMIC and math.abs(sky_index) > #Parallax.sky.dynamic_colors then
      error_msg = error_msg .. "Error in layer " ..  tostring(i) .. ": Dynamic sky index " .. tostring(sky_index) .. " is out of bounds. Max index is " .. tostring(#Parallax.sky.dynamic_colors) .. "\n"
      layer_error = true
    end

    if layer.sky_source == Parallax.SKY_SOURCE.TEXTURE and math.abs(sky_index) > Parallax.sky.h / 3 then
      error_msg = error_msg .. "Error in layer " ..  tostring(i) .. ": Texture sky index " .. tostring(sky_index) .. " is out of bounds. Max index is " .. tostring(Parallax.sky.h / 3) .. " (image height " .. tostring(Parallax.sky.h) .. "px / 3)\n"
      layer_error = true
    end

    if layer.alpha_source == Parallax.SKY_SOURCE.DYNAMIC and math.abs(alpha_index) > #Parallax.sky.dynamic_colors then
      error_msg = error_msg .. "Error in layer " ..  tostring(i) .. ": Dynamic alpha index " .. tostring(alpha_index) .. " is out of bounds. Max index is " .. tostring(#Parallax.sky.dynamic_colors) .. "\n"
      layer_error = true
    end

    if layer.alpha_source == Parallax.SKY_SOURCE.TEXTURE and math.abs(alpha_index) > Parallax.sky.h / 3 then
      error_msg = error_msg .. "Error in layer " ..  tostring(i) .. ": Texture alpha index " .. tostring(alpha_index) .. " is out of bounds. Max index is " .. tostring(Parallax.sky.h / 3) .. " (image height " .. tostring(Parallax.sky.h) .. "px / 3)\n"
      layer_error = true
    end


    local color = getSkyColor(sky_index, time)
    setUniform( "parallax_sky_color_"..i, color[1], color[2], color[3], 1.0)

    local alpha_color = getSkyColor(alpha_index, time)
    setUniform( "parallax_alpha_color_"..i, alpha_color[1], alpha_color[2], alpha_color[3], 1.0)

    local gradient_1, gradient_2 = getSkyGradientColors(time)
    
    setUniform( "parallax_sky_gradient_color_1", gradient_1[1], gradient_1[2], gradient_1[3], 0.0)
    setUniform( "parallax_sky_gradient_color_2", gradient_2[1], gradient_2[2], gradient_2[3], 0.0)

    setUniform( "parallax_sky_gradient_index", Parallax.sky.gradient_texture[1], Parallax.sky.gradient_texture[2], 0.0, 0.0)
    setUniform( "parallax_sky_gradient", Parallax.sky.gradient_dynamic_enabled, 0.0, Parallax.sky.gradient_pos[1], Parallax.sky.gradient_pos[2])

    local error_color = 0
    if layer_error and Parallax.HIGHLIGHT_ERRORS then error_color = math.floor((GameGetFrameNum() % 60) / 30) end

    setUniform( "parallax_"..i.."_1", layer.scale, layer.alpha, layer.offset_x, layer.offset_y )
    setUniform( "parallax_"..i.."_2", layer.depth, layer.sky_blend, layer.speed_x, layer.speed_y )
    setUniform( "parallax_"..i.."_3", layer.sky_index, layer.sky_source, layer.min_y, layer.max_y)
    setUniform( "parallax_"..i.."_4", layer.alpha_blend, layer.alpha_index, layer.alpha_source, error_color) -- 4th param is for error state

  end

  return error_msg
end

local injectShaderCode = function()
  local maxLayers = Parallax.MAX_LAYERS

  local post_final = GetContent("data/shaders/post_final.frag")

  -- Update GLSL version
  post_final = post_final:gsub(Inject.version.pattern, Inject.version.replacement, 1)

  -- Patch
  post_final = post_final:gsub(Inject.patch.pattern, Inject.patch.replacement)

  -- Uniforms
  post_final = post_final:gsub(Inject.static_uniforms.pattern, Inject.static_uniforms.replacement .. "\n%1", 1)

  post_final = post_final:gsub(Inject.dynamic_uniforms.pattern, function(capture)
    local u = ""
    for i = 1, maxLayers do
      u = u .. string.format(Inject.dynamic_uniforms.replacement, i, i, i, i, i, i, i)
    end
    u = u .. "\n" .. capture
    return u
  end)

  -- Functions
  post_final = post_final:gsub(Inject.functions.pattern, Inject.functions.replacement .. "\n%1", 1)

  -- User defined shadercode
  -- TBD

  -- Replace background
  post_final = post_final:gsub(Inject.replace_bg.pattern, Inject.replace_bg.replacement, 1)

  -- Inject layers
  post_final = post_final:gsub(Inject.layers.pattern, function()
    local l = ""
    for i = 1, maxLayers do
      l = l .. string.format(Inject.layers.replacement, i, i, i, i, i, i, i, i, i, i)
    end
    l = l .. "\n"
    return l
  end)

  -- Apply post_final
  SetContent("data/shaders/post_final.frag", post_final)
end

local pushTextures = function()
  local makeEditable = ModImageMakeEditable
  local setTexture = GameSetPostFxTextureParameter
  for i, layer in ipairs(Parallax.layers) do
    -- Workaround: Call ModImageMakeEditable() on all images to ensure the same pixel format is used
    local id, width, height = makeEditable( layer.path, 0, 0 )

    if id == 0 or id == nil then
      error("Failed to load image: " .. layer.path)
    end

    setTexture( "tex_parallax_"..i, layer.path, Parallax.FILTER.BILINEAR, Parallax.WRAP.CLAMP, false )

    print("[Parallax] Loaded texture: " .. layer.path .. " with id: " .. id .. " and size: " .. width .. "x" .. height)
  end

  local missing_sky = false
  -- Create a fallback sky texture if none is provided
  if Parallax.sky.path == nil then
    ModImageMakeEditable("data/parallax_fallback_sky.png", 1, 33)
    --ModImageSetPixel("data/parallax_fallback_sky.png", 0, 0, 0xFF00FFFF)
    Parallax.sky.path = "data/parallax_fallback_sky.png"
    missing_sky = true
  end

  local id, width, height = makeEditable( Parallax.sky.path, 0, 0 )
  if id == 0 or id == nil then
    error("Failed to load sky image: " .. Parallax.sky.path)
  end

  Parallax.sky.w = width
  Parallax.sky.h = height

  setTexture( "tex_parallax_sky", Parallax.sky.path, Parallax.FILTER.BILINEAR, Parallax.WRAP.REPEAT, false )
  
  if missing_sky then
    error("No sky texture provided. Using fallback texture. Please set Parallax.sky.path to a valid texture path.")
  end
end

local init = function()
  injectShaderCode()
end


local update = function()
  local world_state_entity = GameGetWorldStateEntity()
  local world_state = EntityGetFirstComponent( world_state_entity, "WorldStateComponent" )
  local time = ComponentGetValue2( world_state, "time" )
  local day = ComponentGetValue2( world_state, "day_count" )


  local error_msg = pushUniforms(time + day)
  if error_msg ~= "" then
    print(error_msg)
  end
end

Parallax = {
  enabled = 1.0,
  FILTER = {
    UNDEFINED = 0,
    BILINEAR = 1,
    NEAREST = 2
  },
  WRAP = {
    CLAMP = 0,
    CLAMP_TO_EDGE = 1,
    CLAMP_TO_BORDER = 2,
    REPEAT = 3,
    MIRRORED_REPEAT = 4,
  },
  MAX_LAYERS = 6,
  SKY_SOURCE = {
    TEXTURE = 0,
    DYNAMIC = 1,
  },
  INTERP = {
    LINEAR = 0,
    SMOOTHSTEP = 1,
    NONE = 2
  },
  -- These are the sky colors that the game uses by default, and serve as a good base to build off of or just use directly
  -- These indexes match up to sky_colors_deafult.png. It was derived from sky_colors.png in data/weather_gfx/
  SKY_DEFAULT = {
    BACKGROUND_1 = 1,
    BACKGROUND_2 = 2,
    CLOUDS_1 = 3,
    CLOUDS_2 = 4,
    MOUNTAIN_1_HIGHLIGHT = 5,
    MOUNTAIN_1_BACK = 6,
    MOUNTAIN_2 = 7,
    STORM_CLOUDS_1 = 8,
    STORM_CLOUDS_2 = 9,
    STORM_CLOUDS_3 = 10,
    STARS_ALPHA = 11,
  },
  HIGHLIGHT_ERRORS = true,
  layers = {},
  sky = {
    h = 0,
    w = 0,
    path = nil,
    -- Colors to use if dynamic sky colors is enabled
    -- Each index is a list of colors to cycle through. d is the duration of each color measured in noita day cycles.
    -- The last color will blend into the first color
    -- This is the default behaviour for getSkyGradientColors(), but you can go even more custom if you want
    -- This is the same list used by alpha colors if dynamic alpha colors are used, where the resultant luminocity is used
    dynamic_colors = {
      -- index 1
      {
        {c = {255,  0, 0}, d = 0.25},
        {c = {0, 255, 0 }, d = 0.25},
        {c = {0,  0,  255 }, d = 0.25},
        {c = {255, 255, 255}, d = 0.25}
      },
      -- index 2
      -- Durations dont have to sum to 1.0, and can be shorter or longer than an in-game day
      {
        {c = {255,  0, 0}, d = 0.001},
        {c = {0, 0, 255 }, d = 0.005},
      },
      -- etc ...
    },
    -- Gradient colors are for the sky gradient that paints under all
    -- 1.0 to use dynamic colors, 0.0 to use texture colors
    gradient_dynamic_enabled = 0.0,
    -- Position of gradient. 0.6 and 0.4 is the default used by the game
    gradient_pos = { 0.6, 0.4},
    -- texture indexes for gradient colors
    gradient_texture = {1, 2},
    -- Colors to use if dynamic sky gradient is enabled. Needs to be 2 colors
    gradient_dynamic_colors = {
      -- Color 1
      {
        {c = {255,  0, 0}, d = 0.25},
        {c = {0, 255, 0 }, d = 0.25},
        {c = {0,  0,  255 }, d = 0.25},
        {c = {255, 255, 255}, d = 0.25}
      },
      -- Color 2
      {
        {c = {0,  255, 0}, d = 0.25},
        {c = {0, 0, 255 }, d = 0.25},
        {c = {255,  0,  0 }, d = 0.25},
        {c = {0, 0, 0}, d = 0.25}
      },
    }
  },
  update = update,
  pushTextures = pushTextures,
  getLayerById = getLayerById,
  init = init,
}

Parallax.sky.gradient_texture = {Parallax.SKY_DEFAULT.BACKGROUND_1, Parallax.SKY_DEFAULT.BACKGROUND_2}

-- tex_w            | automaticaly set to texture width
-- tex_h            | automatically set to texture height
-- scale            | Layer scale
-- alpha            | Layer transparrency
-- offset_x         | Layer horizontal offset
-- offset_y         | Layer vertical offset
-- depth            | Parallax depth. 0 = infinite distance, 1 = same as foreground
-- sky_blend        | How much the sky color should blend with the layer. 0 = no blending, 1 = full blending
-- speed_x          | Automatic horizontal movement
-- speed_y          | Automatic vertical movement
-- min_y            | Keep layers above this y position (normalized screen position)
-- max_y            | Keep layers below this y position (normalized screen position)
-- sky_index        | Index of the sky color to use
-- sky_source       | Where to get the sky color from. 0 = texture, 1 = dynamic. Can be a mix, eg. 0.5. Dynamic colors can be set via Parallax.sky.dynamic_colors
-- alpha_index      | Index of the alpha color to use. Pulls from the same list as sky_index
-- alpha_source     | Where to get the alpha color from. 0 = texture, 1 = dynamic. Can be a mix, eg. 0.5
-- alpha_blend      | How much the alpha color should blend with the layer. 0 = no blending, 1 = full blending. Dynamic colors can be set via Parallax.sky.dynamic_colors
Parallax.layer_defaults = {
  tex_w = 0, tex_h = 0,
  scale = 1.0, alpha = 1, offset_x = 0, offset_y = 0, depth = 0, sky_blend = 0.0, speed_x = 0, speed_y = 0, min_y = -9999999, max_y = 9999999,
  sky_index = Parallax.SKY_DEFAULT.MOUNTAIN_2, sky_source = Parallax.SKY_SOURCE.TEXTURE, alpha_index = Parallax.SKY_DEFAULT.STARS_ALPHA, alpha_source = Parallax.SKY_SOURCE.TEXTURE,
  alpha_blend = 0.0
}

return Parallax