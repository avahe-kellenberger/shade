import
  hashes,
  sequtils

import
  node,
  ../render/render,
  ../math/vector2

export
  node,
  hashes,
  sequtils,
  render

type
  Entity* = ref object of Node
    location: Vector
    # Rotation in degrees (clockwise).
    rotation*: float

method setLocation*(this: Entity, x, y: float) {.base.}
method hash*(this: Entity): Hash {.base.}

proc initEntity*(entity: Entity, flags: NodeFlags = UPDATE_AND_RENDER) =
  entity.flags = flags

proc newEntity*(flags: NodeFlags = UPDATE_AND_RENDER): Entity =
  result = Entity()
  initEntity(result, flags)

method getLocation*(this: Entity): Vector {.base.} =
  this.location

method x*(this: Entity): float {.base.} =
  this.location.x

method y*(this: Entity): float {.base.} =
  this.location.y

method `x=`*(this: Entity, x: float) {.base.} =
  this.setLocation(x, this.y)

method `y=`*(this: Entity, y: float) {.base.} =
  this.setLocation(this.x, y)

method setLocation*(this: Entity, x, y: float) {.base.} =
  this.location.x = x
  this.location.y = y

method setLocation*(this: Entity, v: Vector) {.base.} =
  this.setLocation(v.x, v.y)

method move*(this: Entity, dx, dy: float) {.base.} =
  this.setLocation(this.x + dx, this.y + dy)

method move*(this: Entity, v: Vector) {.base.} =
  this.setLocation(this.x + v.x, this.y + v.y)

method hash*(this: Entity): Hash {.base.} =
  return hash(this[].unsafeAddr)

