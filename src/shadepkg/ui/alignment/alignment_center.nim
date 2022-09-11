import ../ui_component

template alignMainAxis(this: UIComponent, axis: static StackDirection) =
  let totalAvailableLen = this.len() - this.totalPaddingAndBorders(axis)
  let maxChildLen = determineDynamicChildLen(this, axis)

  var
    totalChildrenLen: float
    prevChild: UIComponent

  # Calculate the total length all children use up
  for child in this.children:
    let
      childPixelLen = pixelLen(this, child, axis)
      childLen = if childPixelLen > 0: childPixelLen else: maxChildLen

    totalChildrenLen += childLen + child.startMargin

    if prevChild != nil and prevChild.endMargin > child.startMargin:
      totalChildrenLen += prevChild.endMargin - child.startMargin

    prevChild = child

  # Set child positions and sizes
  prevChild = nil
  var childStart: float =
    this.boundsStart + this.startPadding + this.borderWidth + totalAvailableLen / 2 - totalChildrenLen / 2

  for child in this.children:
    let
      childPixelLen = pixelLen(this, child, axis)
      childLen = if childPixelLen > 0: childPixelLen else: maxChildLen

    child.set(childStart, childLen)

    childStart += childLen + child.startMargin

    if prevChild != nil and prevChild.endMargin > child.startMargin:
      childStart += prevChild.endMargin - child.startMargin

    prevChild = child

template alignCrossAxis(this: UIComponent, axis: static StackDirection) =
  let
    totalAvailableLen = this.len() - this.totalPaddingAndBorders(axis)
    maxChildLen: float = determineDynamicChildLen(this, axis)
    center = this.boundsStart + this.startPadding + this.borderWidth + totalAvailableLen / 2

  for child in this.children:
    let
      childPixelLen = pixelLen(child, totalAvailableLen, axis)
      childLen = if childPixelLen > 0: childPixelLen else: maxChildLen
      childStart = center - childLen / 2

    child.set(childStart, childLen)

proc alignCenter*(this: UIComponent, axis: static StackDirection) =
  ## Aligns children along the given axis with Alignment.Center
  if axis == this.stackDirection:
    this.alignMainAxis(axis)
  else:
    this.alignCrossAxis(axis)

