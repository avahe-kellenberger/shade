import ../ui_component

template alignMainAxis(this: UIComponent, axis: static StackDirection) =
  var childStart =
    when axis == Horizontal:
      this.bounds.left + this.borderWidth + this.padding.left
    else:
      this.bounds.top + this.borderWidth + this.padding.top

  let maxChildLen = determineDynamicChildLen(this, axis)

  var prevChild: UIComponent

  for child in this.children:
    let
      childPixelLen = pixelLen(this, child, axis)
      childLen = if childPixelLen > 0: childPixelLen else: maxChildLen

    childStart += child.startMargin
    child.set(childStart, childLen)

    childStart += childLen

    if prevChild != nil and prevChild.endMargin > child.startMargin:
      childStart += prevChild.endMargin - child.startMargin

    prevChild = child

template alignCrossAxis(this: UIComponent, axis: static StackDirection) =
  let childStart =
    when axis == Horizontal:
      this.bounds.left + this.borderWidth + this.padding.left
    else:
      this.bounds.top + this.borderWidth + this.padding.top

  let maxChildLen: float = determineDynamicChildLen(this, axis)

  for child in this.children:
    let
      childPixelLen = pixelLen(this, child, axis)
      childLen = if childPixelLen > 0: childPixelLen else: (maxChildLen - child.startMargin - child.endMargin)

    child.set(childStart + child.startMargin, childLen)

proc alignStart*(this: UIComponent, axis: static StackDirection) =
  ## Aligns children along the given axis with Alignment.Start
  if axis == this.stackDirection:
    this.alignMainAxis(axis)
  else:
    this.alignCrossAxis(axis)

