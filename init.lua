Parallax = dofile_once( "mods/noita-parallax/files/parallax.lua" ) -- Make sure parallax.lua and inject.lua are in the same folder

local demo_desert
local demo_mountain

function OnModInit()

  -- Register functions need to be called during OnModInit() or earlier

  -- The max number of layers you may need at once. Higher values will impact startup times
  Parallax.registerLayers(10)

  -- All textures need to be registered
  Parallax.registerTextures({
    "mods/noita-parallax/files/tex/demo/parallax_clounds_01.png",
    "mods/noita-parallax/files/tex/demo/parallax_clounds_02.png",
    "mods/noita-parallax/files/tex/demo/parallax_mountains_02.png",
    "mods/noita-parallax/files/tex/demo/parallax_mountains_layer_01.png",
    "mods/noita-parallax/files/tex/demo/parallax_mountains_layer_02.png",
    "mods/noita-parallax/files/tex/demo/dunes1.png",
    "mods/noita-parallax/files/tex/demo/dunes2.png",
    "mods/noita-parallax/files/tex/demo/temple.png",
    "mods/noita-parallax/files/tex/demo/temple-glow.png",
    "mods/noita-parallax/files/tex/demo/temple-antennas.png",
    "mods/noita-parallax/files/tex/sky_colors_default.png",
  })

end

function OnModPostInit()
  Parallax.postInit() -- Needs to be called during OnModPostInit()
end


function OnWorldPostUpdate()
  -- Some demo backgrounds to switch between.
  -- 9 => Desert demo
  -- 0 => Mountain demo
  -- Minus => Clear custom background
  -- Hold Enter to speed up time

  if InputIsKeyJustDown(38) then demo_desert() end -- Key_9
  if InputIsKeyJustDown(39) then demo_mountain() end -- Key_0
  if InputIsKeyJustDown(45) then Parallax.push(nil, 30) end -- Key_MINUS

  local world_state = EntityGetFirstComponent( GameGetWorldStateEntity(), "WorldStateComponent" )
  if InputIsKeyDown(40) then
    ComponentSetValue2( world_state, "time_dt", 100 )
  else
    ComponentSetValue2( world_state, "time_dt", 1 )
  end

  -- Parallax.update() needs to be called once per frame
  if Parallax ~= nil then Parallax.update()  end
end



local function moveClouds(bank)
  local world_state = EntityGetFirstComponent( GameGetWorldStateEntity(), "WorldStateComponent" )
  local wind_speed = ComponentGetValue2( world_state, "wind_speed" )
  local time_dt = ComponentGetValue2( world_state, "time_dt" )

  if bank.state.cloundx1 ~= nil then
    bank.state.cloundx1 = bank.state.cloundx1 - wind_speed * 0.000017 * time_dt
    local clound1 = bank:getLayerById("clound1")
    clound1.offset_x = bank.state.cloundx1
  end

  if bank.state.cloundx2 ~= nil then
    bank.state.cloundx2 = bank.state.cloundx2 - wind_speed * 0.0000255 * time_dt
    local clound2 = bank:getLayerById("clound2")
    clound2.offset_x = bank.state.cloundx2
  end
end


function demo_desert()
  local desert = Parallax.getBankTemplate()
  desert.id = "desert"
  desert.layers = {
    {id = "clound1", path = "mods/noita-parallax/files/tex/demo/parallax_clounds_01.png",
      offset_y = 0.3894, depth = 0.94, sky_blend = 1.0, sky_index = Parallax.SKY_DEFAULT.CLOUDS_1
    },
    {id = "dunes1", path = "mods/noita-parallax/files/tex/demo/dunes1.png",
    offset_y = 0.3894,  depth = 0.9, sky_blend = 0.85, sky_index = Parallax.SKY_DEFAULT.MOUNTAIN_2,
    },
    {id = "temple", path = "mods/noita-parallax/files/tex/demo/temple.png",
    offset_y = 0.3,  depth = 0.85, sky_blend = 0.7, sky_index = Parallax.SKY_DEFAULT.MOUNTAIN_2,
    },
    {id = "temple-glow", path = "mods/noita-parallax/files/tex/demo/temple-glow.png",
    offset_y = 0.3,  depth = 0.85, sky_blend = 0.0, alpha_blend = 1.0, alpha_index = Parallax.SKY_DEFAULT.STARS_ALPHA,
    },
    {id = "temple-antennas", path = "mods/noita-parallax/files/tex/demo/temple-antennas.png",
    offset_y = 0.3,  depth = 0.85, sky_blend = 0.0, alpha_blend = 1.0,
    alpha_source = Parallax.SKY_SOURCE.DYNAMIC, alpha_index = 1, alpha = 0.5,
    },
    {id = "dunes2", path = "mods/noita-parallax/files/tex/demo/dunes2.png",
    offset_y = 0.4894,  depth = 0.8, sky_blend = 0.7, sky_index = Parallax.SKY_DEFAULT.MOUNTAIN_2,
    },
  }

  -- State and update func for cloud positions
  desert.state = { cloundx1 = 0 }
  desert.update = moveClouds

  desert.sky.path = "mods/noita-parallax/files/tex/sky_colors_default.png"

  -- Construct antenna blinking pattern, specifying no interpolation between colors
  -- As long as the total duration of the pattern adds to 1.0, it will sync with the day/night cycle

  desert.sky.dynamic_colors[1] = {
    {c = {0,  0,  0 }, d = 0.5, i = Parallax.INTERP.NONE},
  }
  local blink = {
    {c = {255, 255, 255}, d = 0.00015, i = Parallax.INTERP.NONE},
    {c = {0,  0,  0 }, d = 0.00015, i = Parallax.INTERP.NONE},
    {c = {255, 255, 255}, d = 0.00015, i = Parallax.INTERP.NONE},
    {c = {0,  0,  0 }, d = 0.00015, i = Parallax.INTERP.NONE},
    {c = {0,  0,  0 }, d = 0.0022, i = Parallax.INTERP.NONE},
  }
  local blink_duration = 0
  for i, v in ipairs(blink) do
    blink_duration = blink_duration + v.d
  end
  -- Night lasts from time 0.5 to 0.7, and is 0.2 long

  local blinks_per_night = 0.2 / blink_duration
  local fract = blinks_per_night - math.floor(blinks_per_night)

  for i = 1, math.floor(blinks_per_night) do
    for j, v in ipairs(blink) do
      table.insert(desert.sky.dynamic_colors[1], v)
    end
  end

  local last = {c = {0,  0,  0 }, d = 0.3, i = Parallax.INTERP.NONE}
  last.d = last.d + fract * blink_duration

  table.insert(desert.sky.dynamic_colors[1], last)

  Parallax.push(desert, 30)

end

function demo_mountain()
  local mountain = Parallax.getBankTemplate()
  mountain.id = "mountain"
  mountain.layers={
    {id = "clound1", path = "mods/noita-parallax/files/tex/demo/parallax_clounds_01.png",
      offset_y = 0.3894, depth = 0.94, sky_blend = 1.0, sky_index = Parallax.SKY_DEFAULT.CLOUDS_1
    },
    {id = "mountain02", path = "mods/noita-parallax/files/tex/demo/parallax_mountains_02.png",
      offset_y = 0.3894,  depth = 0.9245, sky_blend = 1.0, sky_index = Parallax.SKY_DEFAULT.MOUNTAIN_2,
    },
    {id = "clound2", path = "mods/noita-parallax/files/tex/demo/parallax_clounds_02.png",
      offset_y = 0.3894, depth = 0.9, sky_blend = 1.0, sky_index = Parallax.SKY_DEFAULT.CLOUDS_2
    },
    {id = "mountainLayer2", path = "mods/noita-parallax/files/tex/demo/parallax_mountains_layer_02.png",
      offset_y = 0.37569,  depth = 0.87918, sky_blend = 1.0, sky_index = Parallax.SKY_DEFAULT.MOUNTAIN_1_BACK
    },
    {id = "mountainLayer1", path = "mods/noita-parallax/files/tex/demo/parallax_mountains_layer_01.png",
      offset_y = 0.37569,  depth = 0.87918, sky_blend = 1.0, sky_index = Parallax.SKY_DEFAULT.MOUNTAIN_1_HIGHLIGHT
    },
  }
  mountain.sky.path = "mods/noita-parallax/files/tex/sky_colors_default.png"
  mountain.state = { cloundx1 = 0, cloundx2 = 0 }
  mountain.update = moveClouds
  Parallax.push(mountain, 30)
end


