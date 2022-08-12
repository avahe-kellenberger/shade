import sdl2_nim/sdl_gpu
from ../math/mathutils import CompletionRatio
import
  ../math/vector2,
  ../math/aabb,
  ../render/color

export
  CompletionRatio,
  Vector,
  Color,
  Target

type
  Size* = float
  PixelSize* = Size
  RatioSize* = CompletionRatio

  Insets* = AABB

  Alignment* = enum
    Start
    Center
    End
  
  StackDirection* = enum
    Vertical
    Horizontal

  ValidationStatus* = enum
    Valid
    Invalid
    InvalidChild

  UIComponent* = ref object of RootObj
    ## Top-down design: child components cannot cause their parent components to resize.
    parent: UIComponent
    children: seq[UIComponent]
    # If width or height are == 0, fill out all space available in layout.
    width: Size
    height: Size
    margin*: Insets
    padding*: Insets
    alignHorizontal*: Alignment
    alignVertical*: Alignment
    stackDirection*: StackDirection
    layoutStatus: ValidationStatus
    bounds: AABB
    backgroundColor*: Color
    clipToBounds*: bool

template insets*(left, top, right, bottom: float): Insets =
  Insets(aabb(left, top, right, bottom))

template margin*(left, top, right, bottom: float): Insets =
  insets(left, top, right, bottom)

template padding*(left, top, right, bottom: float): Insets =
  insets(left, top, right, bottom)

method preRender*(this: UIComponent, ctx: Target, offsetX, offsetY: float) {.base.}
proc updateBounds*(this: UIComponent, x, y, width, height: float)

proc newUIComponent*(): UIComponent =
  return UIComponent(layoutStatus: Valid)

proc layoutValidationStatus*(this: UIComponent): lent ValidationStatus =
  return this.layoutStatus

proc `layoutValidationStatus=`(this: UIComponent, status: ValidationStatus) =
  this.layoutStatus = status
  case status:
    of Valid:
      discard
    of Invalid:
      if this.parent != nil and this.parent.layoutValidationStatus == Valid:
        this.parent.layoutValidationStatus = InvalidChild
    of InvalidChild:
      discard

proc `width=`*(this: UIComponent, width: float) =
  this.width = width
  this.layoutValidationStatus = Invalid

proc `height=`*(this: UIComponent, height: float) =
  this.height = height
  this.layoutValidationStatus = Invalid

proc `size=`*(this: UIComponent, width, height: float) =
  this.width = width
  this.height = height
  this.layoutValidationStatus = Invalid

proc parent*(this: UIComponent): UIComponent =
  return this.parent

proc children*(this: UIComponent): lent seq[UIComponent] =
  return this.children

proc addChild*(this, child: UIComponent) =
  this.children.add(child)
  child.parent = this
  this.layoutValidationStatus = Invalid

proc bounds*(this: UIComponent): lent AABB =
  return this.bounds

method update*(this: UIComponent, deltaTime: float) {.base.} =
  discard

proc determineChildrenSize(this: UIComponent): Vector =
  ## Calculates the size of children which do not have a fixed width or height.
  ## These children have a width and height <= 0.
  case this.stackDirection:
    of Vertical:
      result.x = this.bounds.width

      var
        unreservedHeight = this.bounds.height
        numChildrenWithoutFixedHeight = this.children.len

      for child in this.children:
        if child.height > 0:
          unreservedHeight -= child.height
          numChildrenWithoutFixedHeight -= 1

      if unreservedHeight > 0 and numChildrenWithoutFixedHeight > 0:
        result.y = unreservedHeight / float(numChildrenWithoutFixedHeight)

    of Horizontal:
      result.y = this.bounds.height

      var
        unreservedWidth = this.bounds.width
        numChildrenWithoutFixedWidth = this.children.len

      for child in this.children:
        if child.width > 0:
          unreservedWidth -= child.width
          numChildrenWithoutFixedWidth -= 1

      if unreservedWidth > 0 and numChildrenWithoutFixedWidth > 0:
        result.x = unreservedWidth / float(numChildrenWithoutFixedWidth)

proc calcChildRenderStartPosition(
  this: UIComponent,
  axis: static StackDirection,
  availableLen: float,
  maxChildLen: float
): float =
  ## Calculates the starting position to render a child on the x axis.
  ## availableLen: Available space on the axis to render children.
  ## maxChildWidth: Maximum length of a child along the axis that does not have a fixed width/height.
  if this.stackDirection != axis:
    return 0.0

  template childLen(): Size =
    when axis == Horizontal:
      child.width
    else:
      child.height

  template axisAlignment(): Alignment =
    if axis == Horizontal:
      this.alignHorizontal
    else:
      this.alignVertical

  case axisAlignment:
    of Start:
      return 0.0

    of Center:
      var totalChildrenLen = 0.0
      for child in this.children:
        if childLen > 0:
          totalChildrenLen += childLen
        else:
          totalChildrenLen += maxChildLen

      return (availableLen - totalChildrenLen) / 2.0

    of End:
      result = availableLen
      for child in this.children:
        if childLen > 0:
          result -= childLen
        else:
          result -= maxChildLen

proc updateChildrenBounds(
  this: UIComponent,
  startX: float,
  startY: float,
  maxChildSize: Vector,
  thisBounds: AABB
) =
  var
    x = startX
    y = startY

  for child in this.children:
    let width = if child.width > 0: child.width else: maxChildSize.x
    let height = if child.height > 0: child.height else: maxChildSize.y
    case this.stackDirection:
      of Vertical:
        case this.alignHorizontal:
          of Start:
            discard
          of Center:
            x = startX + (thisBounds.width - width) / 2.0
          of End:
            x = startX + thisBounds.width - width

      of Horizontal:
        case this.alignVertical:
          of Start:
            discard
          of Center:
            y = startY + (thisBounds.height - height) / 2.0
          of End:
            y = startY + thisBounds.height - height

    child.updateBounds(x, y, width, height)

    case this.stackDirection:
      of Vertical:
        y += height
      of Horizontal:
        x += width

proc updateBounds*(this: UIComponent, x, y, width, height: float) =
  this.bounds.topLeft.x = x + this.margin.left + this.padding.left
  this.bounds.topLeft.y = y + this.margin.top + this.padding.top
  this.bounds.bottomRight.x = x + width - this.margin.right - this.padding.right
  this.bounds.bottomRight.y = y + height - this.margin.bottom - this.padding.bottom

  let maxChildSize = this.determineChildrenSize()
  let x = this.calcChildRenderStartPosition(Horizontal, this.bounds.width, maxChildSize.x)
  let y = this.calcChildRenderStartPosition(Vertical, this.bounds.height, maxChildSize.y)

  this.updateChildrenBounds(
    x + this.bounds.left,
    y + this.bounds.top,
    maxChildSize,
    this.bounds
  )

method preRender*(this: UIComponent, ctx: Target, offsetX, offsetY: float) {.base.} =
  ctx.rectangleFilled(
    offsetX + this.bounds.left,
    offsetY + this.bounds.top,
    offsetX + this.bounds.right,
    offsetY + this.bounds.bottom,
    this.backgroundColor
  )

  for child in this.children:
    child.preRender(ctx, offsetX, offsetY)

method postRender*(this: UIComponent, ctx: Target, offsetX, offsetY: float) {.base.} =
  discard

