import
  layer,
  physicsbody,
  ../math/mathutils,
  ../math/collision/sat,
  ../math/collision/collisionresult

export
  layer,
  physicsbody

# TODO: Tune
const DEFAULT_GRAVITY* = vector(0, 2000)

type PhysicsLayer* = ref object of Layer
  physicsBodyChildren: seq[PhysicsBody]

proc initPhysicsLayer*(
  layer: PhysicsLayer,
  gravity: Vector = DEFAULT_GRAVITY,
  z: float = 1.0
) =
  initLayer(layer, z)

proc newPhysicsLayer*(gravity: Vector = DEFAULT_GRAVITY, z: float = 1.0): PhysicsLayer =
  result = PhysicsLayer()
  initPhysicsLayer(result, gravity, z)

method addChildNow(this: PhysicsLayer, child: Node) =
  procCall Layer(this).addChildNow(child)
  if child of PhysicsBody:
    this.physicsBodyChildren.add((PhysicsBody) child)

method removeChildNow*(this: PhysicsLayer, child: Node) =
  procCall Layer(this).removeChildNow(child)
  if child of PhysicsBody:
    let body = (PhysicsBody) child
    var index = -1
    for i, n in this.physicsBodyChildren:
      if n == body:
        index = i
        break
    
    if index >= 0:
      this.physicsBodyChildren.delete(index)

iterator physicsBodyChildIterator(this: PhysicsLayer): PhysicsBody =
  for body in this.physicsBodyChildren:
    yield body

method update*(this: PhysicsLayer, deltaTime: float) =
  procCall Layer(this).update(deltaTime)

  # TODO: Implement broad phase

  for bodyA in this.physicsBodyChildIterator:
    if bodyA.kind == pbStatic or bodyA.collisionShape == nil:
      # Static bodies do not need to be checked,
      # but other bodies may collide with them.
      continue

    let moveVectorA = bodyA.velocity * deltaTime

    for bodyB in this.physicsBodyChildIterator:
      if bodyA == bodyB or bodyB.collisionShape == nil:
        # Don't collide with self.
        continue
      
      let collision = collides(
        bodyA.center,
        bodyA.collisionShape,
        moveVectorA,
        bodyB.center,
        bodyB.collisionShape,
        bodyB.velocity * deltaTime
      )

      if collision == nil:
        continue

      let
        collisionA = if collision.isCollisionOwnerA: collision else: collision.flip()
        collisionB = if collision.isCollisionOwnerA: collision.flip() else: collision

      let
        relVelocity = bodyB.velocity - bodyA.velocity
        velAlongNormal = relVelocity.dotProduct(collisionA.normal)

      if velAlongNormal > 0:
        # Do not resolve if velocities are separating.
        continue

      # Calculate restitution.
      let e = min(bodyA.collisionShape.elasticity, bodyB.collisionShape.elasticity)
      template iMassA: float = bodyA.collisionShape.inverseMass
      template iMassB: float = bodyB.collisionShape.inverseMass

      # Calculate impuse scalar.
      let j = (-(1.0 + e) * velAlongNormal) / (iMassA + iMassB)

      # Apply the impulse.
      bodyA.velocity -= collisionA.normal * (j * iMassA)
      bodyB.velocity += collisionA.normal * (j * iMassB)

      # Translate the bodies out of each other.
      bodyA.center += collisionA.getMinimumTranslationVector()
      bodyB.center += collisionB.getMinimumTranslationVector()

PhysicsLayer.renderAsChildOf(Layer):
  for body in this.physicsBodyChildIterator():
    body.render(ctx)

