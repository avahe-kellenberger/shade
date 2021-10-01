import
  node,
  material,
  ../math/rectangle,
  ../math/mathutils

export node, rectangle, material, mathutils

type 
  Entity* = ref object of Node
    # Pixels per second.
    velocity*: Vec2
    lastMoveVector*: Vec2

proc initEntity*(entity: Entity, flags: set[LayerObjectFlags], centerX, centerY: float = 0.0) =
  initNode(Node(entity), flags)
  entity.center.x = centerX
  entity.center.y = centerY

proc newEntity*(flags: set[LayerObjectFlags], centerX, centerY: float = 0.0): Entity =
  result = Entity()
  initEntity(result, flags, centerX, centerY)

template x*(this: Entity): float = this.center.x
template y*(this: Entity): float = this.center.y

template translate*(this: Entity, delta: Vec2) =
  this.center += delta

template rotate*(this: Entity, deltaRotation: float) =
  this.rotation += deltaRotation

method update*(this: Entity, deltaTime: float) =
  procCall Node(this).update(deltaTime)
  this.lastMoveVector = this.velocity * deltaTime
  this.center += this.lastMoveVector

