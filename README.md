# Noita Parallax
A tool for creating parallax backgrounds in Noita.

See ```init.lua``` for detailed examples.

## Install
Place ```parallax.lua``` and ```inject.lua``` anywhere within your mod's files.

**IMPORTANT:** Keep these files together in the same folder as they reference eachother.

## Setup
### In your mod's ```init.lua```:

```lua
-- Import Parallax table, call whatever you want
Parallax = dofile_once( "mods/mod-name-here/files/parallax.lua" )

function OnModInit()
  -- How many layers you may use at once
  Parallax.registerLayers(10)

  -- Register all textures you may use
  Parallax.registerTextures({
    "mods/mod-name-here/files/clouds_layer_1.png",
    "mods/mod-name-here/files/clouds_layer_1.png",
    "mods/mod-name-here/files/mountains_layer_1.png",
    "mods/mod-name-here/files/mountains_layer_2.png",
    "mods/mod-name-here/files/sky_colors.png",
  })
end

function OnModPostInit()
-- Call during OnModPostInit()
  Parallax.postInit()
end

function OnWorldPostUpdate()
  -- Call once per frame
  Parallax.update()
end
```

## Apply a bank

Background are managed in banks. Each bank contains information about the layers, colors, and state.
```lua
mountain = Parallax.getBankTemplate()
mountain.id = "mountain"
mountain.layers = {
  {
    id = "cloud1", path = "mods/mod-name-here/files/parallax_clounds_01.png",
    depth = 0.94, sky_blend = 1.0, sky_index = Parallax.SKY_DEFAULT.CLOUDS_1,
    speed_x = 0.02
  },
  {
    id = "mountain02", path = "mods/mod-name-here/files/parallax_mountains_02.png",
    depth = 0.92, sky_blend = 1.0, sky_index = Parallax.SKY_DEFAULT.MOUNTAIN_2,
  },
  {
    id = "cloud2", path = "mods/mod-name-here/files/parallax_clounds_02.png",
    depth = 0.90, sky_blend = 1.0, sky_index = Parallax.SKY_DEFAULT.CLOUDS_2,
    speed_x = 0.04
  },
  {
    id = "mountainLayer2", path = "mods/mod-name-here/files/parallax_mountains_layer_02.png",
    depth = 0.88, sky_blend = 1.0, sky_index = Parallax.SKY_DEFAULT.MOUNTAIN_1_BACK
  },
  {
    id = "mountainLayer1", path = "mods/mod-name-here/files/parallax_mountains_layer_01.png",
    depth = 0.88, sky_blend = 1.0, sky_index = Parallax.SKY_DEFAULT.MOUNTAIN_1_HIGHLIGHT
  },
}
mountain.sky.path = "mods/noita-parallax/files/tex/sky_colors_default.png"
Parallax.push(mountain, 30)
```

And thats it. Once the bank has been pushed, it will remain active until another bank is pushed, or the parallax is cleared.

**Important:** A sky texture path needs to be set. Copy the texture from ```files/tex/sky_colors_default.png``` to get started.

Banks are very customizable, see below for full documentation.

## Bank configuration

The full bank configuration is as follows. Default values will be used for unspecified values.
```lua
bank = Parallax.getBankTemplate()

bank.id = "bank_id",   -- Bank Identifier

bank.layers = {{       -- Table of layers in the bank. Numerical index
  tex_w = 0,           -- automaticaly set to texture width
  tex_h = 0,           -- automatically set to texture height
  scale = 1,           -- Layer scale
  alpha = 1,           -- Layer transparrency
  offset_x = 0,        -- Layer horizontal offset
  offset_y = 0,        -- Layer vertical offset
  depth = 0,           -- Parallax depth. 0 = infinite distance, 1 = same as foreground
  sky_blend = 0,       -- How much the sky color should blend with the layer. 0 = no blending, 1 = full blending
  speed_x = 0,         -- Automatic horizontal movement
  speed_y = 0,         -- Automatic vertical movement
  min_y = -math.huge,  -- Keep layers above this y position (normalized screen position)
  max_y = math.huge,   -- Keep layers below this y position (normalized screen position)
  sky_index = 1,       -- Index of the sky color to use
  sky_source = 1,      -- Where to get the sky color from. 0 = texture, 1 = dynamic. Can be a mix (eg. 0.5)
                       -- Dynamic colors can be set via Parallax.sky.dynamic_colors
  alpha_index = 1,     -- Index of the alpha color to use. Pulls from the same list as sky_index
  alpha_source = 1,    -- Where to get the alpha color from. 0 = texture, 1 = dynamic. Can be a mix (eg. 0.5)
  alpha_blend = 0      -- How much the alpha color should blend with the layer. 0 = no blending, 1 = full blending. 
                       -- Dynamic colors can be set via Parallax.sky.dynamic_colors
}},

bank.sky = {                      -- Information about the sky colors
  w = 0,                          -- Automatically set to sky texture width
  h = 0,                          -- Automatically set to sky texture height
  path = "spy.png",               -- Path to the sky texture. Should always be set to something
  dynamic_colors = {},            -- Color sequence for dynamic sky colors. 
  gradient_pos = {0.6, 0.4},      -- Start and end points for the sky gradient (vertical normalized screen position)
  gradient_dynamic_enabled = 0,   -- Use dynamic colors for the sky gradient. 0 = disabled, 1 = enabled
  gradient_texture = {1, 2},      -- Color indexes to use for the gradient texture
  gradient_dynamic_colors = {},   -- Color sequence for dynamic gradient colors.
},
bank.state = {},                  -- Table for storing state information. Used by bank.update
bank.update = function(state),    -- Function called when Parallax.update() is called. See init.lua for example
bank:getLayerById(id),            -- Helper function to lookup a layer by ID. See init.lua for example
```

## Sky Colors

All layers are blended with a set of sky colors which matches the time of day. The ```sky_blend``` layer property determines how much to blend, with 0 resulting in no blending and 1 resulting in full color replacement.

Sky colors are pulled from a texture, or from the dynamic colors (see below). This is controlled by the ```sky_source``` property.

The default sky colors from the game have been placed in ```files/tex/sky_colors_default.png``` and this will work well for most backgrounds. 

The color indexes for ```sky_colors_default.png``` are defined in ```Parallax.SKY_DEFAULT```:

```lua
SKY_DEFAULT = {
  BACKGROUND_1   = 1,    BACKGROUND_2         = 2,    CLOUDS_1         = 3,
  CLOUDS_2       = 4,    MOUNTAIN_1_HIGHLIGHT = 5,    MOUNTAIN_1_BACK  = 6,
  MOUNTAIN_2     = 7,    STORM_CLOUDS_1       = 8     STORM_CLOUDS_2   = 9,
  STORM_CLOUDS_3 = 10    STARS_ALPHA          = 11,
},
```

Each 3-pixel tall row in the sky texture is the color sweep for 1 in-game day. The row a layer will use is set by the ```sky_index``` property, which is 1-indexed. Keep this in mind if you make a custom sky texture.

### Alpha

Sky colors can also be used as alpha masks with the ```alpha_index```, ```alpha_source``` and ```alpha_blend``` properties. For example, the last color row in ```sky_colors_default.png``` is used to control the alpha of the stars in the game.

See ```init.lua``` for another example of using alpha.

## Dynamic Colors

The sky colors and sky gradient colors can be defined with a color sequence, allowing for fine tuned control.

The colors are defined as:
```lua
dynamic_colors = {
  {
    c = {255, 238, 178},         -- RGB values of the color
    d = 0.5,                     -- Duration of the color. 1 = full day length
    i = Parallax.INTERP.LINEAR   -- How the color should be interpolated into the next color in the sequence
                                 -- Can be LINEAR, SMOOTHSTEP or NONE
  },
  {
    -- next color in the sequence here
  }
}
```

The dynamic color will go through the sequence depending on the time of day, and will loop automatically.

Having the duration of all colors sum to 1.0 will sync it with the day/night cycle, or it can be shorter/longer.

Here is an example of a dynamic color that cycles from red => green => blue => white smoothly throughout the day.

```lua
dynamic_colors = {
  { c = {255, 0,   0},   d = 0.25, i = Parallax.INTERP.LINEAR },
  { c = {0,   255, 0},   d = 0.25, i = Parallax.INTERP.LINEAR },
  { c = {0,   0,   255}, d = 0.25, i = Parallax.INTERP.LINEAR },
  { c = {255, 255, 255}, d = 0.25, i = Parallax.INTERP.LINEAR }
}
```

See ```init.lua``` for an advanced example of using a dynamic color to blink antenna lights.