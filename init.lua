Parallax = dofile( "mods/noita-parallax/files/parallax.lua" )

local demo_desert
local demo_mountain

function OnModInit()

  -- Set maximum number of layers
  -- More layers results in a longer compile time, and a small performance hit.
  -- Shader will fail to compile if there are ~140 layers
  Parallax.MAX_LAYERS = 10

  -- Some demo backgrounds

  -- demo_mountain() -- Re-creation of default background
  demo_desert() -- Desert background with temple

  -- Need to supply sky textures file
  Parallax.sky.path = "mods/noita-parallax/files/tex/sky_colors_default.png"

  Parallax.pushTextures() -- Binds textures. Only able to be called during init.
  Parallax.init() -- Compile shader. Can be called at any time, but may stutter the game for a moment.
end




function demo_desert()
  Parallax.layers = {
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

  -- Construct antenna blinking pattern, specifying no interpolation between colors
  -- As long as the total duration of the pattern adds to 1.0, it will sync with the day/night cycle

  Parallax.sky.dynamic_colors[1] = {
    {c = {0,  0,  0 }, d = 0.5, i = Parallax.INTERP.NONE},
  }
  local blink = {
    {c = {255, 255, 255}, d = 0.0002, i = Parallax.INTERP.NONE},
    {c = {0,  0,  0 }, d = 0.0002, i = Parallax.INTERP.NONE},
    {c = {255, 255, 255}, d = 0.0002, i = Parallax.INTERP.NONE},
    {c = {0,  0,  0 }, d = 0.0002, i = Parallax.INTERP.NONE},
    {c = {0,  0,  0 }, d = 0.002, i = Parallax.INTERP.NONE},
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
      table.insert(Parallax.sky.dynamic_colors[1], v)
    end
  end

  local last = {c = {0,  0,  0 }, d = 0.3, i = Parallax.INTERP.NONE}
  last.d = last.d + fract * blink_duration

  table.insert(Parallax.sky.dynamic_colors[1], last)

end

function demo_mountain()
  Parallax.layers={
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
end


-- An example of how to modify parallax layers in real time
Cloundx1 = 0
Cloundx2 = 0
local function moveClouds()
  local world_state_entity = GameGetWorldStateEntity()
  local world_state = EntityGetFirstComponent( world_state_entity, "WorldStateComponent" )
  local wind_speed = ComponentGetValue2( world_state, "wind_speed" )
  local time = ComponentGetValue2( world_state, "time" )

  --GamePrint(tostring(time))


  if InputIsKeyDown(40) then
    ComponentSetValue2( world_state, "time_dt", 100 )
  else
    ComponentSetValue2( world_state, "time_dt", 1 )
  end



  local time_dt = ComponentGetValue2( world_state, "time_dt" )

  Cloundx1 = Cloundx1 - wind_speed * 0.000017 * time_dt
  Cloundx2 = Cloundx2 - wind_speed * 0.0000255 * time_dt

  local clound1 = Parallax.getLayerById("clound1")
  local clound2 = Parallax.getLayerById("clound2")

  -- Layers can also be accessed directly by index
  if clound1 ~= nil then clound1.offset_x = Cloundx1 end
  if clound2 ~= nil then clound2.offset_x = Cloundx2 end
end



function OnWorldPostUpdate()
  if Parallax ~= nil then

    -- Move clouds based on wind speed
    moveClouds()

    -- Needs to be called once per frame
    Parallax.update()
  end
end
