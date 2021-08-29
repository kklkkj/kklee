import
  std/[sugar, strutils, sequtils, algorithm, dom, math],
  pkg/karax/[karax, karaxdsl, vdom, vstyles],
  kkleeApi, bonkElements

var
  selectedFixtures*: seq[MapFixture]
  fixturesBody*: MapBody

proc removeDeletedFixtures =
  var i = 0
  while i < selectedFixtures.len:
    let fx = selectedFixtures[i]
    if moph.fixtures.find(fx) == -1:
      selectedFixtures.delete i
    else:
      inc i

proc shapeMultiSelectElementBorders* =
  removeDeletedFixtures()
  let
    shapeElements = document
      .getElementById("mapeditor_rightbox_shapetablecontainer")
      .getElementsByClassName("mapeditor_rightbox_table_shape_headerfield")
      .reversed
    body = getCurrentBody().getBody
  for i, se in shapeElements:
    let prevNode = se.previousSibling
    if not prevNode.isNil and prevNode.class ==
        "kkleeMultiSelectShapeIndexLabel":
      prevNode.remove()

    let selectedId = selectedFixtures.find(body.fx[i].getFx)
    if selectedId == -1:
      se.style.border = ""
    else:
      se.style.border = "4px solid blue"

      let indexLabel = document.createElement("span")
      indexLabel.innerText = $selectedId
      indexLabel.setAttr("style", "color: blue; font-size: 12px")
      indexLabel.class = "kkleeMultiSelectShapeIndexLabel"
      se.parentNode.insertBefore(indexLabel, se)

proc shapeMultiSelectSwitchPlatform* =
  if getCurrentBody().getBody != fixturesBody:
    selectedFixtures = @[]
    shapeMultiSelectElementBorders()
  fixturesBody = getCurrentBody().getBody


proc shapeMultiSelectEdit: VNode = buildHtml tdiv(
    style = "display: flex; flex-flow: column".toCss):

  proc onMouseEnter =
    setEditorExplanation("""
[kklee]
Shift+click shape name fields to select shapes
Variables:
 - x is the current value
 - i is the index in list of selected shapes (the first shape you selected will have i=0, the next one i=1, i=2, etc)
Arithmetic, such as x*2+50, will be evaluated
    """)

  var appliers {.global.}: seq[(int, MapFixture) -> void]

  template floatProp(
    name: string; mapFxProp: untyped;
    inpToProp = floatNop;
    propToInp = floatNop;
  ): untyped =
    let
      inpToPropF = inpToProp
      propToInpF = propToInp
    var inp {.global.}: string = "x"

    once: appliers.add proc (i: int; fx {.inject.}: MapFixture) =
      mapFxProp = inpToPropF floatPropApplier(inp, i, propToInpF mapFxProp)

    buildHtml:
      prop name, floatPropInput(inp), inp != "x"

  template boolProp(name: string; mapFxProp: untyped): untyped =
    var inp {.global.}: boolPropValue
    once: appliers.add proc(i: int; fx {.inject.}: MapFixture) =
      case inp
      of tfsFalse: mapFxProp = false
      of tfsTrue: mapFxProp = true
      of tfsSame: discard
    buildHtml:
      prop name, tfsCheckbox(inp), inp != tfsSame

  template colourChanger: untyped =
    var
      canChange {.global.} = false
      inp {.global.}: int = 0
    once: appliers.add proc(i: int; fx: MapFixture) =
      if canChange:
        fx.f = inp
    buildHtml:
      let field = buildHtml tdiv(style = "display: flex".toCss):
        checkbox(canChange)
        colourInput(inp)
      prop "Colour", field, canChange

  template nameChanger: untyped =
    var
      canChange {.global.} = false
      inp {.global.}: string = "Shape %i%"
    once: appliers.add proc(i: int; fx: MapFixture) =
      if canChange:
        fx.n = inp.replace("%i%", $i).cstring
    buildHtml:
      let field = buildHtml tdiv(style = "display: flex".toCss):
        checkbox(canChange)
        bonkInput(inp, s => s, nil, s => s)
      prop "Name", field, canChange

  nameChanger()
  floatProp("x", fx.fxShape.c.x)
  floatProp("y", fx.fxShape.c.y)
  block:
    let
      d2r = proc(f: float): float = degToRad(f)
      r2d = proc(f: float): float = radToDeg(f)
    floatProp("Angle", fx.fxShape.a, d2r, r2d)
  floatProp("Rect width", fx.fxShape.bxW)
  floatProp("Rect height", fx.fxShape.bxH)
  floatProp("Circle radius", fx.fxShape.ciR)
  floatProp("Density", fx.de)
  floatProp("Bounciness", fx.re)
  floatProp("Friction", fx.fr)

  boolProp("No physics", fx.np)
  boolProp("No grapple", fx.ng)
  boolProp("Inner grapple", fx.ig)
  boolProp("Death", fx.d)
  boolProp("Shrink", fx.fxShape.sk)

  colourChanger()

  bonkButton "Apply", proc =
    removeDeletedFixtures()
    for i, f in selectedFixtures:
      for a in appliers: a(i, f)
    saveToUndoHistory()
    updateRenderer(true)
    updateRightBoxBody(-1)


proc shapeMultiSelectCopy: VNode = buildHtml tdiv(
    style = "display: flex; flex-flow: column".toCss):
  var
    copyShapes {.global.}: seq[tuple[fx: MapFixture; sh: MapShape]]
    pasteAmount {.global.} = 1
  bonkButton "Copy shapes", proc =
    removeDeletedFixtures()
    copyShapes = @[]
    for fx in selectedFixtures:
      copyShapes.add (fx: fx.copyObject(), sh: fx.fxShape.copyObject())

  prop "Paste amount", bonkInput(pasteAmount, parseInt, nil, i => $i)
  bonkButton "Paste shapes", proc =
    shapeMultiSelectSwitchPlatform()
    proc copyFxSh(fx: MapFixture; sh: MapShape) =
      moph.shapes.add sh.copyObject()
      let newFx = fx.copyObject()
      moph.fixtures.add newFx
      newFx.sh = moph.shapes.high
      selectedFixtures.add newFx
      fixturesBody.fx.add moph.fixtures.high
    block outer:
      for _ in 1..pasteAmount:
        for (fx, sh) in copyShapes.mitems:
          if fixturesBody.fx.len > 100:
            break outer
          copyFxSh(fx, sh)
    saveToUndoHistory()
    updateRenderer(true)
    updateRightBoxBody(-1)

proc shapeMultiSelectSelectAll: VNode = buildHtml tdiv:
  bonkButton "Select all", proc =
    shapeMultiSelectSwitchPlatform()
    selectedFixtures = collect(newSeq):
      for fxId in fixturesBody.fx: fxId.getFx
    shapeMultiSelectElementBorders()
  bonkButton "Deselect all", proc =
    selectedFixtures = @[]
    shapeMultiSelectElementBorders()
  bonkButton "Invert selection", proc =
    selectedFixtures = collect(newSeq):
      for fxId in fixturesBody.fx:
        let fx = fxId.getFx
        if fx notin selectedFixtures:
          fx
    shapeMultiSelectElementBorders()

proc shapeMultiSelectDelete: VNode =
  buildHtml bonkButton "Delete shapes", proc =
    for f in selectedFixtures:
      let fxId = moph.fixtures.find f
      if fxId == -1: continue
      deleteFx(fxId)
    saveToUndoHistory()
    selectedFixtures = @[]
    updateRenderer(true)
    updateRightBoxBody(-1)

proc shapeMultiSelectMove: VNode = buildHtml tdiv(style =
  "display: flex; flex-flow: row wrap; justify-content: space-between;".toCss
    ):
  text "Move"
  template fx: untyped = fixturesBody.fx
  proc update =
    updateRightBoxBody(-1)
    updateRenderer(true)
    saveToUndoHistory()
  proc getSelectedFxIds: seq[int] =
    selectedFixtures.mapIt moph.fixtures.find(it)
  bonkButton "Down", proc =
    let selectedFxIds = getSelectedFxIds()
    for i in countup(1, fx.high):
      if selectedFxIds.find(fx[i]) != -1 and
          selectedFxIds.find(fx[i - 1]) == -1:
        swap(fx[i], fx[i - 1])
    update()
  bonkButton "Up", proc =
    let selectedFxIds = getSelectedFxIds()
    for i in countdown(fx.high - 1, 0):
      if selectedFxIds.find(fx[i]) != -1 and
          selectedFxIds.find(fx[i + 1]) == -1:
        swap(fx[i], fx[i + 1])
    update()
  bonkButton "Bottom", proc =
    let selectedFxIds = getSelectedFxIds()
    var moveIndex = 0
    for i in countup(0, fx.high):
      if selectedFxIds.find(fx[i]) == -1: continue
      inc moveIndex
      for j in countdown(i, moveIndex):
        swap fx[j], fx[j - 1]
    update()
  bonkButton "Top", proc =
    let selectedFxIds = getSelectedFxIds()
    var moveIndex = fx.high
    for i in countdown(fx.high, 0):
      if selectedFxIds.find(fx[i]) == -1: continue
      dec moveIndex
      for j in countup(i, moveIndex):
        swap fx[j], fx[j + 1]
    update()

proc shapeMultiSelect*: VNode =
  shapeMultiSelectSwitchPlatform()
  buildHtml(tdiv(
      style = "display: flex; flex-flow: column; row-gap: 10px".toCss)):
    shapeMultiSelectSelectAll()
    shapeMultiSelectEdit()
    shapeMultiSelectMove()
    shapeMultiSelectDelete()
    shapeMultiSelectCopy()
