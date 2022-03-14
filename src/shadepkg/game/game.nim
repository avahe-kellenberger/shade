import
  std/monotimes,
  os,
  math,
  sdl2_nim/sdl,
  sdl2_nim/sdl_gpu

import
  scene,
  gamestate,
  ../input/inputhandler,
  ../audio/audioplayer,
  ../render/color,
  ../math/rectangle

const
  oneBillion = 1000000000
  oneMillion = 1000000
  DEFAULT_REFRESH_RATE = 60

type 
  Engine* = ref object of RootObj
    screen*: Target
    scene: Scene
    # The color to fill the screen with to clear it every frame.
    clearColor*: Color
    shouldExit: bool

    refreshRate: int
    deltaTime: float
    sleepNanos: int

proc update*(this: Engine, deltaTime: float)
proc render*(this: Engine, screen: Target)
proc stop*(this: Engine)
proc teardown(this: Engine)

# Singleton
var Game*: Engine

proc initEngineSingleton*(
  title: string,
  gameWidth, gameHeight: int,
  scene: Scene = newScene(),
  windowFlags: int = WINDOW_FULLSCREEN_DESKTOP or WINDOW_ALLOW_HIGHDPI,
  clearColor: Color = BLACK
) =
  if Game != nil:
    raise newException(Exception, "Game has already been initialized!")

  when defined(debug):
    setDebugLevel(DEBUG_LEVEL_MAX)

  let target = init(uint16 gameWidth, uint16 gameHeight, uint32 windowFlags)
  if target == nil:
    raise newException(Exception, "Failed to init SDL!")

  Game = Engine()
  Game.screen = target
  Game.scene = scene
  Game.clearColor = clearColor

  # TODO: Determine display's refresh rate.
  Game.refreshRate = DEFAULT_REFRESH_RATE

  Game.deltaTime = 1.0 / Game.refreshRate.float
  Game.sleepNanos = round(oneBillion / Game.refreshRate).int

  gamestate.updateResolution(gameWidth.float, gameHeight.float)

  initInputHandlerSingleton()
  initAudioPlayerSingleton()

  gamestate.onResolutionChanged:
    Game.screen.setVirtualResolution(uint16 gamestate.resolution.x, uint16 gamestate.resolution.y)

    if Game.scene.camera != nil:
      Game.screen.setViewport(
        (
          cfloat 0,
          cfloat 0,
          cfloat Game.scene.camera.viewport.width,
          cfloat Game.scene.camera.viewport.height
        )
      )

  # Input event handlers

  proc handleWindowEvents(e: Event): bool =
    if e.window.event == WINDOWEVENT_RESIZED:
      gamestate.updateResolution(float e.window.data1, float e.window.data2)

  Input.addEventListener(WINDOWEVENT, handleWindowEvents)
  Input.addEventListener(QUIT,
    proc(e: Event): bool =
      Game.shouldExit = true
  )

template time*(this: Engine): float = this.time
template screen*(this: Engine): Target = this.screen
template scene*(this: Engine): Scene = this.scene
template `scene=`*(this: Engine, scene: Scene) = this.scene = scene

proc handleEvents(this: Engine) =
  ## Passes all pending events to the inputhandler singleton.
  ## Returns if the application should exit.
  var event: Event
  while pollEvent(event.addr) != 0:
    Input.processEvent(event)
    
proc loop(this: Engine) =
  var
    startTimeNanos = getMonoTime().ticks
    elapsedNanos: int64 = 0

  while not this.shouldExit:
    this.handleEvents()
    this.update(this.deltaTime)
    this.render(this.screen)

    Input.update(this.deltaTime)

    # Calculate sleep time
    elapsedNanos = getMonoTime().ticks - startTimeNanos
    let sleepMilis =
      round(max(0, this.sleepNanos - elapsedNanos).float64 / oneMillion.float64).int
    sleep(sleepMilis)

    let time = getMonoTime().ticks
    elapsedNanos = time - startTimeNanos
    startTimeNanos = time

  this.teardown()

proc start*(this: Engine) =
  # TODO: Make this async so it's non-blocking
  this.loop()

proc stop*(this: Engine) =
  this.shouldExit = true

proc teardown(this: Engine) =
  # TODO: Should tear down the running scene here
  sdl_gpu.quit()
  logInfo(LogCategoryApplication, "SDL shutdown completed")

proc update*(this: Engine, deltaTime: float) =
  gamestate.time += deltaTime
  if this.scene != nil:
    this.scene.update(deltaTime)

proc render*(this: Engine, screen: Target) =
  if this.scene == nil:
    return
  clearColor(this.screen, this.clearColor)
  this.scene.render(screen)
  flip(this.screen)

