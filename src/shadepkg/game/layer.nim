import node
import ../render/[render, shader]

import safeseq

export node

type
  ZChangeListener = proc(oldZ, newZ: float): void
  ## Layer is a container of nodes that exist on a two-dimensional plane,
  ## perpendicular to the camera which views the game.
  ## They update and render any nodes they hold.
  ##
  ## Layers have a `z` axis coordinate.
  ## All nodes on the layer are assumed to share this same coordinate.
  ##
  Layer* = ref object of Node
    children: SafeSeq[Node]
    # Location of the layer on the `z` axis.
    z: float
    zChangeListeners: seq[ZChangeListener]

proc initLayer*(layer: Layer, z: float = 1.0) =
  layer.z = z
  layer.children = newSafeSeq[Node]()

proc newLayer*(z: float = 1.0): Layer =
  result = Layer()
  initLayer(result, z)

template z*(this: Layer): float =
  this.z

proc `z=`*(this: Layer, z: float) =
  if this.z != z:
    let oldZ = this.z
    this.z = z
    for listener in this.zChangeListeners:
      listener(oldZ, this.z)

# proc sortChildren*(this: Layer, cmp: proc (x, y: Node): int) =
#   this.children.sort(cmp)

method addChild*(this: Layer, child: Node) {.base.} =
  ## Adds the child to this Layer.
  this.children.add(child)

method removeChild*(this: Layer, child: Node) {.base.} =
  ## Marks the child to be removed on the next update.
  child.flags = (child.flags or DEAD)

iterator items*(this: Layer): Node =
  for child in this.children:
    yield child

proc addZChangeListener*(this: Layer, listener: ZChangeListener) =
  this.zChangeListeners.add(listener)

proc removeZChangeListener*(this: Layer, listener: ZChangeListener) =
  for i, l in this.zChangeListeners:
    if l == listener:
      this.zChangeListeners.del(i)
      break

proc addZChangeListenerOnce*(this: Layer, listener: ZChangeListener): ZChangeListener =
  ## Add a listener that is removed automatically after one invocation.
  ## Returns the listener that was directly added to the Layer.
  ## Use this returned node if you need to remove the listener early.
  let onceListener =
    proc(oldZ, newZ: float) =
      listener(oldZ, newZ)
      this.removeZChangeListener(listener)

  this.zChangeListeners.add(onceListener)
  return onceListener

method update*(this: Layer, deltaTime: float) =
  procCall Node(this).update(deltaTime)

  for child in this.children:
    if child.shouldUpdate:
      update(child, deltaTime)

  # for i in countdown(this.children.len() - 1, 0):
  #   if this.children[i].isDead:
  #     this.children.del(i)

  if not this.children.areElementsLocked():
    this.children.keepItIf(not it.isDead)

Layer.renderAsNodeChild:
  for child in this:
    if not child.shouldRender:
      continue

    if child.shader != nil:
      renderWithShader(child.shader):
        child.render(ctx, offsetX, offsetY)
    else:
      child.render(ctx, offsetX, offsetY)

