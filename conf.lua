function lovr.conf(t)

    -- Set the project identity
    t.identity = 'default'
  
    -- Graphics
    t.graphics.debug = false
  
    -- Headset settings
    t.headset.drivers = { 'openxr', 'oculus', 'vrapi', 'openvr', 'webxr', 'desktop' }
    t.headset.msaa = 4
    t.headset.offset = 1.7
  
    -- Math settings
    t.math.globals = true
  
    -- Enable or disable different modules
    t.modules.audio = true
    t.modules.data = true
    t.modules.event = true
    t.modules.graphics = true
    t.modules.headset = true
    t.modules.math = true
    t.modules.physics = true
    t.modules.thread = true
    t.modules.timer = true
  
    -- Configure the desktop window
    t.window.width = 1080
    t.window.height = 600
    t.window.fullscreen = false
    t.window.msaa = 4
    t.window.vsync = 1
    t.window.title = 'InAdvent'
    t.window.icon = nil
  end