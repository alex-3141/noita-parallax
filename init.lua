Parallax = dofile( "mods/noita-parallax/files/parallax.lua" )

function OnModInit()

  -- Set maximum number of layers
  -- More layers results in a longer compile time, and a small performance hit.
  -- Shader will fail to compile if there are ~140 layers
  Parallax.MAX_LAYERS = 10

  -- Re-creation of default background. Omitted fields will use default values.
  -- See bottom of parallax.lua for details on fields.
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

  -- Need to supply sky textures file
  Parallax.sky.path = "mods/noita-parallax/files/tex/sky_colors_default.png"

  Parallax.pushTextures() -- Binds textures. Only able to be called during init.
  Parallax.init() -- Compile shader. Can be called at any time, but may stutter the game for a moment.
end



-- An example of how to modify parallax layers in real time
Cloundx1 = 0
Cloundx2 = 0
local function moveClouds()
  local world_state_entity = GameGetWorldStateEntity()
  local world_state = EntityGetFirstComponent( world_state_entity, "WorldStateComponent" )
  local wind_speed = ComponentGetValue2( world_state, "wind_speed" )
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
