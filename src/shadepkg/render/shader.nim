import ../game/gamestate
import sdl2_nim/sdl_gpu
import ../math/vector2

var
  resolution: array[2, cfloat] = [ cfloat 0, 0 ]
  hasResolutionCallbackBeenSet = false

type Shader* = ref object of RootObj
  programID*: uint32
  vertShaderID: uint32
  fragShaderID: uint32
  shaderBlock: ShaderBlock

  # Uniforms
  timeUniformID: cint
  resolutionUniformID: cint

proc initShader*(shader: Shader, vertShaderPath, fragShaderPath: string) =
  shader.vertShaderID = loadShader(VERTEX_SHADER, vertShaderPath)
  if shader.vertShaderID == 0:
    raise newException(Exception, $getShaderMessage())

  shader.fragShaderID = loadShader(FRAGMENT_SHADER, fragShaderPath)
  if shader.fragShaderID == 0:
    raise newException(Exception, $getShaderMessage())

  shader.programID = linkShaders(shader.vertShaderID, shader.fragShaderID)
  if shader.programID == 0:
    raise newException(Exception, $getShaderMessage())

  shader.shaderBlock = loadShaderBlock(
    shader.programID,
    # TODO: These names seem hard-coded in sdl_gpu?
    "gpu_Vertex",
    "gpu_TexCoord",
    "gpu_Color",
    "gpu_ModelViewProjectionMatrix"
  )

  # TODO: Need users to be able to create/connect to their own uniforms,
  # and update them in code (via setUniformf etc).
  shader.timeUniformID = getUniformLocation(shader.programID, "time")
  shader.resolutionUniformID = getUniformLocation(shader.programID, "resolution")

  if not hasResolutionCallbackBeenSet:
    resolution[0] = cfloat gamestate.resolution.x
    resolution[1] = cfloat gamestate.resolution.y
    gamestate.onResolutionChanged:
      resolution[0] = cfloat gamestate.resolution.x
      resolution[1] = cfloat gamestate.resolution.y
    hasResolutionCallbackBeenSet = true

proc newShader*(vertShaderPath, fragShaderPath: string): Shader =
  result = Shader()
  initShader(result, vertShaderPath, fragShaderPath)

proc updateTimeUniform*(this: Shader, time: float) =
  setUniformf(this.timeUniformID, cfloat time)

proc updateResolutionUniform(this: Shader, screenResolution: Vector) =
  setUniformfv(this.resolutionUniformID, 2, 1, cast[ptr cfloat](resolution.addr))

proc activate*(this: Shader) =
  activateShaderProgram(this.programID, this.shaderBlock.addr)

proc deactivate*(this: Shader) =
  deactivateShaderProgram()

proc render*(this: Shader) =
  this.activate()
  this.updateTimeUniform(gamestate.runTime)
  this.updateResolutionUniform(gamestate.resolution)

template renderWithShader*(this: Shader, body: untyped) =
  this.render()
  body
  this.deactivate()

